----------------------------------------------------------------
--  Copyright (c) 2019 oO (https://github.com/oocytanb)
--  MIT Licensed
----------------------------------------------------------------

-- [VCI](https://github.com/virtual-cast/VCI) 環境の簡易 Fake モジュール。
-- Unit test を行うための、補助モジュールとしての利用を目的としている。
-- 実環境を忠実にエミュレートするものではなく、挙動が異なる部分が多分にあるため、その点に留意して利用する必要がある。
-- (例えば、3D オブジェクトの物理演算は行われない、ネットワーク通信は行われずローカルのインメモリーで処理される、未実装機能など)
-- **EXPERIMENTAL: 実験的なモジュールであるため、多くの変更が加えられる可能性がある。**

return (function ()
    local dkjson = require('dkjson')

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

    local cytanb
    cytanb = {
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
            return a + (b - a) * t
        end
    }

    local NumberHashCode = function (num, carry)
        local result = bit32.band(carry ~= 0 and carry or 31, 0xFFFFFFFF)
        if num == 0 then
            result = bit32.band(31 * result, 0xFFFFFFFF)
        else
            local integerPart = math.floor(num)
            local fractionPart = num - integerPart

            for i = 1, 4 do
                result = bit32.band(31 * result + bit32.band(integerPart, 0xFFFFFFFF), 0xFFFFFFFF)
                integerPart = math.floor(integerPart / 0x100000000)
                if integerPart == 0 then
                    break
                end
            end

            if fractionPart ~= 0 then
                for i = 1, 5 do
                    local mf = fractionPart * 0x1000000
                    local mfInteger = math.floor(mf)
                    result = bit32.band(31 * result + bit32.band(mfInteger, 0xFFFFFFFF), 0xFFFFFFFF)
                    fractionPart = mf - mfInteger
                    if fractionPart == 0 then
                        break
                    end
                end
            end
        end
        return result
    end

    local ModuleName = 'cytanb_fake_vci'
    local StringModuleName = 'string'
    local moonsharpAdditions = {_MOONSHARP = true, json = true}

    local currentVciName = ModuleName
    local stateMap = {}
    local studioSharedMap = {}
    local studioSharedCallbackMap = {}

    local messageCallbackMap = {}

    local fakeModule, Vector2, Vector3, Vector4, Color, vci

    local Vector2IndexMap = {'x', 'y'}

    local Vector2Metatable
    Vector2Metatable = {
        __add = function (op1, op2)
            return Vector2.__new(op1.x + op2.x, op1.y + op2.y)
        end,

        __sub = function (op1, op2)
            return Vector2.__new(op1.x - op2.x, op1.y - op2.y)
        end,

        __unm = function (op)
            return Vector2.__new(- op.x, - op.y)
        end,

        __mul = function (op1, op2)
            local numType1 = type(op1) == 'number'
            local numType2 = type(op2) == 'number'
            if numType1 or numType2 then
                local vec, m
                if numType1 then
                    vec = op2
                    m = op1
                else
                    vec = op1
                    m = op2
                end
                return Vector2.__new(vec.x * m, vec.y * m)
            else
                return Vector2.__new(op1.x * op2.x, op1.y * op2.y)
            end
        end,

        __div = function (op1, op2)
            if type(op2) == 'number' then
                return Vector2.__new(op1.x / op2, op1.y / op2)
            else
                return Vector2.__new(op1.x / op2.x, op1.y / op2.y)
            end
        end,

        __eq = function (op1, op2)
            return op1.x == op2.x and op1.y == op2.y
        end,

        __index = function (table, key)
            if key == 'magnitude' then
                return math.sqrt(table.SqrMagnitude())
            elseif key == 'normalized' then
                local vec = Vector2.__new(table.x, table.y)
                vec.Normalize()
                return vec
            elseif key == 'sqrMagnitude' then
                return table.SqrMagnitude()
            else
                error('Cannot access field "' .. key .. '"')
            end
        end,

        __newindex = function (table, key, v)
            error('Cannot assign to field "' .. key .. '"')
        end,

        __tostring = function (value)
            return value.ToString()
        end
    }

    local Vector3IndexMap = {'x', 'y', 'z'}

    local Vector3Metatable
    Vector3Metatable = {
        __add = function (op1, op2)
            return Vector3.__new(op1.x + op2.x, op1.y + op2.y, op1.z + op2.z)
        end,

        __sub = function (op1, op2)
            return Vector3.__new(op1.x - op2.x, op1.y - op2.y, op1.z - op2.z)
        end,

        __unm = function (op)
            return Vector3.__new(- op.x, - op.y, - op.z)
        end,

        __mul = function (op1, op2)
            local vec, m
            if type(op1) == 'number'then
                vec = op2
                m = op1
            else
                vec = op1
                m = op2
            end
            return Vector3.__new(vec.x * m, vec.y * m, vec.z * m)
        end,

        __div = function (op1, op2)
            return Vector3.__new(op1.x / op2, op1.y / op2, op1.z / op2)
        end,

        __eq = function (op1, op2)
            return op1.x == op2.x and op1.y == op2.y and op1.z == op2.z
        end,

        __index = function (table, key)
            if key == 'magnitude' then
                return Vector3.Magnitude(table)
            elseif key == 'normalized' then
                return Vector3.Normalize(table)
            elseif key == 'sqrMagnitude' then
                return Vector3.SqrMagnitude(table)
            else
                error('Cannot access field "' .. key .. '"')
            end
        end,

        __newindex = function (table, key, v)
            error('Cannot assign to field "' .. key .. '"')
        end,

        __tostring = function (value)
            return value.ToString()
        end
    }

    local Vector4IndexMap = {'x', 'y', 'z', 'w'}

    local Vector4Metatable
    Vector4Metatable = {
        __add = function (op1, op2)
            return Vector4.__new(op1.x + op2.x, op1.y + op2.y, op1.z + op2.z, op1.w + op2.w)
        end,

        __sub = function (op1, op2)
            return Vector4.__new(op1.x - op2.x, op1.y - op2.y, op1.z - op2.z, op1.w - op2.w)
        end,

        -- VCAS@1.6.3c では非実装
        __unm = function (op)
            return Vector4.__new(- op.x, - op.y, - op.z, - op.w)
        end,

        __mul = function (op1, op2)
            local vec, m
            if type(op1) == 'number'then
                vec = op2
                m = op1
            else
                vec = op1
                m = op2
            end
            return Vector4.__new(vec.x * m, vec.y * m, vec.z * m, vec.w * m)
        end,

        __div = function (op1, op2)
            return Vector4.__new(op1.x / op2, op1.y / op2, op1.z / op2, op1.w / op2)
        end,

        __eq = function (op1, op2)
            return op1.x == op2.x and op1.y == op2.y and op1.z == op2.z and op1.w == op2.w
        end,

        __index = function (table, key)
            if key == 'magnitude' then
                return Vector4.Magnitude(table)
            elseif key == 'normalized' then
                return Vector4.Normalize(table)
            elseif key == 'sqrMagnitude' then
                return Vector4.SqrMagnitude(table)
            else
                error('Cannot access field "' .. key .. '"')
            end
        end,

        __newindex = function (table, key, v)
            error('Cannot assign to field "' .. key .. '"')
        end,

        __tostring = function (value)
            return value.ToString()
        end
    }

    local ColorMetatable = {
        __add = function (op1, op2)
            return Color.__new(op1.r + op2.r, op1.g + op2.g, op1.b + op2.b, op1.a + op2.a)
        end,

        __sub = function (op1, op2)
            return Color.__new(op1.r - op2.r, op1.g - op2.g, op1.b - op2.b, op1.a - op2.a)
        end,

        __mul = function (op1, op2)
            local numType1 = type(op1) == 'number'
            local numType2 = type(op2) == 'number'
            if numType1 or numType2 then
                local color, m
                if numType1 then
                    color = op2
                    m = op1
                else
                    color = op1
                    m = op2
                end
                return Color.__new(color.r * m, color.g * m, color.b * m, color.a * m)
            else
                return Color.__new(op1.r * op2.r, op1.g * op2.g, op1.b * op2.b, op1.a * op2.a)
            end
        end,

        __div = function (op1, op2)
            return Color.__new(op1.r / op2, op1.g / op2, op1.b / op2, op1.a / op2)
        end,

        __eq = function (op1, op2)
            return op1.r == op2.r and op1.g == op2.g and op1.b == op2.b and op1.a == op2.a
        end,

        __index = function (table, key)
            if key == 'gamma' then
                error('!!NOT IMPLEMENTED!!')
            elseif key == 'grayscale' then
                error('!!NOT IMPLEMENTED!!')
            elseif key == 'linear' then
                error('!!NOT IMPLEMENTED!!')
            elseif key == 'maxColorComponent' then
                return math.max(table.r, table.g, table.b)
            else
                error('Cannot access field "' .. key .. '"')
            end
        end,

        __newindex = function (table, key, v)
            error('Cannot assign to field "' .. key .. '"')
        end,

        __tostring = function (value)
            return value.ToString()
        end
    }

    fakeModule = {
        -- [MoonSharp](https://www.moonsharp.org/additions.html) の拡張。
        _MOONSHARP = {
            version = '2.0.0.0',
            luacompat = string.match(_VERSION or '', '(%d+(%.%d+))') or '',
            platform = 'limited.unity.dll.mono.clr4.aot',
            is_aot = true,
            is_unity = true,
            is_mono = true,
            is_clr4 = true,
            is_pcl = false,
            banner = 'cytanb_fake_vci | Copyright (c) 2019 oO (https://github.com/oocytanb) | MIT Licensed'
        },

        -- [MoonSharp](https://www.moonsharp.org/additions.html) の拡張。
        string = {
            contains = function (str1, str2)
                return string.find(str1, str2, 1, true) ~= nil
            end,

            startsWith = function (str1, str2)
                local len1 = string.len(str1)
                local len2 = string.len(str2)
                if len1 < len2 then
                    return false
                elseif len2 == 0 then
                    return true
                end

                return str2 == string.sub(str1, 1, len2)
            end,

            endsWith = function (str1, str2)
                local len1 = string.len(str1)
                local len2 = string.len(str2)
                if len1 < len2 then
                    return false
                elseif len2 == 0 then
                    return true
                end

                local i = string.find(str1, str2, - len2, true)
                return i ~= nil
            end
        },

        -- [MoonSharp](https://www.moonsharp.org/additions.html) の拡張。
        json = {
            parse = function (jsonString)
                return dkjson.decode(jsonString, 1, dkjson.null)
            end,

            serialize = function (table)
                local t = type(table)
                if t ~= 'table' then
                    error('Invalid type: ' .. t)
                end
                return dkjson.encode(table)
            end,

            isNull = function (val)
                return val == dkjson.null
            end,

            null = function ()
                return dkjson.null
            end
        },

        Vector2 = {
            __new = function (x, y)
                local argsSpecified = x and y
                local self
                self = {
                    x = argsSpecified and x or 0.0,
                    y = argsSpecified and y or 0.0,

                    set_Item = function (index, value)
                        local key = Vector2IndexMap[index + 1]
                        if key then
                            self[key] = value
                        else
                            error('Invalid index: ' .. tostring(index))
                        end
                    end,

                    Set = function (newX, newY)
                        self.x = newX or 0.0
                        self.y = newY or 0.0
                    end,

                    Normalize = function ()
                        local m = self.magnitude
                        if math.abs(m) <= Vector2.kEpsilon then
                            self.x = 0.0
                            self.y = 0.0
                        else
                            self.x = self.x / m
                            self.y = self.y / m
                        end
                    end,

                    ToString = function (format)
                        -- format argument is not implemented
                        return string.format('(%.1f, %.1f)', self.x, self.y)
                    end,

                    GetHashCode = function ()
                        return NumberHashCode(self.x, NumberHashCode(self.y))
                    end,

                    -- static 関数として実装すべきところが、非 static 関数として実装されている可能性がある。
                    -- sqrMagnitude フィールドと機能が重複している。
                    SqrMagnitude = function ()
                        return self.x ^ 2 + self.y ^ 2
                    end
                }
                setmetatable(self, Vector2Metatable)
                return self
            end,

            Lerp = function (a, b, t)
                return Vector2.__new(
                    cytanb.Lerp(a.x, b.x, t),
                    cytanb.Lerp(a.y, b.y, t)
                )
            end,

            LerpUnclamped = function (a, b, t)
                return Vector2.__new(
                    cytanb.LerpUnclamped(a.x, b.x, t),
                    cytanb.LerpUnclamped(a.y, b.y, t)
                )
            end,

            Scale = function (a, b)
                return b and Vector2.__new(a.x * b.x, a.y * b.y) or Vector2.__new(a.x ^ 2, a.y ^ 2)
            end,

            Dot = function (lhs, rhs)
                return lhs.x * rhs.x + lhs.y * rhs.y
            end,

            Angle = function (from, to)
                local ip = Vector2.Dot(from, to)
                local scale = from.magnitude * to.magnitude
                if scale <= Vector3.kEpsilon then
                    return 0
                end
                return math.deg(math.acos(ip / scale))
            end,

            Distance = function (a, b)
                return (a - b).magnitude
            end,

            __toVector2 = function (vector)
                return Vector2.__new(vector.x, vector.y)
            end,

            __toVector3 = function (vector)
                return Vector3.__new(vector.x, vector.y, 0.0)
            end
        },

        Vector3 = {
            __new = function (x, y, z)
                local argsSpecified = x and y
                local self
                self = {
                    x = argsSpecified and x or 0.0,
                    y = argsSpecified and y or 0.0,
                    z = z or 0.0,

                    set_Item = function (index, value)
                        local key = Vector3IndexMap[index + 1]
                        if key then
                            self[key] = value
                        else
                            error('Invalid index: ' .. tostring(index))
                        end
                    end,

                    Set = function (newX, newY, newZ)
                        self.x = newX or 0.0
                        self.y = newY or 0.0
                        self.z = newZ or 0.0
                    end,

                    ToString = function (format)
                        -- format argument is not implemented
                        return string.format('(%.1f, %.1f, %.1f)', self.x, self.y, self.z)
                    end,

                    GetHashCode = function ()
                        return NumberHashCode(self.x, NumberHashCode(self.y, NumberHashCode(self.z)))
                    end,

                    Normalize = function ()
                        local m = Vector3.Magnitude(self)
                        if math.abs(m) <= Vector3.kEpsilon then
                            self.x = 0.0
                            self.y = 0.0
                            self.z = 0.0
                        else
                            self.x = self.x / m
                            self.y = self.y / m
                            self.z = self.z / m
                        end
                    end
                }
                setmetatable(self, Vector3Metatable)
                return self
            end,

            Slerp = function (a, b, t)
                return Vector3.SlerpUnclamped(a, b, math.max(0.0, math.min(t, 1.0)))
            end,

            SlerpUnclamped = function (a, b, t)
                if t == 0.0 then
                    return a
                elseif t == 1.0 or a == b then
                    return b
                end

                local s = Vector3.Normalize(a)
                local e = Vector3.Normalize(b)
                local angle = math.acos(Vector3.Dot(s, e))
                local absAngle = math.abs(angle)
                if absAngle <= Vector3.kEpsilon then
                    return Vector3.LerpUnclamped(a, b, t)
                end

                if math.pi - absAngle <= Vector3.kEpsilon then
                    -- @todo 180度の処理を実装する
                    return Vector3.LerpUnclamped(a, b, t)
                end

                local mst = cytanb.LerpUnclamped(a.magnitude, b.magnitude, t) / math.sin(angle)
                return math.sin((1 - t) * angle) * mst * a.normalized + math.sin(t * angle) * mst * b.normalized
            end,

            OrthoNormalize = function (normal, tangent)
                normal.Normalize()
                if normal.x == 0.0 and normal.y == 0.0 and normal.z == 0.0 then
                    normal.x = 1.0
                end

                local ip = Vector3.Dot(normal, tangent)
                local scale = tangent.magnitude
                local a2, ip2
                if scale <= Vector3.kEpsilon or 1 - math.abs(ip / scale) <= Vector3.kEpsilon then
                    -- @todo 左手系座標系の処理
                    a2 = Vector3.__new(- normal.z, normal.x, - normal.y)
                    ip2 = Vector3.Dot(normal, a2)
                else
                    a2 = tangent
                    ip2 = ip
                end

                local v2 = a2 - ip2 * normal
                tangent.x = v2.x
                tangent.y = v2.y
                tangent.z = v2.z
                tangent.Normalize()
            end,

            RotateTowards = function (current, target, maxRadiansDelta, maxMagnitudeDelta)
                error('!!NOT IMPLEMENTED!!')
            end,

            Lerp = function (a, b, t)
                return Vector3.__new(
                    cytanb.Lerp(a.x, b.x, t),
                    cytanb.Lerp(a.y, b.y, t),
                    cytanb.Lerp(a.z, b.z, t)
                )
            end,

            LerpUnclamped = function (a, b, t)
                return Vector3.__new(
                    cytanb.LerpUnclamped(a.x, b.x, t),
                    cytanb.LerpUnclamped(a.y, b.y, t),
                    cytanb.LerpUnclamped(a.z, b.z, t)
                )
            end,

            -- VCAS@1.6.3b で削除された。
            MoveTowards = function (current, target, maxDistanceDelta)
                if maxDistanceDelta == 0 then
                    return current
                end

                local c = target - current
                if maxDistanceDelta >= c.magnitude then
                    return target
                else
                    return current + c.normalized * maxDistanceDelta
                end
            end,

            SmoothDamp = function (current, target, currentVelocity, smoothTime)
                error('!!NOT IMPLEMENTED!!')
            end,

            Scale = function (a, b)
                return b and Vector3.__new(a.x * b.x, a.y * b.y, a.z * b.z) or Vector3.__new(a.x ^ 2, a.y ^ 2, a.z ^ 2)
            end,

            Cross = function (lhs, rhs)
                return Vector3.__new(lhs.y * rhs.z - lhs.z * rhs.y, lhs.z * rhs.x - lhs.x * rhs.z, lhs.x * rhs.y - lhs.y * rhs.x)
            end,

            Normalize = function (value)
                local vec = Vector3.__new(value.x, value.y, value.z)
                vec.Normalize()
                return vec
            end,

            Dot = function (lhs, rhs)
                return lhs.x * rhs.x + lhs.y * rhs.y + lhs.z * rhs.z
            end,

            Project = function (vector, onNormal)
                local wn = Vector3.Normalize(onNormal)
                if wn.x == 0 and wn.y == 0 and wn.z == 0 then
                    return wn
                else
                    return Vector3.Dot(vector, wn) * wn
                end
            end,

            ProjectOnPlane = function (vector, planeNormal)
                return vector - Vector3.Project(vector, planeNormal)
            end,

            Angle = function (from, to)
                local ip = Vector3.Dot(from, to)
                local scale = from.magnitude * to.magnitude
                if scale <= Vector3.kEpsilon then
                    return 0
                end
                return math.deg(math.acos(ip / scale))
            end,

            Distance = function (a, b)
                return (a - b).magnitude
            end,

            ClampMagnitude = function (vector, maxLength)
                local len = vector.magnitude
                if len <= maxLength then
                    return vector
                elseif math.abs(maxLength) <= Vector3.kEpsilon then
                    return Vector3.zero
                else
                    return vector * (maxLength / len)
                end
            end,

            Magnitude = function (vector)
                return math.sqrt(Vector3.SqrMagnitude(vector))
            end,

            SqrMagnitude = function (vector)
                return vector.x ^ 2 + vector.y ^ 2 + vector.z ^ 2
            end,

            Min = function (lhs, rhs)
                return Vector3.__new(math.min(lhs.x, rhs.x), math.min(lhs.y, rhs.y), math.min(lhs.z, rhs.z))
            end,

            Max = function (lhs, rhs)
                return Vector3.__new(math.max(lhs.x, rhs.x), math.max(lhs.y, rhs.y), math.max(lhs.z, rhs.z))
            end
        },

        Vector4 = {
            __new = function (x, y, z, w)
                local argsSpecified = x and y and z
                local self
                self = {
                    x = argsSpecified and x or 0.0,
                    y = argsSpecified and y or 0.0,
                    z = argsSpecified and z or 0.0,
                    w = w or 0.0,

                    set_Item = function (index, value)
                        local key = Vector4IndexMap[index + 1]
                        if key then
                            self[key] = value
                        else
                            error('Invalid index: ' .. tostring(index))
                        end
                    end,

                    ToString = function (format)
                        -- format argument is not implemented
                        return string.format('(%.1f, %.1f, %.1f, %.1f)', self.x, self.y, self.z, self.w)
                    end,

                    GetHashCode = function ()
                        return NumberHashCode(self.x, NumberHashCode(self.y, NumberHashCode(self.z, NumberHashCode(self.w))))
                    end,

                    Normalize = function ()
                        local m = Vector4.Magnitude(self)
                        if math.abs(m) <= Vector4.kEpsilon then
                            self.x = 0.0
                            self.y = 0.0
                            self.z = 0.0
                            self.w = 0.0
                        else
                            self.x = self.x / m
                            self.y = self.y / m
                            self.z = self.z / m
                            self.w = self.w / m
                        end
                    end,

                    -- 同名の関数が static 関数として実装されている。
                    -- sqrMagnitude フィールドと機能が重複している。
                    SqrMagnitude = function ()
                        return Vector4.SqrMagnitude(self)
                    end
                }
                setmetatable(self, Vector4Metatable)
                return self
            end,

            LerpUnclamped = function (a, b, t)
                return Vector4.__new(
                    cytanb.LerpUnclamped(a.x, b.x, t),
                    cytanb.LerpUnclamped(a.y, b.y, t),
                    cytanb.LerpUnclamped(a.z, b.z, t),
                    cytanb.LerpUnclamped(a.w, b.w, t)
                )
            end,

            Normalize = function (value)
                local vec = Vector4.__new(value.x, value.y, value.z, value.w)
                vec.Normalize()
                return vec
            end,

            Dot = function (lhs, rhs)
                return lhs.x * rhs.x + lhs.y * rhs.y + lhs.z * rhs.z + lhs.w * rhs.w
            end,

            Magnitude = function (vector)
                return math.sqrt(Vector4.SqrMagnitude(vector))
            end,

            __toVector4 = function (vector)
                local z = rawget(vector, 'z')
                return Vector4.__new(vector.x, vector.y, z and z or 0.0, 0.0)
            end,

            __toVector3 = function (vector)
                return Vector3.__new(vector.x, vector.y, vector.z)
            end,

            __toVector2 = function (vector)
                return Vector2.__new(vector.x, vector.y)
            end,

            SqrMagnitude = function (vector)
                return vector.x ^ 2 + vector.y ^ 2 + vector.z ^ 2 + vector.w ^ 2
            end,

            -- VCAS@1.6.3c では非実装
            Scale = function (a, b)
                return b and Vector4.__new(a.x * b.x, a.y * b.y, a.z * b.z, a.w * b.w) or Vector4.__new(a.x ^ 2, a.y ^ 2, a.z ^ 2, a.w ^ 2)
            end
        },

        Color = {
            __new = function (r, g, b, a)
                local argsSpecified = r and g and b
                local self
                self = {
                    r = argsSpecified and r or 0.0,
                    g = argsSpecified and g or 0.0,
                    b = argsSpecified and b or 0.0,
                    a = argsSpecified and (a or 1.0) or 0.0,

                    ToString = function (format)
                        -- format argument is not implemented
                        return string.format('RGBA(%.3f, %.3f, %.3f, %.3f)', self.r, self.g, self.b, self.a)
                    end,

                    GetHashCode = function ()
                        return NumberHashCode(self.r, NumberHashCode(self.g, NumberHashCode(self.b, NumberHashCode(self.a))))
                    end,
                }
                setmetatable(self, ColorMetatable)
                return self
            end,

            HSVToRGB = function (H, S, V)
                local h = math.max(0.0, math.min(H, 1.0)) * 6.0
                local s = math.max(0.0, math.min(S, 1.0))
                local v = math.max(0.0, math.min(V, 1.0))
                local c = v * s
                local x = c * (1 - math.abs((h % 2) - 1))
                local m = v - c
                local r, g, b
                if h < 1 then
                    r = c
                    g = x
                    b = 0.0
                elseif h < 2 then
                    r = x
                    g = c
                    b = 0.0
                elseif h < 3 then
                    r = 0.0
                    g = c
                    b = x
                elseif h < 4 then
                    r = 0.0
                    g = x
                    b = c
                elseif h < 5 then
                    r = x
                    g = 0.0
                    b = c
                else
                    r = c
                    g = 0.0
                    b = x
                end
                return Color.__new(r + m, g + m, b + m)
            end,

            Lerp = function (a, b, t)
                return Color.__new(
                    cytanb.Lerp(a.r, b.r, t),
                    cytanb.Lerp(a.g, b.g, t),
                    cytanb.Lerp(a.b, b.b, t),
                    cytanb.Lerp(a.a, b.a, t)
                )
            end,

            LerpUnclamped = function (a, b, t)
                return Color.__new(
                    cytanb.LerpUnclamped(a.r, b.r, t),
                    cytanb.LerpUnclamped(a.g, b.g, t),
                    cytanb.LerpUnclamped(a.b, b.b, t),
                    cytanb.LerpUnclamped(a.a, b.a, t)
                )
            end,

            __toVector4 = function (color)
                return Vector4.__new(color.r, color.g, color.b, color.a)
            end,

            __toColor = function (vector)
                return Color.__new(vector.x, vector.y, vector.z, vector.w)
            end
        },

        -- [VirtualCast Official Wiki](https://virtualcast.jp/wiki/)
        vci = {
            assets = {},

            state = {
                Set = function (name, value)
                    local nv
                    local t = type(value)
                    if (t == 'number' or t == 'string' or t == 'boolean') then
                        nv = value
                    else
                        nv = nil
                    end
                    stateMap[name] = nv
                end,

                Get = function (name)
                    return stateMap[name]
                end,

                Add = function (name, value)
                    if type(value) == 'number' then
                        local curValue = stateMap[name]
                        if type(curValue) == 'number' then
                            stateMap[name] = curValue + value
                        else
                            stateMap[name] = value
                        end
                    end
                end
            },

            studio = {
                shared = {
                    Set = function (name, value)
                        local nv
                        local t = type(value)
                        if (t == 'number' or t == 'string' or t == 'boolean') then
                            nv = value
                        else
                            nv = nil
                        end

                        local changed = studioSharedMap[name] ~= nv
                        studioSharedMap[name] = nv
                        if changed then
                            local cbMap = studioSharedCallbackMap[name]
                            if cbMap then
                                for cb, v in pairs(cbMap) do
                                    cb(nv)
                                end
                            end
                        end
                    end,

                    Get = function (name)
                        return studioSharedMap[name]
                    end,

                    Add = function (name, value)
                        if type(value) == 'number' then
                            local curValue = studioSharedMap[name]
                            local nv
                            if type(curValue) == 'number' then
                                nv = curValue + value
                            else
                                nv = value
                            end

                            local changed = studioSharedMap[name] ~= nv
                            studioSharedMap[name] = nv
                            if changed then
                                local cbMap = studioSharedCallbackMap[name]
                                if cbMap then
                                    for cb, v in pairs(cbMap) do
                                        cb(nv)
                                    end
                                end
                            end
                        end
                    end,

                    Bind = function (name, callback)
                        if not studioSharedCallbackMap[name] then
                            studioSharedCallbackMap[name] = {}
                        end
                        studioSharedCallbackMap[name][callback] = true
                    end
                }
            },

            message = {
                On = function (messageName, callback)
                    if not messageCallbackMap[messageName] then
                        messageCallbackMap[messageName] = {}
                    end
                    messageCallbackMap[messageName][callback] = true
                end,

                Emit = function (messageName, ...)
                    if select('#', ...) < 1 then
                        -- value 引数が指定されない場合は、処理しない。
                        return
                    end

                    local value = ...
                    local nv
                    local t = type(value)
                    if (t == 'number' or t == 'string' or t == 'boolean') then
                        nv = value
                    elseif (t == 'nil' or t == 'table' or t == 'userdata') then
                        nv = nil
                    else
                        -- その他の型の場合は処理しない。
                        return
                    end

                    vci.fake.EmitVciMessage(currentVciName, messageName, nv)
                end
            },

            -- fake module
            fake = {
                Setup = function (target)
                    for k, v in pairs(fakeModule) do
                        if moonsharpAdditions[k] then
                            if target[k] == nil then
                                target[k] = v
                            end
                        elseif k ~= StringModuleName then
                            target[k] = v
                        end
                    end

                    for k, v in pairs(fakeModule[StringModuleName]) do
                        if target[StringModuleName][k] == nil then
                            target[StringModuleName][k] = v
                        end
                    end

                    package.loaded[ModuleName] = fakeModule
                end,

                Teardown = function (target)
                    for k, v in pairs(fakeModule) do
                        if k ~= StringModuleName and target[k] == v then
                            target[k] = nil
                        end
                    end

                    for k, v in pairs(fakeModule[StringModuleName]) do
                        if target[StringModuleName][k] == v then
                            target[StringModuleName][k] = nil
                        end
                    end

                    package.loaded[ModuleName] = nil
                end,

                Round = function (num, decimalPlaces)
                    if decimalPlaces then
                        local m = 10 ^ decimalPlaces
                        return math.floor(num * m + 0.5) / m
                    else
                        return math.floor(num + 0.5)
                    end
                end,

                RoundVector2 = function (vec, decimalPlaces)
                    return Vector2.__new(
                        vci.fake.Round(vec.x, decimalPlaces),
                        vci.fake.Round(vec.y, decimalPlaces)
                    )
                end,

                RoundVector3 = function (vec, decimalPlaces)
                    return Vector3.__new(
                        vci.fake.Round(vec.x, decimalPlaces),
                        vci.fake.Round(vec.y, decimalPlaces),
                        vci.fake.Round(vec.z, decimalPlaces)
                    )
                end,

                RoundVector4 = function (vec, decimalPlaces)
                    return Vector4.__new(
                        vci.fake.Round(vec.x, decimalPlaces),
                        vci.fake.Round(vec.y, decimalPlaces),
                        vci.fake.Round(vec.z, decimalPlaces),
                        vci.fake.Round(vec.w, decimalPlaces)
                    )
                end,

                RoundColor = function (color, decimalPlaces)
                    return Color.__new(
                        vci.fake.Round(color.r, decimalPlaces),
                        vci.fake.Round(color.g, decimalPlaces),
                        vci.fake.Round(color.b, decimalPlaces),
                        vci.fake.Round(color.a, decimalPlaces)
                    )
                end,

                SetVciName = function (name)
                    currentVciName = tostring(name)
                end,

                GetVciName = function ()
                    return currentVciName
                end,

                SetAssetsIsMine = function (mine)
                    cytanb.SetConst(vci.assets, 'IsMine', mine and true or nil)
                end,

                ClearState = function ()
                    stateMap = {}
                end,

                UnbindStudioShared = function (name, callback)
                    local cbMap = studioSharedCallbackMap[name]
                    if cbMap and cbMap[callback] then
                        cbMap[callback] = nil
                    end
                end,

                ClearStudioShared = function ()
                    studioSharedMap = {}
                    studioSharedCallbackMap = {}
                end,

                EmitRawMessage = function (sender, messageName, value)
                    local cbMap = messageCallbackMap[messageName]
                    if cbMap then
                        for cb, v in pairs(cbMap) do
                            cb(sender, messageName, value)
                        end
                    end
                end,

                EmitVciMessage = function (vciName, messageName, value)
                    vci.fake.EmitRawMessage({type = 'vci', name = vciName}, messageName, value)
                end,

                EmitCommentMessage = function (userName, value)
                    vci.fake.EmitRawMessage({type = 'comment', name = userName or ''}, 'comment', tostring(value))
                end,

                OffMessage = function (messageName, callback)
                    local cbMap = messageCallbackMap[messageName]
                    if cbMap and cbMap[callback] then
                        cbMap[callback] = nil
                    end
                end,

                ClearMessage = function ()
                    messageCallbackMap = {}
                end
            }
        }
    }

    Vector2 = fakeModule.Vector2
    cytanb.SetConstEach(Vector2, {
        zero = function() return Vector2.__new(0, 0) end,
        one = function() return Vector2.__new(1, 1) end,
        up = function() return Vector2.__new(0, 1) end,
        down = function() return Vector2.__new(0, -1) end,
        left = function() return Vector2.__new(-1, 0) end,
        right = function() return Vector2.__new(1, 0) end,
        kEpsilon = 9.99999974737875E-06,
        kEpsilonNormalSqrt = 1.00000000362749E-15
    })

    Vector3 = fakeModule.Vector3
    cytanb.SetConstEach(Vector3, {
        zero = function() return Vector3.__new(0, 0, 0) end,
        one = function() return Vector3.__new(1, 1, 1) end,
        forward = function() return Vector3.__new(0, 0, 1) end,
        back = function() return Vector3.__new(0, 0, -1) end,
        up = function() return Vector3.__new(0, 1, 0) end,
        down = function() return Vector3.__new(0, -1, 0) end,
        left = function() return Vector3.__new(-1, 0, 0) end,
        right = function() return Vector3.__new(1, 0, 0) end,
        kEpsilon = Vector2.kEpsilon,
        kEpsilonNormalSqrt = Vector2.kEpsilonNormalSqrt
    })

    Vector4 = fakeModule.Vector4
    cytanb.SetConstEach(Vector4, {
        zero = function() return Vector4.__new(0, 0, 0, 0) end,
        one = function() return Vector4.__new(1, 1, 1, 1) end,
        kEpsilon = Vector2.kEpsilon
    })

    Color = fakeModule.Color
    cytanb.SetConstEach(Color, {
        red = function() return Color.__new(1, 0, 0, 1) end,
        green = function() return Color.__new(0, 1, 0, 1) end,
        blue = function() return Color.__new(0, 0, 1, 1) end,
        white = function() return Color.__new(1, 1, 1, 1) end,
        black = function() return Color.__new(0, 0, 0, 1) end,
        yellow = function() return Color.__new(1, 235 / 255, 4 / 255, 1) end,
        cyan = function() return Color.__new(0, 1, 1, 1) end,
        magenta = function() return Color.__new(1, 0, 1, 1) end,
        gray = function() return Color.__new(0.5, 0.5, 0.5, 1) end,
        grey = function() return Color.__new(0.5, 0.5, 0.5, 1) end,
        clear = function() return Color.__new(0, 0, 0, 0) end
    })

    vci = fakeModule.vci

    vci.fake.SetAssetsIsMine(true)

    return fakeModule
end)()
