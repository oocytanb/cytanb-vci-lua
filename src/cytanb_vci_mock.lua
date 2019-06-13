----------------------------------------------------------------
--  Copyright (c) 2019 oO (https://github.com/oocytanb)
--  MIT Licensed
----------------------------------------------------------------

if not string.contains then
	-- [MoonSharp](http://www.moonsharp.org/additions.html)
	string.contains = function (str1, str2)
		return string.find(str1, str2, 1, true) ~= nil
	end
end

if not string.startsWith then
	-- [MoonSharp](http://www.moonsharp.org/additions.html)
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
	-- [MoonSharp](http://www.moonsharp.org/additions.html)
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
