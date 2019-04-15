----------------------------------------------------------------
--  Copyright (c) 2019 oO (https://github.com/oocytanb)
--  MIT Licensed
----------------------------------------------------------------

math.randomseed(os.time())

--- ログレベル。
__CYTANB_LOG_LEVEL = 500

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

--- カラーパレットのパッケージ名。
local COLOR_PALETTE_PACKAGE_NAME = 'com.github.oocytanb.cytanb-tso-collab.color-palette'

--- パレットで選択した色を格納する共有変数名。別の VCI から色を取得可能。ARGB 32 bit 値。
local SHARED_NAME_ARGB32 = COLOR_PALETTE_PACKAGE_NAME .. '.argb32'

--- メッセージフォーマットのバージョン。
local MESSAGE_VERSION = 0x10000

--- メッセージフォーマットの最小バージョン。
local MESSAGE_MIN_VERSION = 0x10000

--- アイテムのステータスを問い合わせるメッセージ名。
local MESSAGE_NAME_QUERY_STATUS = COLOR_PALETTE_PACKAGE_NAME .. '.query-status'

--- アイテムのステータスを通知するメッセージ名。
local MESSAGE_NAME_ITEM_STATUS = COLOR_PALETTE_PACKAGE_NAME .. '.item-status'

--- カラーピッカーのタグ。
local COLOR_PICKER_TAG = '#cytanb-color-picker'

local PANEL_TAG = '#panel'

local COLOR_STATUS_PREFIX = 'color.'

local AUTO_CHANGE_UNIMSG_RECEIVER_STATE_NAME = 'autoChangeUnimsgReceiver'
local AUTO_CHANGE_ANYMSG_RECEIVER_STATE_NAME = 'autoChangeAnymsgReceiver'
local LINKED_PALETTE_INSTANCE_ID_STATE_NAME = 'linkedColorPaletteInstanceId'

local ITEM_NAME_LIST, ALL_MATERIAL_TABLE, CHALK_MATERIAL_TABLE, PANEL_MATERIAL_TABLE, DEFAULT_ITEM_COLOR_MAP = (
	function (chalkList, panelList, colorList)
		local ci = 1
		local itemNameList = {}
		local allMaterialTable = {}
		local itemColorMap = {}

		local chalkMaterialTable = {}
		for i, v in ipairs(chalkList) do
			local name = v .. COLOR_PICKER_TAG
			chalkMaterialTable[name] = v .. '-mat'
			allMaterialTable[name] = chalkMaterialTable[name]
			itemColorMap[name] = cytanbColorFromARGB32(colorList[ci])
			table.insert(itemNameList, name)
			ci = ci + 1
		end

		local panelMaterialTable = {}
		for i, v in ipairs(panelList) do
			local name = v .. PANEL_TAG
			panelMaterialTable[name] = v .. '-panel-mat'
			allMaterialTable[name] = panelMaterialTable[name]
			itemColorMap[name] = cytanbColorFromARGB32(colorList[ci])
			table.insert(itemNameList, name)
			ci = ci + 1
		end

		return itemNameList, allMaterialTable, chalkMaterialTable, panelMaterialTable, itemColorMap
	end
)(
	{'large-chalk', 'middle-chalk', 'small-chalk'},
	{'shared-variable', 'unimsg-receiver', 'anymsg-receiver'},
	{0xFFE6B422, 0xFF65318E, 0xFFE7E7E7, 0xFF006888, 0xFF00552E, 0xFFA22041}
)

local UNIMSG_RECEIVER_NAME = ITEM_NAME_LIST[5]
local ANYMSG_RECEIVER_NAME = ITEM_NAME_LIST[6]

local UPDATE_PERIOD = TimeSpan.FromMilliseconds(100)
local QUERY_PERIOD = TimeSpan.FromSeconds(2)

local linkPaletteCw = nil

local function getLinkedInstanceId()
	return vci.state.Get(LINKED_PALETTE_INSTANCE_ID_STATE_NAME) or ''
end

-- 現在のカラーパレットとのリンクを解除する
local function unlinkPalette()
	vci.state.Set(LINKED_PALETTE_INSTANCE_ID_STATE_NAME, '')
end

local function isAutoChangeUnimsgReceiver()
	local b = vci.state.Get(AUTO_CHANGE_UNIMSG_RECEIVER_STATE_NAME)
	if b == nil then
		return false
	else
		return b
	end
end

local function isAutoChangeAnymsgReceiver()
	local b = vci.state.Get(AUTO_CHANGE_ANYMSG_RECEIVER_STATE_NAME)
	if b == nil then
		return true
	else
		return b
	end
end

local function getItemColor(itemName)
	return cytanbColorFromARGB32(vci.state.Get(COLOR_STATUS_PREFIX .. itemName))
end

local function setItemColor(itemName, color)
	vci.state.Set(COLOR_STATUS_PREFIX .. itemName, cytanbColorToARGB32(color))
end

local function linkPaletteProc()
	local itemPosition = vci.assets.GetSubItem(UNIMSG_RECEIVER_NAME).GetPosition()
	local candId = ''
	local candPosition = nil
	local candDistance = nil
	local candARGB32 = nil

	unlinkPalette()

	-- 新しいカラーパレットとリンクするために、問い合わせる
	cytanbDebugLog('emitMessage: ', MESSAGE_NAME_QUERY_STATUS)
	cytanbEmitMessage(MESSAGE_NAME_QUERY_STATUS, MESSAGE_VERSION)

	local queryExpires = vci.me.Time + QUERY_PERIOD
	while true do
		local cont, parameterMap = coroutine.yield(100)
		if not cont then
			-- abort
			cytanbDebugLog('linkPaletteProc aborted.')
			return -301
		end

		if parameterMap then
			-- パレットとの距離を調べる
			local instanceId = parameterMap['instanceId']
			local x = parameterMap['positionX']
			local y = parameterMap['positionY']
			local z = parameterMap['positionZ']
			if instanceId and instanceId ~= '' and x and y and z then
				local position = Vector3.__new(x, y, z)
				local distance = Vector3.Distance(position, itemPosition)
				if not candPosition or  distance < candDistance then
					-- より近い距離のパレットを候補にする
					candId = instanceId
					candPosition = position
					candDistance = distance
					candARGB32 = parameterMap['argb32']
				end
			end
		end

		if queryExpires < vci.me.Time then
			-- タイムアウトしたので処理を抜ける
			break
		end
	end

	return 0, candId, candARGB32
end

local function resumeLinkPalette(parameterMap)
	if not linkPaletteCw then return end

	local code, instanceId, argb32 = linkPaletteCw(true, parameterMap)
	if code <= 0 then
		-- スレッド終了
		cytanbDebugLog('linkPaletteCw stoped: ', code)
		linkPaletteCw = nil

		if instanceId and instanceId ~= '' and instanceId ~= getLinkedInstanceId() then
			-- 新しいパレットのインスタンスにリンクする
			print('linked to color-palette #', instanceId)
			vci.state.Set(LINKED_PALETTE_INSTANCE_ID_STATE_NAME, instanceId)
			setItemColor(UNIMSG_RECEIVER_NAME, cytanbColorFromARGB32(argb32))
		end
	end
end

local updateStateCw = coroutine.wrap(function ()
	local lastUpdateTime = vci.me.Time
	local lastItemColorMap = {}
	local lastAutoChangeUnimsg = isAutoChangeUnimsgReceiver()

	while true do
		local time = vci.me.Time
		if time >= lastUpdateTime + UPDATE_PERIOD then
			lastUpdateTime = time

			for itemName, materialName in pairs(ALL_MATERIAL_TABLE) do
				local color = getItemColor(itemName)
				if color ~= lastItemColorMap[itemName] then
					lastItemColorMap[itemName] = color
					vci.assets.SetMaterialColorFromName(materialName, color)
				end
			end

			if vci.assets.IsMine then
				local autoChangeUnimsg = isAutoChangeUnimsgReceiver()
				if autoChangeUnimsg ~= lastAutoChangeUnimsg then
					lastAutoChangeUnimsg = autoChangeUnimsg

					if autoChangeUnimsg then
						if linkPaletteCw then
							-- abort previous thread
							linkPaletteCw(false)
						end

						linkPaletteCw = coroutine.wrap(linkPaletteProc)
					else
						unlinkPalette()
					end
				end
			end
		end

		coroutine.yield(100)
	end
	return 0
end)

-- アイテムを設置したときの初期化処理
if vci.assets.IsMine then
	for k, v in pairs(DEFAULT_ITEM_COLOR_MAP) do
		setItemColor(k, v)
	end
end

-- 全ユーザーで、毎フレーム呼び出される。
function updateAll()
	updateStateCw()

	if vci.assets.IsMine then
		resumeLinkPalette()
	end
end

-- グリップしてアイテムを使用すると呼び出される。
function onUse(use)
	-- 共有変数から色情報を取得する
	local color = cytanbColorFromARGB32(vci.studio.shared.Get(SHARED_NAME_ARGB32))
	cytanbDebugLog('onUse: ', use, ' ,  shared color = ', color)

	local chalkMaterial = CHALK_MATERIAL_TABLE[use]
	if chalkMaterial then
		setItemColor(use, color)
	end

	local panelMaterial = PANEL_MATERIAL_TABLE[use]
	if panelMaterial then
		setItemColor(use, color)

		if use == UNIMSG_RECEIVER_NAME then
			-- 自動でパレットの選択色に変更するかを切り替える
			vci.state.Set(AUTO_CHANGE_UNIMSG_RECEIVER_STATE_NAME, not isAutoChangeUnimsgReceiver())
		elseif use == ANYMSG_RECEIVER_NAME then
			-- 自動でパレットの選択色に変更するかを切り替える
			vci.state.Set(AUTO_CHANGE_ANYMSG_RECEIVER_STATE_NAME, not isAutoChangeAnymsgReceiver())
		end
	end
end

--- 操作権があるユーザーで、アイテムに Collider (Is Trigger = OFF) が衝突したときに呼び出される。
function onCollisionEnter(item, hit)
	cytanbDebugLog('on collision enter: item = ', item, ' , hit = ', hit)

	local chalkMaterial = CHALK_MATERIAL_TABLE[item]
	local panelMaterial = PANEL_MATERIAL_TABLE[hit]
	if chalkMaterial and panelMaterial then
		-- チョークがパネルにヒットしたときは、チョークの色をパネルに設定する
		local chalkColor = getItemColor(item)

		-- まったく同色にすると、チョークと区別できないため、若干値を下げる。
		local d = 0.1
		local color = Color.__new(math.max(chalkColor.r - d, 0.0), math.max(chalkColor.g - d, 0.0), math.max(chalkColor.b - d, 0.0), chalkColor.a)
		cytanbDebugLog('change panel[', hit, '] color to chalk[', item, ']: color = ', color)
		setItemColor(hit, color)
	end
end

cytanbBindMessage(MESSAGE_NAME_ITEM_STATUS, MESSAGE_MIN_VERSION, function (sender, name, parameterMap)
	if not vci.assets.IsMine then return end

	-- vci.message から色情報を取得する
	local color = cytanbColorFromARGB32(parameterMap['argb32'])
	cytanbDebugLog('on item status: color = ', color)

	resumeLinkPalette(parameterMap)

	if isAutoChangeUnimsgReceiver() then
		local instanceId = parameterMap['instanceId']
		local linkedInstanceId = getLinkedInstanceId()

		if linkedInstanceId ~= '' and linkedInstanceId == instanceId then
			-- リンクされたカラーパレットの色情報の場合のみ、パネルの色を変更する
			print('set unimsg receiver color')
			setItemColor(UNIMSG_RECEIVER_NAME, color)
		end
	end

	if isAutoChangeAnymsgReceiver() then
		-- どのカラーパレットの色情報であっても、パネルの色を変更する
		print('set anymsg receiver color')
		setItemColor(ANYMSG_RECEIVER_NAME, color)
	end
end)
