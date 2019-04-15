----------------------------------------------------------------
--  Copyright (c) 2019 oO (https://github.com/oocytanb)
--  MIT Licensed
----------------------------------------------------------------

math.randomseed(os.time())

--- ログレベル。
__CYTANB_LOG_LEVEL = 400

--[[--
	ログを出力する。

	@param logLevel ログレベルを指定する。`logLevel <= __CYTANB_LOG_LEVEL` のときにログが出力される。
	@param ... ログに出力する任意の数の引数を指定する。
]]
function cytanbLog(logLevel, ...)
	if logLevel <= __CYTANB_LOG_LEVEL then
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
end

function cytanbFatalLog(...) cytanbLog(100, ...) end
function cytanbErrorLog(...) cytanbLog(200, ...) end
function cytanbWarnLog(...) cytanbLog(300, ...) end
function cytanbInfoLog(...) cytanbLog(400, ...) end
function cytanbDebugLog(...) cytanbLog(500, ...) end
function cytanbTraceLog(...) cytanbLog(600, ...) end

--- 文字列が指定したプレフィックスで始まるかを調べる。
function cytanbStringStartsWith(str, prefix)
	if not str or not prefix then
		return false
	end

	local prefixLen = string.len(prefix)
	return string.len(str) >= prefixLen and string.sub(str, 1, prefixLen) == prefix
end

--- 文字列が指定したサフィックスで終わるかを調べる。
function cytanbStringEndsWith(str, suffix)
	if not str or not suffix then
		return false
	end

	local suffixLen = string.len(suffix)
	local strLen = string.len(str)
	return strLen >= suffixLen and string.sub(str, 1 + strLen - suffixLen, strLen) == suffix
end

--[[--
	乱数に基づく UUID version 4 を生成する。

	@return 生成した UUID。32 bit の数値データが 4 つ連続して格納された配列。
]]
function cytanbRandomUUID()
	return {
		math.random(0, 0xFFFFFFFF),
		bit32.bor(0x4000, bit32.band(math.random(0, 0xFFFFFFFF), 0xFFFF0FFF)),
		bit32.bor(0x80000000, bit32.band(math.random(0, 0xFFFFFFFF), 0x3FFFFFFF)),
		math.random(0, 0xFFFFFFFF)
	}
end

--[[--
	UUID を文字列へ変換する。

	@param uuid cytanbRandomUUID 関数で生成した UUID を指定する。

	@return "XXXXXXXX-XXXX-XXXX-XXXX-XXXXXXXXXXXX" 形式の文字列。
]]
function cytanbUUIDString(uuid)
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
end

--[[--
	リストを辞書形式のテーブルに変換する。

	@param list リストを指定する。要素の値がキー値となる。
	@param itemValue 要素の値を指定する。nil を指定するか省略した場合は、リストの要素の値が使われる。

	@param 変換結果のテーブル。
]]
function cytanbListToDictionary(list, itemValue)
	local table = {}
	local valueIsNil = itemValue == nil
	for k, v in pairs(list) do
		table[v] = valueIsNil and v or itemValue
	end
	return table
end

--- ARGB 32 bit 値から、Color オブジェクトへ変換する。
function cytanbColorFromARGB32(argb32)
	local n = (type(argb32) == 'number') and argb32 or 0xFF000000
	return Color.__new(
		bit32.band(bit32.rshift(n, 16), 0xFF) / 0xFF,
		bit32.band(bit32.rshift(n, 8), 0xFF) / 0xFF,
		bit32.band(n, 0xFF) / 0xFF,
		bit32.band(bit32.rshift(n, 24), 0xFF) / 0xFF
	)
end

--- Color オブジェクトから ARGB 32 bit 値へ変換する。
function cytanbColorToARGB32(color)
	return bit32.bor(
		bit32.lshift(math.floor(255 * color.a + 0.5), 24),
		bit32.lshift(math.floor(255 * color.r + 0.5), 16),
		bit32.lshift(math.floor(255 * color.g + 0.5), 8),
		math.floor(255 * color.b + 0.5)
	)
end

--- デフォルトの色相のサンプル数。
__CYTANB_COLOR_DEFAULT_HUE_SAMPLES = 10

--- デフォルトの彩度のサンプル数。
__CYTANB_COLOR_DEFAULT_SATURATION_SAMPLES = 4

--- デフォルトの明度のサンプル数。
__CYTANB_COLOR_DEFAULT_BRIGHTNESS_SAMPLES = 4

--- カラーマップのサイズ。
__CYTANB_COLOR_MAP_SIZE = __CYTANB_COLOR_DEFAULT_HUE_SAMPLES * __CYTANB_COLOR_DEFAULT_SATURATION_SAMPLES * __CYTANB_COLOR_DEFAULT_BRIGHTNESS_SAMPLES

--[[--
	カラーインデックスから対応する Color オブジェクトへ変換する。

	@param colorIndex カラーインデックスを指定する。
	@param hueSamples 色相のサンプル数を指定する。
	@param saturationSamples 彩度のサンプル数を指定する。
	@param omitScale グレイスケールを省略するかを true か false で指定する。

	@param 変換結果の Color オブジェクト。
]]
function cytanbColorFromIndex(colorIndex, hueSamples, saturationSamples, omitScale)
	local index = math.max(math.min(math.floor(colorIndex or 0), __CYTANB_COLOR_MAP_SIZE - 1), 0)
	local hueN = math.max(math.floor(hueSamples or __CYTANB_COLOR_DEFAULT_HUE_SAMPLES), 1)
	local toneN = omitScale and hueN or (hueN - 1)
	local saturationN = math.max(math.floor(saturationSamples or __CYTANB_COLOR_DEFAULT_SATURATION_SAMPLES), 1)
	local valueN = math.floor(math.floor((__CYTANB_COLOR_MAP_SIZE + hueN - 1) / hueN + saturationN - 1) / saturationN)

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
end

--[[--
	SubItem の Transform を取得する。

	@return Transform の情報を格納したテーブル。
]]
function cytanbGetSubItemTransform(subItem)
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
end

__CYTANB_NEGATIVE_NUMBER_TAG = '#__CYTANB_NEGATIVE_NUMBER'

--[[--
	パラメーターを JSON エンコードして `vci.message.Emit` する。

	@param name メッセージ名を指定する。
	@param version メッセージのバージョンを正の整数で指定する。
	@param instanceId VCI のインスタンス ID の文字列を指定する。省略可能。
	@param parameterMap パラメーターのテーブルを指定する。省略可能。
]]
function cytanbEmitMessage(name, version, instanceId, parameterMap)
	local table = {
		version = version,
		instanceId = instanceId or ''
	}

	if parameterMap then
		for k, v in pairs(parameterMap) do
			if type(v) == 'number' and v < 0 then
				-- json.parse が負の数値を扱えない問題のワークアラウンド。
				-- https://github.com/xanathar/moonsharp/issues/163
				table[k .. __CYTANB_NEGATIVE_NUMBER_TAG] = tostring(v)
			else
				table[k] = v
			end
		end
	end

	vci.message.Emit(name, json.serialize(table))
end

--[[--
	メッセージハンドラをバインドする。

	@param name メッセージ名を指定する。
	@param minVersion メッセージの最小バージョンを指定する。nil を指定した場合は、バージョンチェックを行わない。
	@param callback Type: fun(sender, name, parameterMap) コールバック関数を指定する。
]]
function cytanbBindMessage(name, minVersion, callback)
	local f = function (sender, messageName, message)
		local pcallStatus, result = pcall(json.parse, message)
		if not pcallStatus or type(result) ~= 'table' then
			return
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
			if type(v) == 'string' and cytanbStringEndsWith(k, __CYTANB_NEGATIVE_NUMBER_TAG) then
				parameterMap[string.sub(k, 1, #k - #__CYTANB_NEGATIVE_NUMBER_TAG)] = tonumber(v)
			else
				parameterMap[k] = v
			end
		end

		callback(sender, messageName, parameterMap)
	end

	vci.message.On(name, f)
	
	return {
		Unbind = function()
			if f then
				-- Unbind が実装されたら、ここで処理をする。
				-- vci.message.Unbind(name, f)
				f = nil
			end
		end
	}
end

--- アイテムのパッケージ名。
local COLOR_PALETTE_PACKAGE_NAME = 'com.github.oocytanb.cytanb-tso-collab.color-palette'

--- パレットで選択した色を格納する共有変数名。別の VCI から色を取得可能。ARGB 32 bit 値。
local SHARED_NAME_ARGB32 = COLOR_PALETTE_PACKAGE_NAME .. '.argb32'

--- パレットで選択した色のインデックス値を格納する共有変数名。
local SHARED_NAME_COLOR_INDEX = COLOR_PALETTE_PACKAGE_NAME .. '.color-index'

--- メッセージフォーマットのバージョン。
local MESSAGE_VERSION = 0x10000

--- メッセージフォーマットの最小バージョン。
local MESSAGE_MIN_VERSION = 0x10000

--- アイテムのステータスを問い合わせるメッセージ名。
local MESSAGE_NAME_QUERY_STATUS = COLOR_PALETTE_PACKAGE_NAME .. '.query-status'

--- アイテムのステータスを通知するメッセージ名。
local MESSAGE_NAME_ITEM_STATUS = COLOR_PALETTE_PACKAGE_NAME .. '.item-status'

local INSTANCE_ID_STATE_NAME = 'instance-id'

local PICKER_TAG = '#cytanb-color-picker'
local ALLOWED_PICKER_LIST = {'HandPointMarker', 'RightArm', 'LeftArm', 'RightHand', 'LeftHand'}
local ALLOWED_PICKER_TABLE = cytanbListToDictionary(ALLOWED_PICKER_LIST, true)
local PICKER_SWITCH_NAME = 'picker-switch'
local ANY_PICKER_ALLOWED_STATE_NAME = 'any-picker-allowed-state'
local DEFAULT_ANY_PICKER_ALLOWED_STATE = false

local PICKER_SWITCH_MATERIAL_NAME = 'picker-switch-mat'
local PICKER_SWITCH_UV_HEIGHT = 50.0 / 1024.0

local COLOR_INDEX_PREFIX = 'cytanb-color-index-'
local CURRENT_COLOR_MATERIAL_NAME = 'current-color-mat'
local HIT_INDEX_STATE_NAME = 'hit-index-state'
local DEFAULT_HIT_INDEX_STATE = 9

local PALETTE_MATERIAL_NAME = 'color-palette-mat'
local PALETTE_PAGE_UV_HEIGHT = 200.0 / 1024.0

local BRIGHTNESS_SWITCH_NAME = 'brightness-switch'
local BRIGHTNESS_SWITCH_STATE_NAME = 'brightness-switch-state'
local DEFAULT_BRIGHTNESS_SWITCH_STATE = 0

local BRIGHTNESS_SWITCH_MATERIAL_NAME = 'brightness-switch-mat'
local BRIGHTNESS_SWITCH_UV_HEIGHT = 50.0 / 1024.0

local DLAY_INIT_TIME = TimeSpan.FromSeconds(1)
local UPDATE_PERIOD = TimeSpan.FromMilliseconds(100)

local PALETTE_BASE = vci.assets.GetSubItem('palette-base')

local instanceId = vci.assets.IsMine and cytanbUUIDString(cytanbRandomUUID()) or ''
local lastBrightnessChangeTime = TimeSpan.FromHours(-1)
local pickerEntered = false

local function calculateColorIndex(hitIndex, brightnessPage)
	return hitIndex + __CYTANB_COLOR_DEFAULT_HUE_SAMPLES * __CYTANB_COLOR_DEFAULT_SATURATION_SAMPLES * brightnessPage
end

local function isAnyPickerAllowed()
	local b = vci.state.Get(ANY_PICKER_ALLOWED_STATE_NAME)
	if b == nil then
		return DEFAULT_ANY_PICKER_ALLOWED_STATE
	else
		return b
	end
end

local function getHitIndex()
	return vci.state.Get(HIT_INDEX_STATE_NAME) or DEFAULT_HIT_INDEX_STATE
end

local function getBrightnessPage()
	return vci.state.Get(BRIGHTNESS_SWITCH_STATE_NAME) or DEFAULT_BRIGHTNESS_SWITCH_STATE
end

local function isPickerHit(hit)
	return hit and (isAnyPickerAllowed() or ALLOWED_PICKER_TABLE[hit] or string.find(hit, PICKER_TAG, 1, true))
end

local function emitStatus(color, colorIndex)
	local argb32 = cytanbColorToARGB32(color)

	cytanbDebugLog('emit status: colorIndex = ', colorIndex, ', color = ', color)

	local params = cytanbGetSubItemTransform(PALETTE_BASE)
	params['argb32'] = argb32
	params['colorIndex'] = colorIndex
	cytanbEmitMessage(MESSAGE_NAME_ITEM_STATUS, MESSAGE_VERSION, instanceId, params)
end

local function updateStatus(color, colorIndex)
	if not vci.assets.IsMine then return end

	cytanbDebugLog('update status: colorIndex = ', colorIndex, ' ,  color = ', color)

	local argb32 = cytanbColorToARGB32(color)
	vci.studio.shared.Set(SHARED_NAME_ARGB32, argb32)
	vci.studio.shared.Set(SHARED_NAME_COLOR_INDEX, colorIndex)

	emitStatus(color, colorIndex)
end

local updateStateCw = coroutine.wrap(function ()
	local takeInstanceId = true
	local firstUpdate = true

	local lastUpdateTime = vci.me.Time
	local lastAnyPickerAllowed = false
	local lastHitIndex = -1
	local lastBrightnessPage = -1

	while true do
		if takeInstanceId then
			if instanceId == '' then
				instanceId = vci.state.Get(INSTANCE_ID_STATE_NAME) or ''
			end
			takeInstanceId = instanceId == ''
		end

		local time = vci.me.Time
		if time >= lastUpdateTime + UPDATE_PERIOD then
			lastUpdateTime = time

			--
			local anyPickerAllowed = isAnyPickerAllowed()
			if firstUpdate or anyPickerAllowed ~= lastAnyPickerAllowed then
				cytanbDebugLog('update anyPickerAllowed: ', anyPickerAllowed)
				lastAnyPickerAllowed = anyPickerAllowed
				local pickerPage = anyPickerAllowed and 1 or 0
				vci.assets.SetMaterialTextureOffsetFromName(PICKER_SWITCH_MATERIAL_NAME, Vector2.__new(0.0, 1.0 - PICKER_SWITCH_UV_HEIGHT * pickerPage))
			end

			--
			local hitIndex = getHitIndex()
			local brightnessPage = getBrightnessPage()
			if firstUpdate or lastHitIndex ~= hitIndex or lastBrightnessPage ~= brightnessPage then
				local colorIndex = calculateColorIndex(hitIndex, brightnessPage)
				local color = cytanbColorFromIndex(colorIndex)

				cytanbDebugLog('update currentColor: colorIndex = ', colorIndex, ' ,  color = ', color)
				lastHitIndex = hitIndex
				lastBrightnessPage = brightnessPage

				vci.assets.SetMaterialColorFromName(CURRENT_COLOR_MATERIAL_NAME, color)
				vci.assets.SetMaterialTextureOffsetFromName(PALETTE_MATERIAL_NAME, Vector2.__new(0.0, 1.0 - PALETTE_PAGE_UV_HEIGHT * brightnessPage))
				vci.assets.SetMaterialTextureOffsetFromName(BRIGHTNESS_SWITCH_MATERIAL_NAME, Vector2.__new(0.0, 1.0 - BRIGHTNESS_SWITCH_UV_HEIGHT * brightnessPage))

				updateStatus(color, colorIndex)
			end

			--
			firstUpdate = false
		end

		coroutine.yield(100)
	end
	return 0
end)

-- アイテムを設置したときの初期化処理
if vci.assets.IsMine then
	vci.state.Set(INSTANCE_ID_STATE_NAME, instanceId)
	vci.state.Set(ANY_PICKER_ALLOWED_STATE_NAME, DEFAULT_ANY_PICKER_ALLOWED_STATE)
	vci.state.Set(HIT_INDEX_STATE_NAME, DEFAULT_HIT_INDEX_STATE)
	vci.state.Set(BRIGHTNESS_SWITCH_STATE_NAME, DEFAULT_BRIGHTNESS_SWITCH_STATE)

	local colorIndex = calculateColorIndex(DEFAULT_HIT_INDEX_STATE, DEFAULT_BRIGHTNESS_SWITCH_STATE)
	local color = cytanbColorFromIndex(colorIndex)
	updateStatus(color, colorIndex)
end

-- 全ユーザーで、毎フレーム呼び出される。
function updateAll()
	updateStateCw()
end

--- SubItem をトリガーでつかむと呼び出される。
function onGrab(target)
	cytanbDebugLog('onGrab: ', target)
end

--- グリップしてアイテムを使用すると呼び出される。
function onUse(use)
	cytanbDebugLog('onUse: ', use)
	if pickerEntered then
		vci.state.Set(ANY_PICKER_ALLOWED_STATE_NAME, not isAnyPickerAllowed())
	end
end

--- 操作権があるユーザーで、アイテムに Collider (Is Trigger = ON) が衝突したときに呼び出される。
function onTriggerEnter(item, hit)
	if isPickerHit(hit) then
		if item == BRIGHTNESS_SWITCH_NAME then
			local time = vci.me.Time
			if time >= lastBrightnessChangeTime + UPDATE_PERIOD then
				lastBrightnessChangeTime = time
				local brightnessPage = (getBrightnessPage() + 1) % __CYTANB_COLOR_DEFAULT_BRIGHTNESS_SAMPLES
				cytanbDebugLog('on trigger: brightness_switch ,  page = ', brightnessPage)
				vci.state.Set(BRIGHTNESS_SWITCH_STATE_NAME, brightnessPage)
			end
		elseif item == PICKER_SWITCH_NAME and PALETTE_BASE.IsMine then
			cytanbDebugLog('on trigger: picker_switch')
			pickerEntered = true
		elseif cytanbStringStartsWith(item, COLOR_INDEX_PREFIX) then
			local hitIndex = tonumber(string.sub(item, 1 + string.len(COLOR_INDEX_PREFIX)), 10)
			cytanbDebugLog('on trigger: hitIndex = ', hitIndex, ' hit = ', hit)
			if (hitIndex) then
				vci.state.Set(HIT_INDEX_STATE_NAME, hitIndex)
			end
		end
	end
end

function onTriggerExit(item, hit)
	if item == PICKER_SWITCH_NAME then
		pickerEntered = false
	end
end

vci.message.On(MESSAGE_NAME_QUERY_STATUS, function (sender, name, message)
	if not vci.assets.IsMine then return end

	local colorIndex = calculateColorIndex(getHitIndex(), getBrightnessPage())
	local color = cytanbColorFromIndex(colorIndex)
	emitStatus(color, colorIndex)
end)
