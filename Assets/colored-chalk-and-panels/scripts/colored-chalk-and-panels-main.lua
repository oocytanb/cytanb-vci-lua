----------------------------------------------------------------
--  Copyright (c) 2019 oO (https://github.com/oocytanb)
--  MIT Licensed
----------------------------------------------------------------

cytanb=(function()math.randomseed(os.time())local a={LOG_LEVEL_FATAL=100,LOG_LEVEL_ERROR=200,LOG_LEVEL_WARN=300,LOG_LEVEL_INFO=400,LOG_LEVEL_DEBUG=500,LOG_LEVEL_TRACE=600,COLOR_HUE_SAMPLES=10,COLOR_SATURATION_SAMPLES=4,COLOR_BRIGHTNESS_SAMPLES=4,COLOR_MAP_SIZE=10*4*4,NEGATIVE_NUMBER_TAG='#__CYTANB_NEGATIVE_NUMBER',INSTANCE_ID_PARAMETER_NAME='__CYTANB_INSTANCE_ID'}local b='__CYTANB_INSTANCE_ID'local c=400;local d;local cytanb={InstanceId=function()if d==''then d=vci.state.Get(b)or''end;return d end,Vars=function(e,f,g,h)local i;if f then i=f~='__NOLF'else f='  'i=true end;if not g then g=''end;if not h then h={}end;local j=type(e)if j=='table'then h[e]=h[e]and h[e]+1 or 1;local k=i and g..f or''local l='('..tostring(e)..') {'local m=true;for n,o in pairs(e)do if m then m=false else l=l..(i and','or', ')end;if i then l=l..'\n'..k end;if type(o)=='table'and h[o]and h[o]>0 then l=l..n..' = ('..tostring(o)..')'else l=l..n..' = '..cytanb.Vars(o,f,k,h)end end;if not m and i then l=l..'\n'..g end;l=l..'}'h[e]=h[e]-1;if h[e]<=0 then h[e]=nil end;return l elseif j=='function'or j=="thread"or j=="userdata"then return'('..j..')'elseif j=='string'then return'('..j..') '..string.format('%q',e)else return'('..j..') '..tostring(e)end end,GetLogLevel=function()return c end,SetLogLevel=function(p)c=p end,Log=function(p,...)if p<=c then local q=table.pack(...)if q.n==1 then local e=q[1]if e~=nil then print(type(e)=='table'and cytanb.Vars(e)or tostring(e))else print('')end else local l=''for r=1,q.n do local e=q[r]if e~=nil then l=l..(type(e)=='table'and cytanb.Vars(e)or tostring(e))end end;print(l)end end end,FatalLog=function(...)cytanb.Log(a.LOG_LEVEL_FATAL,...)end,ErrorLog=function(...)cytanb.Log(a.LOG_LEVEL_ERROR,...)end,WarnLog=function(...)cytanb.Log(a.LOG_LEVEL_WARN,...)end,InfoLog=function(...)cytanb.Log(a.LOG_LEVEL_INFO,...)end,DebugLog=function(...)cytanb.Log(a.LOG_LEVEL_DEBUG,...)end,TraceLog=function(...)cytanb.Log(a.LOG_LEVEL_TRACE,...)end,ListToDictionary=function(s,t)local table={}local u=t==nil;for v,e in pairs(s)do table[e]=u and e or t end;return table end,RandomUUID=function()return{math.random(0,0xFFFFFFFF),bit32.bor(0x4000,bit32.band(math.random(0,0xFFFFFFFF),0xFFFF0FFF)),bit32.bor(0x80000000,bit32.band(math.random(0,0xFFFFFFFF),0x3FFFFFFF)),math.random(0,0xFFFFFFFF)}end,UUIDString=function(w)local x=w[2]or 0;local y=w[3]or 0;return string.format('%08x-%04x-%04x-%04x-%04x%08x',bit32.band(w[1]or 0,0xFFFFFFFF),bit32.band(bit32.rshift(x,16),0xFFFF),bit32.band(x,0xFFFF),bit32.band(bit32.rshift(y,16),0xFFFF),bit32.band(y,0xFFFF),bit32.band(w[4]or 0,0xFFFFFFFF))end,ColorFromARGB32=function(z)local A=type(z)=='number'and z or 0xFF000000;return Color.__new(bit32.band(bit32.rshift(A,16),0xFF)/0xFF,bit32.band(bit32.rshift(A,8),0xFF)/0xFF,bit32.band(A,0xFF)/0xFF,bit32.band(bit32.rshift(A,24),0xFF)/0xFF)end,ColorToARGB32=function(B)return bit32.bor(bit32.lshift(math.floor(255*B.a+0.5),24),bit32.lshift(math.floor(255*B.r+0.5),16),bit32.lshift(math.floor(255*B.g+0.5),8),math.floor(255*B.b+0.5))end,ColorFromIndex=function(C,D,E,F,G)local H=math.max(math.floor(D or a.COLOR_HUE_SAMPLES),1)local I=G and H or H-1;local J=math.max(math.floor(E or a.COLOR_SATURATION_SAMPLES),1)local K=math.max(math.floor(F or a.COLOR_BRIGHTNESS_SAMPLES),1)local L=math.max(math.min(math.floor(C or 0),H*J*K-1),0)local M=L%H;local N=math.floor(L/H)local O=N%J;local P=math.floor(N/J)if G or M~=I then local Q=M/I;local R=(J-O)/J;local e=(K-P)/K;return Color.HSVToRGB(Q,R,e)else local e=(K-P)/K*O/(J-1)return Color.HSVToRGB(0.0,0.0,e)end end,GetSubItemTransform=function(S)local T=S.GetPosition()local U=S.GetRotation()local V=S.GetLocalScale()return{positionX=T.x,positionY=T.y,positionZ=T.z,rotationX=U.x,rotationY=U.y,rotationZ=U.z,rotationW=U.w,scaleX=V.x,scaleY=V.y,scaleZ=V.z}end,TableToSerialiable=function(W)if type(W)~='table'then return W end;local X={}for v,e in pairs(W)do if type(e)=='number'and e<0 then X[v..a.NEGATIVE_NUMBER_TAG]=tostring(e)else X[v]=cytanb.TableToSerialiable(e)end end;return X end,TableFromSerialiable=function(X)if type(X)~='table'then return X end;local W={}for v,e in pairs(X)do if type(e)=='string'and string.endsWith(v,a.NEGATIVE_NUMBER_TAG)then W[string.sub(v,1,#v-#a.NEGATIVE_NUMBER_TAG)]=tonumber(e)else W[v]=cytanb.TableFromSerialiable(e)end end;return W end,EmitMessage=function(Y,Z)local table=Z and cytanb.TableToSerialiable(Z)or{}table[a.INSTANCE_ID_PARAMETER_NAME]=cytanb.InstanceId()vci.message.Emit(Y,json.serialize(table))end,OnMessage=function(Y,_)local a0=function(a1,a2,a3)local Z;if a3==''then Z={}else local a4,X=pcall(json.parse,a3)if not a4 or type(X)~='table'then cytanb.TraceLog('Invalid message format: ',a3)return end;Z=cytanb.TableFromSerialiable(X)end;_(a1,a2,Z)end;vci.message.On(Y,a0)return{Off=function()if a0 then a0=nil end end}end}setmetatable(cytanb,{__index=a})if vci.assets.IsMine then d=cytanb.UUIDString(cytanb.RandomUUID())vci.state.Set(b,d)else d=''end;return cytanb end)()

cytanb.SetLogLevel(cytanb.LOG_LEVEL_DEBUG)

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
			itemColorMap[name] = cytanb.ColorFromARGB32(colorList[ci])
			table.insert(itemNameList, name)
			ci = ci + 1
		end

		local panelMaterialTable = {}
		for i, v in ipairs(panelList) do
			local name = v .. PANEL_TAG
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
	return cytanb.ColorFromARGB32(vci.state.Get(COLOR_STATUS_PREFIX .. itemName))
end

local function setItemColor(itemName, color)
	vci.state.Set(COLOR_STATUS_PREFIX .. itemName, cytanb.ColorToARGB32(color))
end

local function linkPaletteProc()
	local itemPosition = vci.assets.GetSubItem(UNIMSG_RECEIVER_NAME).GetPosition()
	local candId = ''
	local candPosition = nil
	local candDistance = nil
	local candARGB32 = nil

	unlinkPalette()

	-- 新しいカラーパレットとリンクするために、問い合わせる
	cytanb.DebugLog('emitMessage: ', MESSAGE_NAME_QUERY_STATUS)
	cytanb.EmitMessage(MESSAGE_NAME_QUERY_STATUS, {version = MESSAGE_VERSION})

	local queryExpires = vci.me.Time + QUERY_PERIOD
	while true do
		local cont, parameterMap = coroutine.yield(100)
		if not cont then
			-- abort
			cytanb.DebugLog('linkPaletteProc aborted.')
			return -301
		end

		if parameterMap then
			-- パレットとの距離を調べる
			local instanceId = parameterMap[cytanb.INSTANCE_ID_PARAMETER_NAME]
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
		cytanb.DebugLog('linkPaletteCw stoped: ', code)
		linkPaletteCw = nil

		if instanceId and instanceId ~= '' and instanceId ~= getLinkedInstanceId() then
			-- 新しいパレットのインスタンスにリンクする
			print('linked to color-palette #', instanceId)
			vci.state.Set(LINKED_PALETTE_INSTANCE_ID_STATE_NAME, instanceId)
			setItemColor(UNIMSG_RECEIVER_NAME, cytanb.ColorFromARGB32(argb32))
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
	local color = cytanb.ColorFromARGB32(vci.studio.shared.Get(SHARED_NAME_ARGB32))
	cytanb.DebugLog('onUse: ', use, ' ,  shared color = ', color)

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
	cytanb.DebugLog('on collision enter: item = ', item, ' , hit = ', hit)

	local chalkMaterial = CHALK_MATERIAL_TABLE[item]
	local panelMaterial = PANEL_MATERIAL_TABLE[hit]
	if chalkMaterial and panelMaterial then
		-- チョークがパネルにヒットしたときは、チョークの色をパネルに設定する
		local chalkColor = getItemColor(item)

		-- まったく同色にすると、チョークと区別できないため、若干値を下げる。
		local d = 0.1
		local color = Color.__new(math.max(chalkColor.r - d, 0.0), math.max(chalkColor.g - d, 0.0), math.max(chalkColor.b - d, 0.0), chalkColor.a)
		cytanb.DebugLog('change panel[', hit, '] color to chalk[', item, ']: color = ', color)
		setItemColor(hit, color)
	end
end

cytanb.OnMessage(MESSAGE_NAME_ITEM_STATUS, function (sender, name, parameterMap)
	if not vci.assets.IsMine then return end

	local version = parameterMap['version']
	if not version or parameterMap['version'] < MESSAGE_MIN_VERSION then return end

	-- vci.message から色情報を取得する
	local color = cytanb.ColorFromARGB32(parameterMap['argb32'])
	cytanb.DebugLog('on item status: color = ', color)

	resumeLinkPalette(parameterMap)

	if isAutoChangeUnimsgReceiver() then
		local instanceId = parameterMap[cytanb.INSTANCE_ID_PARAMETER_NAME]
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
