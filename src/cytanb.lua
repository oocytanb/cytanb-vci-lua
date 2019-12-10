----------------------------------------------------------------
--  Copyright (c) 2019 oO (https://github.com/oocytanb)
--  MIT Licensed
----------------------------------------------------------------

-- VCAS@1.7.0a 時点において、`cytanb.lua` は VCI の `require` に対応していません。

---@type cytanb @See `cytanb_annotations.lua`
local cytanb = (function ()
    --- インスタンス ID の状態変数名。
    local InstanceIDStateName = '__CYTANB_INSTANCE_ID'

    --- 値の変換マップ。
    local valueConversionMap

    --- エスケープシーケンスの置換パターン。
    local escapeSequenceReplacementPatterns

    -- パラメーター値の置換マップ。
    local parameterValueReplacementMap

    --- 出力するログレベル。
    local logLevel

    --- ログ出力する時に、ログレベルの文字列を出力するか。
    local outputLogLevelEnabled = false

    --- ログレベルの文字列マップ。
    local logLevelStringMap

    --- インスタンス ID の文字列。
    local instanceID

    local cytanb

    -- set random seed
    (function ()
        local lspid = 'eff3a188-bfc7-4b0e-93cb-90fd1adc508c'
        local pmap = _G[lspid]
        if not pmap then
            pmap = {}
            _G[lspid] = pmap
        end

        local seed = pmap.randomSeedValue
        if not seed then
            seed = os.time() - os.clock() * 10000
            pmap.randomSeedValue = seed
            math.randomseed(seed)
        end

        return seed
    end)()

    local UUIDCompare = function (op1, op2)
        for i = 1, 4 do
            local diff = op1[i] - op2[i]
            if diff ~= 0 then
                return diff
            end
        end
        return 0
    end

    local UUIDMetatable
    UUIDMetatable = {
        __eq = function (op1, op2)
            return op1[1] == op2[1] and op1[2] == op2[2] and op1[3] == op2[3] and op1[4] == op2[4]
        end,

        __lt = function (op1, op2)
            return UUIDCompare(op1, op2) < 0
        end,

        __le = function (op1, op2)
            return UUIDCompare(op1, op2) <= 0
        end,

        __tostring = function (value)
            local second = value[2] or 0
            local third = value[3] or 0
            return string.format(
                '%08x-%04x-%04x-%04x-%04x%08x',
                bit32.band(value[1] or 0, 0xFFFFFFFF),
                bit32.band(bit32.rshift(second, 16), 0xFFFF),
                bit32.band(second, 0xFFFF),
                bit32.band(bit32.rshift(third, 16), 0xFFFF),
                bit32.band(third, 0xFFFF),
                bit32.band(value[4] or 0, 0xFFFFFFFF)
            )
        end,

        __concat = function (op1, op2)
            local meta1 = getmetatable(op1)
            local c1 = meta1 == UUIDMetatable or (type(meta1) == 'table' and meta1.__concat == UUIDMetatable.__concat)
            local meta2 = getmetatable(op2)
            local c2 = meta2 == UUIDMetatable or (type(meta2) == 'table' and meta2.__concat == UUIDMetatable.__concat)
            if not c1 and not c2 then
                error('UUID: attempt to concatenate illegal values', 2)
            end
            return (c1 and UUIDMetatable.__tostring(op1) or op1) .. (c2 and UUIDMetatable.__tostring(op2) or op2)
        end
    }

    local ConstVariablesFieldName = '__CYTANB_CONST_VARIABLES'

    local ConstIndexHandler = function (table, key)
        local meta = getmetatable(table)
        if meta then
            local mc = rawget(meta, ConstVariablesFieldName)
            if mc then
                local h = rawget(mc, key)
                if type(h) == 'function' then
                    return (h(table, key))
                else
                    return h
                end
            end
        end
        return nil
    end

    local ConstNewIndexHandler = function (table, key, v)
        local meta = getmetatable(table)
        if meta then
            local mc = rawget(meta, ConstVariablesFieldName)
            if mc then
                if rawget(mc, key) ~= nil then
                    error('Cannot assign to read only field "' .. key .. '"', 2)
                end
            end
        end
        rawset(table, key, v)
    end

    local TestValueFromTable = function (tbl, typeName)
        local nillableType = tbl[cytanb.TypeParameterName]
        if cytanb.NillableHasValue(nillableType) and cytanb.NillableValue(nillableType) ~= typeName then
            -- 型が一致していない
            return false, false
        end

        return cytanb.NillableIfHasValueOrElse(
            valueConversionMap[typeName],
            function (conv)
                local fieldNames = conv.compositionFieldNames
                local remain = conv.compositionFieldLength
                local unknownFieldContains = false

                for k, v in pairs(tbl) do
                    if fieldNames[k] then
                        remain = remain - 1
                        if remain <= 0 and unknownFieldContains then
                            break
                        end
                    elseif k ~= cytanb.TypeParameterName then
                        unknownFieldContains = true
                        if remain <= 0 then
                            break
                        end
                    end
                end

                return remain <= 0, unknownFieldContains
            end,
            function ()
                return false, false
            end
        )
    end

    local EscapeForSerialization = function (str)
        -- エスケープタグの文字列を処理したあと、前方スラッシュをエスケープする。
        return string.gsub(
            string.gsub(str, cytanb.EscapeSequenceTag, cytanb.EscapeSequenceTag .. cytanb.EscapeSequenceTag),
            '/', cytanb.SolidusTag
        )
    end

    local UnescapeForDeserialization = function (str, replacer)
        local len = string.len(str)
        local tagLen = string.len(cytanb.EscapeSequenceTag)
        if tagLen > len then
            return str
        end

        local buf = ''
        local i = 1
        while i < len do
            local ei, ee = string.find(str, cytanb.EscapeSequenceTag, i, true)
            if not ei then
                if i == 1 then
                    -- 初回の検索で見つからなければ、処理する必要がないので、str をそのまま返す
                    buf = str
                else
                    -- 残りの文字列をアペンドする
                    buf = buf .. string.sub(str, i)
                end
                break
            end

            if ei > i then
                buf = buf .. string.sub(str, i, ei - 1)
            end

            local replaced = false
            for entryIndex, entry in ipairs(escapeSequenceReplacementPatterns) do
                local ri, re = string.find(str, entry.pattern, ei)
                if ri then
                    buf = buf .. (replacer and replacer(entry.tag) or entry.replacement)
                    i = re + 1
                    replaced = true
                    break
                end
            end

            if not replaced then
                -- エスケープタグが開始されたが、未知の形式であるため、そのままアペンドする
                buf = buf .. cytanb.EscapeSequenceTag
                i = ee + 1
            end
        end
        return buf
    end

    local InternalTableToSerializable
    InternalTableToSerializable = function (data, refTable)
        if type(data) ~= 'table' then
            return data
        end

        if not refTable then
            refTable = {}
        end

        if refTable[data] then
            error('circular reference')
        end

        refTable[data] = true
        local serData = {}
        for k, v in pairs(data) do
            local keyType = type(k)
            local nk
            if keyType == 'string' then
                -- 文字列であれば、エスケープ処理をする
                nk = EscapeForSerialization(k)
            elseif keyType == 'number' then
                -- 数値インデックスであれば、タグを付加する
                nk = tostring(k) .. cytanb.ArrayNumberTag
            else
                nk = k
            end

            local valueType = type(v)
            if valueType == 'string' then
                -- 文字列であれば、エスケープ処理をする
                serData[nk] = EscapeForSerialization(v)
            elseif valueType == 'number' and v < 0 then
                -- 負の数値であれば、タグを付加する
                serData[tostring(nk) .. cytanb.NegativeNumberTag] = tostring(v)
            else
                serData[nk] = InternalTableToSerializable(v, refTable)
            end
        end

        refTable[data] = nil
        return serData
    end

    local InternalTableFromSerializable
    InternalTableFromSerializable = function (serData, noValueConversion)
        if type(serData) ~= 'table' then
            return serData
        end

        local data = {}
        for k, v in pairs(serData) do
            local nk
            local valueIsNegativeNumber = false
            if type(k) == 'string' then
                local keyIsArrayNumber = false
                nk = UnescapeForDeserialization(k, function (tag)
                    if tag == cytanb.NegativeNumberTag then
                        valueIsNegativeNumber = true
                    elseif tag == cytanb.ArrayNumberTag then
                        keyIsArrayNumber = true
                    end
                    return nil
                end)

                if keyIsArrayNumber then
                    -- 数値インデックスの文字列のキーを数値へ戻す
                    nk = tonumber(nk) or nk
                end
            else
                nk = k
                valueIsNegativeNumber = false
            end

            if valueIsNegativeNumber and type(v) == 'string' then
                data[nk] = tonumber(v)
            elseif type(v) == 'string' then
                data[nk] = UnescapeForDeserialization(v, function (tag)
                    return parameterValueReplacementMap[tag]
                end)
            else
                data[nk] = InternalTableFromSerializable(v, noValueConversion)
            end
        end

        if not noValueConversion then
            cytanb.NillableIfHasValue(data[cytanb.TypeParameterName], function (typeValue)
                -- 値の変換を試みる
                cytanb.NillableIfHasValue(valueConversionMap[typeValue], function (conv)
                    local nillableValue, unknownFieldContains = conv.fromTableFunc(data)
                    -- 値の変換に成功し、成分フィールド以外が含まれていない場合は、変換した値を返す
                    if not unknownFieldContains then
                        cytanb.NillableIfHasValue(nillableValue, function (value)
                            data = value
                        end)
                    end
                end)
            end)
        end

        return data
    end

    cytanb = {
        InstanceID = function ()
            if instanceID == '' then
                instanceID = vci.state.Get(InstanceIDStateName) or ''
            end
            return instanceID
        end,

        NillableHasValue = function (nillable)
            return nillable ~= nil
        end,

        NillableValue = function (nillable)
            if nillable == nil then
                error('nillable: value is nil', 2)
            end
            return nillable
        end,

        NillableValueOrDefault = function (nillable, defaultValue)
            if nillable == nil then
                if defaultValue == nil then
                    error('nillable: defaultValue is nil', 2)
                end
                return defaultValue
            else
                return nillable
            end
        end,

        NillableIfHasValue = function (nillable, callback)
            if nillable == nil then
                return nil
            else
                return callback(nillable)
            end
        end,

        NillableIfHasValueOrElse = function (nillable, callback, emptyCallback)
            if nillable == nil then
                return emptyCallback()
            else
                return callback(nillable)
            end
        end,

        SetConst = function (target, name, value)
            if type(target) ~= 'table' then
                error('Cannot set const to non-table target', 2)
            end

            local curMeta = getmetatable(target)
            local meta = curMeta or {}
            local metaConstVariables = rawget(meta, ConstVariablesFieldName)
            if rawget(target, name) ~= nil then
                error('Non-const field "' .. name .. '" already exists', 2)
            end

            if not metaConstVariables then
                metaConstVariables = {}
                rawset(meta, ConstVariablesFieldName, metaConstVariables)
                meta.__index = ConstIndexHandler
                meta.__newindex = ConstNewIndexHandler
            end

            rawset(metaConstVariables, name, value)

            if not curMeta then
                setmetatable(target, meta)
            end

            return target
        end,

        SetConstEach = function (target, entries)
            for k, v in pairs(entries) do
                cytanb.SetConst(target, k, v)
            end
            return target
        end,

        Extend = function (target, source, deep, omitMetaTable, refTable)
            if target == source or type(target) ~= 'table' or type(source) ~= 'table' then
                return target
            end

            if deep then
                if not refTable then
                    refTable = {}
                end

                if refTable[source] then
                    error('circular reference')
                end

                refTable[source] = true
            end

            for k, v in pairs(source) do
                if deep and type(v) == 'table' then
                    local targetChild = target[k]
                    target[k] = cytanb.Extend(type(targetChild) == 'table' and targetChild or {}, v, deep, omitMetaTable, refTable)
                else
                    target[k] = v
                end
            end

            if not omitMetaTable then
                local sourceMetatable = getmetatable(source)
                if type(sourceMetatable) == 'table' then
                    if deep then
                        local targetMetatable = getmetatable(target)
                        setmetatable(target, cytanb.Extend(type(targetMetatable) == 'table' and targetMetatable or {}, sourceMetatable, true))
                    else
                        setmetatable(target, sourceMetatable)
                    end
                end
            end

            if deep then
                refTable[source] = nil
            end

            return target
        end,

        Vars = function (v, padding, indent, refTable)
            local feed
            if padding then
                feed = padding ~= '__NOLF'
            else
                padding = '  '
                feed = true
            end

            if not indent then
                indent = ''
            end

            if not refTable then
                refTable = {}
            end

            local t = type(v)
            if t == 'table' then
                refTable[v] = refTable[v] and refTable[v] + 1 or 1

                local childIndent = feed and (indent .. padding) or ''
                local str = '(' .. tostring(v) .. ') {'

                local firstEntry = true
                for key, val in pairs(v) do
                    if firstEntry then
                        firstEntry = false
                    else
                        str = str .. (feed and ',' or ', ')
                    end

                    if feed then
                        str = str .. '\n' .. childIndent
                    end

                    if type(val) == 'table' and refTable[val] and refTable[val] > 0 then
                        str = str .. key .. ' = (' .. tostring(val) .. ')'
                    else
                        str = str .. key .. ' = ' .. cytanb.Vars(val, padding, childIndent, refTable)
                    end
                end

                if not firstEntry and feed then
                    str = str .. '\n' .. indent
                end
                str = str .. '}'

                refTable[v] = refTable[v] - 1
                if (refTable[v] <= 0) then
                    refTable[v] = nil
                end
                return str
            elseif t == 'function' or t == 'thread' or t == 'userdata' then
                return '(' .. t .. ')'
            elseif t == 'string' then
                return '(' .. t .. ') ' .. string.format('%q', v)
            else
                return '(' .. t .. ') ' .. tostring(v)
            end
        end,

        GetLogLevel = function ()
            return logLevel
        end,

        SetLogLevel = function (level)
            logLevel = level
        end,

        IsOutputLogLevelEnabled = function ()
            return outputLogLevelEnabled
        end,

        SetOutputLogLevelEnabled = function (enabled)
            outputLogLevelEnabled = not not enabled
        end,

        Log = function (level, ...)
            if level <= logLevel then
                local levelString = outputLogLevelEnabled and ((logLevelStringMap[level] or 'LOG LEVEL ' .. tostring(level)) .. ' | ') or ''
                local args = table.pack(...)
                if args.n == 1 then
                    local v = args[1]
                    if v ~= nil then
                        local str = type(v) == 'table' and cytanb.Vars(v) or tostring(v)
                        print(outputLogLevelEnabled and levelString .. str or str)
                    else
                        print(levelString)
                    end
                else
                    local str = levelString
                    for i = 1, args.n do
                        local v = args[i]
                        if v ~= nil then
                            str = str .. (type(v) == 'table' and cytanb.Vars(v) or tostring(v))
                        end
                    end
                    print(str)
                end
            end
        end,

        LogFatal = function (...) cytanb.Log(cytanb.LogLevelFatal, ...) end,

        LogError = function (...) cytanb.Log(cytanb.LogLevelError, ...) end,

        LogWarn = function (...) cytanb.Log(cytanb.LogLevelWarn, ...) end,

        LogInfo = function (...) cytanb.Log(cytanb.LogLevelInfo, ...) end,

        LogDebug = function (...) cytanb.Log(cytanb.LogLevelDebug, ...) end,

        LogTrace = function (...) cytanb.Log(cytanb.LogLevelTrace, ...) end,

        -- @deprecated
        FatalLog = function (...) cytanb.LogFatal(...) end,

        -- @deprecated
        ErrorLog = function (...) cytanb.LogError(...) end,

        -- @deprecated
        WarnLog = function (...) cytanb.LogWarn(...) end,

        -- @deprecated
        InfoLog = function (...) cytanb.LogInfo(...) end,

        -- @deprecated
        DebugLog = function (...) cytanb.LogDebug(...) end,

        -- @deprecated
        TraceLog = function (...) cytanb.LogTrace(...) end,

        ListToMap = function (list, itemValue)
            local table = {}
            local valueIsNil = itemValue == nil
            for k, v in pairs(list) do
                table[v] = valueIsNil and v or itemValue
            end
            return table
        end,

        Round = function (num, decimalPlaces)
            if decimalPlaces then
                local m = 10 ^ decimalPlaces
                return math.floor(num * m + 0.5) / m
            else
                return math.floor(num + 0.5)
            end
        end,

        Clamp = function (value, min, max)
            return math.max(min, math.min(value, max))
        end,

        Lerp = function (a, b, t)
            if t <= 0.0 then
                return a
            elseif t >= 1.0 then
                return b
            else
                return a + (b - a) * t
            end
        end,

        LerpUnclamped = function (a, b, t)
            if t == 0.0 then
                return a
            elseif t == 1.0 then
                return b
            else
                return a + (b - a) * t
            end
        end,

        PingPong = function (t, length)
            if length == 0 then
                return 0
            end

            local q = math.floor(t / length)
            local r = t - q * length
            if q < 0 then
                if (q + 1) % 2 == 0 then
                    return length - r
                else
                    return r
                end
            else
                if q % 2 == 0 then
                    return r
                else
                    return length - r
                end
            end
        end,

        VectorApproximatelyEquals = function (lhs, rhs)
            return (lhs - rhs).sqrMagnitude < 1E-10
        end,

        QuaternionApproximatelyEquals = function (lhs, rhs)
            local dot = Quaternion.Dot(lhs, rhs)
            return dot < 1.0 + 1E-06 and dot > 1.0 - 1E-06
        end,

        QuaternionToAngleAxis = function (quat)
            local q = quat.normalized
            local halfTheta = math.acos(q.w)
            local st = math.sin(halfTheta)
            local angle = math.deg(halfTheta * 2.0)
            local vec
            if math.abs(st) <= Quaternion.kEpsilon then
                vec = Vector3.right
            else
                local si = 1.0 / st
                vec = Vector3.__new(q.x * si, q.y * si, q.z * si)
            end
            return angle, vec
        end,

        ApplyQuaternionToVector3 = function (quat, vec3)
            -- (quat * Quaternion.__new(vec3.x, vec3.y, vec3.z, 0)) * Quaternion.Inverse(quat)
            local qpx = quat.w * vec3.x + quat.y * vec3.z - quat.z * vec3.y
            local qpy = quat.w * vec3.y - quat.x * vec3.z + quat.z * vec3.x
            local qpz = quat.w * vec3.z + quat.x * vec3.y - quat.y * vec3.x
            local qpw = - quat.x * vec3.x - quat.y * vec3.y - quat.z * vec3.z

            return Vector3.__new(
                qpw * - quat.x + qpx * quat.w + qpy * - quat.z - qpz * - quat.y,
                qpw * - quat.y - qpx * - quat.z + qpy * quat.w + qpz * - quat.x,
                qpw * - quat.z + qpx * - quat.y - qpy * - quat.x + qpz * quat.w
            )
        end,

        RotateAround = function (targetPosition, targetRotation, centerPosition, rotation)
            return centerPosition + cytanb.ApplyQuaternionToVector3(rotation, targetPosition - centerPosition), rotation * targetRotation
        end,

        Random32 = function ()
            -- MoonSharp では整数値の場合 32bit int 型にキャストされ、2147483646 が渡すことのできる最大値。
            return bit32.band(math.random(-2147483648, 2147483646), 0xFFFFFFFF)
        end,

        RandomUUID = function ()
            return cytanb.UUIDFromNumbers(
                cytanb.Random32(),
                bit32.bor(0x4000, bit32.band(cytanb.Random32(), 0xFFFF0FFF)),
                bit32.bor(0x80000000, bit32.band(cytanb.Random32(), 0x3FFFFFFF)),
                cytanb.Random32()
            )
        end,

        -- @deprecated use tostring(uuid)
        UUIDString = function (uuid)
            return UUIDMetatable.__tostring(uuid)
        end,

        UUIDFromNumbers = function (...)
            local first = ...
            local t = type(first)
            local num1, num2, num3, num4
            if t == 'table' then
                num1 = first[1]
                num2 = first[2]
                num3 = first[3]
                num4 = first[4]
            else
                num1, num2, num3, num4 = ...
            end

            local uuid = {
                bit32.band(num1 or 0, 0xFFFFFFFF),
                bit32.band(num2 or 0, 0xFFFFFFFF),
                bit32.band(num3 or 0, 0xFFFFFFFF),
                bit32.band(num4 or 0, 0xFFFFFFFF)
            }
            setmetatable(uuid, UUIDMetatable)
            return uuid
        end,

        UUIDFromString = function (str)
            local len = string.len(str)
            if len ~= 32 and len ~= 36 then return nil end

            local reHex = '[0-9a-f-A-F]+'
            local reHexString = '^(' .. reHex .. ')$'
            local reHyphenHexString = '^-(' .. reHex .. ')$'

            local mi, mj, token, token2
            if len == 32 then
                local uuid = cytanb.UUIDFromNumbers(0, 0, 0, 0)
                local startPos = 1
                for i, endPos in ipairs({8, 16, 24, 32}) do
                    mi, mj, token = string.find(string.sub(str, startPos, endPos), reHexString)
                    if not mi then return nil end
                    uuid[i] = tonumber(token, 16)
                    startPos = endPos + 1
                end
                return uuid
            else
                mi, mj, token = string.find(string.sub(str, 1, 8), reHexString)
                if not mi then return nil end
                local num1 = tonumber(token, 16)

                mi, mj, token = string.find(string.sub(str, 9, 13), reHyphenHexString)
                if not mi then return nil end
                mi, mj, token2 = string.find(string.sub(str, 14, 18), reHyphenHexString)
                if not mi then return nil end
                local num2 = tonumber(token .. token2, 16)

                mi, mj, token = string.find(string.sub(str, 19, 23), reHyphenHexString)
                if not mi then return nil end
                mi, mj, token2 = string.find(string.sub(str, 24, 28), reHyphenHexString)
                if not mi then return nil end
                local num3 = tonumber(token .. token2, 16)

                mi, mj, token = string.find(string.sub(str, 29, 36), reHexString)
                if not mi then return nil end
                local num4 = tonumber(token, 16)

                return cytanb.UUIDFromNumbers(num1, num2, num3, num4)
            end
        end,

        -- @deprecated use UUIDFromString
        ParseUUID = function (str)
            return cytanb.UUIDFromString(str)
        end,

        CreateCircularQueue = function (capacity)
            if type(capacity) ~= 'number' or capacity < 1 then
                error('Invalid argument: capacity = ' .. tostring(capacity), 2)
            end

            local self
            local maxSize = math.floor(capacity)
            local buf = {}
            local top = 0
            local bottom = 0
            local size = 0

            self = {
                Size = function ()
                    return size
                end,

                Clear = function ()
                    top = 0
                    bottom = 0
                    size = 0
                end,

                IsEmpty = function ()
                    return size == 0
                end,

                Offer = function (element)
                    buf[top + 1] = element
                    top = (top + 1) % maxSize
                    if size < maxSize then
                        size = size + 1
                    else
                        -- バッファーがフルになっているので、古い要素を捨てるために bottom を進める。
                        bottom = (bottom + 1) % maxSize
                    end
                    return true
                end,

                OfferFirst = function (element)
                    bottom = (maxSize + bottom - 1) % maxSize
                    buf[bottom + 1] = element
                    if size < maxSize then
                        size = size + 1
                    else
                        -- バッファーがフルになっているので、古い要素を捨てるために top を戻す。
                        top = (maxSize + top - 1) % maxSize
                    end
                    return true
                end,

                Poll = function ()
                    if size == 0 then
                        return nil
                    else
                        local element = buf[bottom + 1]
                        bottom = (bottom + 1) % maxSize
                        size = size - 1
                        return element
                    end
                end,

                PollLast = function ()
                    if size == 0 then
                        return nil
                    else
                        top = (maxSize + top - 1) % maxSize
                        local element = buf[top + 1]
                        size = size - 1
                        return element
                    end
                end,

                Peek = function ()
                    if size == 0 then
                        return nil
                    else
                        return buf[bottom + 1]
                    end
                end,

                PeekLast = function ()
                    if size == 0 then
                        return nil
                    else
                        return buf[(maxSize + top - 1) % maxSize + 1]
                    end
                end,

                Get = function (index)
                    if index < 1 or index > size then
                        cytanb.LogError('CreateCircularQueue.Get: index is outside the range: ' .. index)
                        return nil
                    end
                    return buf[(bottom + (index - 1)) % maxSize + 1]
                end,

                IsFull = function ()
                    return size >= maxSize
                end,

                MaxSize = function ()
                    return maxSize
                end
            }
            return self
        end,

        DetectClicks = function (lastClickCount, lastTime, clickTiming)
            local count = lastClickCount or 0
            local timing = clickTiming or TimeSpan.FromMilliseconds(500)
            local now = vci.me.Time
            local result = (lastTime and now > lastTime + timing) and 1 or count + 1
            return result, now
        end,

        ColorRGBToHSV = function (color)
            local r = math.max(0.0, math.min(color.r, 1.0))
            local g = math.max(0.0, math.min(color.g, 1.0))
            local b = math.max(0.0, math.min(color.b, 1.0))
            local max = math.max(r, g, b)
            local min = math.min(r, g, b)

            local d = max - min
            local h
            if d == 0.0 then
                h = 0.0
            elseif max == r then
                h = (g - b) / d / 6.0
            elseif max == g then
                h = (2.0 + (b - r) / d) / 6.0
            else
                h = (4.0 + (r - g) / d) / 6.0
            end

            if h < 0.0 then
                h = h + 1.0
            end

            local s = max == 0.0 and d or d / max
            local v = max
            return h, s, v
        end,

        ColorFromARGB32 = function (argb32)
            local n = (type(argb32) == 'number') and argb32 or 0xFF000000
            return Color.__new(
                bit32.band(bit32.rshift(n, 16), 0xFF) / 0xFF,
                bit32.band(bit32.rshift(n, 8), 0xFF) / 0xFF,
                bit32.band(n, 0xFF) / 0xFF,
                bit32.band(bit32.rshift(n, 24), 0xFF) / 0xFF
            )
        end,

        ColorToARGB32 = function (color)
            return bit32.bor(
                bit32.lshift(bit32.band(cytanb.Round(0xFF * color.a), 0xFF), 24),
                bit32.lshift(bit32.band(cytanb.Round(0xFF * color.r), 0xFF), 16),
                bit32.lshift(bit32.band(cytanb.Round(0xFF * color.g), 0xFF), 8),
                bit32.band(cytanb.Round(0xFF * color.b), 0xFF)
            )
        end,

        ColorFromIndex = function (colorIndex, hueSamples, saturationSamples, brightnessSamples, omitScale)
            local hueN = math.max(math.floor(hueSamples or cytanb.ColorHueSamples), 1)
            local toneN = omitScale and hueN or (hueN - 1)
            local saturationN = math.max(math.floor(saturationSamples or cytanb.ColorSaturationSamples), 1)
            local valueN = math.max(math.floor(brightnessSamples or cytanb.ColorBrightnessSamples), 1)
            local index = cytanb.Clamp(math.floor(colorIndex or 0), 0, hueN * saturationN * valueN - 1)

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
        end,

        --- **EXPERIMENTAL:実験的な機能。`Color` オブジェクトから近似するカラーインデックスを計算する。**
        ColorToIndex = function (color, hueSamples, saturationSamples, brightnessSamples, omitScale)
            local hueN = math.max(math.floor(hueSamples or cytanb.ColorHueSamples), 1)
            local toneN = omitScale and hueN or (hueN - 1)
            local saturationN = math.max(math.floor(saturationSamples or cytanb.ColorSaturationSamples), 1)
            local valueN = math.max(math.floor(brightnessSamples or cytanb.ColorBrightnessSamples), 1)

            local h, s, v = cytanb.ColorRGBToHSV(color)
            local si = cytanb.Round(saturationN * (1.0 - s))
            if omitScale or si < saturationN then
                local hi = cytanb.Round(toneN * h)
                if hi >= toneN then
                    hi = 0
                end

                if si >= saturationN then
                    si = saturationN - 1
                end

                local vi = math.min(valueN - 1, cytanb.Round(valueN * (1.0 - v)))
                return hi + hueN * (si + saturationN * vi)
            else
                local msi = cytanb.Round((saturationN - 1) * v)
                if msi == 0 then
                    local mvi = cytanb.Round(valueN * (1.0 - v))
                    if mvi >= valueN then
                        return hueN - 1
                    else
                        return hueN * (1 + cytanb.Round(v * (saturationN - 1) / (valueN - mvi) * valueN) + saturationN * mvi) - 1
                    end
                else
                    return hueN * (1 + msi + saturationN * cytanb.Round(valueN * (1.0 - v * (saturationN - 1) / msi))) - 1
                end
            end
        end,

        ColorToTable = function (color)
            return {[cytanb.TypeParameterName] = cytanb.ColorTypeName, r = color.r, g = color.g, b = color.b, a = color.a}
        end,

        ColorFromTable = function (tbl)
            local b, unknownFieldContains = TestValueFromTable(tbl, cytanb.ColorTypeName)
            return (b and Color.__new(tbl.r, tbl.g, tbl.b, tbl.a) or nil), unknownFieldContains
        end,

        Vector2ToTable = function (value)
            return {[cytanb.TypeParameterName] = cytanb.Vector2TypeName, x = value.x, y = value.y}
        end,

        Vector2FromTable = function (tbl)
            local b, unknownFieldContains = TestValueFromTable(tbl, cytanb.Vector2TypeName)
            return (b and Vector2.__new(tbl.x, tbl.y) or nil), unknownFieldContains
        end,

        Vector3ToTable = function (value)
            return {[cytanb.TypeParameterName] = cytanb.Vector3TypeName, x = value.x, y = value.y, z = value.z}
        end,

        Vector3FromTable = function (tbl)
            local b, unknownFieldContains = TestValueFromTable(tbl, cytanb.Vector3TypeName)
            return (b and Vector3.__new(tbl.x, tbl.y, tbl.z) or nil), unknownFieldContains
        end,

        Vector4ToTable = function (value)
            return {[cytanb.TypeParameterName] = cytanb.Vector4TypeName, x = value.x, y = value.y, z = value.z, w = value.w}
        end,

        Vector4FromTable = function (tbl)
            local b, unknownFieldContains = TestValueFromTable(tbl, cytanb.Vector4TypeName)
            return (b and Vector4.__new(tbl.x, tbl.y, tbl.z, tbl.w) or nil), unknownFieldContains
        end,

        QuaternionToTable = function (value)
            return {[cytanb.TypeParameterName] = cytanb.QuaternionTypeName, x = value.x, y = value.y, z = value.z, w = value.w}
        end,

        QuaternionFromTable = function (tbl)
            local b, unknownFieldContains = TestValueFromTable(tbl, cytanb.QuaternionTypeName)
            return (b and Quaternion.__new(tbl.x, tbl.y, tbl.z, tbl.w) or nil), unknownFieldContains
        end,

        TableToSerializable = function (data)
            return InternalTableToSerializable(data)
        end,

        TableFromSerializable = function (serData, noValueConversion)
            return InternalTableFromSerializable(serData, noValueConversion)
        end,

        -- @deprecated use TableToSerializable
        TableToSerialiable = function (data)
            return InternalTableToSerializable(data)
        end,

        -- @deprecated use TableFromSerializable
        TableFromSerialiable = function (serData, noValueConversion)
            return InternalTableFromSerializable(serData, noValueConversion)
        end,

        EmitMessage = function (name, parameterMap)
            local table = parameterMap and cytanb.TableToSerializable(parameterMap) or {}
            table[cytanb.InstanceIDParameterName] = cytanb.InstanceID()
            vci.message.Emit(name, json.serialize(table))
        end,

        OnMessage = function (name, callback)
            local f = function (sender, messageName, message)
                local decodedData = nil
                if sender.type ~= 'comment' and type(message) == 'string' then
                    local pcallStatus, serData = pcall(json.parse, message)
                    if pcallStatus and type(serData) == 'table' then
                        decodedData = cytanb.TableFromSerializable(serData)
                    end
                end

                local parameterMap = decodedData and decodedData or {[cytanb.MessageValueParameterName] = message}
                callback(sender, messageName, parameterMap)
            end

            vci.message.On(name, f)

            return {
                Off = function ()
                    if f then
                        -- Off が実装されたら、ここで処理をする。
                        -- vci.message.Off(name, f)
                        f = nil
                    end
                end
            }
        end,

        OnInstanceMessage = function (name, callback)
            local f = function (sender, messageName, parameterMap)
                local id = cytanb.InstanceID()
                if id ~= '' and id == parameterMap[cytanb.InstanceIDParameterName] then
                    callback(sender, messageName, parameterMap)
                end
            end

            return cytanb.OnMessage(name, f)
        end,

        GetEffekseerEmitterMap = function (name)
            local efkList = vci.assets.GetEffekseerEmitters(name)
            if not efkList then
                return nil
            end

            local map = {}
            for i, efk in pairs(efkList) do
                map[efk.EffectName] = efk
            end
            return map
        end,

        --- **EXPERIMENTAL:実験的な機能。 物理演算の実行間隔を推定する。`updateAll` 関数から呼び出して使う。`physicalObject` に `AddForce` し、オブジェクトの時間当たりの移動量から計算を行う。`physicalObject` は `Rigidbody` コンポーネントを設定 (`Mass: 1`, `Drag: 0`, `Use Gravity: OFF`, `Is Kinematic: OFF`, `Interpolate: None`, `Freeze Position: OFF`) したオブジェクト。`Collider` や `VCI Sub Item` コンポーネントをセットしてはいけない。
        EstimateFixedTimestep = function (physicalObject)
            -- mass は 1.0 固定とする。
            local mass = 1.0

            local acceleration = 1000.0

            -- 規定値は 0.02 sec とする。
            local timestep = TimeSpan.FromSeconds(0.02)

            local timestepPrecision = 0xFFFF
            local timestepQueue = cytanb.CreateCircularQueue(64)

            -- キューを使った計算を開始する時間。
            local minTime = TimeSpan.FromSeconds(5)

            -- キューを使った計算を終了する時間。
            local maxTime = TimeSpan.FromSeconds(30)

            local finished = false

            local startTime = vci.me.Time

            -- 開始位置の X, Y 座標はランダムに、Z 座標はゼロとする。
            local rnd32 = cytanb.Random32()
            local startPosition = Vector3.__new(
                bit32.bor(0x400, bit32.band(rnd32, 0x1FFF)),
                bit32.bor(0x400, bit32.band(bit32.rshift(rnd32, 16), 0x1FFF)),
                0.0
            )

            physicalObject.SetPosition(startPosition)
            physicalObject.SetRotation(Quaternion.identity)
            physicalObject.SetVelocity(Vector3.zero)
            physicalObject.SetAngularVelocity(Vector3.zero)

            -- Z 軸方向に力を加える。
            physicalObject.AddForce(Vector3.__new(0.0, 0.0, mass * acceleration))

            local self = {
                --- 推定した物理演算の実行間隔を返す。
                Timestep = function ()
                    return timestep
                end,

                --- 推定した timestep の精度を返す。
                Precision = function ()
                    return timestepPrecision
                end,

                --- 計算が完了したかを返す。
                IsFinished = function ()
                    return finished
                end,

                --- `updateAll` 関数からこの関数を呼び出す。timestep を計算し、その値を返す。`IsFinish` が `true` を返したら、それ以上は呼び出す必要はない。
                Update = function ()
                    if finished then
                        return timestep
                    end

                    local elapsedTime = vci.me.Time - startTime
                    local dt = elapsedTime.TotalSeconds
                    if dt <= Vector3.kEpsilon then
                        return timestep
                    end

                    local dz = physicalObject.GetPosition().z - startPosition.z
                    local vz = dz / dt
                    local ts = vz / acceleration
                    if ts <= Vector3.kEpsilon then
                        return timestep
                    end

                    timestepQueue.Offer(ts)
                    local queueSize = timestepQueue.Size()
                    if queueSize >= 2 and elapsedTime >= minTime then
                        -- 平均と分散を計算する
                        local sum = 0.0
                        for i = 1, queueSize do
                            sum = sum + timestepQueue.Get(i)
                        end
                        local average = sum / queueSize

                        local vSum = 0.0
                        for i = 1, queueSize do
                            vSum = vSum + (timestepQueue.Get(i) - average) ^ 2
                        end
                        local variance = vSum / queueSize

                        if variance < timestepPrecision then
                            -- 分散が小さければ採用する
                            timestepPrecision = variance
                            timestep = TimeSpan.FromSeconds(average)
                        end

                        if elapsedTime > maxTime then
                            -- 最大時間を超えたら計算終了
                            finished = true

                            physicalObject.SetPosition(startPosition)
                            physicalObject.SetRotation(Quaternion.identity)
                            physicalObject.SetVelocity(Vector3.zero)
                            physicalObject.SetAngularVelocity(Vector3.zero)
                        end
                    else
                        timestep = TimeSpan.FromSeconds(ts)
                    end

                    return timestep
                end
            }
            return self
        end,

        --- **EXPERIMENTAL:実験的な機能のため変更される可能性がある。** サブアイテムオブジェクトの位置と回転を合わせるための、接着剤を作成する。
        CreateSubItemGlue = function ()
            local itemMap = {}

            local self
            self = {
                --- `parent` に `child` が含まれているかを調べる。
                Contains = function (parent, child)
                    return cytanb.NillableIfHasValueOrElse(
                        itemMap[parent],
                        function (entries) return cytanb.NillableHasValue(entries[child]) end,
                        function () return false end
                    )
                end,

                --- `parent` と `children` の組み合わせを指定する。`Update` 関数を呼び出すと、`parent` オブジェクトの位置と回転をが `children` に適用される。`velocityReset` に `true` が指定されていた場合は、`SetVelocity` と `SetAngularVelocity` も実行され、ゼロベクトルにリセットされる。
                Add = function (parent, children, velocityReset)
                    if not parent or not children then
                        local msg = 'CreateSubItemGlue.Add: INVALID ARGUMENT ' ..
                                    (not parent and (', parent = ' .. tostring(parent)) or '') ..
                                    (not children and (', children = ' .. tostring(children)) or '')
                        error(msg, 2)
                    end

                    local entries = cytanb.NillableIfHasValueOrElse(
                        itemMap[parent],
                        function (childMap)
                            return childMap
                        end,
                        function ()
                            local childMap = {}
                            itemMap[parent] = childMap
                            return childMap
                        end
                    )

                    if type(children) == 'table' then
                        for key, val in pairs(children) do
                            entries[val] = {velocityReset = not not velocityReset}
                        end
                    else
                        entries[children] = {velocityReset = not not velocityReset}
                    end
                end,

                --- `parent` から `child` を削除する。
                Remove = function (parent, child)
                    return cytanb.NillableIfHasValueOrElse(
                        itemMap[parent],
                        function (entries)
                            if cytanb.NillableHasValue(entries[child]) then
                                entries[child] = nil
                                return true
                            else
                                return false
                            end
                        end,
                        function ()
                            return false
                        end
                    )
                end,

                --- `parent` とその子要素を削除する。
                RemoveParent = function (parent)
                    if cytanb.NillableHasValue(itemMap[parent]) then
                        itemMap[parent] = nil
                        return true
                    else
                        return false
                    end
                end,

                --- すべての要素を削除する。
                RemoveAll = function ()
                    itemMap = {}
                    return true
                end,

                --- `callback(child, parent, glue)` には、各要素に対して実行するコールバック関数を指定する。`nillableParent` に親のオブジェクトを指定した場合は、その子要素が対象となる。省略した場合はすべての要素が対象となる。
                Each = function (callback, nillableParent)
                    return cytanb.NillableIfHasValueOrElse(
                        nillableParent,
                        function (parent)
                            return cytanb.NillableIfHasValue(
                                itemMap[parent],
                                function (entries)
                                    for child, options in pairs(entries) do
                                        if callback(child, parent, self) == false then
                                            return false
                                        end
                                    end
                                end
                            )
                        end,
                        function ()
                            for parent, entries in pairs(itemMap) do
                                if self.Each(callback, parent) == false then
                                    return false
                                end
                            end
                        end
                    )
                end,

                --- `child.IsMine` が `true` あるいは `force` を指定した場合に、 `parent` の位置と回転を `child` に適用する。`velocityReset` に `true` が指定されていた場合は、`SetVelocity` と `SetAngularVelocity` を行い、ゼロベクトルにリセットする。
                Update = function (force)
                    for parent, entries in pairs(itemMap) do
                        local parentPos = parent.GetPosition()
                        local parentRot = parent.GetRotation()

                        for child, options in pairs(entries) do
                            if force or child.IsMine then
                                if not cytanb.QuaternionApproximatelyEquals(child.GetRotation(), parentRot) then
                                    child.SetRotation(parentRot)
                                end

                                if not cytanb.VectorApproximatelyEquals(child.GetPosition(), parentPos) then
                                    child.SetPosition(parentPos)
                                end

                                if options.velocityReset then
                                    child.SetVelocity(Vector3.zero)
                                    child.SetAngularVelocity(Vector3.zero)
                                end
                            end
                        end
                    end
                end
            }
            return self
        end,

        --- **EXPERIMENTAL:実験的な機能のため変更される可能性がある。** サブアイテム間の位置と回転を相互に作用させるためのコネクターを作成する。スケールは非対応。サブアイテムのグループIDは、ゼロ以外の同じ値を設定しておく必要がある。
        CreateSubItemConnector = function ()
            local SetItemStatus = function (status, item, propagation)
                status.item = item

                status.position = item.GetPosition()
                status.rotation = item.GetRotation()

                status.initialPosition = status.position
                status.initialRotation = status.rotation

                status.propagation = not not propagation

                return status
            end

            local UpdateItemStatusMap = function (statusMap)
                for item, status in pairs(statusMap) do
                    SetItemStatus(status, item, status.propagation)
                end
            end

            local ApplyTransform = function (position, rotation, status, targetStatusMap, targetFilter)
                local dp = position - status.initialPosition
                local dr = rotation * Quaternion.Inverse(status.initialRotation)

                status.position = position
                status.rotation = rotation

                for item, targetStatus in pairs(targetStatusMap) do
                    -- フィルターが指定されていないか、フィルターが指定されていて true を返した場合は、適用処理をする
                    if item ~= status.item and (not targetFilter or targetFilter(targetStatus)) then
                        targetStatus.position, targetStatus.rotation = cytanb.RotateAround(targetStatus.initialPosition + dp, targetStatus.initialRotation, position, dr)

                        item.SetPosition(targetStatus.position)
                        item.SetRotation(targetStatus.rotation)
                    end
                end
            end

            local itemStatusMap = {}
            local updateEnabled = true
            local dirty = false

            local self
            self = {
                IsEnabled = function ()
                    return updateEnabled
                end,

                SetEnabled = function (enabled)
                    updateEnabled = enabled
                    if enabled then
                        UpdateItemStatusMap(itemStatusMap)
                        dirty = false
                    end
                end,

                Contains = function (subItem)
                    return cytanb.NillableHasValue(itemStatusMap[subItem])
                end,

                Add = function (subItems, noPropagation)
                    if not subItems then
                        error('CreateSubItemConnector.Add: INVALID ARGUMENT: subItems = ' .. tostring(subItems), 2)
                    end

                    local itemList = type(subItems) == 'table' and subItems or {subItems}

                    UpdateItemStatusMap(itemStatusMap)
                    dirty = false

                    for k, item in pairs(itemList) do
                        itemStatusMap[item] = SetItemStatus({}, item, not noPropagation)
                    end
                end,

                Remove = function (subItem)
                    local b = cytanb.NillableHasValue(itemStatusMap[subItem])
                    itemStatusMap[subItem] = nil
                    return b
                end,

                RemoveAll = function ()
                    itemStatusMap = {}
                    return true
                end,

                --- `callback(item, connector)` には、各要素に対して実行するコールバック関数を指定する。
                Each = function (callback)
                    for item, status in pairs(itemStatusMap) do
                        if callback(item, self) == false then
                            return false
                        end
                    end
                end,

                -- @deprecated
                GetItems = function ()
                    local itemList = {}
                    for item, status in pairs(itemStatusMap) do
                        table.insert(itemList, item)
                    end
                    return itemList
                end,

                Update = function ()
                    if not updateEnabled then
                        return
                    end

                    local transformed = false
                    for item, status in pairs(itemStatusMap) do
                        local pos = item.GetPosition()
                        local rot = item.GetRotation()
                        if not cytanb.VectorApproximatelyEquals(pos, status.position) or not cytanb.QuaternionApproximatelyEquals(rot, status.rotation) then
                            if status.propagation then
                                if item.IsMine then
                                    ApplyTransform(pos, rot, itemStatusMap[item], itemStatusMap, function (targetStatus)
                                        if targetStatus.item.IsMine then
                                            return true
                                        else
                                            -- 操作権がないアイテムがある場合は、ダーティーフラグをセットする
                                            dirty = true
                                            return false
                                        end
                                    end)

                                    -- 複数のアイテムが変更されていても、1度に変更を適用するのは1つだけ
                                    transformed = true
                                    break
                                else
                                    -- 操作権がないものは非サポート。SubItem が同期されるときに補間される関係で、まともに動かないため。
                                    dirty = true
                                end
                            else
                                -- 変更を伝搬しない場合は、ダーティーフラグをセットする
                                dirty = true
                            end
                        end
                    end

                    if not transformed and dirty then
                        -- 全アイテムのステータスをセットし直す
                        UpdateItemStatusMap(itemStatusMap)
                        dirty = false
                    end
                end
            }
            return self
        end,

        -- @deprecated この関数のかわりに、`Vector3ToTable/QuaternionToTable` を使用すること。
        GetSubItemTransform = function (subItem)
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
        end,

        -- @deprecated 廃止予定につき使用しないこと。
        RestoreCytanbTransform = function (transformParameters)
            local pos = (transformParameters.positionX and transformParameters.positionY and transformParameters.positionZ) and
                Vector3.__new(transformParameters.positionX, transformParameters.positionY, transformParameters.positionZ) or
                nil

            local rot = (transformParameters.rotationX and transformParameters.rotationY and transformParameters.rotationZ and transformParameters.rotationW) and
                Quaternion.__new(transformParameters.rotationX, transformParameters.rotationY, transformParameters.rotationZ, transformParameters.rotationW) or
                nil

            local scale = (transformParameters.scaleX and transformParameters.scaleY and transformParameters.scaleZ) and
                Vector3.__new(transformParameters.scaleX, transformParameters.scaleY, transformParameters.scaleZ) or
                nil

            return pos, rot, scale
        end
    }

    cytanb.SetConstEach(cytanb, {
        LogLevelOff = 0,
        LogLevelFatal = 100,
        LogLevelError = 200,
        LogLevelWarn = 300,
        LogLevelInfo = 400,
        LogLevelDebug = 500,
        LogLevelTrace = 600,
        LogLevelAll = 0x7FFFFFFF,
        ColorHueSamples = 10,
        ColorSaturationSamples = 4,
        ColorBrightnessSamples = 5,
        EscapeSequenceTag = '#__CYTANB',
        SolidusTag = '#__CYTANB_SOLIDUS',
        NegativeNumberTag = '#__CYTANB_NEGATIVE_NUMBER',
        ArrayNumberTag = '#__CYTANB_ARRAY_NUMBER',
        InstanceIDParameterName = '__CYTANB_INSTANCE_ID',
        MessageValueParameterName = '__CYTANB_MESSAGE_VALUE',
        TypeParameterName = '__CYTANB_TYPE',
        ColorTypeName = 'Color',
        Vector2TypeName = 'Vector2',
        Vector3TypeName = 'Vector3',
        Vector4TypeName = 'Vector4',
        QuaternionTypeName = 'Quaternion'
    })

    cytanb.SetConstEach(cytanb, {
        ColorMapSize = cytanb.ColorHueSamples * cytanb.ColorSaturationSamples * cytanb.ColorBrightnessSamples,
        FatalLogLevel = cytanb.LogLevelFatal,    -- @deprecated
        ErrorLogLevel = cytanb.LogLevelError,    -- @deprecated
        WarnLogLevel = cytanb.LogLevelWarn,      -- @deprecated
        InfoLogLevel = cytanb.LogLevelInfo,      -- @deprecated
        DebugLogLevel = cytanb.LogLevelDebug,    -- @deprecated
        TraceLogLevel = cytanb.LogLevelTrace     -- @deprecated
    })

    valueConversionMap = {
        [cytanb.ColorTypeName] = {compositionFieldNames = cytanb.ListToMap({'r', 'g', 'b', 'a'}), compositionFieldLength = 4, toTableFunc = cytanb.ColorToTable, fromTableFunc = cytanb.ColorFromTable},
        [cytanb.Vector2TypeName] = {compositionFieldNames = cytanb.ListToMap({'x', 'y'}), compositionFieldLength = 2, toTableFunc = cytanb.Vector2ToTable, fromTableFunc = cytanb.Vector2FromTable},
        [cytanb.Vector3TypeName] = {compositionFieldNames = cytanb.ListToMap({'x', 'y', 'z'}), compositionFieldLength = 3, toTableFunc = cytanb.Vector3ToTable, fromTableFunc = cytanb.Vector3FromTable},
        [cytanb.Vector4TypeName] = {compositionFieldNames = cytanb.ListToMap({'x', 'y', 'z', 'w'}), compositionFieldLength = 4, toTableFunc = cytanb.Vector4ToTable, fromTableFunc = cytanb.Vector4FromTable},
        [cytanb.QuaternionTypeName] = {compositionFieldNames = cytanb.ListToMap({'x', 'y', 'z', 'w'}), compositionFieldLength = 4, toTableFunc = cytanb.QuaternionToTable, fromTableFunc = cytanb.QuaternionFromTable}
    }

    -- タグ文字列の長い順にパターン配列をセットする
    escapeSequenceReplacementPatterns = {
        {tag = cytanb.NegativeNumberTag, pattern = '^' .. cytanb.NegativeNumberTag, replacement = ''},
        {tag = cytanb.ArrayNumberTag, pattern = '^' .. cytanb.ArrayNumberTag, replacement = ''},
        {tag = cytanb.SolidusTag, pattern = '^' .. cytanb.SolidusTag, replacement = '/'},
        {tag = cytanb.EscapeSequenceTag, pattern = '^' .. cytanb.EscapeSequenceTag .. cytanb.EscapeSequenceTag, replacement = cytanb.EscapeSequenceTag}
    }

    parameterValueReplacementMap = cytanb.ListToMap({cytanb.NegativeNumberTag, cytanb.ArrayNumberTag})

    logLevel = cytanb.LogLevelInfo
    logLevelStringMap = {
        [cytanb.LogLevelFatal] = 'FATAL',
        [cytanb.LogLevelError] = 'ERROR',
        [cytanb.LogLevelWarn] = 'WARN',
        [cytanb.LogLevelInfo] = 'INFO',
        [cytanb.LogLevelDebug] = 'DEBUG',
        [cytanb.LogLevelTrace] = 'TRACE'
    }

    package.loaded['cytanb'] = cytanb

    instanceID = vci.state.Get(InstanceIDStateName) or ''
    if instanceID == '' and vci.assets.IsMine then
        -- vci.state に ID が設定されていない場合は生成する。
        instanceID = tostring(cytanb.RandomUUID())
        vci.state.Set(InstanceIDStateName, instanceID)
    end

    return cytanb
end)()
