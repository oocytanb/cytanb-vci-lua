----------------------------------------------------------------
--  Copyright (c) 2019 oO (https://github.com/oocytanb)
--  MIT Licensed
----------------------------------------------------------------
cytanb=(function()math.randomseed(os.time())local a='__CYTANB_INSTANCE_ID'local b=10;local c=4;local d=4;local e=b*c*d;local f='#__CYTANB_NEGATIVE_NUMBER'local g=400;local h;local cytanb={InstanceId=function()if h==''then h=vci.state.Get(a)or''end;return h end,LOG_LEVEL_FATAL=100,LOG_LEVEL_ERROR=200,LOG_LEVEL_WARN=300,LOG_LEVEL_INFO=400,LOG_LEVEL_DEBUG=500,LOG_LEVEL_TRACE=600,GetLogLevel=function()return g end,SetLogLevel=function(i)g=i end,Log=function(i,...)if i<=g then local j=table.pack(...)if j.n==1 then print(j[1]~=nil and tostring(j[1])or'')else local k=''for l=1,j.n do if j[l]~=nil then k=k..tostring(j[l])end end;print(k)end end end,FatalLog=function(...)cytanb.Log(cytanb.LOG_LEVEL_FATAL,...)end,ErrorLog=function(...)cytanb.Log(cytanb.LOG_LEVEL_ERROR,...)end,WarnLog=function(...)cytanb.Log(cytanb.LOG_LEVEL_WARN,...)end,InfoLog=function(...)cytanb.Log(cytanb.LOG_LEVEL_INFO,...)end,DebugLog=function(...)cytanb.Log(cytanb.LOG_LEVEL_DEBUG,...)end,TraceLog=function(...)cytanb.Log(cytanb.LOG_LEVEL_TRACE,...)end,Vars=function(m,n,o)if n==nil then n=''end;if o==nil then o={}end;local p=type(m)if p=='table'then o[m]=o[m]and o[m]+1 or 1;local k='('..tostring(m)..') {\n'local q=n..'  'for r,s in pairs(m)do if type(s)=='table'and o[s]and o[s]>0 then k=k..q..r..': ('..tostring(s)..')\n'else k=k..q..r..': '..cytanb.Vars(s,q,o)..'\n'end end;k=k..n..'}'o[m]=o[m]-1;if o[m]<=0 then o[m]=nil end;return k elseif p=='function'or p=="thread"or p=="userdata"then return'('..p..')'elseif p=='string'then return'('..p..') '..string.format('%q',m)else return'('..p..') '..tostring(m)end end,ListToDictionary=function(t,u)local table={}local v=u==nil;for w,m in pairs(t)do table[m]=v and m or u end;return table end,RandomUUID=function()return{math.random(0,0xFFFFFFFF),bit32.bor(0x4000,bit32.band(math.random(0,0xFFFFFFFF),0xFFFF0FFF)),bit32.bor(0x80000000,bit32.band(math.random(0,0xFFFFFFFF),0x3FFFFFFF)),math.random(0,0xFFFFFFFF)}end,UUIDString=function(x)local y=x[2]or 0;local z=x[3]or 0;return string.format('%08x-%04x-%04x-%04x-%04x%08x',bit32.band(x[1]or 0,0xFFFFFFFF),bit32.band(bit32.rshift(y,16),0xFFFF),bit32.band(y,0xFFFF),bit32.band(bit32.rshift(z,16),0xFFFF),bit32.band(z,0xFFFF),bit32.band(x[4]or 0,0xFFFFFFFF))end,ColorFromARGB32=function(A)local B=type(A)=='number'and A or 0xFF000000;return Color.__new(bit32.band(bit32.rshift(B,16),0xFF)/0xFF,bit32.band(bit32.rshift(B,8),0xFF)/0xFF,bit32.band(B,0xFF)/0xFF,bit32.band(bit32.rshift(B,24),0xFF)/0xFF)end,ColorToARGB32=function(C)return bit32.bor(bit32.lshift(math.floor(255*C.a+0.5),24),bit32.lshift(math.floor(255*C.r+0.5),16),bit32.lshift(math.floor(255*C.g+0.5),8),math.floor(255*C.b+0.5))end,GetDefaultHueSamples=function()return b end,GetDefaultSaturationSamples=function()return c end,GetDefaultBrightnessSamples=function()return d end,GetDefaultColorMapSize=function()return e end,ColorFromIndex=function(D,E,F,G,H)local I=math.max(math.floor(E or b),1)local J=H and I or I-1;local K=math.max(math.floor(F or c),1)local L=math.max(math.floor(G or d),1)local M=math.max(math.min(math.floor(D or 0),I*K*L-1),0)local N=M%I;local O=math.floor(M/I)local P=O%K;local Q=math.floor(O/K)if H or N~=J then local R=N/J;local S=(K-P)/K;local m=(L-Q)/L;return Color.HSVToRGB(R,S,m)else local m=(L-Q)/L*P/(K-1)return Color.HSVToRGB(0.0,0.0,m)end end,GetSubItemTransform=function(T)local U=T.GetPosition()local V=T.GetRotation()local W=T.GetLocalScale()return{positionX=U.x,positionY=U.y,positionZ=U.z,rotationX=V.x,rotationY=V.y,rotationZ=V.z,rotationW=V.w,scaleX=W.x,scaleY=W.y,scaleZ=W.z}end,TableToSerialiable=function(X)if type(X)~='table'then return X end;local Y={}for w,m in pairs(X)do if type(m)=='number'and m<0 then Y[w..f]=tostring(m)else Y[w]=cytanb.TableToSerialiable(m)end end;return Y end,TableFromSerialiable=function(Y)if type(Y)~='table'then return Y end;local X={}for w,m in pairs(Y)do if type(m)=='string'and string.endsWith(w,f)then X[string.sub(w,1,#w-#f)]=tonumber(m)else X[w]=cytanb.TableFromSerialiable(m)end end;return X end,INSTANCE_ID_PARAMETER_NAME='__CYTANB_INSTANCE_ID',EmitMessage=function(Z,_)local table=_ and cytanb.TableToSerialiable(_)or{}table[cytanb.INSTANCE_ID_PARAMETER_NAME]=cytanb.InstanceId()vci.message.Emit(Z,json.serialize(table))end,OnMessage=function(Z,a0)local a1=function(a2,a3,a4)local _;if a4==''then _={}else local a5,Y=pcall(json.parse,a4)if not a5 or type(Y)~='table'then cytanb.TraceLog('Invalid message format: ',a4)return end;_=cytanb.TableFromSerialiable(Y)end;a0(a2,a3,_)end;vci.message.On(Z,a1)return{Off=function()if a1 then a1=nil end end}end}if vci.assets.IsMine then h=cytanb.UUIDString(cytanb.RandomUUID())vci.state.Set(a,h)else h=''end;return cytanb end)()

--- カラーパレットの共有変数の名前空間。
local COLOR_PALETTE_SHARED_NS = 'com.github.oocytanb.cytanb-tso-collab.color-palette'

--- パレットで選択した色を格納する共有変数名。別の VCI から色を取得可能。ARGB 32 bit 値。
local SHARED_NAME_ARGB32 = COLOR_PALETTE_SHARED_NS .. '.argb32'

--- パレットで選択した色のインデックス値を格納する共有変数名。
local SHARED_NAME_COLOR_INDEX = COLOR_PALETTE_SHARED_NS .. '.color-index'

--- カラーパレットのメッセージの名前空間。
local COLOR_PALETTE_MESSAGE_NS = 'cytanb.color-palette'

--- メッセージフォーマットのバージョン。
local MESSAGE_VERSION = 0x10000

--- メッセージフォーマットの最小バージョン。
local MESSAGE_MIN_VERSION = 0x10000

--- アイテムのステータスを問い合わせるメッセージ名。
local MESSAGE_NAME_QUERY_STATUS = COLOR_PALETTE_MESSAGE_NS .. '.query-status'

--- アイテムのステータスを通知するメッセージ名。
local MESSAGE_NAME_ITEM_STATUS = COLOR_PALETTE_MESSAGE_NS .. '.item-status'

--- カラーピッカーのタグ。
local COLOR_PICKER_TAG = '#cytanb-color-picker'

local ALLOWED_PICKER_LIST = {'HandPointMarker', 'RightArm', 'LeftArm', 'RightHand', 'LeftHand'}
local ALLOWED_PICKER_TABLE = cytanb.ListToDictionary(ALLOWED_PICKER_LIST, true)
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

local lastBrightnessChangeTime = TimeSpan.FromHours(-1)
local pickerEntered = false

local function calculateColorIndex(hitIndex, brightnessPage)
	return hitIndex + cytanb.GetDefaultHueSamples() * cytanb.GetDefaultSaturationSamples() * brightnessPage
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
	return hit and (isAnyPickerAllowed() or ALLOWED_PICKER_TABLE[hit] or string.contains(hit, COLOR_PICKER_TAG))
end

local function emitStatus(color, colorIndex)
	local argb32 = cytanb.ColorToARGB32(color)

	cytanb.DebugLog('emit status: colorIndex = ', colorIndex, ', color = ', color)

	local params = cytanb.GetSubItemTransform(PALETTE_BASE)
	params['version'] = MESSAGE_VERSION
	params['argb32'] = argb32
	params['colorIndex'] = colorIndex
	cytanb.EmitMessage(MESSAGE_NAME_ITEM_STATUS, params)
end

local function updateStatus(color, colorIndex)
	if not vci.assets.IsMine then return end

	cytanb.DebugLog('update status: colorIndex = ', colorIndex, ' ,  color = ', color)

	local argb32 = cytanb.ColorToARGB32(color)
	vci.studio.shared.Set(SHARED_NAME_ARGB32, argb32)
	vci.studio.shared.Set(SHARED_NAME_COLOR_INDEX, colorIndex)

	emitStatus(color, colorIndex)
end

local updateStateCw = coroutine.wrap(function ()
	local firstUpdate = true

	local lastUpdateTime = vci.me.Time
	local lastAnyPickerAllowed = false
	local lastHitIndex = -1
	local lastBrightnessPage = -1

	while true do
		local time = vci.me.Time
		if time >= lastUpdateTime + UPDATE_PERIOD then
			lastUpdateTime = time

			--
			local anyPickerAllowed = isAnyPickerAllowed()
			if firstUpdate or anyPickerAllowed ~= lastAnyPickerAllowed then
				cytanb.DebugLog('update anyPickerAllowed: ', anyPickerAllowed)
				lastAnyPickerAllowed = anyPickerAllowed
				local pickerPage = anyPickerAllowed and 1 or 0
				vci.assets.SetMaterialTextureOffsetFromName(PICKER_SWITCH_MATERIAL_NAME, Vector2.__new(0.0, 1.0 - PICKER_SWITCH_UV_HEIGHT * pickerPage))
			end

			--
			local hitIndex = getHitIndex()
			local brightnessPage = getBrightnessPage()
			if firstUpdate or lastHitIndex ~= hitIndex or lastBrightnessPage ~= brightnessPage then
				local colorIndex = calculateColorIndex(hitIndex, brightnessPage)
				local color = cytanb.ColorFromIndex(colorIndex)

				cytanb.DebugLog('update currentColor: colorIndex = ', colorIndex, ' ,  color = ', color)
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

cytanb.OnMessage(MESSAGE_NAME_QUERY_STATUS, function (sender, name, parameterMap)
	if not vci.assets.IsMine then return end

	local colorIndex = calculateColorIndex(getHitIndex(), getBrightnessPage())
	local color = cytanb.ColorFromIndex(colorIndex)
	emitStatus(color, colorIndex)
end)

-- アイテムを設置したときの初期化処理
if vci.assets.IsMine then
	vci.state.Set(ANY_PICKER_ALLOWED_STATE_NAME, DEFAULT_ANY_PICKER_ALLOWED_STATE)
	vci.state.Set(HIT_INDEX_STATE_NAME, DEFAULT_HIT_INDEX_STATE)
	vci.state.Set(BRIGHTNESS_SWITCH_STATE_NAME, DEFAULT_BRIGHTNESS_SWITCH_STATE)

	local colorIndex = calculateColorIndex(DEFAULT_HIT_INDEX_STATE, DEFAULT_BRIGHTNESS_SWITCH_STATE)
	local color = cytanb.ColorFromIndex(colorIndex)
	updateStatus(color, colorIndex)
end

-- 全ユーザーで、毎フレーム呼び出される。
function updateAll()
	updateStateCw()
end

--- SubItem をトリガーでつかむと呼び出される。
function onGrab(target)
	cytanb.DebugLog('onGrab: ', target)
end

--- グリップしてアイテムを使用すると呼び出される。
function onUse(use)
	cytanb.DebugLog('onUse: ', use)
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
				local brightnessPage = (getBrightnessPage() + 1) % cytanb.GetDefaultBrightnessSamples()
				cytanb.DebugLog('on trigger: brightness_switch ,  page = ', brightnessPage)
				vci.state.Set(BRIGHTNESS_SWITCH_STATE_NAME, brightnessPage)
			end
		elseif item == PICKER_SWITCH_NAME and PALETTE_BASE.IsMine then
			cytanb.DebugLog('on trigger: picker_switch')
			pickerEntered = true
		elseif string.startsWith(item, COLOR_INDEX_PREFIX) then
			local hitIndex = tonumber(string.sub(item, 1 + string.len(COLOR_INDEX_PREFIX)), 10)
			cytanb.DebugLog('on trigger: hitIndex = ', hitIndex, ' hit = ', hit)
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
