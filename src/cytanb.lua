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

		SetConst = function (target, name, value)
			if type(target) ~= 'table' then
				error('Cannot set const to non-table target')
			end

			local curMeta = getmetatable(target)
			local meta = curMeta or {}
			local hasMetaIndex = type(meta.__index) == 'table'
			if target[name] ~= nil and (not hasMetaIndex or meta.__index[name] == nil) then
				error('Non-const field "' .. name .. '" already exists')
			end

			if not hasMetaIndex then
				meta.__index = {}
			end
			local metaIndex = meta.__index
			metaIndex[name] = value

			if not hasMetaIndex or type(meta.__newindex) ~= 'function' then
				meta.__newindex = function (table, key, v)
					if table == target and metaIndex[key] ~= nil then
						error('Cannot assign to read only field "' .. key .. '"')
					end
					rawset(table, key, v)
				end
			end

			if not curMeta then
				setmetatable(target, meta)
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

		FatalLog = function (...) cytanb.Log(cytanb.FatalLogLevel, ...) end,

		ErrorLog = function (...) cytanb.Log(cytanb.ErrorLogLevel, ...) end,

		WarnLog = function (...) cytanb.Log(cytanb.WarnLogLevel, ...) end,

		InfoLog = function (...) cytanb.Log(cytanb.InfoLogLevel, ...) end,

		DebugLog = function (...) cytanb.Log(cytanb.DebugLogLevel, ...) end,

		TraceLog = function (...) cytanb.Log(cytanb.TraceLogLevel, ...) end,

		ListToMap = function (list, itemValue)
			local table = {}
			local valueIsNil = itemValue == nil
			for k, v in pairs(list) do
				table[v] = valueIsNil and v or itemValue
			end
			return table
		end,

		Random32 = function ()
			-- MoonSharp は 32bit int 型で実装されていて、2147483646 が渡すことのできる最大値。
			return bit32.band(math.random(-2147483648, 2147483646), 0xFFFFFFFF)
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

		ParseUUID = function (str)
			local len = string.len(str)
			if len ~= 32 and len ~= 36 then return nil end

			local reHex = '[0-9a-f-A-F]+'
			local reHexString = '^(' .. reHex .. ')$'
			local reHyphenHexString = '^-(' .. reHex .. ')$'

			local uuid = {}
			local mi, mj, token, token2
			if len == 32 then
				local startPos = 1
				for i, endPos in ipairs({8, 16, 24, 32}) do
					mi, mj, token = string.find(string.sub(str, startPos, endPos), reHexString)
					if not mi then return nil end
					uuid[i] = tonumber(token, 16)
					startPos = endPos + 1
				end
			else
				mi, mj, token = string.find(string.sub(str, 1, 8), reHexString)
				if not mi then return nil end
				uuid[1] = tonumber(token, 16)

				mi, mj, token = string.find(string.sub(str, 9, 13), reHyphenHexString)
				if not mi then return nil end
				mi, mj, token2 = string.find(string.sub(str, 14, 18), reHyphenHexString)
				if not mi then return nil end
				uuid[2] = tonumber(token .. token2, 16)

				mi, mj, token = string.find(string.sub(str, 19, 23), reHyphenHexString)
				if not mi then return nil end
				mi, mj, token2 = string.find(string.sub(str, 24, 28), reHyphenHexString)
				if not mi then return nil end
				uuid[3] = tonumber(token .. token2, 16)

				mi, mj, token = string.find(string.sub(str, 29, 36), reHexString)
				if not mi then return nil end
				uuid[4] = tonumber(token, 16)
			end

			return uuid
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
				position = position,
				rotation = rotation,
				scale = scale,
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
				if type(k) == 'number' then
					k = cytanb.ArrayNumberTag .. k
				end
				if type(v) == 'number' and v < 0 then
					serData[k .. cytanb.NegativeNumberTag] = tostring(v)
				else
					serData[k] = cytanb.TableToSerializable(v, refTable)
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
				if type(v) == 'string' and string.endsWith(k, cytanb.NegativeNumberTag) then
                    if k:startsWith(cytanb.ArrayNumberTag) then
                        k = k:sub(1, #k - #cytanb.NegativeNumberTag)
                        data[tonumber(k:sub(#cytanb.ArrayNumberTag + 1,#k))] = tonumber(v)
                    else
                        data[k:sub(1, #k - #cytanb.NegativeNumberTag)] = tonumber(v)
                    end
                else
                    if k:startsWith(cytanb.ArrayNumberTag) then
                        data[tonumber(k:sub(#cytanb.ArrayNumberTag + 1,#k))] = cytanb.TableFromSerializable(v)
                    else
                        data[k] = cytanb.TableFromSerializable(v)
                    end
				end
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

	cytanb:SetConst('FatalLogLevel', 100)
		:SetConst('ErrorLogLevel', 200)
		:SetConst('WarnLogLevel', 300)
		:SetConst('InfoLogLevel', 400)
		:SetConst('DebugLogLevel', 500)
		:SetConst('TraceLogLevel', 600)
		:SetConst('ColorHueSamples', 10)
		:SetConst('ColorSaturationSamples', 4)
		:SetConst('ColorBrightnessSamples', 5)
		:SetConst('ColorMapSize', cytanb.ColorHueSamples * cytanb.ColorSaturationSamples * cytanb.ColorBrightnessSamples)
		:SetConst('NegativeNumberTag', '#__CYTANB_NEGATIVE_NUMBER')
		:SetConst('ArrayNumberTag', '#__CYTANB_ARRAY_NUMBER')
		:SetConst('InstanceIDParameterName', '__CYTANB_INSTANCE_ID')
		:SetConst('MessageValueParameterName', '__CYTANB_MESSAGE_VALUE')

	package.loaded['cytanb'] = cytanb

	if vci.assets.IsMine then
		instanceID = cytanb.UUIDString(cytanb.RandomUUID())
		vci.state.Set(InstanceIDStateName, instanceID)
	else
		instanceID = ''
	end

	return cytanb
end)()
