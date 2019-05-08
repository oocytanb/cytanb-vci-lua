----------------------------------------------------------------
--  Copyright (c) 2019 oO (https://github.com/oocytanb)
--  MIT Licensed
----------------------------------------------------------------

cytanb=(function()local a={FatalLogLevel=100,ErrorLogLevel=200,WarnLogLevel=300,InfoLogLevel=400,DebugLogLevel=500,TraceLogLevel=600,ColorHueSamples=10,ColorSaturationSamples=4,ColorBrightnessSamples=5,ColorMapSize=10*4*5,NegativeNumberTag='#__CYTANB_NEGATIVE_NUMBER',InstanceIDParameterName='__CYTANB_INSTANCE_ID'}local b='__CYTANB_INSTANCE_ID'local c=400;local d;local cytanb;cytanb={InstanceID=function()if d==''then d=vci.state.Get(b)or''end;return d end,Vars=function(e,f,g,h)local i;if f then i=f~='__NOLF'else f='  'i=true end;if not g then g=''end;if not h then h={}end;local j=type(e)if j=='table'then h[e]=h[e]and h[e]+1 or 1;local k=i and g..f or''local l='('..tostring(e)..') {'local m=true;for n,o in pairs(e)do if m then m=false else l=l..(i and','or', ')end;if i then l=l..'\n'..k end;if type(o)=='table'and h[o]and h[o]>0 then l=l..n..' = ('..tostring(o)..')'else l=l..n..' = '..cytanb.Vars(o,f,k,h)end end;if not m and i then l=l..'\n'..g end;l=l..'}'h[e]=h[e]-1;if h[e]<=0 then h[e]=nil end;return l elseif j=='function'or j=="thread"or j=="userdata"then return'('..j..')'elseif j=='string'then return'('..j..') '..string.format('%q',e)else return'('..j..') '..tostring(e)end end,GetLogLevel=function()return c end,SetLogLevel=function(p)c=p end,Log=function(p,...)if p<=c then local q=table.pack(...)if q.n==1 then local e=q[1]if e~=nil then print(type(e)=='table'and cytanb.Vars(e)or tostring(e))else print('')end else local l=''for r=1,q.n do local e=q[r]if e~=nil then l=l..(type(e)=='table'and cytanb.Vars(e)or tostring(e))end end;print(l)end end end,FatalLog=function(...)cytanb.Log(a.FatalLogLevel,...)end,ErrorLog=function(...)cytanb.Log(a.ErrorLogLevel,...)end,WarnLog=function(...)cytanb.Log(a.WarnLogLevel,...)end,InfoLog=function(...)cytanb.Log(a.InfoLogLevel,...)end,DebugLog=function(...)cytanb.Log(a.DebugLogLevel,...)end,TraceLog=function(...)cytanb.Log(a.TraceLogLevel,...)end,ListToMap=function(s,t)local table={}local u=t==nil;for v,e in pairs(s)do table[e]=u and e or t end;return table end,Random32=function()return math.random(-2147483648,2147483646)end,RandomUUID=function()return{cytanb.Random32(),bit32.bor(0x4000,bit32.band(cytanb.Random32(),0xFFFF0FFF)),bit32.bor(0x80000000,bit32.band(cytanb.Random32(),0x3FFFFFFF)),cytanb.Random32()}end,UUIDString=function(w)local x=w[2]or 0;local y=w[3]or 0;return string.format('%08x-%04x-%04x-%04x-%04x%08x',bit32.band(w[1]or 0,0xFFFFFFFF),bit32.band(bit32.rshift(x,16),0xFFFF),bit32.band(x,0xFFFF),bit32.band(bit32.rshift(y,16),0xFFFF),bit32.band(y,0xFFFF),bit32.band(w[4]or 0,0xFFFFFFFF))end,ColorFromARGB32=function(z)local A=type(z)=='number'and z or 0xFF000000;return Color.__new(bit32.band(bit32.rshift(A,16),0xFF)/0xFF,bit32.band(bit32.rshift(A,8),0xFF)/0xFF,bit32.band(A,0xFF)/0xFF,bit32.band(bit32.rshift(A,24),0xFF)/0xFF)end,ColorToARGB32=function(B)return bit32.bor(bit32.lshift(math.floor(255*B.a+0.5),24),bit32.lshift(math.floor(255*B.r+0.5),16),bit32.lshift(math.floor(255*B.g+0.5),8),math.floor(255*B.b+0.5))end,ColorFromIndex=function(C,D,E,F,G)local H=math.max(math.floor(D or a.ColorHueSamples),1)local I=G and H or H-1;local J=math.max(math.floor(E or a.ColorSaturationSamples),1)local K=math.max(math.floor(F or a.ColorBrightnessSamples),1)local L=math.max(math.min(math.floor(C or 0),H*J*K-1),0)local M=L%H;local N=math.floor(L/H)local O=N%J;local P=math.floor(N/J)if G or M~=I then local Q=M/I;local R=(J-O)/J;local e=(K-P)/K;return Color.HSVToRGB(Q,R,e)else local e=(K-P)/K*O/(J-1)return Color.HSVToRGB(0.0,0.0,e)end end,GetSubItemTransform=function(S)local T=S.GetPosition()local U=S.GetRotation()local V=S.GetLocalScale()return{positionX=T.x,positionY=T.y,positionZ=T.z,rotationX=U.x,rotationY=U.y,rotationZ=U.z,rotationW=U.w,scaleX=V.x,scaleY=V.y,scaleZ=V.z}end,TableToSerialiable=function(W,h)if type(W)~='table'then return W end;if not h then h={}end;if h[W]then error('circular reference')end;h[W]=true;local X={}for v,e in pairs(W)do if type(e)=='number'and e<0 then X[v..a.NegativeNumberTag]=tostring(e)else X[v]=cytanb.TableToSerialiable(e,h)end end;h[W]=nil;return X end,TableFromSerialiable=function(X)if type(X)~='table'then return X end;local W={}for v,e in pairs(X)do if type(e)=='string'and string.endsWith(v,a.NegativeNumberTag)then W[string.sub(v,1,#v-#a.NegativeNumberTag)]=tonumber(e)else W[v]=cytanb.TableFromSerialiable(e)end end;return W end,EmitMessage=function(Y,Z)local table=Z and cytanb.TableToSerialiable(Z)or{}table[a.InstanceIDParameterName]=cytanb.InstanceID()vci.message.Emit(Y,json.serialize(table))end,OnMessage=function(Y,_)local a0=function(a1,a2,a3)local Z;if a3==''then Z={}else local a4,X=pcall(json.parse,a3)if not a4 or type(X)~='table'then cytanb.TraceLog('Invalid message format: ',a3)return end;Z=cytanb.TableFromSerialiable(X)end;_(a1,a2,Z)end;vci.message.On(Y,a0)return{Off=function()if a0 then a0=nil end end}end}setmetatable(cytanb,{__index=a})if vci.assets.IsMine then d=cytanb.UUIDString(cytanb.RandomUUID())vci.state.Set(b,d)else d=''end;return cytanb end)()

cytanb.SetLogLevel(cytanb.DebugLogLevel)

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

local PanelTag = '#panel'

local ColorStatusPrefix = 'color.'

local AutoChangeUnimsgReceiverStateName = 'autoChangeUnimsgReceiver'
local AutoChangeAnymsgReceiverStateName = 'autoChangeAnymsgReceiver'
local LinkedPaletteInstanceIDState = 'linkedColorPaletteInstanceID'

local ItemNameList, AllMaterialTable, ChalkMaterialTable, PanelMaterialTable, DefaultItemColorMap = (
	function (chalkList, panelList, colorList)
		local ci = 1
		local itemNameList = {}
		local allMaterialTable = {}
		local itemColorMap = {}

		local chalkMaterialTable = {}
		for i, v in ipairs(chalkList) do
			local name = v .. ColorPickerTag
			chalkMaterialTable[name] = v .. '-mat'
			allMaterialTable[name] = chalkMaterialTable[name]
			itemColorMap[name] = cytanb.ColorFromARGB32(colorList[ci])
			table.insert(itemNameList, name)
			ci = ci + 1
		end

		local panelMaterialTable = {}
		for i, v in ipairs(panelList) do
			local name = v .. PanelTag
			panelMaterialTable[name] = v .. '-panel-mat'
			allMaterialTable[name] = panelMaterialTable[name]
			itemColorMap[name] = cytanb.ColorFromARGB32(colorList[ci])
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

local UnimsgReceiverName = ItemNameList[5]
local AnymsgReceiverName = ItemNameList[6]

local UpdatePeriod = TimeSpan.FromMilliseconds(100)
local QueryPeriod = TimeSpan.FromSeconds(2)

local linkPaletteCw = nil

local function GetLinkedInstanceID()
	return vci.state.Get(LinkedPaletteInstanceIDState) or ''
end

-- 現在のカラーパレットとのリンクを解除する
local function UnlinkPalette()
	vci.state.Set(LinkedPaletteInstanceIDState, '')
end

local function IsAutoChangeUnimsgReceiver()
	local b = vci.state.Get(AutoChangeUnimsgReceiverStateName)
	if b == nil then
		return false
	else
		return b
	end
end

local function IsAutoChangeAnymsgReceiver()
	local b = vci.state.Get(AutoChangeAnymsgReceiverStateName)
	if b == nil then
		return true
	else
		return b
	end
end

local function GetItemColor(itemName)
	return cytanb.ColorFromARGB32(vci.state.Get(ColorStatusPrefix .. itemName))
end

local function SetItemColor(itemName, color)
	vci.state.Set(ColorStatusPrefix .. itemName, cytanb.ColorToARGB32(color))
end

local function LinkPaletteProc()
	local itemPosition = vci.assets.GetSubItem(UnimsgReceiverName).GetPosition()
	local candId = ''
	local candPosition = nil
	local candDistance = nil
	local candARGB32 = nil

	UnlinkPalette()

	-- 新しいカラーパレットとリンクするために、問い合わせる
	cytanb.DebugLog('emitMessage: ', QueryStatusMessageName)
	cytanb.EmitMessage(QueryStatusMessageName, {version = MessageVersion})

	local queryExpires = vci.me.Time + QueryPeriod
	while true do
		local cont, parameterMap = coroutine.yield(100)
		if not cont then
			-- abort
			cytanb.DebugLog('LinkPaletteProc aborted.')
			return -301
		end

		if parameterMap then
			-- パレットとの距離を調べる
			local instanceID = parameterMap[cytanb.InstanceIDParameterName]
			local x = parameterMap['positionX']
			local y = parameterMap['positionY']
			local z = parameterMap['positionZ']
			if instanceID and instanceID ~= '' and x and y and z then
				local position = Vector3.__new(x, y, z)
				local distance = Vector3.Distance(position, itemPosition)
				if not candPosition or  distance < candDistance then
					-- より近い距離のパレットを候補にする
					candId = instanceID
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

local function ResumeLinkPalette(parameterMap)
	if not linkPaletteCw then return end

	local code, instanceID, argb32 = linkPaletteCw(true, parameterMap)
	if code <= 0 then
		-- スレッド終了
		cytanb.DebugLog('linkPaletteCw stoped: ', code)
		linkPaletteCw = nil

		if instanceID and instanceID ~= '' and instanceID ~= GetLinkedInstanceID() then
			-- 新しいパレットのインスタンスにリンクする
			print('linked to color-palette #', instanceID)
			vci.state.Set(LinkedPaletteInstanceIDState, instanceID)
			SetItemColor(UnimsgReceiverName, cytanb.ColorFromARGB32(argb32))
		end
	end
end

local updateStateCw = coroutine.wrap(function ()
	local lastUpdateTime = vci.me.Time
	local lastItemColorMap = {}
	local lastAutoChangeUnimsg = IsAutoChangeUnimsgReceiver()

	while true do
		local time = vci.me.Time
		if time >= lastUpdateTime + UpdatePeriod then
			lastUpdateTime = time

			for itemName, materialName in pairs(AllMaterialTable) do
				local color = GetItemColor(itemName)
				if color ~= lastItemColorMap[itemName] then
					lastItemColorMap[itemName] = color
					vci.assets.SetMaterialColorFromName(materialName, color)
				end
			end

			if vci.assets.IsMine then
				local autoChangeUnimsg = IsAutoChangeUnimsgReceiver()
				if autoChangeUnimsg ~= lastAutoChangeUnimsg then
					lastAutoChangeUnimsg = autoChangeUnimsg

					if autoChangeUnimsg then
						if linkPaletteCw then
							-- abort previous thread
							linkPaletteCw(false)
						end

						linkPaletteCw = coroutine.wrap(LinkPaletteProc)
					else
						UnlinkPalette()
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
	for k, v in pairs(DefaultItemColorMap) do
		SetItemColor(k, v)
	end
end

-- 全ユーザーで、毎フレーム呼び出される。
function updateAll()
	updateStateCw()

	if vci.assets.IsMine then
		ResumeLinkPalette()
	end
end

-- グリップしてアイテムを使用すると呼び出される。
function onUse(use)
	-- 共有変数から色情報を取得する
	local color = cytanb.ColorFromARGB32(vci.studio.shared.Get(ARGB32SharedName))
	cytanb.DebugLog('onUse: ', use, ' ,  shared color = ', color)

	local chalkMaterial = ChalkMaterialTable[use]
	if chalkMaterial then
		SetItemColor(use, color)
	end

	local panelMaterial = PanelMaterialTable[use]
	if panelMaterial then
		SetItemColor(use, color)

		if use == UnimsgReceiverName then
			-- 自動でパレットの選択色に変更するかを切り替える
			vci.state.Set(AutoChangeUnimsgReceiverStateName, not IsAutoChangeUnimsgReceiver())
		elseif use == AnymsgReceiverName then
			-- 自動でパレットの選択色に変更するかを切り替える
			vci.state.Set(AutoChangeAnymsgReceiverStateName, not IsAutoChangeAnymsgReceiver())
		end
	end
end

--- 操作権があるユーザーで、アイテムに Collider (Is Trigger = OFF) が衝突したときに呼び出される。
function onCollisionEnter(item, hit)
	cytanb.DebugLog('on collision enter: item = ', item, ' , hit = ', hit)

	local chalkMaterial = ChalkMaterialTable[item]
	local panelMaterial = PanelMaterialTable[hit]
	if chalkMaterial and panelMaterial then
		-- チョークがパネルにヒットしたときは、チョークの色をパネルに設定する
		local chalkColor = GetItemColor(item)

		-- まったく同色にすると、チョークと区別できないため、若干値を下げる。
		local d = 0.1
		local color = Color.__new(math.max(chalkColor.r - d, 0.0), math.max(chalkColor.g - d, 0.0), math.max(chalkColor.b - d, 0.0), chalkColor.a)
		cytanb.DebugLog('change panel[', hit, '] color to chalk[', item, ']: color = ', color)
		SetItemColor(hit, color)
	end
end

cytanb.OnMessage(ItemStatusMessageName, function (sender, name, parameterMap)
	if not vci.assets.IsMine then return end

	local version = parameterMap['version']
	if not version or parameterMap['version'] < MinMessageVersion then return end

	-- vci.message から色情報を取得する
	local color = cytanb.ColorFromARGB32(parameterMap['argb32'])
	cytanb.DebugLog('on item status: color = ', color)

	ResumeLinkPalette(parameterMap)

	if IsAutoChangeUnimsgReceiver() then
		local instanceID = parameterMap[cytanb.InstanceIDParameterName]
		local linkedInstanceID = GetLinkedInstanceID()

		if linkedInstanceID ~= '' and linkedInstanceID == instanceID then
			-- リンクされたカラーパレットの色情報の場合のみ、パネルの色を変更する
			print('set unimsg receiver color')
			SetItemColor(UnimsgReceiverName, color)
		end
	end

	if IsAutoChangeAnymsgReceiver() then
		-- どのカラーパレットの色情報であっても、パネルの色を変更する
		print('set anymsg receiver color')
		SetItemColor(AnymsgReceiverName, color)
	end
end)
