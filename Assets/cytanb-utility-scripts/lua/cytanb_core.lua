----------------------------------------------------------------
--  Copyright (c) 2019 oO (https://github.com/oocytanb)
--  MIT Licensed
----------------------------------------------------------------

math.randomseed(os.time())

cytanb = {
	--- ログレベル。
	LOG_LEVEL = 400,

	--- ログを出力する。
	--- @param logLevel number @ログレベルを指定する。`logLevel <= cytanb.LOG_LEVEL` のときにログが出力される。
	--- @vararg any @ログに出力する任意の数の引数を指定する。
	Log = function (logLevel, ...)
		if logLevel <= cytanb.LOG_LEVEL then
			local args = table.pack(...)
			if args.n == 1 then
				print(args[1] ~= nil and tostring(args[1]) or '')
			else
				local str = ''
				for i = 1, args.n do
					if args[i] ~= nil then
						str = str .. tostring(args[i])
					end
				end
				print(str)
			end
		end
	end,

	FatalLog = function (...) cytanb.Log(100, ...) end,
	ErrorLog = function (...) cytanb.Log(200, ...) end,
	WarnLog = function (...) cytanb.Log(300, ...) end,
	InfoLog = function (...) cytanb.Log(400, ...) end,
	DebugLog = function (...) cytanb.Log(500, ...) end,
	TraceLog = function (...) cytanb.Log(600, ...) end,

	--- 文字列が指定したプレフィックスで始まるかを調べる。
	--- @param str string
	--- @param prefix string
	--- @return boolean
	StringStartsWith = function (str, prefix)
		if not str or not prefix then
			return false
		end

		local prefixLen = string.len(prefix)
		return string.len(str) >= prefixLen and string.sub(str, 1, prefixLen) == prefix
	end,

	--- 文字列が指定したサフィックスで終わるかを調べる。
	--- @param str string
	--- @param suffix string
	--- @return boolean
	StringEndsWith = function (str, suffix)
		if not str or not suffix then
			return false
		end

		local suffixLen = string.len(suffix)
		local strLen = string.len(str)
		return strLen >= suffixLen and string.sub(str, 1 + strLen - suffixLen, strLen) == suffix
	end,

	--- リストを辞書形式のテーブルに変換する。
	--- @param list table @リストを指定する。要素の値がキー値となる。
	--- @param itemValue any @要素の値を指定する。nil を指定するか省略した場合は、リストの要素の値が使われる。
	--- @return table @変換結果のテーブル。
	ListToDictionary = function (list, itemValue)
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

	--- デフォルトの色相のサンプル数。
	COLOR_DEFAULT_HUE_SAMPLES = 10,

	--- デフォルトの彩度のサンプル数。
	COLOR_DEFAULT_SATURATION_SAMPLES = 4,

	--- デフォルトの明度のサンプル数。
	COLOR_DEFAULT_BRIGHTNESS_SAMPLES = 4,

	--- カラーマップのサイズ。
	COLOR_MAP_SIZE = 10 * 4 * 4,    -- COLOR_DEFAULT_HUE_SAMPLES * COLOR_DEFAULT_SATURATION_SAMPLES * COLOR_DEFAULT_BRIGHTNESS_SAMPLES

	--- カラーインデックスから対応する Color オブジェクトへ変換する。
	--- @param colorIndex number @カラーインデックスを指定する。
	--- @param hueSamples number @色相のサンプル数を指定する。
	--- @param saturationSamples number @彩度のサンプル数を指定する。
	--- @param omitScale boolean @グレイスケールを省略するかを true か false で指定する。
	--- @return Color @変換結果の Color オブジェクト。
	ColorFromIndex = function (colorIndex, hueSamples, saturationSamples, omitScale)
		local index = math.max(math.min(math.floor(colorIndex or 0), cytanb.COLOR_MAP_SIZE - 1), 0)
		local hueN = math.max(math.floor(hueSamples or cytanb.COLOR_DEFAULT_HUE_SAMPLES), 1)
		local toneN = omitScale and hueN or (hueN - 1)
		local saturationN = math.max(math.floor(saturationSamples or cytanb.COLOR_DEFAULT_SATURATION_SAMPLES), 1)
		local valueN = math.floor(math.floor((cytanb.COLOR_MAP_SIZE + hueN - 1) / hueN + saturationN - 1) / saturationN)

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

	NEGATIVE_NUMBER_TAG = '#__CYTANB_NEGATIVE_NUMBER',
	ROOT_NEGATIVE_NUMBER_TAG = '#__CYTANB_ROOT#__CYTANB_NEGATIVE_NUMBER',

	--[[--
		パラメーターを JSON エンコードして `vci.message.Emit` する。
	
		@param name メッセージ名を指定する。
		@param version メッセージのバージョンを正の整数で指定する。省略可能。
		@param instanceId VCI のインスタンス ID の文字列を指定する。省略可能。
		@param parameterMap パラメーターのテーブルを指定する。省略可能。
	]]
	EmitMessage = function (name, version, instanceId, parameterMap)
		local table = {
			version = version,
			instanceId = instanceId or ''
		}
	
		if parameterMap then
			for k, v in pairs(parameterMap) do
				if type(v) == 'number' and v < 0 then
					-- json.parse が負の数値を扱えない問題のワークアラウンド。
					-- https://github.com/xanathar/moonsharp/issues/163
					table[k .. cytanb.NEGATIVE_NUMBER_TAG] = tostring(v)
				else
					table[k] = v
				end
			end
		end
	
		vci.message.Emit(name, json.serialize(table))
	end,

	--[[--
		メッセージハンドラをバインドする。

		@param name メッセージ名を指定する。
		@param minVersion メッセージの最小バージョンを指定する。省略した場合は、バージョンチェックを行わない。
		@param callback Type: fun(sender, name, parameterMap) コールバック関数を指定する。
	]]
	OnMessage = function (name, minVersion, callback)
		local f = function (sender, messageName, message)
			if message ~= '' then
				local pcallStatus, result = pcall(json.parse, message)
				if not pcallStatus or type(result) ~= 'table' then
					cytanb.TraceLog('Invalid message format: ', message)
					return
				end
			end

			if minVersion then
				local messageVersion = result['version']
				if type(messageVersion) ~= 'number' or messageVersion < minVersion then
					return
				end
			end

			-- json.parse が負の数値を扱えない問題のワークアラウンド。
			-- https://github.com/xanathar/moonsharp/issues/163
			local parameterMap = {}
			for k, v in pairs(result) do
				if type(v) == 'string' and cytanb.StringEndsWith(k, cytanb.NEGATIVE_NUMBER_TAG) then
					parameterMap[string.sub(k, 1, #k - #cytanb.NEGATIVE_NUMBER_TAG)] = tonumber(v)
				else
					parameterMap[k] = v
				end
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
