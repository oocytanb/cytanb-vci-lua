----------------------------------------------------------------
--  Copyright (c) 2019 oO (https://github.com/oocytanb)
--  MIT Licensed
----------------------------------------------------------------

cytanb=(function()math.randomseed(os.time())local a={FatalLogLevel=100,ErrorLogLevel=200,WarnLogLevel=300,InfoLogLevel=400,DebugLogLevel=500,TraceLogLevel=600,ColorHueSamples=10,ColorSaturationSamples=4,ColorBrightnessSamples=5,ColorMapSize=10*4*5,NegativeNumberTag='#__CYTANB_NEGATIVE_NUMBER',InstanceIDParameterName='__CYTANB_INSTANCE_ID'}local b='__CYTANB_INSTANCE_ID'local c=400;local d;local cytanb={InstanceID=function()if d==''then d=vci.state.Get(b)or''end;return d end,Vars=function(e,f,g,h)local i;if f then i=f~='__NOLF'else f='  'i=true end;if not g then g=''end;if not h then h={}end;local j=type(e)if j=='table'then h[e]=h[e]and h[e]+1 or 1;local k=i and g..f or''local l='('..tostring(e)..') {'local m=true;for n,o in pairs(e)do if m then m=false else l=l..(i and','or', ')end;if i then l=l..'\n'..k end;if type(o)=='table'and h[o]and h[o]>0 then l=l..n..' = ('..tostring(o)..')'else l=l..n..' = '..cytanb.Vars(o,f,k,h)end end;if not m and i then l=l..'\n'..g end;l=l..'}'h[e]=h[e]-1;if h[e]<=0 then h[e]=nil end;return l elseif j=='function'or j=="thread"or j=="userdata"then return'('..j..')'elseif j=='string'then return'('..j..') '..string.format('%q',e)else return'('..j..') '..tostring(e)end end,GetLogLevel=function()return c end,SetLogLevel=function(p)c=p end,Log=function(p,...)if p<=c then local q=table.pack(...)if q.n==1 then local e=q[1]if e~=nil then print(type(e)=='table'and cytanb.Vars(e)or tostring(e))else print('')end else local l=''for r=1,q.n do local e=q[r]if e~=nil then l=l..(type(e)=='table'and cytanb.Vars(e)or tostring(e))end end;print(l)end end end,FatalLog=function(...)cytanb.Log(a.FatalLogLevel,...)end,ErrorLog=function(...)cytanb.Log(a.ErrorLogLevel,...)end,WarnLog=function(...)cytanb.Log(a.WarnLogLevel,...)end,InfoLog=function(...)cytanb.Log(a.InfoLogLevel,...)end,DebugLog=function(...)cytanb.Log(a.DebugLogLevel,...)end,TraceLog=function(...)cytanb.Log(a.TraceLogLevel,...)end,ListToMap=function(s,t)local table={}local u=t==nil;for v,e in pairs(s)do table[e]=u and e or t end;return table end,RandomUUID=function()return{math.random(0,0xFFFFFFFF),bit32.bor(0x4000,bit32.band(math.random(0,0xFFFFFFFF),0xFFFF0FFF)),bit32.bor(0x80000000,bit32.band(math.random(0,0xFFFFFFFF),0x3FFFFFFF)),math.random(0,0xFFFFFFFF)}end,UUIDString=function(w)local x=w[2]or 0;local y=w[3]or 0;return string.format('%08x-%04x-%04x-%04x-%04x%08x',bit32.band(w[1]or 0,0xFFFFFFFF),bit32.band(bit32.rshift(x,16),0xFFFF),bit32.band(x,0xFFFF),bit32.band(bit32.rshift(y,16),0xFFFF),bit32.band(y,0xFFFF),bit32.band(w[4]or 0,0xFFFFFFFF))end,ColorFromARGB32=function(z)local A=type(z)=='number'and z or 0xFF000000;return Color.__new(bit32.band(bit32.rshift(A,16),0xFF)/0xFF,bit32.band(bit32.rshift(A,8),0xFF)/0xFF,bit32.band(A,0xFF)/0xFF,bit32.band(bit32.rshift(A,24),0xFF)/0xFF)end,ColorToARGB32=function(B)return bit32.bor(bit32.lshift(math.floor(255*B.a+0.5),24),bit32.lshift(math.floor(255*B.r+0.5),16),bit32.lshift(math.floor(255*B.g+0.5),8),math.floor(255*B.b+0.5))end,ColorFromIndex=function(C,D,E,F,G)local H=math.max(math.floor(D or a.ColorHueSamples),1)local I=G and H or H-1;local J=math.max(math.floor(E or a.ColorSaturationSamples),1)local K=math.max(math.floor(F or a.ColorBrightnessSamples),1)local L=math.max(math.min(math.floor(C or 0),H*J*K-1),0)local M=L%H;local N=math.floor(L/H)local O=N%J;local P=math.floor(N/J)if G or M~=I then local Q=M/I;local R=(J-O)/J;local e=(K-P)/K;return Color.HSVToRGB(Q,R,e)else local e=(K-P)/K*O/(J-1)return Color.HSVToRGB(0.0,0.0,e)end end,GetSubItemTransform=function(S)local T=S.GetPosition()local U=S.GetRotation()local V=S.GetLocalScale()return{positionX=T.x,positionY=T.y,positionZ=T.z,rotationX=U.x,rotationY=U.y,rotationZ=U.z,rotationW=U.w,scaleX=V.x,scaleY=V.y,scaleZ=V.z}end,TableToSerialiable=function(W)if type(W)~='table'then return W end;local X={}for v,e in pairs(W)do if type(e)=='number'and e<0 then X[v..a.NegativeNumberTag]=tostring(e)else X[v]=cytanb.TableToSerialiable(e)end end;return X end,TableFromSerialiable=function(X)if type(X)~='table'then return X end;local W={}for v,e in pairs(X)do if type(e)=='string'and string.endsWith(v,a.NegativeNumberTag)then W[string.sub(v,1,#v-#a.NegativeNumberTag)]=tonumber(e)else W[v]=cytanb.TableFromSerialiable(e)end end;return W end,EmitMessage=function(Y,Z)local table=Z and cytanb.TableToSerialiable(Z)or{}table[a.InstanceIDParameterName]=cytanb.InstanceID()vci.message.Emit(Y,json.serialize(table))end,OnMessage=function(Y,_)local a0=function(a1,a2,a3)local Z;if a3==''then Z={}else local a4,X=pcall(json.parse,a3)if not a4 or type(X)~='table'then cytanb.TraceLog('Invalid message format: ',a3)return end;Z=cytanb.TableFromSerialiable(X)end;_(a1,a2,Z)end;vci.message.On(Y,a0)return{Off=function()if a0 then a0=nil end end}end}setmetatable(cytanb,{__index=a})if vci.assets.IsMine then d=cytanb.UUIDString(cytanb.RandomUUID())vci.state.Set(b,d)else d=''end;return cytanb end)()

--- カラーパレットの共有変数の名前空間。
local ColorPaletteSharedNS = 'com.github.oocytanb.cytanb-tso-collab.color-palette'

--- パレットで選択した色を格納する共有変数名。別の VCI から色を取得可能。ARGB 32 bit 値。
local ARGB32SharedName = ColorPaletteSharedNS .. '.argb32'

--- パレットで選択した色のインデックス値を格納する共有変数名。
local ColorIndexSharedName = ColorPaletteSharedNS .. '.color-index'

--- カラーパレットのメッセージの名前空間。
local ColorPaletteMessageNS = 'cytanb.color-palette'

--- メッセージフォーマットのバージョン。
local MessageVersion = 0x10000

--- メッセージフォーマットの最小バージョン。
local MinMessageVersion = 0x10000

--- アイテムのステータスを問い合わせるメッセージ名。
local QueryStatusMessageName = ColorPaletteMessageNS .. '.query-status'

--- アイテムのステータスを通知するメッセージ名。
local ItemStatusMessageName = ColorPaletteMessageNS .. '.item-status'

--- カラーピッカーのタグ。
local ColorPickerTag = '#cytanb-color-picker'

local ColorIndexPrefix = 'cytanb-color-index-'
local CurrentColorMaterialName = 'current-color-mat'

local HitIndexStateName = 'hit-index-state'

local PaletteMaterialName = 'color-palette-mat'
local PalettePageHeight = 200.0 / 1024.0

local AllowedPickerList = {'HandPointMarker', 'RightArm', 'LeftArm', 'RightHand', 'LeftHand'}
local AllowedPickerMap = cytanb.ListToMap(AllowedPickerList, true)

local UpdatePeriod = TimeSpan.FromMilliseconds(100)

local PaletteBase = vci.assets.GetSubItem('palette-base')

--- スイッチ類
local advancedSwitch, pickerSwitch, opacitySwitch, brightnessSwitch

local function CreateSwitch(name, maxState, defaultState, advancedFunction, uvHeight, panelColor, inputInterval)
	local materialName = name .. '-mat'
	local stateName = name .. '-state'
	local default = defaultState or 0
	local height = uvHeight or (50.0 / 1024.0)
	local color = panelColor or Color.__new(0.8, 0.8, 0.8, 1.0)
	local hiddenColor = Color.__new(color.r, color.g, color.b, 0.0)
	local interval = inputInterval or TimeSpan.FromMilliseconds(100)
	local pickerEntered = false
	local lastInputTime = TimeSpan.Zero
	local lastState = nil
	local lastAdvancedState = nil

	local self
	self = {
		name = name,
		maxState = maxState,
		advancedFunction = advancedFunction,

		GetState = function()
			return vci.state.Get(stateName) or default
		end,

		SetState = function(state)
			vci.state.Set(stateName, state)
		end,

		NextState = function()
			local state = (self.GetState() + 1) % (maxState + 1)
			self.SetState(state)
			return state
		end,

		DoInput = function()
			-- advancedFunction が設定されているスイッチは、advanced モードのときのみ処理する
			if advancedFunction and advancedSwitch.GetState() == 0 then
				return
			end

			local time = vci.me.Time
			if time >= lastInputTime + interval then
				lastInputTime = time
				self.NextState()
			end
		end,

		SetPickerEntered = function(entered)
			pickerEntered = entered
		end,

		IsPickerEntered = function()
			return pickerEntered
		end,

		Update = function(force)
			local state = self.GetState()
			local advancedState = advancedSwitch.GetState()
			if advancedFunction and (force or advancedState ~= lastAdvancedState) then
				lastAdvancedState = advancedState
				-- advancedFunction が設定されているスイッチは、advanced モードのときのみ表示する
				vci.assets.SetMaterialColorFromName(materialName, advancedState == 0 and hiddenColor or color)
			end

			if force or state ~= lastState then
				lastState = state
				vci.assets.SetMaterialTextureOffsetFromName(materialName, Vector2.__new(0.0, 1.0 - height * state))
				return true
			else
				return false
			end
		end
	}
	return self
end

advancedSwitch = CreateSwitch('advanced-switch', 1, 0, false)
pickerSwitch = CreateSwitch('picker-switch', 1, 0, true)
opacitySwitch = CreateSwitch('opacity-switch', 4, 0, true)
brightnessSwitch = CreateSwitch('brightness-switch', cytanb.ColorBrightnessSamples - 1, 0, true)

local switchMap = {
	[advancedSwitch.name] = advancedSwitch,
	[pickerSwitch.name] = pickerSwitch,
	[opacitySwitch.name] = opacitySwitch,
	[brightnessSwitch.name] = brightnessSwitch
}

local function CalculateColor(hitIndex, brightnessPage, opacityPage)
	local colorIndex = hitIndex + cytanb.ColorHueSamples * cytanb.ColorSaturationSamples * brightnessPage
	local color = cytanb.ColorFromIndex(colorIndex)
	color.a = (opacitySwitch.maxState - opacityPage) / opacitySwitch.maxState
	return color, colorIndex
end

local function GetHitIndex()
	return vci.state.Get(HitIndexStateName) or 9
end

local function IsPickerHit(hit)
	return hit and (pickerSwitch.GetState() == 1 or AllowedPickerMap[hit] or string.contains(hit, ColorPickerTag))
end

local function EmitStatus(color, colorIndex)
	local argb32 = cytanb.ColorToARGB32(color)

	cytanb.DebugLog('emit status: colorIndex = ', colorIndex, ', color = ', color)

	local params = cytanb.GetSubItemTransform(PaletteBase)
	params['version'] = MessageVersion
	params['argb32'] = argb32
	params['colorIndex'] = colorIndex
	cytanb.EmitMessage(ItemStatusMessageName, params)
end

local function UpdateStatus(color, colorIndex)
	if not vci.assets.IsMine then return end

	cytanb.DebugLog('update status: colorIndex = ', colorIndex, ' ,  color = ', color)

	local argb32 = cytanb.ColorToARGB32(color)
	vci.studio.shared.Set(ARGB32SharedName, argb32)
	vci.studio.shared.Set(ColorIndexSharedName, colorIndex)

	EmitStatus(color, colorIndex)
end

local updateStateCw = coroutine.wrap(function ()
	local firstUpdate = true

	local lastUpdateTime = vci.me.Time
	local lastHitIndex = -1

	while true do
		local time = vci.me.Time
		if time >= lastUpdateTime + UpdatePeriod then
			lastUpdateTime = time

			--
			local switchChanged = false
			for k, v in pairs(switchMap) do
				local b = v.Update(firstUpdate)
				if v == brightnessSwitch or v == opacitySwitch then
					switchChanged = switchChanged or b
				end
			end

			--
			local hitIndex = GetHitIndex()
			if firstUpdate or lastHitIndex ~= hitIndex or switchChanged then
				local brightnessPage = brightnessSwitch.GetState()
				local color, colorIndex = CalculateColor(hitIndex, brightnessPage, opacitySwitch.GetState())

				cytanb.DebugLog('update currentColor: colorIndex = ', colorIndex, ' ,  color = ', color)
				lastHitIndex = hitIndex

				vci.assets.SetMaterialColorFromName(CurrentColorMaterialName, color)
				vci.assets.SetMaterialTextureOffsetFromName(PaletteMaterialName, Vector2.__new(0.0, 1.0 - PalettePageHeight * brightnessPage))

				UpdateStatus(color, colorIndex)
			end

			--
			firstUpdate = false
		end

		coroutine.yield(100)
	end
	return 0
end)

cytanb.OnMessage(QueryStatusMessageName, function (sender, name, parameterMap)
	if not vci.assets.IsMine then return end

	local color, colorIndex = CalculateColor(GetHitIndex(), brightnessSwitch.GetState(), opacitySwitch.GetState())
	EmitStatus(color, colorIndex)
end)

-- アイテムを設置したときの初期化処理
if vci.assets.IsMine then
	local color, colorIndex = CalculateColor(GetHitIndex(), brightnessSwitch.GetState(), opacitySwitch.GetState())
	UpdateStatus(color, colorIndex)
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
	if advancedSwitch.IsPickerEntered() then
		cytanb.DebugLog('onUse: ', advancedSwitch.name)
		advancedSwitch.DoInput()
	elseif pickerSwitch.IsPickerEntered() then
		cytanb.DebugLog('onUse: ', pickerSwitch.name)
		pickerSwitch.DoInput()
	end
end

--- 操作権があるユーザーで、アイテムに Collider (Is Trigger = ON) が衝突したときに呼び出される。
function onTriggerEnter(item, hit)
	if IsPickerHit(hit) then
		local switch = switchMap[item]
		if switch then
			if PaletteBase.IsMine then
				switch.SetPickerEntered(true)
			end

			if switch == opacitySwitch or switch == brightnessSwitch then
				switch.DoInput()
			end
		elseif string.startsWith(item, ColorIndexPrefix) then
			local hitIndex = tonumber(string.sub(item, 1 + string.len(ColorIndexPrefix)), 10)
			cytanb.DebugLog('on trigger: hitIndex = ', hitIndex, ' hit = ', hit)
			if (hitIndex) then
				vci.state.Set(HitIndexStateName, hitIndex)
			end
		end
	end
end

function onTriggerExit(item, hit)
	local switch = switchMap[item]
	if switch then
		switchMap[item].SetPickerEntered(false)
	end
end
