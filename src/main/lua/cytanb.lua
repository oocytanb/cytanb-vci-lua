----------------------------------------------------------------
--  Copyright (c) 2019 oO (https://github.com/oocytanb)
--  MIT Licensed
----------------------------------------------------------------

---@type cytanb @See `cytanb_annotations.lua`
local cytanb = (function ()
	local constants = {
		FatalLogLevel = 100,
		ErrorLogLevel = 200,
		WarnLogLevel = 300,
		InfoLogLevel = 400,
		DebugLogLevel = 500,
		TraceLogLevel = 600,
		ColorHueSamples = 10,
		ColorSaturationSamples = 4,
		ColorBrightnessSamples = 5,
		ColorMapSize = 10 * 4 * 5,        -- ColorHueSamples * ColorSaturationSamples * ColorBrightnessSamples
		NegativeNumberTag = '#__CYTANB_NEGATIVE_NUMBER',
		InstanceIDParameterName = '__CYTANB_INSTANCE_ID'
	}

	--- インスタンス ID の状態変数名。
	local InstanceIDStateName = '__CYTANB_INSTANCE_ID'

	--- 出力するログレベル。
	local logLevel = 400

	--- インスタンス ID の文字列。
	local instanceID

	local cytanb

	cytanb = {
		InstanceID = function ()
			if instanceID == '' then
				instanceID = vci.state.Get(InstanceIDStateName) or ''
			end
			return instanceID
		end,

		Vars = function (v, padding, indent, refTable)
			local feed
			if padding then
				feed = padding ~= '__NOLF'
			else
				padding = '  '
				feed = true
			end

			if not indent then
				indent = ''
			end

			if not refTable then
				refTable = {}
			end

			local t = type(v)
			if t == 'table' then
				refTable[v] = refTable[v] and refTable[v] + 1 or 1

				local childIndent = feed and (indent .. padding) or ''
				local str = '(' .. tostring(v) .. ') {'

				local firstEntry = true
				for key, val in pairs(v) do
					if firstEntry then
						firstEntry = false
					else
						str = str .. (feed and ',' or ', ')
					end

					if feed then
						str = str .. '\n' .. childIndent
					end

					if type(val) == 'table' and refTable[val] and refTable[val] > 0 then
						str = str .. key .. ' = (' .. tostring(val) .. ')'
					else
						str = str .. key .. ' = ' .. cytanb.Vars(val, padding, childIndent, refTable)
					end
				end

				if not firstEntry and feed then
					str = str .. '\n' .. indent
				end
				str = str .. '}'

				refTable[v] = refTable[v] - 1
				if (refTable[v] <= 0) then
					refTable[v] = nil
				end
				return str
			elseif t == 'function' or t == "thread" or t == "userdata" then
				return '(' .. t .. ')'
			elseif t == 'string' then
				return '(' .. t .. ') ' .. string.format('%q', v)
			else
				return '(' .. t .. ') ' .. tostring(v)
			end
		end,

		GetLogLevel = function ()
			return logLevel
		end,

		SetLogLevel = function (level)
			logLevel = level
		end,

		Log = function (level, ...)
			if level <= logLevel then
				local args = table.pack(...)
				if args.n == 1 then
					local v = args[1]
					if v ~= nil then
						print(type(v) == 'table' and cytanb.Vars(v) or tostring(v))
					else
						print('')
					end
				else
					local str = ''
					for i = 1, args.n do
						local v = args[i]
						if v ~= nil then
							str = str .. (type(v) == 'table' and cytanb.Vars(v) or tostring(v))
						end
					end
					print(str)
				end
			end
		end,

		FatalLog = function (...) cytanb.Log(constants.FatalLogLevel, ...) end,

		ErrorLog = function (...) cytanb.Log(constants.ErrorLogLevel, ...) end,

		WarnLog = function (...) cytanb.Log(constants.WarnLogLevel, ...) end,

		InfoLog = function (...) cytanb.Log(constants.InfoLogLevel, ...) end,

		DebugLog = function (...) cytanb.Log(constants.DebugLogLevel, ...) end,

		TraceLog = function (...) cytanb.Log(constants.TraceLogLevel, ...) end,

		ListToMap = function (list, itemValue)
			local table = {}
			local valueIsNil = itemValue == nil
			for k, v in pairs(list) do
				table[v] = valueIsNil and v or itemValue
			end
			return table
		end,

		Random32 = function ()
			-- MoonSharp の実装上、2147483646 が渡すことのできる最大値。
			return math.random(-2147483648, 2147483646)
		end,

		RandomUUID = function ()
			return {
				cytanb.Random32(),
				bit32.bor(0x4000, bit32.band(cytanb.Random32(), 0xFFFF0FFF)),
				bit32.bor(0x80000000, bit32.band(cytanb.Random32(), 0x3FFFFFFF)),
				cytanb.Random32()
			}
		end,

		UUIDString = function (uuid)
			local second = uuid[2] or 0
			local third = uuid[3] or 0
			return string.format(
				'%08x-%04x-%04x-%04x-%04x%08x',
				bit32.band(uuid[1] or 0, 0xFFFFFFFF),
				bit32.band(bit32.rshift(second, 16), 0xFFFF),
				bit32.band(second, 0xFFFF),
				bit32.band(bit32.rshift(third, 16), 0xFFFF),
				bit32.band(third, 0xFFFF),
				bit32.band(uuid[4] or 0, 0xFFFFFFFF)
			)
		end,

		ColorFromARGB32 = function (argb32)
			local n = (type(argb32) == 'number') and argb32 or 0xFF000000
			return Color.__new(
				bit32.band(bit32.rshift(n, 16), 0xFF) / 0xFF,
				bit32.band(bit32.rshift(n, 8), 0xFF) / 0xFF,
				bit32.band(n, 0xFF) / 0xFF,
				bit32.band(bit32.rshift(n, 24), 0xFF) / 0xFF
			)
		end,

		ColorToARGB32 = function (color)
			return bit32.bor(
				bit32.lshift(math.floor(255 * color.a + 0.5), 24),
				bit32.lshift(math.floor(255 * color.r + 0.5), 16),
				bit32.lshift(math.floor(255 * color.g + 0.5), 8),
				math.floor(255 * color.b + 0.5)
			)
		end,

		ColorFromIndex = function (colorIndex, hueSamples, saturationSamples, brightnessSamples, omitScale)
			local hueN = math.max(math.floor(hueSamples or constants.ColorHueSamples), 1)
			local toneN = omitScale and hueN or (hueN - 1)
			local saturationN = math.max(math.floor(saturationSamples or constants.ColorSaturationSamples), 1)
			local valueN = math.max(math.floor(brightnessSamples or constants.ColorBrightnessSamples), 1)
			local index = math.max(math.min(math.floor(colorIndex or 0), hueN * saturationN * valueN - 1), 0)

			local x = index % hueN
			local y = math.floor(index / hueN)
			local si = y % saturationN
			local vi = math.floor(y / saturationN)

			if omitScale or x ~= toneN then
				local h = x / toneN
				local s = (saturationN - si) / saturationN
				local v = (valueN - vi) / valueN
				return Color.HSVToRGB(h, s, v)
			else
				local v = (valueN - vi) / valueN * si / (saturationN - 1)
				return Color.HSVToRGB(0.0, 0.0, v)
			end
		end,

		GetSubItemTransform = function (subItem)
			local position = subItem.GetPosition()
			local rotation = subItem.GetRotation()
			local scale = subItem.GetLocalScale()
			return {
				positionX = position.x,
				positionY = position.y,
				positionZ = position.z,
				rotationX = rotation.x,
				rotationY = rotation.y,
				rotationZ = rotation.z,
				rotationW = rotation.w,
				scaleX = scale.x,
				scaleY = scale.y,
				scaleZ = scale.z
			}
		end,

		TableToSerialiable = function (data, refTable)
			if type(data) ~= 'table' then
				return data
			end

			if not refTable then
				refTable = {}
			end

			if refTable[data] then
				error('circular reference')
			end

			refTable[data] = true
			local serData = {}
			for k, v in pairs(data) do
				if type(v) == 'number' and v < 0 then
					serData[k .. constants.NegativeNumberTag] = tostring(v)
				else
					serData[k] = cytanb.TableToSerialiable(v, refTable)
				end
			end

			refTable[data] = nil
			return serData
		end,

		TableFromSerialiable = function (serData)
			if type(serData) ~= 'table' then
				return serData
			end

			local data = {}
			for k, v in pairs(serData) do
				if type(v) == 'string' and string.endsWith(k, constants.NegativeNumberTag) then
					data[string.sub(k, 1, #k - #constants.NegativeNumberTag)] = tonumber(v)
				else
					data[k] = cytanb.TableFromSerialiable(v)
				end
			end
			return data
		end,

		EmitMessage = function (name, parameterMap)
			local table = parameterMap and cytanb.TableToSerialiable(parameterMap) or {}
			table[constants.InstanceIDParameterName] = cytanb.InstanceID()
			vci.message.Emit(name, json.serialize(table))
		end,

		OnMessage = function (name, callback)
			local f = function (sender, messageName, message)
				local parameterMap
				if message == '' then
					parameterMap = {}
				else
					local pcallStatus, serData = pcall(json.parse, message)
					if not pcallStatus or type(serData) ~= 'table' then
						cytanb.TraceLog('Invalid message format: ', message)
						return
					end
					parameterMap = cytanb.TableFromSerialiable(serData)
				end
				callback(sender, messageName, parameterMap)
			end

			vci.message.On(name, f)

			return {
				Off = function ()
					if f then
						-- Off が実装されたら、ここで処理をする。
						-- vci.message.Off(name, f)
						f = nil
					end
				end
			}
		end
	}

	setmetatable(cytanb, {__index = constants})
	package.loaded.cytanb = cytanb

	if vci.assets.IsMine then
		instanceID = cytanb.UUIDString(cytanb.RandomUUID())
		vci.state.Set(InstanceIDStateName, instanceID)
	else
		instanceID = ''
	end

	return cytanb
end)()
