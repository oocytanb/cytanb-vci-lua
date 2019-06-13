----------------------------------------------------------------
--  Copyright (c) 2019 oO (https://github.com/oocytanb)
--  MIT Licensed
----------------------------------------------------------------

-- VCI 環境の簡易 Mock モジュール。

if not string.contains then
	-- [MoonSharp](https://www.moonsharp.org/additions.html)
	string.contains = function (str1, str2)
		return string.find(str1, str2, 1, true) ~= nil
	end
end

if not string.startsWith then
	-- [MoonSharp](https://www.moonsharp.org/additions.html)
	string.startsWith = function (str1, str2)
		local len1 = string.len(str1)
		local len2 = string.len(str2)
		if len1 < len2 then
			return false
		elseif len2 == 0 then
			return true
		end

		return str2 == string.sub(str1, 1, len2)
	end
end

if not string.endsWith then
	-- [MoonSharp](https://www.moonsharp.org/additions.html)
	string.endsWith = function (str1, str2)
		local len1 = string.len(str1)
		local len2 = string.len(str2)
		if len1 < len2 then
			return false
		elseif len2 == 0 then
			return true
		end

		local i = string.find(str1, str2, - len2, true)
		return i ~= nil
	end
end

if not json then
	-- [MoonSharp](https://www.moonsharp.org/additions.html)
	local dkjson = require('dkjson')
	json = {
		parse = function (jsonString)
			return dkjson.decode(jsonString, 1, dkjson.null)
		end,

		serialize = function (table)
			local t = type(table)
			if t ~= 'table' then
				error('Invalid type: ' .. t)
			end
			return dkjson.encode(table)
		end,

		isNull = function (val)
			return val == dkjson.null
		end,

		null = function ()
			return dkjson.null
		end
	}
end
