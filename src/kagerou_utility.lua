----------------------------------------------------------------
--  Copyright (c) 2019 Kagerou (https://twitter.com/shiromacKagerou)
--  MIT Licensed
----------------------------------------------------------------

package.path=package.path..';./?.lua'
require("kagerou_foundation")

---------------------------------------
KFList = _defineClass()
KFList_n = _defineClass()
KFList_n.prev = nil
KFList_n.next = nil
KFList_n.content = nil
KFList.last = nil
KFList.first = nil
KFList.size = 0;
function KFList:push_back(content)
    local ins = KFList_n:new()
    ins._.content = content
    if (not self.first) then
        self._.first = ins
    else
        self.last._.next = ins
        ins._.prev = _weak(self.last)
    end
    self._.last = ins
    self._.size = self.size +1;
end
function KFList:erase(KFList_n)
    if (self.first == KFList_n) then
        self._.first = KFList_n.next;
    else
        KFList_n.prev()._.next = KFList_n.next
    end
    if (self.last == KFList_n) then
        if KFList_n.prev then
            self._.last = KFList_n.prev()
        else
            self._.last = nil
        end
    else
        KFList_n.next._.prev = KFList_n.prev
    end
    KFList_n:delete()
    self._.size = self.size -1;
end
function KFList:delete()
    local KFList_n = self.first
    while KFList_n ~= nil do
        local list_n_next = KFList_n.next
        KFList_n:delete()
        KFList_n = list_n_next
    end
end
function KFList:EveryDo(func)
    local KFList_n = self.first
    while KFList_n ~= nil do
        local list_n_next = KFList_n.next
        func(KFList_n.content)
        KFList_n = list_n_next
    end
end
function KFList_n:delete(content)
    if type(self.content) == "table" then self.content:delete() end
end
_makeClassStatic(KFList)
_makeClassStatic(KFList_n)
---------------------------------------
KFEventSender = _defineClass()
function KFEventSender:new(eventName)
    local ins = self:_rawnew()
    ins._.eventName = eventName
    ins._.observers = {}
    return ins
end
function KFEventSender:register(obj)
    self.observers[tostring(obj)] = obj
end
function KFEventSender:registerWithName(name, obj)
    self.observers[name] = obj
end
function KFEventSender:unregister(obj)
    self.observers[tostring(obj)] = nil
end
function KFEventSender:unregisterWithName(name)
    self.observers[name] = nil
end
function KFEventSender:send(...)
    for k,v in pairs(self.observers) do
        v[self.eventName](v,...)
    end
end
_makeClassStatic(KFEventSender)
---------------------------------------
KFObjectPool = _defineClass()
function KFObjectPool:new()
    local ins = self:_rawnew()
    ins._.observers = {}
    return ins
end
function KFObjectPool:registerWithName(name, obj)
    self.observers[name] = obj
end
function KFObjectPool:unregisterWithName(name)
    self.observers[name] = nil
end
function KFObjectPool:callMethod(name, methodName, ...)
    local obj = self.observers[name]
    return obj and obj[methodName](obj, ...)
end
_makeClassStatic(KFObjectPool)