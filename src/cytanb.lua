----------------------------------------------------------------
--  Copyright (c) 2019 oO (https://github.com/oocytanb)
--  MIT Licensed
----------------------------------------------------------------

-- VCAS@1.7.0a 時点において、`cytanb.lua` は VCI の `require` に対応していません。

---@type cytanb @See `cytanb_annotations.lua`
local cytanb = (function ()
    math.randomseed(os.time() - os.clock() * 10000)

    --- インスタンス ID の状態変数名。
    local InstanceIDStateName = '__CYTANB_INSTANCE_ID'

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
                error('attempt to concatenate illegal values')
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
                    error('Cannot assign to read only field "' .. key .. '"')
                end
            end
        end
        rawset(table, key, v)
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

    cytanb = {
        InstanceID = function ()
            if instanceID == '' then
                instanceID = vci.state.Get(InstanceIDStateName) or ''
            end
            return instanceID
        end,

        SetConst = function (target, name, value)
            if type(target) ~= 'table' then
                error('Cannot set const to non-table target')
            end

            local curMeta = getmetatable(target)
            local meta = curMeta or {}
            local metaConstVariables = rawget(meta, ConstVariablesFieldName)
            if rawget(target, name) ~= nil then
                error('Non-const field "' .. name .. '" already exists')
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
                error('Invalid argument: capacity = ' .. tostring(capacity))
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

        DetectClicks = function (lastClickCount, lastTime, clickTiming)
            local count = lastClickCount or 0
            local timing = clickTiming or TimeSpan.FromMilliseconds(500)
            local now = vci.me.Time
            local result = (lastTime and now > lastTime + timing) and 1 or count + 1
            return result, now
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

        TableToSerializable = function (data, refTable)
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
                    serData[nk] = cytanb.TableToSerializable(v, refTable)
                end
            end

            refTable[data] = nil
            return serData
        end,

        TableFromSerializable = function (serData)
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
                    data[nk] = cytanb.TableFromSerializable(v)
                end
            end
            return data
        end,

        -- @deprecated use TableToSerializable
        TableToSerialiable = function (data, refTable)
            return cytanb.TableToSerializable(data, refTable)
        end,

        -- @deprecated use TableFromSerializable
        TableFromSerialiable = function (serData)
            return cytanb.TableFromSerializable(serData)
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
        MessageValueParameterName = '__CYTANB_MESSAGE_VALUE'
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
