----------------------------------------------------------------
--  Copyright (c) 2019 oO (https://github.com/oocytanb)
--  MIT Licensed
----------------------------------------------------------------

---@type cytanb @See `cytanb_annotations.lua`
local cytanb = (function ()
	math.randomseed(os.time() - os.clock() * 10000)

	--- インスタンス ID の状態変数名。
	local InstanceIDStateName = '__CYTANB_INSTANCE_ID'

	--- 出力するログレベル。
	local logLevel

	--- インスタンス ID の文字列。
	local instanceID

	local cytanb

	local UUIDCompare = function (op1, op2)
		for i = 1, 4 do
			local diff = op1[i] - op2[i]
			if diff ~= 0 then
				return diff
			end
		end
		return 0
	end

	local UUIDMetatable
	UUIDMetatable = {
		__eq = function (op1, op2)
			return op1[1] == op2[1] and op1[2] == op2[2] and op1[3] == op2[3] and op1[4] == op2[4]
		end,

		__lt = function (op1, op2)
			return UUIDCompare(op1, op2) < 0
		end,

		__le = function (op1, op2)
			return UUIDCompare(op1, op2) <= 0
		end,

		__tostring = function (value)
			local second = value[2] or 0
			local third = value[3] or 0
			return string.format(
				'%08x-%04x-%04x-%04x-%04x%08x',
				bit32.band(value[1] or 0, 0xFFFFFFFF),
				bit32.band(bit32.rshift(second, 16), 0xFFFF),
				bit32.band(second, 0xFFFF),
				bit32.band(bit32.rshift(third, 16), 0xFFFF),
				bit32.band(third, 0xFFFF),
				bit32.band(value[4] or 0, 0xFFFFFFFF)
			)
		end,

		__concat = function (op1, op2)
			local meta1 = getmetatable(op1)
			local c1 = meta1 == UUIDMetatable or (type(meta1) == 'table' and meta1.__concat == UUIDMetatable.__concat)
			local meta2 = getmetatable(op2)
			local c2 = meta2 == UUIDMetatable or (type(meta2) == 'table' and meta2.__concat == UUIDMetatable.__concat)
			if not c1 and not c2 then
				error('attempt to concatenate illegal values')
			end
			return (c1 and UUIDMetatable.__tostring(op1) or op1) .. (c2 and UUIDMetatable.__tostring(op2) or op2)
		end
	}

	local ConstVariablesFieldName = '__CYTANB_CONST_VARIABLES'

	local ConstIndexHandler = function (table, key)
		local meta = getmetatable(table)
		if meta then
			local mc = rawget(meta, ConstVariablesFieldName)
			if mc then
				local h = rawget(mc, key)
				if type(h) == 'function' then
					return (h(table, key))
				else
					return h
				end
			end
		end
		return nil
	end

	local ConstNewIndexHandler = function (table, key, v)
		local meta = getmetatable(table)
		if meta then
			local mc = rawget(meta, ConstVariablesFieldName)
			if mc then
				if rawget(mc, key) ~= nil then
					error('Cannot assign to read only field "' .. key .. '"')
				end
			end
		end
		rawset(table, key, v)
	end

	cytanb = {
		InstanceID = function ()
			if instanceID == '' then
				instanceID = vci.state.Get(InstanceIDStateName) or ''
			end
			return instanceID
		end,

		SetConst = function (target, name, value)
			if type(target) ~= 'table' then
				error('Cannot set const to non-table target')
			end

			local curMeta = getmetatable(target)
			local meta = curMeta or {}
			local metaConstVariables = rawget(meta, ConstVariablesFieldName)
			if rawget(target, name) ~= nil then
				error('Non-const field "' .. name .. '" already exists')
			end

			if not metaConstVariables then
				metaConstVariables = {}
				rawset(meta, ConstVariablesFieldName, metaConstVariables)
				meta.__index = ConstIndexHandler
				meta.__newindex = ConstNewIndexHandler
			end

			rawset(metaConstVariables, name, value)

			if not curMeta then
				setmetatable(target, meta)
			end

			return target
		end,

		SetConstEach = function (target, entries)
			for k, v in pairs(entries) do
				cytanb.SetConst(target, k, v)
			end
			return target
		end,

		Extend = function (target, source, deep, omitMetaTable, refTable)
			if target == source or type(target) ~= 'table' or type(source) ~= 'table' then
				return target
			end

			if deep then
				if not refTable then
					refTable = {}
				end

				if refTable[source] then
					error('circular reference')
				end

				refTable[source] = true
			end

			for k, v in pairs(source) do
				if deep and type(v) == 'table' then
					local targetChild = target[k]
					target[k] = cytanb.Extend(type(targetChild) == 'table' and targetChild or {}, v, deep, omitMetaTable, refTable)
				else
					target[k] = v
				end
			end

			if not omitMetaTable then
				local sourceMetatable = getmetatable(source)
				if type(sourceMetatable) == 'table' then
					if deep then
						local targetMetatable = getmetatable(target)
						setmetatable(target, cytanb.Extend(type(targetMetatable) == 'table' and targetMetatable or {}, sourceMetatable, true))
					else
						setmetatable(target, sourceMetatable)
					end
				end
			end

			if deep then
				refTable[source] = nil
			end

			return target
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
			elseif t == 'function' or t == 'thread' or t == 'userdata' then
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

		LogFatal = function (...) cytanb.Log(cytanb.LogLevelFatal, ...) end,

		LogError = function (...) cytanb.Log(cytanb.LogLevelError, ...) end,

		LogWarn = function (...) cytanb.Log(cytanb.LogLevelWarn, ...) end,

		LogInfo = function (...) cytanb.Log(cytanb.LogLevelInfo, ...) end,

		LogDebug = function (...) cytanb.Log(cytanb.LogLevelDebug, ...) end,

		LogTrace = function (...) cytanb.Log(cytanb.LogLevelTrace, ...) end,

		-- @deprecated
		FatalLog = function (...) cytanb.LogFatal(...) end,

		-- @deprecated
		ErrorLog = function (...) cytanb.LogError(...) end,

		-- @deprecated
		WarnLog = function (...) cytanb.LogWarn(...) end,

		-- @deprecated
		InfoLog = function (...) cytanb.LogInfo(...) end,

		-- @deprecated
		DebugLog = function (...) cytanb.LogDebug(...) end,

		-- @deprecated
		TraceLog = function (...) cytanb.LogTrace(...) end,

		ListToMap = function (list, itemValue)
			local table = {}
			local valueIsNil = itemValue == nil
			for k, v in pairs(list) do
				table[v] = valueIsNil and v or itemValue
			end
			return table
		end,

		Round = function (num, decimalPlaces)
			if decimalPlaces then
				local m = 10 ^ decimalPlaces
				return math.floor(num * m + 0.5) / m
			else
				return math.floor(num + 0.5)
			end
		end,

		Lerp = function (a, b, t)
			if t <= 0.0 then
				return a
			elseif t >= 1.0 then
				return b
			else
				return a + (b - a) * t
			end
		end,

		LerpUnclamped = function (a, b, t)
			return a + (b - a) * t
		end,

		Random32 = function ()
			-- MoonSharp では整数値の場合 32bit int 型にキャストされ、2147483646 が渡すことのできる最大値。
			return bit32.band(math.random(-2147483648, 2147483646), 0xFFFFFFFF)
		end,

		RandomUUID = function ()
			return cytanb.UUIDFromNumbers(
				cytanb.Random32(),
				bit32.bor(0x4000, bit32.band(cytanb.Random32(), 0xFFFF0FFF)),
				bit32.bor(0x80000000, bit32.band(cytanb.Random32(), 0x3FFFFFFF)),
				cytanb.Random32()
			)
		end,

		-- @deprecated use tostring(uuid)
		UUIDString = function (uuid)
			return UUIDMetatable.__tostring(uuid)
		end,

		UUIDFromNumbers = function (...)
			local first = ...
			local t = type(first)
			local num1, num2, num3, num4
			if t == 'table' then
				num1 = first[1]
				num2 = first[2]
				num3 = first[3]
				num4 = first[4]
			else
				num1, num2, num3, num4 = ...
			end

			local uuid = {
				bit32.band(num1 or 0, 0xFFFFFFFF),
				bit32.band(num2 or 0, 0xFFFFFFFF),
				bit32.band(num3 or 0, 0xFFFFFFFF),
				bit32.band(num4 or 0, 0xFFFFFFFF)
			}
			setmetatable(uuid, UUIDMetatable)
			return uuid
		end,

		UUIDFromString = function (str)
			local len = string.len(str)
			if len ~= 32 and len ~= 36 then return nil end

			local reHex = '[0-9a-f-A-F]+'
			local reHexString = '^(' .. reHex .. ')$'
			local reHyphenHexString = '^-(' .. reHex .. ')$'

			local mi, mj, token, token2
			if len == 32 then
				local uuid = cytanb.UUIDFromNumbers(0, 0, 0, 0)
				local startPos = 1
				for i, endPos in ipairs({8, 16, 24, 32}) do
					mi, mj, token = string.find(string.sub(str, startPos, endPos), reHexString)
					if not mi then return nil end
					uuid[i] = tonumber(token, 16)
					startPos = endPos + 1
				end
				return uuid
			else
				mi, mj, token = string.find(string.sub(str, 1, 8), reHexString)
				if not mi then return nil end
				local num1 = tonumber(token, 16)

				mi, mj, token = string.find(string.sub(str, 9, 13), reHyphenHexString)
				if not mi then return nil end
				mi, mj, token2 = string.find(string.sub(str, 14, 18), reHyphenHexString)
				if not mi then return nil end
				local num2 = tonumber(token .. token2, 16)

				mi, mj, token = string.find(string.sub(str, 19, 23), reHyphenHexString)
				if not mi then return nil end
				mi, mj, token2 = string.find(string.sub(str, 24, 28), reHyphenHexString)
				if not mi then return nil end
				local num3 = tonumber(token .. token2, 16)

				mi, mj, token = string.find(string.sub(str, 29, 36), reHexString)
				if not mi then return nil end
				local num4 = tonumber(token, 16)

				return cytanb.UUIDFromNumbers(num1, num2, num3, num4)
			end
		end,

		-- @deprecated use UUIDFromString
		ParseUUID = function (str)
			return cytanb.UUIDFromString(str)
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
				bit32.lshift(bit32.band(cytanb.Round(0xFF * color.a), 0xFF), 24),
				bit32.lshift(bit32.band(cytanb.Round(0xFF * color.r), 0xFF), 16),
				bit32.lshift(bit32.band(cytanb.Round(0xFF * color.g), 0xFF), 8),
				bit32.band(cytanb.Round(0xFF * color.b), 0xFF)
			)
		end,

		ColorFromIndex = function (colorIndex, hueSamples, saturationSamples, brightnessSamples, omitScale)
			local hueN = math.max(math.floor(hueSamples or cytanb.ColorHueSamples), 1)
			local toneN = omitScale and hueN or (hueN - 1)
			local saturationN = math.max(math.floor(saturationSamples or cytanb.ColorSaturationSamples), 1)
			local valueN = math.max(math.floor(brightnessSamples or cytanb.ColorBrightnessSamples), 1)
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

		TableToSerializable = function (data, refTable)
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
				-- 数値インデックスであれば、タグを付加する
				local nk = (type(k) == 'number') and tostring(k) .. cytanb.ArrayNumberTag or k

				if type(v) == 'number' and v < 0 then
					-- 負の数値であれば、タグを付加する
					serData[tostring(nk) .. cytanb.NegativeNumberTag] = tostring(v)
				else
					serData[nk] = cytanb.TableToSerializable(v, refTable)
				end
			end

			refTable[data] = nil
			return serData
		end,

		TableFromSerializable = function (serData)
			if type(serData) ~= 'table' then
				return serData
			end

			local data = {}
			for k, v in pairs(serData) do
				local nk
				local valueIsNegativeNumber
				if type(k) == 'string' then
					if string.endsWith(k, cytanb.NegativeNumberTag) then
						nk = string.sub(k, 1, -1 - #cytanb.NegativeNumberTag)
						valueIsNegativeNumber = true
					else
						nk = k
						valueIsNegativeNumber = false
					end

					if string.endsWith(nk, cytanb.ArrayNumberTag) then
						local strBody = string.sub(nk, 1, -1 - #cytanb.ArrayNumberTag)
						nk = tonumber(strBody) or strBody
					end
				else
					nk = k
					valueIsNegativeNumber = false
				end

				data[nk] = (valueIsNegativeNumber and type(v) == 'string') and tonumber(v) or cytanb.TableFromSerializable(v)
			end
			return data
		end,

		-- @deprecated use TableToSerializable
		TableToSerialiable = function (data, refTable)
			return cytanb.TableToSerializable(data, refTable)
		end,

		-- @deprecated use TableFromSerializable
		TableFromSerialiable = function (serData)
			return cytanb.TableFromSerializable(serData)
		end,

		EmitMessage = function (name, parameterMap)
			local table = parameterMap and cytanb.TableToSerializable(parameterMap) or {}
			table[cytanb.InstanceIDParameterName] = cytanb.InstanceID()
			vci.message.Emit(name, json.serialize(table))
		end,

		OnMessage = function (name, callback)
			local f = function (sender, messageName, message)
				local decodedData = nil
				if sender.type ~= 'comment' and type(message) == 'string' then
					local pcallStatus, serData = pcall(json.parse, message)
					if pcallStatus and type(serData) == 'table' then
						decodedData = cytanb.TableFromSerializable(serData)
					end
				end

				local parameterMap = decodedData and decodedData or {[cytanb.MessageValueParameterName] = message}
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

	cytanb.SetConstEach(cytanb, {
		LogLevelFatal = 100,
		LogLevelError = 200,
		LogLevelWarn = 300,
		LogLevelInfo = 400,
		LogLevelDebug = 500,
		LogLevelTrace = 600,
		ColorHueSamples = 10,
		ColorSaturationSamples = 4,
		ColorBrightnessSamples = 5,
		NegativeNumberTag = '#__CYTANB_NEGATIVE_NUMBER',
		ArrayNumberTag = '#__CYTANB_ARRAY_NUMBER',
		InstanceIDParameterName = '__CYTANB_INSTANCE_ID',
		MessageValueParameterName = '__CYTANB_MESSAGE_VALUE'
	})

	cytanb.SetConstEach(cytanb, {
		ColorMapSize = cytanb.ColorHueSamples * cytanb.ColorSaturationSamples * cytanb.ColorBrightnessSamples,
		FatalLogLevel = cytanb.LogLevelFatal,    -- @deprecated
		ErrorLogLevel = cytanb.LogLevelError,    -- @deprecated
		WarnLogLevel = cytanb.LogLevelWarn,      -- @deprecated
		InfoLogLevel = cytanb.LogLevelInfo,      -- @deprecated
		DebugLogLevel = cytanb.LogLevelDebug,    -- @deprecated
		TraceLogLevel = cytanb.LogLevelTrace     -- @deprecated
	})

	logLevel = cytanb.LogLevelInfo

	package.loaded['cytanb'] = cytanb

	if vci.assets.IsMine then
		instanceID = tostring(cytanb.RandomUUID())
		vci.state.Set(InstanceIDStateName, instanceID)
	else
		instanceID = ''
	end

	return cytanb
end)()
