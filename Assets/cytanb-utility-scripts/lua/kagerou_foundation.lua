----------------------------------------------------------------
--  Copyright (c) 2019 Kagerou (https://twitter.com/shiromacKagerou)
--  MIT Licensed
----------------------------------------------------------------

---------------------------------------
--- class template
function _defineClass(...) -- @param protocol
    local cls = {}
    local protocols = {...}
    for _, protocol in pairs(protocols) do
        _tableCopy(protocol, cls)
        local meta = _tableCopy(getmetatable(protocol) or {},{})
        meta.__newindex = nil
        _addmetatable(cls, meta)
    end

    cls._rawnew =
        function(cls)
            local ins = {_ = {}}
            local meta = _tableCopy(getmetatable(cls) or {},{})
            local wins = _weak(ins)
            meta.__gc = function(self)
                wins().delete(self)
            end
            meta._super = cls
            meta._memberTable = {}
            meta.__index = function(table,key)
                local value = rawget(_getMemberTable(wins()),key)
                if value == nil then
                    return cls[key]
                else
                    return value
                end
            end
            meta.__newindex = function(table,key,value)
                rawset(_getMemberTable(wins()),key,value)
            end
            if DEBUG then meta.__newindex = DEBUG.checkSubstitutionFunc() end
            setmetatable(ins, meta)
            setmetatable(ins._, {__index = function(table,key) return rawget(_getMemberTable(wins()),key) end,
                __newindex=function(table,key,value) rawset(_getMemberTable(wins()),key,value) end})
            return ins
        end
    local wcls = _weak(cls)
    cls.new = function(cls)
            local ins = wcls():_rawnew()
            return ins
        end
    cls.delete = function(self)
        end

    local wcls = _weak(cls)
    local meta = getmetatable(cls) or {}
    if DEBUG then
        meta.__newindex = DEBUG.preClassNewIndexFunc()
    else
        meta.__newindex = function(table,key,value) rawset(_getMemberTable(wcls()),key,value) end
    end
    meta.__index = function(table,key) return rawget(_getMemberTable(wcls()),key) end
    if meta._memberTable == nil then
        meta._memberTable = {}
    end
    setmetatable(cls, meta)
    return cls
end
---------------------------------------
--- standard function
function _mutable(obj)
    return (DEBUG and DEBUG.mutable(obj)) or obj
end
function _makeClassStatic(cls)
    return (DEBUG and DEBUG.makeClassStatic(cls)) or cls
end
function _weak(data)
    local weak = setmetatable({content=data}, {__mode="v"})
    return function() return weak.content end
end
function _tableCopy(from, to)
    for k,v in pairs(from) do
        to[k] = v
    end
    return to
end
function _addmetatable(table, add_meta)
    local meta = _tableCopy(getmetatable(table) or {},{})
    local mergeMetatable = function(key)
        local meta_table = meta[key]
        if meta_table == nil then
            meta[key] = {}
            meta_table = meta[key]
        end
        local add_metatable = add_meta[key] or {}
        _tableCopy(meta_table, add_metatable)
    end
    mergeMetatable("_memberTable")
    mergeMetatable("_mutableList")
    mergeMetatable("_readableList")

    for k,v in pairs(add_meta) do
        meta[k] = v
    end
    setmetatable(table, meta)
end
function _getMemberTable(obj)
    local meta = getmetatable(obj) or {}
    return meta._memberTable
end
---------------------------------------
--- DEBUG function
DEBUG = {}
DEBUG.null = {}
function DEBUG.printTable(table)
    for k, v in pairs(table) do
        print( k, v )
    end
end
function DEBUG.mutable(obj)
    return DEBUG.mutablePack(obj)
end
function DEBUG.isMutable(ins, key)
    local insmeta = getmetatable(ins) or {}
    local mutableList = insmeta._mutableList or {}
    return (mutableList[key] == true) or (insmeta._super and DEBUG.isMutable(insmeta._super, key))
end
function DEBUG.isReadable(ins, key)
    local insmeta = getmetatable(ins) or {}
    local readableList = insmeta._readableList or {}
    return (readableList[key] == true) or (insmeta._super and DEBUG.isReadable(insmeta._super, key))
end
function DEBUG.makeClassStatic(cls)
    local meta = getmetatable(cls) or {}
    meta.__newindex = DEBUG.checkSubstitutionFunc()
    meta.__index = function(table,key)
        local value = rawget(_getMemberTable(table),key)
        if not DEBUG.isReadable(table,key) and value == nil then
            error("class member: '" .. key .. "' is not defined. in call of class member.")
        end
        return value
    end
    setmetatable(cls, meta)
end
function DEBUG.checkSubstitution(table,key,value)
    if not DEBUG.isReadable(table, key) then
        error("class member: '" .. key .. "' is not defined. in substitution of class member.")
    end
    if not DEBUG.isMutable(table, key) then
        error("class member: '" .. key .. "' is not _mutable. in substitution of class member.")
    end
    if not DEBUG.isKindOf(table[key], value) then
        error("class member: '" .. key .. "' is not compatible. in substitution of class member.")
    end
end
function DEBUG.checkSubstitutionFunc()
    return function(table,key,value)
        DEBUG.checkSubstitution(table,key,value)
        rawset(_getMemberTable(table), key, value)
    end
end
function DEBUG.isKindOf(base, value)
    local baseins, basemetains = DEBUG.interfaceMap(base)
    local valueins, valuemetains = DEBUG.interfaceMap(value)
    return DEBUG.isTableSubset(valueins, baseins) and DEBUG.isTableSubset(valuemetains, basemetains)
end
function DEBUG.isTableSubset(set, subset)
    for k,v in pairs(subset) do
        if set[k] == nil then
            print("!ERROR! '" .. k .. "' is required interface. but, not exist in substituted value.")
            return false
        end
    end
    return true
end
function DEBUG.mutablePack(obj)
    local mutableObj = {}
    if obj == nil then
        obj = DEBUG.null
    end
    local meta = {_mutableValue = obj or {}}
    setmetatable(mutableObj, meta)
    return mutableObj
end
function DEBUG.mutableUnpack(obj)
    local meta = getmetatable(obj) or {}
    return meta._mutableValue
end
function DEBUG.preClassNewIndexFunc()
    return function(table,key,value)
        local meta = getmetatable(table) or {}
        local unpack = DEBUG.mutableUnpack(value)
        if unpack ~= nil then
            if meta._mutableList == nil then
                meta._mutableList = {}
            end
            meta._mutableList[key] = true
            if unpack == DEBUG.null then
                value = nil
            else
                value = unpack
            end
        end
        if meta._readableList == nil then
            meta._readableList = {}
        end
        meta._readableList[key] = true
        if type(value) == "function" then
            local wsuper = _weak(table)
            local localvalue = value
            local newfunc = function(self, ...)
                local meta = getmetatable(self) or {}
                if type(self) ~= "table" or (meta._super and meta._super ~= wsuper()) then
                    error("class function: '" .. key .. "' must use ':', do not use '.'")
                end
                return localvalue(self, ...)
            end
            value = newfunc
        end
        rawset(_getMemberTable(table), key, value)
    end
end
function DEBUG.interfaceMap(any)
    local type = type(any)
    if type == "nil" then
        return {},{}
    elseif type == "string" then
        return {},{}
    elseif type == "number" then
        return {},{}
    elseif type == "function" then
        return {},{__call = true}
    elseif type == "boolean" then
        return {},{}
    elseif type == "thread" then
        return {},{thread = true}
    elseif type == "table" then
        local ins = any
        local interface = {}
        local metainterface = {}
        repeat
            for k,v in pairs(ins) do
                interface[k] = true
            end
            local super = nil
            for k,v in pairs(getmetatable(ins) or {}) do
                if k == "_super" then
                    super = v
                elseif k == "_memberTable" then
                    for k2,v2 in pairs(v) do
                        interface[k2] = true
                    end
                elseif k ~= "_mutableList" and k ~= "_readableList" and k ~= "__newindex" then
                    metainterface[k] = true
                end
            end
            ins = super
        until ins == nil
        return interface,metainterface
    else -- userdata | lightuserdata
        return {},{}
    end
end
