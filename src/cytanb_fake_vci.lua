-- SPDX-License-Identifier: MIT
-- Copyright (c) 2019 oO (https://github.com/oocytanb)

-- [VCI](https://github.com/virtual-cast/VCI) 環境の簡易 Fake モジュール。
-- Unit test を行うための、補助モジュールとしての利用を目的としている。
-- 実環境を忠実にエミュレートするものではなく、挙動が異なる部分が多分にあるため、その点に留意して利用する必要がある。
-- (例えば、3D オブジェクトの物理演算は行われない、ネットワーク通信は行われずローカルのインメモリーで処理される、不完全な実装など)
-- **EXPERIMENTAL: 仮実装の実験的なモジュールであるため、多くの変更が加えられる可能性がある。**
--
-- 参考資料:
-- https://docs.unity3d.com/2018.4/Documentation/Manual/index.html
-- https://ja.wikipedia.org/wiki/%E5%9B%9B%E5%85%83%E6%95%B0
-- https://en.wikipedia.org/wiki/Quaternions_and_spatial_rotation
-- https://en.wikipedia.org/wiki/Euler_angles
-- https://www.euclideanspace.com/

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

    -- VCI の Lua API において、Vector や Quaternion の等値比較 `==` は、`Equals` メソッドによる判定を行っている可能性がある。
    -- Unity 上では、single float の精度に落ちた結果、各成分が等しくなるケースがある。
    -- この関数では、非ゼロのときは 1E-05 未満の差を、等しいとみなすことで、VCAS 上での実行結果に近づける。
    local LowAccuracyEquals = function(a, b)
        if a == 0 then
            return b == 0
        elseif b == 0 then
            return false
        else
            local d = a - b
            return d < 1E-05 and d > -1E-05
        end
    end

    --[[
    local CreateSoftImpactor = function (item, maxForceMagnitude)
        local AssertMaxForceMagnitude = function (forceMagnitude)
            if forceMagnitude < 0 then
                error('CreateSoftImpactor: Invalid argument: forceMagnitude < 0', 3)
            end
            return forceMagnitude
        end

        local maxMagnitude = AssertMaxForceMagnitude(maxForceMagnitude)
        local accf = Vector3.zero

        return {
            Reset = function ()
                accf = Vector3.zero
            end,

            GetMaxForceMagnitude = function ()
                return maxMagnitude
            end,

            SetMaxForceMagnitude = function (maxForceMagnitude)
                maxMagnitude = AssertMaxForceMagnitude(maxForceMagnitude)
            end,

            GetAccumulatedForce = function ()
                return accf
            end,

            AccumulateForce = function (force, deltaTime, fixedTimestep)
                local ds = deltaTime.TotalSeconds
                local fs = fixedTimestep.TotalSeconds
                if ds <= 0 or fs <= 0 then
                    return
                end

                accf = accf + ds / fs * force
            end,

            --- `updateAll` 関数の最後で、この関数を呼び出すこと。
            Update = function ()
                if accf == Vector3.zero then
                    return
                end

                if not item.IsMine then
                    -- 操作権が無い場合はリセットする。
                    accf = Vector3.zero
                    return
                end

                if maxMagnitude <= 0 then
                    return
                end

                local am = accf.magnitude
                local f
                if am <= maxMagnitude then
                    f = accf
                    accf = Vector3.zero
                else
                    -- 制限を超えている部分は、次以降のフレームに繰り越す
                    f = maxMagnitude / am * accf
                    accf = accf - f
                    -- cytanb.LogTrace('CreateSoftImpactor: on Update: accf.magnitude = ', accf.magnitude)
                end

                item.AddForce(f)
            end
        }
    end
    ]]

    local ModuleName = 'cytanb_fake_vci'
    local StringModuleName = 'string'
    local moonsharpAdditions = {_MOONSHARP = true, json = true}

    local currentVciName = ModuleName
    local stateMap = {}
    local studioSharedMap = {}
    local studioSharedCallbackMap = {}

    local messageCallbackMap = {}

    local fakeModule, Vector2, Vector3, Vector4, Quaternion, Matrix4x4, Color, vci

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
            return LowAccuracyEquals(op1.x, op2.x) and LowAccuracyEquals(op1.y, op2.y)
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
            return LowAccuracyEquals(op1.x, op2.x) and LowAccuracyEquals(op1.y, op2.y) and LowAccuracyEquals(op1.z, op2.z)
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
            return LowAccuracyEquals(op1.x, op2.x) and LowAccuracyEquals(op1.y, op2.y) and LowAccuracyEquals(op1.z, op2.z) and LowAccuracyEquals(op1.w, op2.w)
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

    local QuaternionMetatable
    QuaternionMetatable = {
        __mul = function (op1, op2)
            if getmetatable(op2) == Vector3Metatable then
                -- (quat * Quaternion.__new(vec3.x, vec3.y, vec3.z, 0)) * Quaternion.Inverse(quat)
                local qpx = op1.w * op2.x + op1.y * op2.z - op1.z * op2.y
                local qpy = op1.w * op2.y - op1.x * op2.z + op1.z * op2.x
                local qpz = op1.w * op2.z + op1.x * op2.y - op1.y * op2.x
                local qpw = - op1.x * op2.x - op1.y * op2.y - op1.z * op2.z

                return Vector3.__new(
                    qpw * - op1.x + qpx * op1.w + qpy * - op1.z - qpz * - op1.y,
                    qpw * - op1.y - qpx * - op1.z + qpy * op1.w + qpz * - op1.x,
                    qpw * - op1.z + qpx * - op1.y - qpy * - op1.x + qpz * op1.w
                )
            else
                return Quaternion.__new(
                    op1.w * op2.x + op1.x * op2.w + op1.y * op2.z - op1.z * op2.y,
                    op1.w * op2.y - op1.x * op2.z + op1.y * op2.w + op1.z * op2.x,
                    op1.w * op2.z + op1.x * op2.y - op1.y * op2.x + op1.z * op2.w,
                    op1.w * op2.w - op1.x * op2.x - op1.y * op2.y - op1.z * op2.z
                )
            end
        end,

        __eq = function (op1, op2)
            return LowAccuracyEquals(op1.x, op2.x) and LowAccuracyEquals(op1.y, op2.y) and LowAccuracyEquals(op1.z, op2.z) and LowAccuracyEquals(op1.w, op2.w)
        end,

        __index = function (table, key)
            if key == 'normalized' then
                return Quaternion.Normalize(table)
            elseif key == 'eulerAngles' then
                local quat = Quaternion.Normalize(table)
                local rx, ry, rz
                local m21 = 2 * (quat.y * quat.z - quat.x * quat.w)
                if math.abs(1 - math.abs(m21)) <= Quaternion.kEpsilon then
                    -- @todo ±90度の処理の見直し
                    local sign = m21 < 1e-2 and 1 or -1
                    rx = sign * math.pi * 0.5
                    ry = sign * math.atan2(2 * (quat.x * quat.y - quat.z * quat.w), 1 - 2 * (quat.y ^ 2 + quat.z ^ 2))
                    rz = 0
                else
                    rx = math.asin(- m21)
                    ry = math.atan2(2 * (quat.x * quat.z + quat.y * quat.w), 1 - 2 * (quat.x ^ 2 + quat.y ^ 2))
                    rz = math.atan2(2 * (quat.x * quat.y + quat.z * quat.w), 1 - 2 * (quat.x ^ 2 + quat.z ^ 2))
                end
                return Vector3.__new(math.deg(rx) % 360, math.deg(ry) % 360, math.deg(rz) % 360)
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

    local Matrix4x4IndexMap = {
        {'m00', 'm01', 'm02', 'm03'},
        {'m10', 'm11', 'm12', 'm13'},
        {'m20', 'm21', 'm22', 'm23'},
        {'m30', 'm31', 'm32', 'm33'}
    }

    local Matrix4x4Metatable
    Matrix4x4Metatable = {
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
            return LowAccuracyEquals(op1.r, op2.r) and LowAccuracyEquals(op1.g, op2.g) and LowAccuracyEquals(op1.b, op2.b) and LowAccuracyEquals(op1.a, op2.a)
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
            end,

            unicode = function (str, i, j)
                -- @TODO implement Unicode conversion
                return string.byte(str, i, j)
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
                            local im = 1.0 / m
                            self.x = self.x * im
                            self.y = self.y * im
                        end
                    end,

                    ToString = function (format)
                        -- format argument is not implemented
                        return string.format('(%.1f, %.1f)', self.x, self.y)
                    end,

                    GetHashCode = function ()
                        return NumberHashCode(self.x, NumberHashCode(self.y))
                    end,

                    -- sqrMagnitude フィールドと同等の機能。
                    SqrMagnitude = function ()
                        return self.x ^ 2 + self.y ^ 2
                    end
                }
                setmetatable(self, Vector2Metatable)
                return self
            end,

            Lerp = function (a, b, t)
                return Vector2.LerpUnclamped(a, b, cytanb.Clamp(t, 0, 1))
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
                return math.deg(math.acos(cytanb.Clamp(ip / scale, -1, 1)))
            end,

            Distance = function (a, b)
                return (a - b).magnitude
            end,

            Min = function (lhs, rhs)
                return Vector2.__new(math.min(lhs.x, rhs.x), math.min(lhs.y, rhs.y))
            end,

            Max = function (lhs, rhs)
                return Vector2.__new(math.max(lhs.x, rhs.x), math.max(lhs.y, rhs.y))
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
                            local im = 1.0 / m
                            self.x = self.x * im
                            self.y = self.y * im
                            self.z = self.z * im
                        end
                    end
                }
                setmetatable(self, Vector3Metatable)
                return self
            end,

            Slerp = function (a, b, t)
                return Vector3.SlerpUnclamped(a, b, math.max(0.0, math.min(t, 1.0)))
            end,

            -- 仮実装の状態。
            SlerpUnclamped = function (a, b, t)
                if t == 0.0 then
                    return Vector3.__new(a.x, a.y, a.z)
                elseif t == 1.0 or a == b then
                    return Vector3.__new(b.x, b.y, b.z)
                end

                local s = Vector3.Normalize(a)
                local e = Vector3.Normalize(b)
                local angle = math.acos(cytanb.Clamp(Vector3.Dot(s, e), -1, 1))
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

            -- 仮実装の状態。
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
                return Vector3.LerpUnclamped(a, b, cytanb.Clamp(t, 0, 1))
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
                return math.deg(math.acos(cytanb.Clamp(ip / scale, -1, 1)))
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
                            local im = 1.0 / m
                            self.x = self.x * im
                            self.y = self.y * im
                            self.z = self.z * im
                            self.w = self.w * im
                        end
                    end,

                    -- 同名の関数が static 関数としても実装されている。
                    -- sqrMagnitude フィールドと同等の機能。
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
            end

            -- VCAS@1.6.3c では非実装
            -- Scale = function (a, b)
            --     return b and Vector4.__new(a.x * b.x, a.y * b.y, a.z * b.z, a.w * b.w) or Vector4.__new(a.x ^ 2, a.y ^ 2, a.z ^ 2, a.w ^ 2)
            -- end
        },

        Quaternion = {
            __new = function (x, y, z, w)
                local argsSpecified = x and y and z and w
                local self
                self = {
                    x = argsSpecified and x or 0.0,
                    y = argsSpecified and y or 0.0,
                    z = argsSpecified and z or 0.0,
                    w = argsSpecified and w or 0.0,

                    ToString = function (format)
                        -- format argument is not implemented
                        return string.format('(%.1f, %.1f, %.1f, %.1f)', self.x, self.y, self.z, self.w)
                    end,

                    GetHashCode = function ()
                        return NumberHashCode(self.x, NumberHashCode(self.y, NumberHashCode(self.z, NumberHashCode(self.w))))
                    end,

                    Normalize = function ()
                        local m = math.sqrt(self.x ^ 2 + self.y ^ 2 + self.z ^ 2 + self.w ^ 2)
                        if math.abs(m) <= Quaternion.kEpsilon then
                            self.x = 0.0
                            self.y = 0.0
                            self.z = 0.0
                            self.w = 1.0
                        else
                            local im = 1.0 / m
                            self.x = self.x * im
                            self.y = self.y * im
                            self.z = self.z * im
                            self.w = self.w * im
                        end
                    end,

                    -- Warning message: Use Quaternion.eulerAngles instead. This function was deprecated because it uses radians instead of degrees.
                    ToEuler = function ()
                        return self.ToEulerAngles()
                    end,

                    -- Warning message: Use Quaternion.eulerAngles instead. This function was deprecated because it uses radians instead of degrees.
                    ToEulerAngles = function()
                        local v = self.eulerAngles
                        return Vector3.__new(math.rad(v.x >= 180 and v.x - 360 or v.x), math.rad(v.y >= 180 and v.y - 360 or v.y), math.rad(v.z >= 180 and v.z - 360 or v.z))
                    end
                }
                setmetatable(self, QuaternionMetatable)
                return self
            end,

            -- 仮実装の状態。
            FromToRotation = function (fromDirection, toDirection)
                -- @todo 計算方法の見直し
                local s = fromDirection.normalized
                local e = toDirection.normalized
                if s == e then
                    return Quaternion.identity
                end

                local cross = Vector3.Cross(s, e)
                if cross.sqrMagnitude <= Vector3.kEpsilonNormalSqrt then
                    return Quaternion.__new(1.0, 0.0, 0.0, 0.0)
                end

                local halfDot = 0.5 * Vector3.Dot(s, e)
                local ca = math.sqrt(0.5 + halfDot)
                local sa = math.sqrt(0.5 - halfDot)
                return Quaternion.__new(cross.x * sa, cross.y * sa, cross.z * sa, ca)
            end,

            Inverse = function (rotation)
                return Quaternion.__new(- rotation.x, - rotation.y, - rotation.z, rotation.w)
            end,

            Slerp = function (a, b, t)
                return Quaternion.SlerpUnclamped(a, b, cytanb.Clamp(t, 0, 1))
            end,

            -- 仮実装の状態。
            SlerpUnclamped = function (a, b, t)
                if t == 0.0 then
                    return Quaternion.__new(a.x, a.y, a.z, a.w)
                elseif t == 1.0 or a == b then
                    return Quaternion.__new(b.x, b.y, b.z, b.w)
                end

                local s = Quaternion.Normalize(a)
                local e = Quaternion.Normalize(b)
                local dot = cytanb.Clamp(Quaternion.Dot(s, e), -1, 1)
                if dot < 0 then
                    dot = - dot
                    e.x = - e.x
                    e.y = - e.y
                    e.z = - e.z
                    e.w = - e.w
                end

                -- @todo 特殊ケースの処理
                if 1.0 - dot <= Quaternion.kEpsilon then
                    local quat = Quaternion.LerpUnclamped(a, b, t)
                    quat.Normalize()
                    return quat
                end

                local angle = math.acos(dot)
                local angleT = angle * t
                local isa = 1 / math.sin(angle)
                local ratioS = math.sin(angle - angleT) * isa
                local ratioE = math.sin(angleT) * isa

                return Quaternion.__new(
                    s.x * ratioS + e.x * ratioE,
                    s.y * ratioS + e.y * ratioE,
                    s.z * ratioS + e.z * ratioE,
                    s.w * ratioS + e.w * ratioE
                )
            end,

            Lerp = function (a, b, t)
                return Quaternion.LerpUnclamped(a, b, cytanb.Clamp(t, 0, 1))
            end,

            LerpUnclamped = function (a, b, t)
                local quat = Quaternion.__new(
                    cytanb.LerpUnclamped(a.x, b.x, t),
                    cytanb.LerpUnclamped(a.y, b.y, t),
                    cytanb.LerpUnclamped(a.z, b.z, t),
                    cytanb.LerpUnclamped(a.w, b.w, t)
                )
                quat.Normalize()
                return quat
            end,

            AngleAxis = function (angle, axis)
                local vec = axis.normalized
                if vec.x == 0 and vec.y == 0 and vec.z == 0 then
                    return Quaternion.identity
                end
                local halfTheta = math.rad(angle * 0.5)
                local s = math.sin(halfTheta)
                local c = math.cos(halfTheta)
                return Quaternion.__new(vec.x * s, vec.y * s, vec.z * s, c)
            end,

            -- 仮実装の状態。
            LookRotation = function (forward, upwards)
                -- @todo 計算方法の見直し
                local fw = forward.normalized
                if fw.x == 0 and fw.y == 0 and fw.z == 0 then
                    return Quaternion.identity
                end

                local up = Vector3.Cross(upwards and upwards or Vector3.up, fw)
                up.Normalize()
                if up.x == 0 and up.y == 0 and up.z == 0 then
                    return Quaternion.identity
                end

                local rt = Vector3.Cross(fw, up)

                local m00 = up.x
                local m01 = up.y
                local m02 = up.z
                local m10 = rt.x
                local m11 = rt.y
                local m12 = rt.z
                local m20 = fw.x
                local m21 = fw.y
                local m22 = fw.z

                local ix = m00 - m11 - m22 + 1.0
                local iy = - m00 + m11 - m22 + 1.0
                local iz = - m00 - m11 + m22 + 1.0
                local iw = m00 + m11 + m22 + 1.0

                if ix < 0 and iy < 0 and iz < 0 and iw < 0 then
                    return Quaternion.identity
                end

                if ix > iy and ix > iz and ix > iw then
                    local qe2 = math.sqrt(ix)
                    local qe4 = 0.5 / qe2
                    return Quaternion.__new(
                        qe2 * 0.5,
                        (m01 + m10) * qe4,
                        (m20 + m02) * qe4,
                        (m12 - m21) * qe4
                    )
                elseif iy > iz and iy > iw then
                    local qe2 = math.sqrt(iy)
                    local qe4 = 0.5 / qe2
                    return Quaternion.__new(
                        (m01 + m10) * qe4,
                        qe2 * 0.5,
                        (m12 + m21) * qe4,
                        (m20 - m02) * qe4
                    )
                elseif iz > iw then
                    local qe2 = math.sqrt(iz)
                    local qe4 = 0.5 / qe2
                    return Quaternion.__new(
                        (m20 + m02) * qe4,
                        (m12 + m21) * qe4,
                        qe2 * 0.5,
                        (m01 - m10) * qe4
                    )
                else
                    local qe2 = math.sqrt(iw + 1.0)
                    local qe4 = 0.5 / qe2
                    return Quaternion.__new(
                        (m12 - m21) * qe4,
                        (m20 - m02) * qe4,
                        (m01 - m10) * qe4,
                        qe2 * 0.5
                    )
                end
            end,

            Dot = function (lhs, rhs)
                return lhs.x * rhs.x + lhs.y * rhs.y + lhs.z * rhs.z + lhs.w * rhs.w
            end,

            -- 仮実装の状態。
            Angle = function (a, b)
                -- @todo 特殊ケースの処理
                local ip = Quaternion.Dot(a, b)
                local scale = math.sqrt((a.x ^ 2 + a.y ^ 2 + a.z ^ 2 + a.w ^ 2) * (b.x ^ 2 + b.y ^ 2 + b.z ^ 2 + b.w ^ 2))
                if scale <= Quaternion.kEpsilon then
                    return 180
                end
                return 2 * math.deg(math.acos(math.abs(cytanb.Clamp(ip / scale, -1, 1))))
            end,

            Euler = function (x, y, z)
                local rx = math.rad(x)
                local ry = math.rad(y)
                local rz = math.rad(z)

                local cx = math.cos(rx * 0.5)
                local cy = math.cos(ry * 0.5)
                local cz = math.cos(rz * 0.5)

                local sx = math.sin(rx * 0.5)
                local sy = math.sin(ry * 0.5)
                local sz = math.sin(rz * 0.5)

                return Quaternion.__new(
                    sx * cy * cz + cx * sy * sz,
                    cx * sy * cz - sx * cy * sz,
                    cx * cy * sz - sx * sy * cz,
                    cx * cy * cz + sx * sy * sz
                )
            end,

            -- Lua は引数を参照で受け取ることができないようなので、そのまま実装することはできない。
            ToAngleAxis = function (angle, axis)
                error('!!NOT IMPLEMENTED!!')
            end,

            -- 仮実装の状態。
            RotateTowards = function (from, to, maxDegreesDelta)
                -- @todo 計算方法の見直し
                local angle = Quaternion.Angle(from, to)
                if math.abs(angle) <= Quaternion.kEpsilon then
                    return Quaternion.__new(from.x, from.y, from.z, from.w)
                end
                local t = math.min(1.0, maxDegreesDelta / angle)
                return Quaternion.SlerpUnclamped(from, to, t)
            end,

            Normalize = function (value)
                local quat = Quaternion.__new(value.x, value.y, value.z, value.w)
                quat.Normalize()
                return quat
            end
        },

        Matrix4x4 = {
            __new = function (column0, column1, column2, column3)
                -- local argsSpecified = column0 and column1 and column2 and column3
                local self
                self = {
                    set_Item = function (row, column, value)
                        local rowMap = Matrix4x4IndexMap[row + 1]
                        local key = rowMap and rowMap[column + 1] or nil
                        if key then
                            self[key] = value
                        else
                            error('Invalid index: ' .. tostring(row) .. ', ' .. tostring(column))
                        end
                    end
                }
                setmetatable(self, Matrix4x4Metatable)
                return self
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
                return Color.LerpUnclamped(a, b, cytanb.Clamp(t, 0, 1))
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

                VectorApproximatelyEquals = function (lhs, rhs)
                    return (lhs - rhs).sqrMagnitude < 1E-10
                end,

                QuaternionApproximatelyEquals = function (lhs, rhs)
                    local dot = Quaternion.Dot(lhs, rhs)
                    return dot < 1.0 + 1E-06 and dot > 1.0 - 1E-06
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
                    vci.fake.EmitRawMessage({type = 'vci', name = vciName, commentSource = ''}, messageName, value)
                end,

                EmitVciCommentMessage = function (userName, value, commentSource)
                    vci.fake.EmitRawMessage({type = 'comment', name = userName or '', commentSource = commentSource or ''}, 'comment', tostring(value))
                end,

                EmitVciNicoliveCommentMessage = function (userName, value)
                    vci.fake.EmitVciCommentMessage(userName, value, 'Nicolive')
                end,

                EmitVciTwitterCommentMessage = function (userName, value)
                    vci.fake.EmitVciCommentMessage(userName, value, 'Twitter')
                end,

                EmitVciShowroomCommentMessage = function (userName, value)
                    vci.fake.EmitVciCommentMessage(userName, value, 'Showroom')
                end,

                EmitVciNotificationMessage = function (userName, value)
                    vci.fake.EmitRawMessage({type = 'notification', name = userName or '', commentSource = ''}, 'notification', tostring(value))
                end,

                EmitVciJoinedNotificationMessage = function (userName)
                    vci.fake.EmitVciNotificationMessage(userName, 'joined')
                end,

                EmitVciLeftNotificationMessage = function (userName)
                    vci.fake.EmitVciNotificationMessage(userName, 'left')
                end,

                OffMessage = function (messageName, callback)
                    local cbMap = messageCallbackMap[messageName]
                    if cbMap and cbMap[callback] then
                        cbMap[callback] = nil
                    end
                end,

                ClearMessageCallbacks = function ()
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
        kEpsilon = 1E-05,
        kEpsilonNormalSqrt = 1E-15
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
        kEpsilon = 1E-05,
        kEpsilonNormalSqrt = 1E-15
    })

    Vector4 = fakeModule.Vector4
    cytanb.SetConstEach(Vector4, {
        zero = function() return Vector4.__new(0, 0, 0, 0) end,
        one = function() return Vector4.__new(1, 1, 1, 1) end,
        kEpsilon = 1E-05
    })

    Quaternion = fakeModule.Quaternion
    cytanb.SetConstEach(Quaternion, {
        identity = function() return Quaternion.__new(0, 0, 0, 1) end,
        kEpsilon = 1E-06
    })

    Matrix4x4 = fakeModule.Matrix4x4

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
