-- Created by swadical@lab.glua.team
-- Used in ARCLib with permission
local TEST_LOAD = true -- set to false to live on the wild side and not assert-test on load

--[[ Highest positive signed 32-bit float value ]]
local maxInt = 2147483647 -- aka. 0x7FFFFFFF or 2^31-1

--[[ Bootstring parameters ]]

local base = 36
local tMin = 1
local tMax = 26
local skew = 38
local damp = 700
local initialBias = 72
local initialN = 128 -- 0x80
local delimiter = "-" -- "\x2D"

--[[ js helpers ]]

local function _bool(b)
    return b and 1 or 0
end

--[[ utf8 helpers ]]

local function utf8lookup(str,lookup)
    local out = {}
    
    for pos,code in utf8.codes(str) do
        local char = utf8.char(code)
        
        if lookup[char] then
            out[#out + 1] = char
        end
    end
    
    return out
end


local function utf8lastIndexOf(str,char)
    local p,c
    local point = utf8.codepoint(char,1)
    
    for pos,code in utf8.codes(str) do
        if code == point then
            p,c = pos,code
        end
    end
    
    return p,c
end


local function utf8gsub(str,lookup,sub)
    local out = ""
    
    for pos,code in utf8.codes(str) do
        local char = utf8.char(code)
        
        if lookup[char] then
            out = out .. sub
        else
            out = out .. char
        end
    end
    
    return out
end


local function utf8at(str,at)
    local idx = 1
    
    for pos,code in utf8.codes(str) do
        if idx == at then
            return code
        end
        
        idx = idx + 1
    end
    
    error("Out of range")
end

--[[ Regular expressions ]]

local regexPunycode = "^xn%-%-"
local regexNonASCII = "[\x7F-\xFF]" -- non-ASCII chars
local regexSeparatorsLookup = {
    ["\x2e"] = true, -- "."
    ["\xe3\x80\x82"] = true, -- "。"
    ["\xef\xbc\x8e"] = true, -- "．"
    ["\xef\xbd\xa1"] = true, -- "｡"
}

local function regexSeparators(str)
    -- RFC 3490 separator lookup
    return utf8lookup(str,regexSeparatorsLookup)
end


local function regexSeparatorsReplace(str,sub)
    -- RFC 3490 separator replacement
    return utf8gsub(str,regexSeparatorsLookup,sub)
end

--[[ Error messages ]]

local errors = {
    overflow = "Overflow: input needs wider integers to process",
    notBasic = "Illegal input >= 0x80 (not a basic code point)",
    invalidInput = "Invalid input"
}
--[[ Convenience shortcuts ]]
local baseMinusTMin = base - tMin
local floor = math.floor
local stringFromCharCode = utf8.char

--[[--------------------------------------------------------------------------]]

--[[
 - A generic error utility function.
 - @private
 - @param {String} type The error type.
 - @returns {Error} Throws a `RangeError` with the applicable error message.
]]
local _error = error

local function error(type)
    _error(errors[type])
end

--[[
 - A generic `Array#map` utility function.
 - @private
 - @param {Array} array The array to iterate over.
 - @param {Function} callback The function that gets called for every array
 - item.
 - @returns {Array} A new array of values returned by the callback function.
 ]]

local function map(array,fn)
    local result = {}
    local length = #array
    
    while length ~= 0 do
        result[length] = fn(array[length])
        length = length - 1
    end
    
    return result
end

--[[
 - string split because lua
 - @private
 - @param {String} str String to split
 - @param {String} sep Separator string
 - @returns {Array} Array of split strings.
]]

local function stringsplit(str,sep)
    local sep,fields = sep,{}
    local pattern = string.format("([^%s]+)",sep)
    string.gsub(str,pattern,function(c)
        fields[#fields + 1] = c
    end)
    return fields
end

--[[
 - A simple `Array#map`-like wrapper to work with domain name strings or email
 - addresses.
 - @private
 - @param {String} domain The domain name or email address.
 - @param {Function} callback The function that gets called for every
 - character.
 - @returns {Array} A new string of characters returned by the callback
 - function.
 ]]

local function mapDomain(str,fn)
    local parts = stringsplit(str,"@")
    local result = ""
    
    if (#parts > 1) then
        -- In email addresses, only the domain name should be punycoded. Leave
        -- the local part (i.e. everything up to `@`) intact.
        result = parts[1] .. "@"
        str = parts[2]
    end
    
    str = regexSeparatorsReplace(str,".")
    local labels = stringsplit(str,".")
    local encoded = table.concat(map(labels,fn),".")
    return result .. encoded
end

--[[
 - Creates an array containing the numeric code points of each Unicode
 - character in the string. While JavaScript uses UCS-2 internally,
 - this function will convert a pair of surrogate halves (each of which
 - UCS-2 exposes as separate characters) into a single code point,
 - matching UTF-16.
 - @see `punycode.ucs2.encode`
 - @see <https:--mathiasbynens.be/notes/javascript-encoding>
 - @memberOf punycode.ucs2
 - @name decode
 - @param {String} string The Unicode input string (UCS-2).
 - @returns {Array} The new array of code points.
 ]]

local function ucs2decode(str)
    local output = {}
    local counter = 1
    local length = utf8.len(str)
    
    while (counter <= length) do
        local value = utf8at(str,counter)
        
        if ((value >= 0xD800) and (value <= 0xDBFF) and (counter < length)) then
            -- It's a high surrogate, and there is a next character.
            counter = counter + 1
            local extra = utf8at(str,counter)
            
            if (bit.band(extra,0xFC00) == 0xDC00) then
                -- Low surrogate.
                output[#output + 1] = (bit.lshift(bit.band(value,0x3FF),10) + bit.band(extra,0x3FF) + 0x10000)
            else
                -- It's an unmatched surrogate; only append this code unit, in case the
                -- next code unit is the high surrogate of a surrogate pair.
                output[#output + 1] = (value)
                counter = counter - 1
            end
        else
            output[#output + 1] = (value)
        end
        
        counter = counter + 1
    end
    
    return output
end

--[[
 - Creates a string based on an array of numeric code points.
 - @see `punycode.ucs2.decode`
 - @memberOf punycode.ucs2
 - @name encode
 - @param {Array} codePoints The array of numeric code points.
 - @returns {String} The new Unicode string (UCS-2).
 ]]

local function ucs2encode(arr)
    local out = {}
    
    for _,code in ipairs(arr) do
        out[#out + 1] = utf8.char(code)
    end
    
    return table.concat(out,"")
end

--[[
 - Converts a basic code point into a digit/integer.
 - @see `digitToBasic()`
 - @private
 - @param {Number} codePoint The basic numeric code point value.
 - @returns {Number} The numeric value of a basic code point (for use in
 - representing integers) in the range `0` to `base - 1`, or `base` if
 - the code point does not represent a value.
 ]]

local function basicToDigit(codePoint)
    if (codePoint - 0x30 < 0x0A) then
        return codePoint - 0x16
    end
    
    
    if (codePoint - 0x41 < 0x1A) then
        return codePoint - 0x41
    end
    
    
    if (codePoint - 0x61 < 0x1A) then
        return codePoint - 0x61
    end
    
    return base
end

--[[
 - Converts a digit/integer into a basic code point.
 - @see `basicToDigit()`
 - @private
 - @param {Number} digit The numeric value of a basic code point.
 - @returns {Number} The basic code point whose value (when used for
 - representing integers) is `digit`, which needs to be in the range
 - `0` to `base - 1`. If `flag` is non-zero, the uppercase form is
 - used; else, the lowercase form is used. The behavior is undefined
 - if `flag` is non-zero and `digit` has no uppercase form.
 ]]

local function digitToBasic(digit,flag)
    --  0..25 map to ASCII a..z or A..Z
    -- 26..35 map to ASCII 0..9
    return digit + 22 + 75 * _bool(digit < 26) - bit.lshift(_bool(flag ~= 0),5)
end

--[[
 - Bias adaptation function as per section 3.4 of RFC 3492.
 - https:--tools.ietf.org/html/rfc3492#section-3.4
 - @private
 ]]

local function adapt(delta,numPoints,firstTime)
    local k = 0
    delta = firstTime and floor(delta / damp) or bit.rshift(delta,1)
    delta = delta + floor(delta / numPoints)
    
    while (delta > baseMinusTMin * bit.rshift(tMax,1)) do
        delta = floor(delta / baseMinusTMin)
        k = k + base
    end
    
    return floor(k + (baseMinusTMin + 1) * delta / (delta + skew))
end

--[[
 - Converts a Punycode string of ASCII-only symbols to a string of Unicode
 - symbols.
 - @memberOf punycode
 - @param {String} input The Punycode string of ASCII-only symbols.
 - @returns {String} The resulting string of Unicode symbols.
 ]]

local function decode(input)
    -- Don't use UCS-2.
    local output = {}
    local inputLength = utf8.len(input)
    local i = 0
    local n = initialN
    local bias = initialBias
    -- Handle the basic code points: local `basic` be the number of input code
    -- points before the last delimiter, or `0` if there is none, then copy
    -- the first basic code points to the output.
    local basic = utf8lastIndexOf(input,delimiter)
    
    if (basic < 0) then
        basic = 0
    end
    
    
    for j=1,basic - 1 do
        -- if it's not a basic code point
        
        if (utf8at(input,j) >= 0x80) then
            error("notBasic")
        end
        
        output[#output + 1] = (utf8at(input,j))
    end

    -- Main decoding loop: start just after the last delimiter if any basic code
    -- points were copied; start at the beginning otherwise.
    
    local index = (basic > 0) and (basic) or 0
    
    while index < inputLength do
        --[[ no final expression ]]
        -- `index` is the index of the next character to be consumed.
        -- Decode a generalized variable-length integer into `delta`,
        -- which gets added to `i`. The overflow checking is easier
        -- if we increase `i` as we go, then subtract off its starting
        -- value at the end to obtain `delta`.
        local oldi = i
        local w,k = 1,base
        
        while true do
            --[[ no condition ]]
            
            if (index >= inputLength) then
                error("invalidInput")
            end
            
            index = index + 1
            local digit = basicToDigit(utf8at(input,index))
            
            if ((digit >= base) or (digit > floor((maxInt - i) / w))) then
                error("overflow")
            end
            
            i = i + digit * w
            local t = (k <= bias) and tMin or ((k >= (bias + tMax)) and tMax or (k - bias))
            
            if (digit < t) then
                break
            end
            
            local baseMinusT = base - t
            
            if (w > floor(maxInt / baseMinusT)) then
                error("overflow")
            end
            
            w = w * baseMinusT
            k = k + base
        end
        
        local i2 = i - 1
        local out = #output + 1
        bias = adapt(i - oldi,out,oldi == 0)
        -- `i` was supposed to wrap around from `out` to `0`,
        -- incrementing `n` each time, so we'll fix that now:
        
        if (floor(i / out) > (maxInt - n)) then
            error("overflow")
        end
        
        n = n + floor(i / out)
        i = i % out
        -- Insert `n` at position `i` of the output.
        i = i + 1
        table.insert(output,i,n)
    end
    
    return ucs2encode(output)
end

--[[
 - Converts a string of Unicode symbols (e.g. a domain name label) to a
 - Punycode string of ASCII-only symbols.
 - @memberOf punycode
 - @param {String} input The string of Unicode symbols.
 - @returns {String} The resulting Punycode string of ASCII-only symbols.
 ]]

local function encode(input)
    local output = {}
    -- Convert the input in UCS-2 to an array of Unicode code points.
    input = ucs2decode(input)
    -- Cache the length.
    local inputLength = #(input)
    -- Initialize the state.
    local n = initialN
    local delta = 0
    local bias = initialBias
    -- Handle the basic code points.
    
    for _,currentValue in ipairs(input) do
        if (currentValue < 0x80) then
            output[#output + 1] = (stringFromCharCode(currentValue))
        end
    end
    
    local basicLength = #output
    local handledCPCount = basicLength
    -- `handledCPCount` is the number of code points that have been handled;
    -- `basicLength` is the number of basic code points.
    -- Finish the basic string with a delimiter unless it's empty.
    
    if (basicLength) then
        output[#output + 1] = (delimiter)
    end
    
    -- Main encoding loop:
    
    while (handledCPCount < inputLength) do
        -- All non-basic code points < n have been handled already. Find the next
        -- larger one:
        local m = maxInt
        
        for _,currentValue in ipairs(input) do
            if ((currentValue >= n) and (currentValue < m)) then
                m = currentValue
            end
        end
        -- Increase `delta` enough to advance the decoder's <n,i> state to <m,0>,
        -- but guard against overflow.
        
        local handledCPCountPlusOne = handledCPCount + 1
        
        if (m - n > floor((maxInt - delta) / handledCPCountPlusOne)) then
            error("overflow")
        end
        
        delta = delta + (m - n) * handledCPCountPlusOne
        n = m
        
        for _,currentValue in ipairs(input) do
            local hasOverflow = false
            
            if currentValue < n then
                delta = delta + 1
                hasOverflow = delta > maxInt
            end
            
            
            if (hasOverflow) then
                error("overflow")
            end
            
            
            if (currentValue == n) then
                -- Represent delta as a generalized variable-length integer.
                local q = delta
                local k = base
                
                while true do
                    --[[ no condition ]]
                    local t = (k <= bias) and tMin or ((k >= (bias + tMax)) and tMax or (k - bias))
                    
                    if (q < t) then
                        break
                    end
                    
                    local qMinusT = q - t
                    local baseMinusT = base - t
                    output[#output + 1] = (stringFromCharCode(digitToBasic(t + qMinusT % baseMinusT,0)))
                    q = floor(qMinusT / baseMinusT)
                    k = k + base
                end
                
                output[#output + 1] = (stringFromCharCode(digitToBasic(q,0)))
                bias = adapt(delta,handledCPCountPlusOne,handledCPCount == basicLength)
                delta = 0
                handledCPCount = handledCPCount + 1
            end
        end
        
        delta = delta + 1
        n = n + 1
    end
    
    return table.concat(output,"")
end

--[[
 - Converts a Punycode string representing a domain name or an email address
 - to Unicode. Only the Punycoded parts of the input will be converted, i.e.
 - it doesn't matter if you call it on a string that has already been
 - converted to Unicode.
 - @memberOf punycode
 - @param {String} input The Punycoded domain name or email address to
 - convert to Unicode.
 - @returns {String} The Unicode representation of the given Punycode
 - string.
 ]]

local function toUnicode(input,nomap)
	if nomap then
		return string.match(input,regexPunycode) and decode(input:sub(5)) or input
	else
		return mapDomain(input,function(str)
			return toUnicode(str,true)
		end)
	end
end

--[[
 - Converts a Unicode string representing a domain name or an email address to
 - Punycode. Only the non-ASCII parts of the domain name will be converted,
 - i.e. it doesn't matter if you call it with a domain that's already in
 - ASCII.
 - @memberOf punycode
 - @param {String} input The domain name or email address to convert, as a
 - Unicode string.
 - @returns {String} The Punycode representation of the given domain name or
 - email address.
 ]]

local function toASCII(input,nomap)
	if nomap then
		return string.match(input,regexNonASCII) and "xn--" .. encode(input) or input
	else
		return mapDomain(input,function(str)
			return toASCII(str,true)
		end)
	end
end

--[[ tests ]]

if TEST_LOAD then
    local unicodeExample = "\x6d\x65\x6d\x65\x73\xef\xbd\xa1\x20\x28\x20\xcd\xa1\xc2\xb0\x20\xcd\x9c\xca\x96\x20\xcd\xa1\xc2\xb0\x29" -- "memes｡ ( ͡° ͜ʖ ͡°)"

    local idna_enc = "\xd0\xb4\xd0\xb6\xd1\x83\xd0\xbc\xd0\xbb\xd0\xb0\x40\x78\x6e\x2d\x2d\x70\x2d\x38\x73\x62\x6b\x67\x63\x35\x61\x67\x37\x62\x68\x63\x65\x2e\x78\x6e\x2d\x2d\x62\x61\x2d\x6c\x6d\x63\x71" -- "джумла@xn--p-8sbkgc5ag7bhce.xn--ba-lmcq"
    local idna_src = "\xd0\xb4\xd0\xb6\xd1\x83\xd0\xbc\xd0\xbb\xd0\xb0\x40\xd0\xb4\xd0\xb6\x70\xd1\x83\xd0\xbc\xd0\xbb\xd0\xb0\xd1\x82\xd0\xb5\xd1\x81\xd1\x82\x2e\x62\xd1\x80\xd1\x84\x61" -- "джумла@джpумлатест.bрфa"

    local unic_enc = "\x6d\x61\x61\x6e\x61\x2d\x70\x74\x61" -- "maana-pta"
    local unic_src = "\x6d\x61\xc3\xb1\x61\x6e\x61" -- "mañana"

    assert(ucs2encode(ucs2decode(unicodeExample)) == unicodeExample,"ucs2encode() and ucs2decode() fail")
    assert(decode(unic_enc) == unic_src,"decode() fail")
    assert(encode(unic_src) == unic_enc,"encode() fail")
    assert(toASCII(idna_src) == idna_enc,"toASCII() fail")
    assert(toUnicode(idna_enc) == idna_src,"toUnicode() fail")
end

local punycode = {
	--[[
     * A string representing the current Punycode.js version number.
     * @memberOf punycode
     * @type String
     ]]
    version = "2.1.1",
	--[[
     * An object of methods to convert from JavaScript's internal character
     * representation (UCS-2) to Unicode code points, and back.
     * @see <https:--mathiasbynens.be/notes/javascript-encoding>
     * @memberOf punycode
     * @type Object
     ]]
    ucs2 = {
        decode = ucs2decode,
        encode = ucs2encode
    },
    decode = decode,
    encode = encode,
    toASCII = toASCII,
    toUnicode = toUnicode
}

--return punycode
ARCLib.punycode = punycode
