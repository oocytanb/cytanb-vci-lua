----------------------------------------------------------------
--  Copyright (c) 2019 oO (https://github.com/oocytanb)
--  MIT Licensed
----------------------------------------------------------------

cytanb=(function()math.randomseed(os.time())local a={LOG_LEVEL_FATAL=100,LOG_LEVEL_ERROR=200,LOG_LEVEL_WARN=300,LOG_LEVEL_INFO=400,LOG_LEVEL_DEBUG=500,LOG_LEVEL_TRACE=600,COLOR_HUE_SAMPLES=10,COLOR_SATURATION_SAMPLES=4,COLOR_BRIGHTNESS_SAMPLES=4,COLOR_MAP_SIZE=10*4*4,NEGATIVE_NUMBER_TAG='#__CYTANB_NEGATIVE_NUMBER',INSTANCE_ID_PARAMETER_NAME='__CYTANB_INSTANCE_ID'}local b='__CYTANB_INSTANCE_ID'local c=400;local d;local cytanb={InstanceId=function()if d==''then d=vci.state.Get(b)or''end;return d end,Vars=function(e,f,g,h)local i;if f then i=f~='__NOLF'else f='  'i=true end;if not g then g=''end;if not h then h={}end;local j=type(e)if j=='table'then h[e]=h[e]and h[e]+1 or 1;local k=i and g..f or''local l='('..tostring(e)..') {'local m=true;for n,o in pairs(e)do if m then m=false else l=l..(i and','or', ')end;if i then l=l..'\n'..k end;if type(o)=='table'and h[o]and h[o]>0 then l=l..n..' = ('..tostring(o)..')'else l=l..n..' = '..cytanb.Vars(o,f,k,h)end end;if not m and i then l=l..'\n'..g end;l=l..'}'h[e]=h[e]-1;if h[e]<=0 then h[e]=nil end;return l elseif j=='function'or j=="thread"or j=="userdata"then return'('..j..')'elseif j=='string'then return'('..j..') '..string.format('%q',e)else return'('..j..') '..tostring(e)end end,GetLogLevel=function()return c end,SetLogLevel=function(p)c=p end,Log=function(p,...)if p<=c then local q=table.pack(...)if q.n==1 then local e=q[1]if e~=nil then print(type(e)=='table'and cytanb.Vars(e)or tostring(e))else print('')end else local l=''for r=1,q.n do local e=q[r]if e~=nil then l=l..(type(e)=='table'and cytanb.Vars(e)or tostring(e))end end;print(l)end end end,FatalLog=function(...)cytanb.Log(a.LOG_LEVEL_FATAL,...)end,ErrorLog=function(...)cytanb.Log(a.LOG_LEVEL_ERROR,...)end,WarnLog=function(...)cytanb.Log(a.LOG_LEVEL_WARN,...)end,InfoLog=function(...)cytanb.Log(a.LOG_LEVEL_INFO,...)end,DebugLog=function(...)cytanb.Log(a.LOG_LEVEL_DEBUG,...)end,TraceLog=function(...)cytanb.Log(a.LOG_LEVEL_TRACE,...)end,ListToDictionary=function(s,t)local table={}local u=t==nil;for v,e in pairs(s)do table[e]=u and e or t end;return table end,RandomUUID=function()return{math.random(0,0xFFFFFFFF),bit32.bor(0x4000,bit32.band(math.random(0,0xFFFFFFFF),0xFFFF0FFF)),bit32.bor(0x80000000,bit32.band(math.random(0,0xFFFFFFFF),0x3FFFFFFF)),math.random(0,0xFFFFFFFF)}end,UUIDString=function(w)local x=w[2]or 0;local y=w[3]or 0;return string.format('%08x-%04x-%04x-%04x-%04x%08x',bit32.band(w[1]or 0,0xFFFFFFFF),bit32.band(bit32.rshift(x,16),0xFFFF),bit32.band(x,0xFFFF),bit32.band(bit32.rshift(y,16),0xFFFF),bit32.band(y,0xFFFF),bit32.band(w[4]or 0,0xFFFFFFFF))end,ColorFromARGB32=function(z)local A=type(z)=='number'and z or 0xFF000000;return Color.__new(bit32.band(bit32.rshift(A,16),0xFF)/0xFF,bit32.band(bit32.rshift(A,8),0xFF)/0xFF,bit32.band(A,0xFF)/0xFF,bit32.band(bit32.rshift(A,24),0xFF)/0xFF)end,ColorToARGB32=function(B)return bit32.bor(bit32.lshift(math.floor(255*B.a+0.5),24),bit32.lshift(math.floor(255*B.r+0.5),16),bit32.lshift(math.floor(255*B.g+0.5),8),math.floor(255*B.b+0.5))end,ColorFromIndex=function(C,D,E,F,G)local H=math.max(math.floor(D or a.COLOR_HUE_SAMPLES),1)local I=G and H or H-1;local J=math.max(math.floor(E or a.COLOR_SATURATION_SAMPLES),1)local K=math.max(math.floor(F or a.COLOR_BRIGHTNESS_SAMPLES),1)local L=math.max(math.min(math.floor(C or 0),H*J*K-1),0)local M=L%H;local N=math.floor(L/H)local O=N%J;local P=math.floor(N/J)if G or M~=I then local Q=M/I;local R=(J-O)/J;local e=(K-P)/K;return Color.HSVToRGB(Q,R,e)else local e=(K-P)/K*O/(J-1)return Color.HSVToRGB(0.0,0.0,e)end end,GetSubItemTransform=function(S)local T=S.GetPosition()local U=S.GetRotation()local V=S.GetLocalScale()return{positionX=T.x,positionY=T.y,positionZ=T.z,rotationX=U.x,rotationY=U.y,rotationZ=U.z,rotationW=U.w,scaleX=V.x,scaleY=V.y,scaleZ=V.z}end,TableToSerialiable=function(W)if type(W)~='table'then return W end;local X={}for v,e in pairs(W)do if type(e)=='number'and e<0 then X[v..a.NEGATIVE_NUMBER_TAG]=tostring(e)else X[v]=cytanb.TableToSerialiable(e)end end;return X end,TableFromSerialiable=function(X)if type(X)~='table'then return X end;local W={}for v,e in pairs(X)do if type(e)=='string'and string.endsWith(v,a.NEGATIVE_NUMBER_TAG)then W[string.sub(v,1,#v-#a.NEGATIVE_NUMBER_TAG)]=tonumber(e)else W[v]=cytanb.TableFromSerialiable(e)end end;return W end,EmitMessage=function(Y,Z)local table=Z and cytanb.TableToSerialiable(Z)or{}table[a.INSTANCE_ID_PARAMETER_NAME]=cytanb.InstanceId()vci.message.Emit(Y,json.serialize(table))end,OnMessage=function(Y,_)local a0=function(a1,a2,a3)local Z;if a3==''then Z={}else local a4,X=pcall(json.parse,a3)if not a4 or type(X)~='table'then cytanb.TraceLog('Invalid message format: ',a3)return end;Z=cytanb.TableFromSerialiable(X)end;_(a1,a2,Z)end;vci.message.On(Y,a0)return{Off=function()if a0 then a0=nil end end}end}setmetatable(cytanb,{__index=a})if vci.assets.IsMine then d=cytanb.UUIDString(cytanb.RandomUUID())vci.state.Set(b,d)else d=''end;return cytanb end)()

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
	return hitIndex + cytanb.COLOR_HUE_SAMPLES * cytanb.COLOR_SATURATION_SAMPLES * brightnessPage
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
				local brightnessPage = (getBrightnessPage() + 1) % cytanb.COLOR_BRIGHTNESS_SAMPLES
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
