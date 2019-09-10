-- cytanb | Copyright (c) 2019 oO (https://github.com/oocytanb) | MIT Licensed
---@type cytanb @See `cytanb_annotations.lua`
local cytanb=(function()math.randomseed(os.time()-os.clock()*10000)local b='__CYTANB_INSTANCE_ID'local c;local d;local e;local f=false;local g;local h;local a;local i=function(j,k)for l=1,4 do local m=j[l]-k[l]if m~=0 then return m end end;return 0 end;local n;n={__eq=function(j,k)return j[1]==k[1]and j[2]==k[2]and j[3]==k[3]and j[4]==k[4]end,__lt=function(j,k)return i(j,k)<0 end,__le=function(j,k)return i(j,k)<=0 end,__tostring=function(o)local p=o[2]or 0;local q=o[3]or 0;return string.format('%08x-%04x-%04x-%04x-%04x%08x',bit32.band(o[1]or 0,0xFFFFFFFF),bit32.band(bit32.rshift(p,16),0xFFFF),bit32.band(p,0xFFFF),bit32.band(bit32.rshift(q,16),0xFFFF),bit32.band(q,0xFFFF),bit32.band(o[4]or 0,0xFFFFFFFF))end,__concat=function(j,k)local r=getmetatable(j)local s=r==n or type(r)=='table'and r.__concat==n.__concat;local t=getmetatable(k)local u=t==n or type(t)=='table'and t.__concat==n.__concat;if not s and not u then error('attempt to concatenate illegal values')end;return(s and n.__tostring(j)or j)..(u and n.__tostring(k)or k)end}local v='__CYTANB_CONST_VARIABLES'local w=function(table,x)local y=getmetatable(table)if y then local z=rawget(y,v)if z then local A=rawget(z,x)if type(A)=='function'then return A(table,x)else return A end end end;return nil end;local B=function(table,x,C)local y=getmetatable(table)if y then local z=rawget(y,v)if z then if rawget(z,x)~=nil then error('Cannot assign to read only field "'..x..'"')end end end;rawset(table,x,C)end;local D=function(E)return string.gsub(string.gsub(E,a.EscapeSequenceTag,a.EscapeSequenceTag..a.EscapeSequenceTag),'/',a.SolidusTag)end;local F=function(E,G)local H=string.len(E)local I=string.len(a.EscapeSequenceTag)if I>H then return E end;local J=''local l=1;while l<H do local K,L=string.find(E,a.EscapeSequenceTag,l,true)if not K then if l==1 then J=E else J=J..string.sub(E,l)end;break end;if K>l then J=J..string.sub(E,l,K-1)end;local M=false;for N,O in ipairs(c)do local P,Q=string.find(E,O.pattern,K)if P then J=J..(G and G(O.tag)or O.replacement)l=Q+1;M=true;break end end;if not M then J=J..a.EscapeSequenceTag;l=L+1 end end;return J end;a={InstanceID=function()if h==''then h=vci.state.Get(b)or''end;return h end,SetConst=function(R,S,o)if type(R)~='table'then error('Cannot set const to non-table target')end;local T=getmetatable(R)local y=T or{}local U=rawget(y,v)if rawget(R,S)~=nil then error('Non-const field "'..S..'" already exists')end;if not U then U={}rawset(y,v,U)y.__index=w;y.__newindex=B end;rawset(U,S,o)if not T then setmetatable(R,y)end;return R end,SetConstEach=function(R,V)for W,C in pairs(V)do a.SetConst(R,W,C)end;return R end,Extend=function(R,X,Y,Z,_)if R==X or type(R)~='table'or type(X)~='table'then return R end;if Y then if not _ then _={}end;if _[X]then error('circular reference')end;_[X]=true end;for W,C in pairs(X)do if Y and type(C)=='table'then local a0=R[W]R[W]=a.Extend(type(a0)=='table'and a0 or{},C,Y,Z,_)else R[W]=C end end;if not Z then local a1=getmetatable(X)if type(a1)=='table'then if Y then local a2=getmetatable(R)setmetatable(R,a.Extend(type(a2)=='table'and a2 or{},a1,true))else setmetatable(R,a1)end end end;if Y then _[X]=nil end;return R end,Vars=function(C,a3,a4,_)local a5;if a3 then a5=a3~='__NOLF'else a3='  'a5=true end;if not a4 then a4=''end;if not _ then _={}end;local a6=type(C)if a6=='table'then _[C]=_[C]and _[C]+1 or 1;local a7=a5 and a4 ..a3 or''local E='('..tostring(C)..') {'local a8=true;for x,a9 in pairs(C)do if a8 then a8=false else E=E..(a5 and','or', ')end;if a5 then E=E..'\n'..a7 end;if type(a9)=='table'and _[a9]and _[a9]>0 then E=E..x..' = ('..tostring(a9)..')'else E=E..x..' = '..a.Vars(a9,a3,a7,_)end end;if not a8 and a5 then E=E..'\n'..a4 end;E=E..'}'_[C]=_[C]-1;if _[C]<=0 then _[C]=nil end;return E elseif a6=='function'or a6=='thread'or a6=='userdata'then return'('..a6 ..')'elseif a6=='string'then return'('..a6 ..') '..string.format('%q',C)else return'('..a6 ..') '..tostring(C)end end,GetLogLevel=function()return e end,SetLogLevel=function(aa)e=aa end,IsOutputLogLevelEnabled=function()return f end,SetOutputLogLevelEnabled=function(ab)f=not not ab end,Log=function(aa,...)if aa<=e then local ac=f and(g[aa]or'LOG LEVEL '..tostring(aa))..' | 'or''local ad=table.pack(...)if ad.n==1 then local C=ad[1]if C~=nil then local E=type(C)=='table'and a.Vars(C)or tostring(C)print(f and ac..E or E)else print(ac)end else local E=ac;for l=1,ad.n do local C=ad[l]if C~=nil then E=E..(type(C)=='table'and a.Vars(C)or tostring(C))end end;print(E)end end end,LogFatal=function(...)a.Log(a.LogLevelFatal,...)end,LogError=function(...)a.Log(a.LogLevelError,...)end,LogWarn=function(...)a.Log(a.LogLevelWarn,...)end,LogInfo=function(...)a.Log(a.LogLevelInfo,...)end,LogDebug=function(...)a.Log(a.LogLevelDebug,...)end,LogTrace=function(...)a.Log(a.LogLevelTrace,...)end,FatalLog=function(...)a.LogFatal(...)end,ErrorLog=function(...)a.LogError(...)end,WarnLog=function(...)a.LogWarn(...)end,InfoLog=function(...)a.LogInfo(...)end,DebugLog=function(...)a.LogDebug(...)end,TraceLog=function(...)a.LogTrace(...)end,ListToMap=function(ae,af)local table={}local ag=af==nil;for W,C in pairs(ae)do table[C]=ag and C or af end;return table end,Round=function(ah,ai)if ai then local aj=10^ai;return math.floor(ah*aj+0.5)/aj else return math.floor(ah+0.5)end end,Clamp=function(o,ak,al)return math.max(ak,math.min(o,al))end,Lerp=function(am,an,a6)if a6<=0.0 then return am elseif a6>=1.0 then return an else return am+(an-am)*a6 end end,LerpUnclamped=function(am,an,a6)if a6==0.0 then return am elseif a6==1.0 then return an else return am+(an-am)*a6 end end,PingPong=function(a6,ao)if ao==0 then return 0 end;local ap=math.floor(a6/ao)local aq=a6-ap*ao;if ap<0 then if(ap+1)%2==0 then return ao-aq else return aq end else if ap%2==0 then return aq else return ao-aq end end end,VectorApproximatelyEquals=function(ar,as)return(ar-as).sqrMagnitude<1E-10 end,QuaternionApproximatelyEquals=function(ar,as)local at=Quaternion.Dot(ar,as)return at<1.0+1E-06 and at>1.0-1E-06 end,QuaternionToAngleAxis=function(au)local ap=au.normalized;local av=math.acos(ap.w)local aw=math.sin(av)local ax=math.deg(av*2.0)local ay;if math.abs(aw)<=Quaternion.kEpsilon then ay=Vector3.right else local az=1.0/aw;ay=Vector3.__new(ap.x*az,ap.y*az,ap.z*az)end;return ax,ay end,ApplyQuaternionToVector3=function(au,aA)local aB=au.w*aA.x+au.y*aA.z-au.z*aA.y;local aC=au.w*aA.y-au.x*aA.z+au.z*aA.x;local aD=au.w*aA.z+au.x*aA.y-au.y*aA.x;local aE=-au.x*aA.x-au.y*aA.y-au.z*aA.z;return Vector3.__new(aE*-au.x+aB*au.w+aC*-au.z-aD*-au.y,aE*-au.y-aB*-au.z+aC*au.w+aD*-au.x,aE*-au.z+aB*-au.y-aC*-au.x+aD*au.w)end,RotateAround=function(aF,aG,aH,aI)return aH+a.ApplyQuaternionToVector3(aI,aF-aH),aI*aG end,Random32=function()return bit32.band(math.random(-2147483648,2147483646),0xFFFFFFFF)end,RandomUUID=function()return a.UUIDFromNumbers(a.Random32(),bit32.bor(0x4000,bit32.band(a.Random32(),0xFFFF0FFF)),bit32.bor(0x80000000,bit32.band(a.Random32(),0x3FFFFFFF)),a.Random32())end,UUIDString=function(aJ)return n.__tostring(aJ)end,UUIDFromNumbers=function(...)local aK=...local a6=type(aK)local aL,aM,aN,aO;if a6=='table'then aL=aK[1]aM=aK[2]aN=aK[3]aO=aK[4]else aL,aM,aN,aO=...end;local aJ={bit32.band(aL or 0,0xFFFFFFFF),bit32.band(aM or 0,0xFFFFFFFF),bit32.band(aN or 0,0xFFFFFFFF),bit32.band(aO or 0,0xFFFFFFFF)}setmetatable(aJ,n)return aJ end,UUIDFromString=function(E)local H=string.len(E)if H~=32 and H~=36 then return nil end;local aP='[0-9a-f-A-F]+'local aQ='^('..aP..')$'local aR='^-('..aP..')$'local aS,aT,aU,aV;if H==32 then local aJ=a.UUIDFromNumbers(0,0,0,0)local aW=1;for l,aX in ipairs({8,16,24,32})do aS,aT,aU=string.find(string.sub(E,aW,aX),aQ)if not aS then return nil end;aJ[l]=tonumber(aU,16)aW=aX+1 end;return aJ else aS,aT,aU=string.find(string.sub(E,1,8),aQ)if not aS then return nil end;local aL=tonumber(aU,16)aS,aT,aU=string.find(string.sub(E,9,13),aR)if not aS then return nil end;aS,aT,aV=string.find(string.sub(E,14,18),aR)if not aS then return nil end;local aM=tonumber(aU..aV,16)aS,aT,aU=string.find(string.sub(E,19,23),aR)if not aS then return nil end;aS,aT,aV=string.find(string.sub(E,24,28),aR)if not aS then return nil end;local aN=tonumber(aU..aV,16)aS,aT,aU=string.find(string.sub(E,29,36),aQ)if not aS then return nil end;local aO=tonumber(aU,16)return a.UUIDFromNumbers(aL,aM,aN,aO)end end,ParseUUID=function(E)return a.UUIDFromString(E)end,CreateCircularQueue=function(aY)if type(aY)~='number'or aY<1 then error('Invalid argument: capacity = '..tostring(aY))end;local self;local aZ=math.floor(aY)local J={}local a_=0;local b0=0;local b1=0;self={Size=function()return b1 end,Clear=function()a_=0;b0=0;b1=0 end,IsEmpty=function()return b1==0 end,Offer=function(b2)J[a_+1]=b2;a_=(a_+1)%aZ;if b1<aZ then b1=b1+1 else b0=(b0+1)%aZ end;return true end,OfferFirst=function(b2)b0=(aZ+b0-1)%aZ;J[b0+1]=b2;if b1<aZ then b1=b1+1 else a_=(aZ+a_-1)%aZ end;return true end,Poll=function()if b1==0 then return nil else local b2=J[b0+1]b0=(b0+1)%aZ;b1=b1-1;return b2 end end,PollLast=function()if b1==0 then return nil else a_=(aZ+a_-1)%aZ;local b2=J[a_+1]b1=b1-1;return b2 end end,Peek=function()if b1==0 then return nil else return J[b0+1]end end,PeekLast=function()if b1==0 then return nil else return J[(aZ+a_-1)%aZ+1]end end,Get=function(b3)if b3<1 or b3>b1 then a.LogError('CreateCircularQueue.Get: index is outside the range: '..b3)return nil end;return J[(b0+b3-1)%aZ+1]end,IsFull=function()return b1>=aZ end,MaxSize=function()return aZ end}return self end,
ColorFromARGB32=function(b4)local b5=type(b4)=='number'and b4 or 0xFF000000;return Color.__new(bit32.band(bit32.rshift(b5,16),0xFF)/0xFF,bit32.band(bit32.rshift(b5,8),0xFF)/0xFF,bit32.band(b5,0xFF)/0xFF,bit32.band(bit32.rshift(b5,24),0xFF)/0xFF)end,ColorToARGB32=function(b6)return bit32.bor(bit32.lshift(bit32.band(a.Round(0xFF*b6.a),0xFF),24),bit32.lshift(bit32.band(a.Round(0xFF*b6.r),0xFF),16),bit32.lshift(bit32.band(a.Round(0xFF*b6.g),0xFF),8),bit32.band(a.Round(0xFF*b6.b),0xFF))end,ColorFromIndex=function(b7,b8,b9,ba,bb)local bc=math.max(math.floor(b8 or a.ColorHueSamples),1)local bd=bb and bc or bc-1;local be=math.max(math.floor(b9 or a.ColorSaturationSamples),1)local bf=math.max(math.floor(ba or a.ColorBrightnessSamples),1)local b3=a.Clamp(math.floor(b7 or 0),0,bc*be*bf-1)local bg=b3%bc;local bh=math.floor(b3/bc)local az=bh%be;local bi=math.floor(bh/be)if bb or bg~=bd then local A=bg/bd;local bj=(be-az)/be;local C=(bf-bi)/bf;return Color.HSVToRGB(A,bj,C)else local C=(bf-bi)/bf*az/(be-1)return Color.HSVToRGB(0.0,0.0,C)end end,DetectClicks=function(bk,bl,bm)local bn=bk or 0;local bo=bm or TimeSpan.FromMilliseconds(500)local bp=vci.me.Time;local bq=bl and bp>bl+bo and 1 or bn+1;return bq,bp end,GetEffekseerEmitterMap=function(S)local br=vci.assets.GetEffekseerEmitters(S)if not br then return nil end;local bs={}for l,bt in pairs(br)do bs[bt.EffectName]=bt end;return bs end,GetSubItemTransform=function(bu)local bv=bu.GetPosition()local aI=bu.GetRotation()local bw=bu.GetLocalScale()return{positionX=bv.x,positionY=bv.y,positionZ=bv.z,rotationX=aI.x,rotationY=aI.y,rotationZ=aI.z,rotationW=aI.w,scaleX=bw.x,scaleY=bw.y,scaleZ=bw.z}end,TableToSerializable=function(bx,_)if type(bx)~='table'then return bx end;if not _ then _={}end;if _[bx]then error('circular reference')end;_[bx]=true;local by={}for W,C in pairs(bx)do local bz=type(W)local bA;if bz=='string'then bA=D(W)elseif bz=='number'then bA=tostring(W)..a.ArrayNumberTag else bA=W end;local bB=type(C)if bB=='string'then by[bA]=D(C)elseif bB=='number'and C<0 then by[tostring(bA)..a.NegativeNumberTag]=tostring(C)else by[bA]=a.TableToSerializable(C,_)end end;_[bx]=nil;return by end,TableFromSerializable=function(by)if type(by)~='table'then return by end;local bx={}for W,C in pairs(by)do local bA;local bC=false;if type(W)=='string'then local bD=false;bA=F(W,function(bE)if bE==a.NegativeNumberTag then bC=true elseif bE==a.ArrayNumberTag then bD=true end;return nil end)if bD then bA=tonumber(bA)or bA end else bA=W;bC=false end;if bC and type(C)=='string'then bx[bA]=tonumber(C)elseif type(C)=='string'then bx[bA]=F(C,function(bE)return d[bE]end)else bx[bA]=a.TableFromSerializable(C)end end;return bx end,TableToSerialiable=function(bx,_)return a.TableToSerializable(bx,_)end,TableFromSerialiable=function(by)return a.TableFromSerializable(by)end,EmitMessage=function(S,bF)local table=bF and a.TableToSerializable(bF)or{}table[a.InstanceIDParameterName]=a.InstanceID()vci.message.Emit(S,json.serialize(table))end,OnMessage=function(S,bG)local bH=function(bI,bJ,bK)local bL=nil;if bI.type~='comment'and type(bK)=='string'then local bM,by=pcall(json.parse,bK)if bM and type(by)=='table'then bL=a.TableFromSerializable(by)end end;local bF=bL and bL or{[a.MessageValueParameterName]=bK}bG(bI,bJ,bF)end;vci.message.On(S,bH)return{Off=function()if bH then bH=nil end end}end,OnInstanceMessage=function(S,bG)local bH=function(bI,bJ,bF)local bN=a.InstanceID()if bN~=''and bN==bF[a.InstanceIDParameterName]then bG(bI,bJ,bF)end end;return a.OnMessage(S,bH)end}a.SetConstEach(a,{LogLevelOff=0,LogLevelFatal=100,LogLevelError=200,LogLevelWarn=300,LogLevelInfo=400,LogLevelDebug=500,LogLevelTrace=600,LogLevelAll=0x7FFFFFFF,ColorHueSamples=10,ColorSaturationSamples=4,ColorBrightnessSamples=5,EscapeSequenceTag='#__CYTANB',SolidusTag='#__CYTANB_SOLIDUS',NegativeNumberTag='#__CYTANB_NEGATIVE_NUMBER',ArrayNumberTag='#__CYTANB_ARRAY_NUMBER',InstanceIDParameterName='__CYTANB_INSTANCE_ID',MessageValueParameterName='__CYTANB_MESSAGE_VALUE'})a.SetConstEach(a,{ColorMapSize=a.ColorHueSamples*a.ColorSaturationSamples*a.ColorBrightnessSamples,FatalLogLevel=a.LogLevelFatal,ErrorLogLevel=a.LogLevelError,WarnLogLevel=a.LogLevelWarn,InfoLogLevel=a.LogLevelInfo,DebugLogLevel=a.LogLevelDebug,TraceLogLevel=a.LogLevelTrace})c={{tag=a.NegativeNumberTag,pattern='^'..a.NegativeNumberTag,replacement=''},{tag=a.ArrayNumberTag,pattern='^'..a.ArrayNumberTag,replacement=''},{tag=a.SolidusTag,pattern='^'..a.SolidusTag,replacement='/'},{tag=a.EscapeSequenceTag,pattern='^'..a.EscapeSequenceTag..a.EscapeSequenceTag,replacement=a.EscapeSequenceTag}}d=a.ListToMap({a.NegativeNumberTag,a.ArrayNumberTag})e=a.LogLevelInfo;g={[a.LogLevelFatal]='FATAL',[a.LogLevelError]='ERROR',[a.LogLevelWarn]='WARN',[a.LogLevelInfo]='INFO',[a.LogLevelDebug]='DEBUG',[a.LogLevelTrace]='TRACE'}package.loaded['cytanb']=a;h=vci.state.Get(b)or''if h==''and vci.assets.IsMine then h=tostring(a.RandomUUID())vci.state.Set(b,h)end;return a end)()
