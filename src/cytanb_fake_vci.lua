----------------------------------------------------------------
--  Copyright (c) 2019 oO (https://github.com/oocytanb)
--  MIT Licensed
----------------------------------------------------------------

-- [VCI](https://github.com/virtual-cast/VCI) 環境の簡易 Fake モジュール。

return (function ()
	local dkjson = require('dkjson')

	local ModuleName = 'cytanb_fake_vci'
	local StringModuleName = 'string'

	local SetConstants = function (targetTable, constTable)
		setmetatable(targetTable, {
			__index = constTable,
			__newindex = function (table, key, value)
				if table == targetTable and constTable[key] ~= nil then
					error('Cannot assign to read only field "' .. key .. '"')
				end
				rawset(table, key, value)
			end
		})
		return targetTable
	end

	local fakeModule = {
		-- [MoonSharp](https://www.moonsharp.org/additions.html) の拡張。
		_MOONSHARP = {
			version = '2.0.0.0',
			luacompat = string.match(_VERSION or '', '(%d+(%.%d+))') or '',
			platform = 'limited.unity.dll.mono.clr4.aot',
			is_aot = true,
			is_unity = true,
			is_mono = true,
			is_clr4 = true,
			is_pcl = false,
			banner = 'cytanb_fake_vci | Copyright (c) 2019 oO (https://github.com/oocytanb) | MIT Licensed'
		},

		-- [MoonSharp](https://www.moonsharp.org/additions.html) の拡張。
		string = {
			contains = function (str1, str2)
				return string.find(str1, str2, 1, true) ~= nil
			end,

			startsWith = function (str1, str2)
				local len1 = string.len(str1)
				local len2 = string.len(str2)
				if len1 < len2 then
					return false
				elseif len2 == 0 then
					return true
				end

				return str2 == string.sub(str1, 1, len2)
			end,

			endsWith = function (str1, str2)
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
		},

		-- [MoonSharp](https://www.moonsharp.org/additions.html) の拡張。
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
	}

	-- [VirtualCast Official Wiki](https://virtualcast.jp/wiki/)
	local vci

	local assetsConstants = {
		IsMine = true
	}

	local stateMap = {}

	vci = {
		assets = SetConstants({
		}, assetsConstants),

		state = {
			Set = function (name, value)
				local t = type(value)
				if (t == 'number' or t == 'string' or t == 'boolean') then
					stateMap[name] = value
				else
					stateMap[name] = nil
				end
			end,

			Get = function (name)
				return stateMap[name]
			end,

			Add = function (name, value)
				if type(value) == 'number' then
					local curValue = stateMap[name]
					if type(curValue) == 'number' then
						stateMap[name] = curValue + value
					else
						stateMap[name] = value
					end
				end
			end
		},

		fake = {
			Setup = function (target)
				for k, v in pairs(fakeModule) do
					if k ~= StringModuleName then
						target[k] = v
					end
				end

				for k, v in pairs(fakeModule[StringModuleName]) do
					target[StringModuleName][k] = v
				end

				package.loaded[ModuleName] = fakeModule
			end,

			Teardown = function (target)
				for k, v in pairs(fakeModule) do
					if k ~= StringModuleName then
						target[k] = nil
					end
				end

				for k, v in pairs(fakeModule[StringModuleName]) do
					target[StringModuleName][k] = nil
				end

				package.loaded[ModuleName] = nil
			end,

			SetAssetsIsMine = function(mine)
				assetsConstants.IsMine = mine and true or nil
			end
		}
	}

	fakeModule.vci = vci
	return fakeModule
end)()
