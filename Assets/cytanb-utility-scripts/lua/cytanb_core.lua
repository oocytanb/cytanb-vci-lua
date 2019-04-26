----------------------------------------------------------------
--  Copyright (c) 2019 oO (https://github.com/oocytanb)
--  MIT Licensed
----------------------------------------------------------------

cytanb = (function ()
	math.randomseed(os.time())

	-- 定数定義。
	local constants = {
		--- 致命的なレベルのログを表す定数値。
		FatalLogLevel = 100,

		--- エラーレベルのログを表す定数値。
		ErrorLogLevel = 200,

		--- 警告レベルのログを表す定数値。
		WarnLogLevel = 300,

		--- 情報レベルのログを表す定数値。
		InfoLogLevel = 400,

		--- デバッグレベルのログを表す定数値。
		DebugLogLevel = 500,

		--- トレースレベルのログを表す定数値。
		TraceLogLevel = 600,

		--- デフォルトの色相のサンプル数。
		ColorHueSamples = 10,
	
		--- デフォルトの彩度のサンプル数。
		ColorSaturationSamples = 4,
	
		--- デフォルトの明度のサンプル数。
		ColorBrightnessSamples = 4,
	
		--- デフォルトのカラーマップのサイズ。
		ColorMapSize = 10 * 4 * 4,        -- ColorHueSamples * ColorSaturationSamples * ColorBrightnessSamples
	
		--- 負の数値を示すタグ。
		NegativeNumberTag = '#__CYTANB_NEGATIVE_NUMBER',

		--- インスタンス ID のパラーメーター名。
		InstanceIDParameterName = '__CYTANB_INSTANCE_ID'
	}

	--- インスタンス ID の状態変数名。
	local InstanceIDStateName = '__CYTANB_INSTANCE_ID'

	--- 出力するログレベル。
	local logLevel = 400

	--- インスタンス ID の文字列。
	local instanceID

	local cytanb = {
		--- インスタンス ID を取得する。
		--- @return string @インスタンス ID の文字列。VCI を設置したユーザー以外では、同期完了前は空文字列を返す。
		InstanceID = function()
			if instanceID == '' then
				instanceID = vci.state.Get(InstanceIDStateName) or ''
			end
			return instanceID
		end,

		--- 変数の情報を文字列で返す。
		--- @param v any @調べたい変数を指定する。
		--- @param padding string @パディング文字列を指定する。省略可能。'__NOLF' を指定した場合は、インデントおよび改行を行わない。
		--- @param indent string @省略。
		--- @param refTable table @省略。
		--- @return string 文字列化した変数の情報。
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

		--- 現在のログレベルを取得する。
		--- @return number
		GetLogLevel = function()
			return logLevel
		end,

		--- ログレベルを設定する。
		--- @param level number
		SetLogLevel = function(level)
			logLevel = level
		end,

		--- ログを出力する。
		--- @param level number @ログレベルを指定する。cytanb.SetLogLevel() で設定したレベル以下のときにログが出力される。
		--- @vararg any @ログに出力する任意の数の引数を指定する。
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

		-- 致命的なレベルのログを出力する。
		FatalLog = function (...) cytanb.Log(constants.FatalLogLevel, ...) end,

		-- エラーレベルのログを出力する。
		ErrorLog = function (...) cytanb.Log(constants.ErrorLogLevel, ...) end,

		-- 警告レベルのログを出力する。
		WarnLog = function (...) cytanb.Log(constants.WarnLogLevel, ...) end,

		-- 情報レベルのログを出力する。
		InfoLog = function (...) cytanb.Log(constants.InfoLogLevel, ...) end,

		-- デバッグレベルのログを出力する。
		DebugLog = function (...) cytanb.Log(constants.DebugLogLevel, ...) end,

		-- トレースレベルのログを出力する。
		TraceLog = function (...) cytanb.Log(constants.TraceLogLevel, ...) end,

		--- リストをテーブルに変換する。
		--- @param list table @リストを指定する。要素の値がキー値となる。
		--- @param itemValue any @要素の値を指定する。nil を指定するか省略した場合は、リストの要素の値が使われる。
		--- @return table @変換結果のテーブル。
		ListToMap = function (list, itemValue)
			local table = {}
			local valueIsNil = itemValue == nil
			for k, v in pairs(list) do
				table[v] = valueIsNil and v or itemValue
			end
			return table
		end,

		--- 乱数に基づく UUID version 4 を生成する。
		--- @return table @生成した UUID。32 bit の数値データが 4 つ連続して格納された配列。
		RandomUUID = function ()
			return {
				math.random(0, 0xFFFFFFFF),
				bit32.bor(0x4000, bit32.band(math.random(0, 0xFFFFFFFF), 0xFFFF0FFF)),
				bit32.bor(0x80000000, bit32.band(math.random(0, 0xFFFFFFFF), 0x3FFFFFFF)),
				math.random(0, 0xFFFFFFFF)
			}
		end,

		--- UUID を文字列へ変換する。
		--- @param uuid table @cytanbRandomUUID 関数で生成した UUID を指定する。
		--- @return string @"XXXXXXXX-XXXX-XXXX-XXXX-XXXXXXXXXXXX" 形式の文字列。
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

		--- ARGB 32 bit 値から、Color オブジェクトへ変換する。
		--- @param argb32 number
		--- @return Color
		ColorFromARGB32 = function (argb32)
			local n = (type(argb32) == 'number') and argb32 or 0xFF000000
			return Color.__new(
				bit32.band(bit32.rshift(n, 16), 0xFF) / 0xFF,
				bit32.band(bit32.rshift(n, 8), 0xFF) / 0xFF,
				bit32.band(n, 0xFF) / 0xFF,
				bit32.band(bit32.rshift(n, 24), 0xFF) / 0xFF
			)
		end,

		--- Color オブジェクトから ARGB 32 bit 値へ変換する。
		--- @param color Color
		--- @return number
		ColorToARGB32 = function (color)
			return bit32.bor(
				bit32.lshift(math.floor(255 * color.a + 0.5), 24),
				bit32.lshift(math.floor(255 * color.r + 0.5), 16),
				bit32.lshift(math.floor(255 * color.g + 0.5), 8),
				math.floor(255 * color.b + 0.5)
			)
		end,

		--- カラーインデックスから対応する Color オブジェクトへ変換する。
		--- @param colorIndex number @カラーインデックスを指定する。
		--- @param hueSamples number @色相のサンプル数を指定する。省略した場合は、ColorHueSamples。
		--- @param saturationSamples number @彩度のサンプル数を指定する。省略した場合は、ColorSaturationSamples。
		--- @param brightnessSamples number @明度のサンプル数を指定する。省略した場合は、ColorBrightnessSamples。
		--- @param omitScale boolean @グレイスケールを省略するかを指定する。省略した場合は、false。
		--- @return Color @変換結果の Color オブジェクト。
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

		--- SubItem の Transform を取得する。
		--- @return table<string, number> @Transform の情報を格納したテーブル。
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

		--- json.parse が負の数値を扱えない問題(https://github.com/xanathar/moonsharp/issues/163)のワークアラウンドを行う。
		--- 負の数値は、キー名に '#__CYTANB_NEGATIVE_NUMBER' タグを付加し、負の数値を文字列に変換する。
		--- @param data table @シリアライズするテーブルを指定する。
		--- @return table @修正後のテーブル。
		TableToSerialiable = function (data)
			if type(data) ~= 'table' then
				return data
			end

			local serData = {}
			for k, v in pairs(data) do
				if type(v) == 'number' and v < 0 then
					serData[k .. constants.NegativeNumberTag] = tostring(v)
				else
					serData[k] = cytanb.TableToSerialiable(v)
				end
			end
			return serData
		end,

		--- cytanb.TableToSerialiable() したテーブルを復元する。
		--- @param serData table @cytanb.TableToSerialiable() したテーブルを指定する。
		--- @return table @復元後のテーブル。
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

		--- パラメーターを JSON シリアライズして `vci.message.Emit` する。
		--- @param name string @メッセージ名を指定する。
		--- @param parameterMap table @パラメーターのテーブルを指定する。省略可能。
		EmitMessage = function (name, parameterMap)
			local table = parameterMap and cytanb.TableToSerialiable(parameterMap) or {}
			table[constants.InstanceIDParameterName] = cytanb.InstanceID()
			vci.message.Emit(name, json.serialize(table))
		end,

		--- メッセージハンドラを登録する。
		--- @param name string @メッセージ名を指定する。
		--- @param callback fun(table:sender, string:name, table:parameterMap) @コールバック関数を指定する。
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
				Off = function()
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

	if vci.assets.IsMine then
		instanceID = cytanb.UUIDString(cytanb.RandomUUID())
		vci.state.Set(InstanceIDStateName, instanceID)
	else
		instanceID = ''
	end

	return cytanb
end)()
