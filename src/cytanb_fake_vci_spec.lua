-- SPDX-License-Identifier: MIT
-- Copyright (c) 2019 oO (https://github.com/oocytanb)

describe('Test cytanb_fake_vci', function ()
    local RoundVector3 = function (vec, decimalPlaces)
        return Vector3.__new(
            vci.fake.Round(vec.x, decimalPlaces),
            vci.fake.Round(vec.y, decimalPlaces),
            vci.fake.Round(vec.z, decimalPlaces)
        )
    end

    local RoundQuaternion = function (vec, decimalPlaces)
        return Quaternion.__new(
            vci.fake.Round(vec.x, decimalPlaces),
            vci.fake.Round(vec.y, decimalPlaces),
            vci.fake.Round(vec.z, decimalPlaces),
            vci.fake.Round(vec.w, decimalPlaces)
        )
    end

    setup(function ()
        require('cytanb_fake_vci').vci.fake.Setup(_G)
    end)

    teardown(function ()
        vci.fake.Teardown(_G)
    end)

    it('_MOONSHARP', function ()
        assert.same('2.0.0.0', _MOONSHARP.version)
    end)

    it('string.contains', function ()
        assert.is_true(string.contains('abcdefg', 'ab'))
        assert.is_true(string.contains('abcdefg', 'cde'))
        assert.is_true(string.contains('abcdefg', 'fg'))
        assert.is_true(string.contains('abcdefg', ''))
        assert.is_false(string.contains('abcdefg', 'ag'))
        assert.is_false(string.contains('abcdefg', 'fgh'))
    end)

    it('string.startsWith', function ()
        assert.is_true(string.startsWith('abcdefg', ''))
        assert.is_true(string.startsWith('abcdefg', 'a'))
        assert.is_true(string.startsWith('abcdefg', 'abc'))
        assert.is_false(string.startsWith('abcdefg', 'bc'))
        assert.is_false(string.startsWith('abcdefg', 'abcdefgh'))
    end)

    it('string.endsWith', function ()
        assert.is_true(string.endsWith('abcdefg', ''))
        assert.is_true(string.endsWith('abcdefg', 'g'))
        assert.is_true(string.endsWith('abcdefg', 'efg'))
        assert.is_false(string.endsWith('abcdefg', 'ef'))
        assert.is_false(string.endsWith('abcdefg', 'zabcdefg'))
    end)

    it('json', function ()
        local table1 = {foo = "apple"}
        local table2 = {bar = 1234.5}
        local table3 = {baz = json.null()}
        local table4 = {qux = true, quux = table1}

        local jstr1 = json.serialize(table1)
        local jstr2 = json.serialize(table2)
        local jstr3 = json.serialize(table3)
        local jstr4 = json.serialize(table4)

        assert.is_true(json.isNull(json.null()))
        assert.is_false(json.isNull(nil))

        assert.are.same('{"foo":"apple"}', jstr1)
        assert.are.same('{"bar":1234.5}', jstr2)
        assert.are.same('{"baz":null}', jstr3)

        assert.are.same(table1, json.parse(jstr1))
        assert.are.same(table2, json.parse(jstr2))
        assert.are.same(table3, json.parse(jstr3))
        assert.are.same(table4, json.parse(jstr4))
    end)

    it('Vector2', function ()
        local vOne = Vector2.one
        vOne.x = 0.5
        vOne.y = 0.75
        assert.are.equal(Vector2.__new(0.5, 0.75), vOne)
        assert.are.equal(Vector2.__new(1, 1), Vector2.one)

        assert.is_true(Vector2.kEpsilon <= 1E-05)
        assert.are_not.equal(0, 0 + Vector2.kEpsilon)
        assert.are_not.equal(0, 0 - Vector2.kEpsilon)
        assert.are.equal(0, math.floor(Vector2.kEpsilon * 10000) / 10000)
        assert.are.equal(0, math.floor(Vector2.kEpsilonNormalSqrt * 100000000) / 100000000)

        assert.are.equal(Vector2.__new(1, 1), Vector2.__new(1 + 1e-8, 1))
        assert.are_not.equal(Vector2.__new(1, 0), Vector2.__new(1, 1e-8))
        assert.are_not.equal(Vector2.__new(0, 0), Vector2.__new(1e-9, 0))

        assert.are.equal('(0.0, -1.0)', tostring(Vector2.down))
        assert.are.equal(Vector2.__new(0, -1), Vector2.down)
        assert.are.equal(Vector2.__new(-1, 0), Vector2.left)
        assert.are.equal(Vector2.__new(1, 0), Vector2.right)
        assert.are.equal(Vector2.__new(0, 1), Vector2.up)

        assert.are.equal(Vector2.zero, Vector2.__new())
        assert.are.equal(Vector2.zero, Vector2.__new(500))

        assert.are.equal(Vector2.__new(3.0, 4.0), Vector2.__toVector2(Vector3.__new(3, 4, 5)))
        assert.are.equal(Vector3.__new(30.0, 40.0, 0.0), Vector2.__toVector3(Vector2.__new(30, 40)))

        local v12 = Vector2.__new(0, 0)
        v12.Set(120, 240)
        assert.are.equal(Vector2.__new(120, 240), v12)

        local v1 = Vector2.__new(10, 200)
        v1.set_Item(0, -0.5)
        v1.set_Item(1, 987)
        assert.are.equal(Vector2.__new(-0.5, 987), v1)

        local v2 = Vector2.__new(3, 5)
        assert.are.equal(5.83095, vci.fake.Round(v2.magnitude, 5))
        assert.are.equal(34, v2.sqrMagnitude)
        assert.are.equal(34, v2.SqrMagnitude())
        assert.are.equal(v2.magnitude, math.sqrt(v2.sqrMagnitude))
        assert.are.equal(v2.magnitude, Vector2.__new(-3, -5).magnitude)
        assert.are.equal(0, Vector2.zero.magnitude)

        assert.are.equal('(0.5, 0.9)', tostring(v2.normalized))
        assert.are.equal(Vector2.__new(0.51449579000473, 0.857492983341217), v2.normalized)
        local v3 = Vector2.__new(3, 5)
        v3.Normalize()
        assert.are.equal(v2.normalized, v3)
        assert.are.equal(Vector2.__new(-0.51449579000473, -0.857492983341217), Vector2.__new(-3, -5).normalized)
        assert.are.equal(Vector2.zero, Vector2.__new(Vector2.kEpsilon, -Vector2.kEpsilonNormalSqrt).normalized)
        assert.are.equal(Vector2.zero, Vector2.zero.normalized)

        assert.are.equal(Vector2.__new(3.0, 5.0), Vector2.__new(1, 2) + Vector2.__new(2, 3))
        assert.are.equal(Vector2.__new(-1.0, -1.0), Vector2.__new(1, 2) - Vector2.__new(2, 3))
        assert.are.equal(Vector2.__new(2.0, 6.0), Vector2.__new(1, 2) * Vector2.__new(2, 3))
        assert.are.equal(Vector2.__new(2.0, 6.0), Vector2.Scale(Vector2.__new(1, 2), Vector2.__new(2, 3)))
        assert.are.equal(Vector2.__new(5.0, 10.0), Vector2.__new(1, 2) * 5)
        assert.are.equal(Vector2.__new(-5.0, -10.0), -5 * Vector2.__new(1, 2))
        assert.are.equal(Vector2.__new(0.5, 0.666666686534882), Vector2.__new(1, 2) / Vector2.__new(2, 3))
        assert.are.equal(Vector2.__new(0.2, 0.4), Vector2.__new(1, 2) / 5)
        assert.are.equal(Vector2.__new(-3, 5), - Vector2.__new(3, -5))

        assert.are.equal(2.82843, vci.fake.Round(Vector2.Distance(Vector2.__new(1, 2), Vector2.__new(3, 4)), 5))
        assert.are.equal(11, Vector2.Dot(Vector2.__new(1, 2), Vector2.__new(3, 4)))

        assert.are.equal(Vector2.__new(4.0, 2.0), Vector2.Lerp(Vector2.__new(4, 2), Vector2.__new(-1, -2), -0.5))
        assert.are.equal(Vector2.__new(4.0, 2.0), Vector2.Lerp(Vector2.__new(4, 2), Vector2.__new(-1, -2), -0))
        assert.are.equal(Vector2.__new(2.75, 1.0), Vector2.Lerp(Vector2.__new(4, 2), Vector2.__new(-1, -2), 0.25))
        assert.are.equal(Vector2.__new(0.25, -1.0), Vector2.Lerp(Vector2.__new(4, 2), Vector2.__new(-1, -2), 0.75))
        assert.are.equal(Vector2.__new(-1.0, -2.0), Vector2.Lerp(Vector2.__new(4, 2), Vector2.__new(-1, -2), 1))
        assert.are.equal(Vector2.__new(-1.0, -2.0), Vector2.Lerp(Vector2.__new(4, 2), Vector2.__new(-1, -2), 1.5))

        assert.are.equal(Vector2.__new(6.5, 4.0), Vector2.LerpUnclamped(Vector2.__new(4, 2), Vector2.__new(-1, -2), -0.5))
        assert.are.equal(Vector2.__new(4.0, 2.0), Vector2.LerpUnclamped(Vector2.__new(4, 2), Vector2.__new(-1, -2), -0))
        assert.are.equal(Vector2.__new(2.75, 1.0), Vector2.LerpUnclamped(Vector2.__new(4, 2), Vector2.__new(-1, -2), 0.25))
        assert.are.equal(Vector2.__new(0.25, -1.0), Vector2.LerpUnclamped(Vector2.__new(4, 2), Vector2.__new(-1, -2), 0.75))
        assert.are.equal(Vector2.__new(-1.0, -2.0), Vector2.LerpUnclamped(Vector2.__new(4, 2), Vector2.__new(-1, -2), 1))
        assert.are.equal(Vector2.__new(-3.5, -4.0), Vector2.LerpUnclamped(Vector2.__new(4, 2), Vector2.__new(-1, -2), 1.5))

        assert.are.equal(Vector2.__new(1, 2), Vector2.Min(Vector2.__new(1, 3), Vector2.__new(4, 2)))
        assert.are.equal(Vector2.__new(-4, -3), Vector2.Min(Vector2.__new(-1, -3), Vector2.__new(-4, 2)))

        assert.are.equal(Vector2.__new(4, 3), Vector2.Max(Vector2.__new(1, 3), Vector2.__new(4, 2)))
        assert.are.equal(Vector2.__new(-1, 2), Vector2.Max(Vector2.__new(-1, -3), Vector2.__new(-4, 2)))

        local angleTargets = {
            [{2, 0}] = 0,
            [{2, 1}] = 26.56505,
            [{0, 2}] = 90,
            [{-1, 2}] = 116.56505,
            [{-2, 0}] = 180,
            [{-2, -1}] = 153.43495,
            [{0, -2}] = 90,
            [{1, -2}] = 63.43495
        }

        local angleMap = {}
        local angleBase = Vector2.__new(4, 0)
        local angleConflictCount = 0

        for iv, angle in pairs(angleTargets) do
            local vec = Vector2.__new(iv[1], iv[2])
            assert.are.equal(angle, vci.fake.Round(Vector2.Angle(angleBase, vec), 5))
            local hashCode = vec.GetHashCode()
            if angleMap[hashCode] then
                angleConflictCount = angleConflictCount + 1
            else
                angleMap[hashCode] = vec
            end
        end
        assert.are.equal(0, angleConflictCount)
    end)

    it('Vector3', function ()
        local vForward = Vector3.forward
        vForward.x = 0.5
        vForward.y = 0.75
        assert.are.equal(Vector3.__new(0.5, 0.75, 1), vForward)
        assert.are.equal(Vector3.__new(0, 0, 1), Vector3.forward)

        assert.is_true(Vector3.kEpsilon <= 1E-05)
        assert.is_true(Vector3.kEpsilonNormalSqrt < Vector3.kEpsilon)

        assert.are.equal(Vector3.__new(0, 0, -1), Vector3.back)
        assert.are.equal('(0.0, -1.0, 0.0)', tostring(Vector3.down))
        assert.are.equal(Vector3.__new(0, -1, 0), Vector3.down)
        assert.are.equal(Vector3.__new(0, 0, 1), Vector3.forward)
        assert.are.equal(Vector3.__new(-1, 0, 0), Vector3.left)
        assert.are.equal(Vector3.__new(1, 1, 1), Vector3.one)
        assert.are.equal(Vector3.__new(1, 0, 0), Vector3.right)
        assert.are.equal(Vector3.__new(0, 1, 0), Vector3.up)

        assert.are.equal(Vector3.zero, Vector3.__new())
        assert.are.equal(Vector3.zero, Vector3.__new(500))
        assert.are.equal(Vector3.__new(500, 600, 0), Vector3.__new(500, 600))

        local v12 = Vector3.__new(0, 0, 0)
        v12.Set(120, 240, 360)
        assert.are.equal(Vector3.__new(120, 240, 360), v12)

        local v1 = Vector3.__new(10, 200, 3000)
        v1.set_Item(0, -0.5)
        v1.set_Item(1, 987)
        v1.set_Item(2, 6.5)
        assert.are.equal(Vector3.__new(-0.5, 987, 6.5), v1)

        local v2 = Vector3.__new(3, 4, 5)
        assert.are.equal(7.07107, vci.fake.Round(v2.magnitude, 5))
        assert.are.equal(50, v2.sqrMagnitude)
        assert.are.equal(50, Vector3.SqrMagnitude(v2))
        assert.are.equal(Vector3.Magnitude(v2), math.sqrt(v2.sqrMagnitude))
        assert.are.equal(v2.magnitude, Vector3.__new(-3, -4, -5).magnitude)
        assert.are.equal(0, Vector3.zero.magnitude)

        assert.are.equal('(0.4, 0.6, 0.7)', tostring(v2.normalized))
        assert.are.equal(Vector3.__new(0.424264073371887, 0.565685451030731, 0.70710676908493), v2.normalized)
        local v3 = Vector3.__new(5, 12, 13)
        v3.Normalize()
        assert.are.equal(Vector3.__new (0.271964132785797, 0.6527139544487, 0.70710676908493), v3)
        assert.are.equal(v3, Vector3.Normalize(Vector3.__new(5, 12, 13)))
        assert.are.equal(Vector3.__new(-0.271964132785797, -0.6527139544487, -0.70710676908493), Vector3.__new(-5, -12, -13).normalized)
        assert.are.equal(Vector3.zero, Vector3.__new(Vector3.kEpsilon, -Vector3.kEpsilonNormalSqrt).normalized)
        assert.are.equal(Vector3.zero, Vector3.zero.normalized)

        assert.are.equal(Vector3.__new(1, 1, 0), Vector3.__new(1 + 1e-8, 1 - 1e-8, 0))
        assert.are_not.equal(Vector3.__new(1, 1, 0), Vector3.__new(1 + 1e-8, 1 - 1e-8, 1e-8))
        assert.are_not.equal(Vector3.__new(0, 0, 0), Vector3.__new(1e-8, 0, 0))
        assert.are_not.equal(Vector3.__new(4.4408920985006261617e-16, 3, -2), Vector3.__new(0, 3, -2))

        assert.are.equal(Vector3.__new(11.0, 19.0, 22.0), Vector3.__new(3, 4, 5) + Vector3.__new(8, 15, 17))
        assert.are.equal(Vector3.__new(-5.0, -11.0, -12.0), Vector3.__new(3, 4, 5) - Vector3.__new(8, 15, 17))
        assert.are.equal(Vector3.__new(24.0, 60.0, 85.0), Vector3.Scale(Vector3.__new(3, 4, 5), Vector3.__new(8, 15, 17)))
        assert.are.equal(Vector3.__new(15.0, 20.0, 25.0), Vector3.__new(3, 4, 5) * 5)
        assert.are.equal(Vector3.__new(-15.0, -20.0, -25.0), -5 * Vector3.__new(3, 4, 5))
        assert.are.equal(Vector3.__new(0.6, 0.8, 1.0), Vector3.__new(3, 4, 5) / 5)
        assert.are.equal(Vector3.__new(-3, 0, 5), - Vector3.__new(3, 0, -5))

        assert.are.equal(17.02939, vci.fake.Round(Vector3.Distance(Vector3.__new(3, 4, 5), Vector3.__new(8, 15, 17)), 5))

        assert.are.equal(169, Vector3.Dot(Vector3.__new(3, 4, 5), Vector3.__new(8, 15, 17)))

        assert.are.equal(Vector3.__new(3.0, 4.0, -5.0), Vector3.Lerp(Vector3.__new(3, 4, -5), Vector3.__new(8, -15, -17), -0.5))
        assert.are.equal(Vector3.__new(3.0, 4.0, -5.0), Vector3.Lerp(Vector3.__new(3, 4, -5), Vector3.__new(8, -15, -17), -0))
        assert.are.equal(Vector3.__new(4.25, -0.75, -8.0), Vector3.Lerp(Vector3.__new(3, 4, -5), Vector3.__new(8, -15, -17), 0.25))
        assert.are.equal(Vector3.__new(6.75, -10.25, -14.0), Vector3.Lerp(Vector3.__new(3, 4, -5), Vector3.__new(8, -15, -17), 0.75))
        assert.are.equal(Vector3.__new(8.0, -15.0, -17.0), Vector3.Lerp(Vector3.__new(3, 4, -5), Vector3.__new(8, -15, -17), 1))
        assert.are.equal(Vector3.__new(8.0, -15.0, -17.0), Vector3.Lerp(Vector3.__new(3, 4, -5), Vector3.__new(8, -15, -17), 1.5))

        assert.are.equal(Vector3.__new(0.5, 13.5, 1.0), Vector3.LerpUnclamped(Vector3.__new(3, 4, -5), Vector3.__new(8, -15, -17), -0.5))
        assert.are.equal(Vector3.__new(3.0, 4.0, -5.0), Vector3.LerpUnclamped(Vector3.__new(3, 4, -5), Vector3.__new(8, -15, -17), -0))
        assert.are.equal(Vector3.__new(4.25, -0.75, -8.0), Vector3.LerpUnclamped(Vector3.__new(3, 4, -5), Vector3.__new(8, -15, -17), 0.25))
        assert.are.equal(Vector3.__new(6.75, -10.25, -14.0), Vector3.LerpUnclamped(Vector3.__new(3, 4, -5), Vector3.__new(8, -15, -17), 0.75))
        assert.are.equal(Vector3.__new(8.0, -15.0, -17.0), Vector3.LerpUnclamped(Vector3.__new(3, 4, -5), Vector3.__new(8, -15, -17), 1))
        assert.are.equal(Vector3.__new(10.5, -24.5, -23.0), Vector3.LerpUnclamped(Vector3.__new(3, 4, -5), Vector3.__new(8, -15, -17), 1.5))

        assert.are.equal(Vector3.__new(3.0, 4.0, -5.0), Vector3.Slerp(Vector3.__new(3, 4, -5), Vector3.__new(8, -15, -17), -0.5))
        assert.are.equal(Vector3.__new(3.0, 4.0, -5.0), Vector3.Slerp(Vector3.__new(3, 4, -5), Vector3.__new(8, -15, -17), -0))
        assert.are.equal(Vector3.__new(5.33822870254517, 3.15452098846436, -9.46320724487305), Vector3.Slerp(Vector3.__new(3, 4, -5), Vector3.__new(8, -15, -17), 0.25))
        assert.are.equal(Vector3.__new(7.33673048019409, -0.564363121986389, -13.705979347229), Vector3.Slerp(Vector3.__new(3, 4, -5), Vector3.__new(8, -15, -17), 0.5))
        assert.are.equal(Vector3.__new(8.38769912719727, -6.88422679901123, -16.5606155395508), Vector3.Slerp(Vector3.__new(3, 4, -5), Vector3.__new(8, -15, -17), 0.75))
        assert.are.equal(Vector3.__new(8.35148143768311, -11.6094493865967, -17.1683864593506), Vector3.Slerp(Vector3.__new(3, 4, -5), Vector3.__new(8, -15, -17), 0.9))
        assert.are.equal(Vector3.__new(8.0, -15.0, -17.0), Vector3.Slerp(Vector3.__new(3, 4, -5), Vector3.__new(8, -15, -17), 1))
        assert.are.equal(Vector3.__new(8.0, -15.0, -17.0), Vector3.Slerp(Vector3.__new(3, 4, -5), Vector3.__new(8, -15, -17), 1.5))
        --assert.are.equal(Vector3.__new(0, 0, -2), Vector3.Slerp(Vector3.__new(2, 0, 0), Vector3.__new(-2, 0, 0), 0.5))
        --assert.are.equal(Vector3.__new(-1.41421353816986, 0, -1.41421353816986), Vector3.Slerp(Vector3.__new(2, 0, 0), Vector3.__new(-2, 0, 0), 0.75))
        assert.are.equal(Vector3.__new(3.5, 0, 0), Vector3.Slerp(Vector3.__new(2, 0, 0), Vector3.__new(4, 0, 0), 0.75))

        assert.are.equal(Vector3.__new(-0.296107739210129, -1.33541643619537, 0.359140545129776), Vector3.SlerpUnclamped(Vector3.__new(3, 4, -5), Vector3.__new(8, -15, -17), -0.5))
        assert.are.equal(Vector3.__new(3.0, 4.0, -5.0), Vector3.SlerpUnclamped(Vector3.__new(3, 4, -5), Vector3.__new(8, -15, -17), -0))
        assert.are.equal(Vector3.__new (5.33822870254517, 3.15452098846436, -9.46320724487305), Vector3.SlerpUnclamped(Vector3.__new(3, 4, -5), Vector3.__new(8, -15, -17), 0.25))
        assert.are.equal(Vector3.__new(8.0, -15.0, -17.0), Vector3.SlerpUnclamped(Vector3.__new(3, 4, -5), Vector3.__new(8, -15, -17), 1))
        assert.are.equal(Vector3.__new(2.03282833099365, -31.3948421478271, -8.26023197174072), Vector3.SlerpUnclamped(Vector3.__new(3, 4, -5), Vector3.__new(8, -15, -17), 1.5))

        local v103 = Vector3.zero
        local v103t = Vector3.zero
        Vector3.OrthoNormalize(v103, v103t)
        assert.are.equal(Vector3.__new(1, 0, 0), v103)
        assert.are.equal(Vector3.__new(0, 1, 0), v103t)
        assert.are.equal(0, vci.fake.Round(Vector3.Dot(v103, v103t), 5))

        local v104 = Vector3.left
        local v104t = Vector3.zero
        Vector3.OrthoNormalize(v104, v104t)
        assert.are.equal(Vector3.__new(0, -1, 0), v104t)
        assert.are.equal(0, vci.fake.Round(Vector3.Dot(v104, v104t), 5))

        local v105 = Vector3.right
        local v105t = Vector3.zero
        Vector3.OrthoNormalize(v105, v105t)
        assert.are.equal(Vector3.__new(0, 1, 0), v105t)
        assert.are.equal(0, vci.fake.Round(Vector3.Dot(v105, v105t), 5))

        local v106 = Vector3.up
        local v106t = Vector3.zero
        Vector3.OrthoNormalize(v106, v106t)
        -- assert.are.equal(Vector3.__new(-1, 0, 0), v106t)
        assert.are.equal(0, vci.fake.Round(Vector3.Dot(v106, v106t), 5))

        local v107 = Vector3.down
        local v107t = Vector3.zero
        Vector3.OrthoNormalize(v107, v107t)
        -- assert.are.equal(Vector3.__new(1, 0, 0), v107t)
        assert.are.equal(0, vci.fake.Round(Vector3.Dot(v107, v107t), 5))

        local v108 = Vector3.forward
        local v108t = Vector3.zero
        Vector3.OrthoNormalize(v108, v108t)
        -- assert.are.equal(Vector3.__new(0, -1, 0), v108t)
        assert.are.equal(0, vci.fake.Round(Vector3.Dot(v108, v108t), 5))

        local v109 = Vector3.back
        local v109t = Vector3.zero
        Vector3.OrthoNormalize(v109, v109t)
        -- assert.are.equal(Vector3.__new(0, 1, 0), v108t)
        assert.are.equal(0, vci.fake.Round(Vector3.Dot(v109, v109t), 5))

        local v110 = Vector3.__new(1, 1, 0)
        local v110t = Vector3.zero
        Vector3.OrthoNormalize(v110, v110t)
        -- assert.are.equal(Vector3.__new(-0.707106828689575, 0.707106828689575, 0), v110t)
        assert.are.equal(0, vci.fake.Round(Vector3.Dot(v110, v110t), 5))

        local v111 = Vector3.__new(0, 1, 1)
        local v111t = Vector3.zero
        Vector3.OrthoNormalize(v111, v111t)
        -- assert.are.equal(Vector3.__new(-1, 0, 0), v111t)
        assert.are.equal(0, vci.fake.Round(Vector3.Dot(v111, v111t), 5))

        local v112 = Vector3.__new(1, 0, 1)
        local v112t = Vector3.zero
        Vector3.OrthoNormalize(v112, v112t)
        -- assert.are.equal(Vector3.__new(0, 1, 0), v112t)
        assert.are.equal(0, vci.fake.Round(Vector3.Dot(v112, v112t), 5))

        local v113 = Vector3.__new(1, 1, 1)
        local v113t = Vector3.zero
        Vector3.OrthoNormalize(v113, v113t)
        -- assert.are.equal(Vector3.__new(-0.70711, 0.70711, 0), v113t)
        assert.are.equal(0, vci.fake.Round(Vector3.Dot(v113, v113t), 5))

        local v150 = Vector3.__new(4, 0, 0)
        local v151 = Vector3.__new(0, 2, 0)
        Vector3.OrthoNormalize(v150, v151)
        assert.are.equal(Vector3.__new(1, 0, 0), v150)
        assert.are.equal(Vector3.__new(0, 1, 0), v151)

        local v152 = Vector3.__new(4, 0, 0)
        local v153 = Vector3.__new(0, -2, 0)
        Vector3.OrthoNormalize(v152, v153)
        assert.are.equal(Vector3.__new(1, 0, 0), v152)
        assert.are.equal(Vector3.__new(0, -1, 0), v153)

        local v154 = Vector3.__new(4, 0, 0)
        local v155 = Vector3.__new(-3, -4, -5)
        Vector3.OrthoNormalize(v154, v155)
        assert.are.equal(Vector3.__new(1, 0, 0), v154)
        assert.are.equal(Vector3.__new(0, -0.624695062637329, -0.780868768692017), v155)

        local v156 = Vector3.__new(3, 4, 5)
        local v157 = Vector3.__new(3, 4, 5)
        Vector3.OrthoNormalize(v156, v157)
        -- assert.are.equal(Vector3.__new(-0.8, 0.6, 0), v157)
        assert.are.equal(0, vci.fake.Round(Vector3.Dot(v156, v157), 5))

        local v158 = Vector3.__new(3, 4, 5)
        local v159 = Vector3.__new(-3, -4, -5)
        Vector3.OrthoNormalize(v158, v159)
        -- assert.are.equal(Vector3.__new(-0.8, 0.6, 0), v159)
        assert.are.equal(0, vci.fake.Round(Vector3.Dot(v158, v159), 5))

        local v160 = Vector3.__new(3, 4, 5)
        local v161 = Vector3.zero
        Vector3.OrthoNormalize(v160, v161)
        assert.are.equal(Vector3.__new(0.424264073371887, 0.565685451030731, 0.70710676908493), v160)
        -- assert.are.equal(Vector3.__new(-0.8, 0.6, 0), v161)
        assert.are.equal(0, vci.fake.Round(Vector3.Dot(v160, v161), 5))

        local v162 = Vector3.__new(3, 4, 5)
        local v163 = Vector3.__new(-2, -1, -9)
        Vector3.OrthoNormalize(v162, v163)
        assert.are.equal(Vector3.__new(0.257438361644745, 0.673300385475159, -0.693103313446045), v163)

        local v164 = Vector3.__new(4, 0, 0)
        local v165 = Vector3.__new(8, -15, -17)
        Vector3.OrthoNormalize(v164, v165)
        assert.are.equal(Vector3.__new(0, -0.661621630191803, -0.749837875366211), v165)

        assert.are.equal(Vector3.__new(3.0, 4.0, 5.0), Vector3.MoveTowards(Vector3.__new(3, 4, 5), Vector3.__new(8, -15, -17), 0))
        assert.are.equal(Vector3.__new(3.08476, 3.67792, 4.62707), Vector3.MoveTowards(Vector3.__new(3, 4, 5), Vector3.__new(8, -15, -17), 0.5))
        assert.are.equal(Vector3.__new(2.49145, 5.93248, 7.23761), Vector3.MoveTowards(Vector3.__new(3, 4, 5), Vector3.__new(8, -15, -17), -3))
        assert.are.equal(Vector3.__new(8.0, -15.0, -17.0), Vector3.MoveTowards(Vector3.__new(3, 4, 5), Vector3.__new(8, -15, -17), 100))

        assert.are.equal(Vector3.zero, Vector3.Cross(Vector3.__new(2, 0, 0), Vector3.__new(-2, 0, 0)))
        assert.are.equal(Vector3.__new(7, 91, -77), Vector3.Cross(Vector3.__new(3, 4, 5), Vector3.__new(8, -15, -17)))

        assert.are.equal(Vector3.__new(3, 0, 0), Vector3.Project(Vector3.__new(3, 4, 5), Vector3.__new(2, 0, 0)))
        assert.are.equal(Vector3.__new(-1.67474043369293, 3.14013838768005, 3.55882358551025), Vector3.Project(Vector3.__new(3, 4, 5), Vector3.__new(8, -15, -17)))

        assert.are.equal(Vector3.__new(0, 4, 5), Vector3.ProjectOnPlane(Vector3.__new(3, 4, 5), Vector3.__new(2, 0, 0)))
        assert.are.equal(Vector3.__new(4.67474031448364, 0.859861612319946, 1.44117641448975), Vector3.ProjectOnPlane(Vector3.__new(3, 4, 5), Vector3.__new(8, -15, -17)))

        assert.are.equal(6.48074, vci.fake.Round(Vector3.Distance(Vector3.__new(3, 4, 5), Vector3.__new(2, 0, 0)), 5))
        assert.are.equal(29.49576, vci.fake.Round(Vector3.Distance(Vector3.__new(3, 4, 5), Vector3.__new(8, -15, -17)), 5))

        assert.are.equal(Vector3.__new(-0.848528146743774, -1.13137090206146, -1.41421353816986), Vector3.ClampMagnitude(Vector3.__new(3, 4, 5), -2))
        assert.are.equal(Vector3.zero, Vector3.ClampMagnitude(Vector3.__new(3, 4, 5), 0))
        assert.are.equal(Vector3.__new(0.848528146743774, 1.13137090206146, 1.41421353816986), Vector3.ClampMagnitude(Vector3.__new(3, 4, 5), 2))
        assert.are.equal(Vector3.__new(3, 4, 5), Vector3.ClampMagnitude(Vector3.__new(3, 4, 5), 1000))

        assert.are.equal(Vector3.__new(1, 2, 2), Vector3.Min(Vector3.__new(1, 2, 3), Vector3.__new(4, 3, 2)))

        assert.are.equal(Vector3.__new(4, 3, 3), Vector3.Max(Vector3.__new(1, 2, 3), Vector3.__new(4, 3, 2)))

        local angleTargets = {
            [{2, 0, 0}] = 0,
            [{2, 1, 1}] = 35.26439,
            [{0, 2, 2}] = 90,
            [{-1, 2, -1}] = 114.09484,
            [{-2, 0, -2}] = 135,
            [{-2, -1, 0.5}] = 150.79407,
            [{0, -2, -0.25}] = 90,
            [{1, -2, 0}] = 63.43495
        }

        local angleMap = {}
        local angleBase = Vector3.__new(4, 0, 0)
        local angleConflictCount = 0

        for iv, angle in pairs(angleTargets) do
            local vec = Vector3.__new(iv[1], iv[2], iv[3])
            assert.are.equal(angle, vci.fake.Round(Vector3.Angle(angleBase, vec), 5))
            local hashCode = vec.GetHashCode()
            if angleMap[hashCode] then
                angleConflictCount = angleConflictCount + 1
            else
                angleMap[hashCode] = vec
            end
        end
        assert.are.equal(0, angleConflictCount)
    end)

    it('Vector4', function ()
        local vOne = Vector4.one
        vOne.x = 0.5
        vOne.y = 0.75
        vOne.z = -0.25
        vOne.w = -0.125
        assert.are.equal(Vector4.__new(0.5, 0.75, -0.25, -0.125), vOne)
        assert.are.equal(Vector4.__new(1, 1, 1, 1), Vector4.one)
        assert.are.equal('(3.0, -2.0, 1.1, -0.5)', tostring(Vector4.__new(3, -2, 1.125, -0.5)))

        assert.is_true(Vector4.kEpsilon <= 1E-05)

        assert.are.equal(Vector4.__new(100, 200, 300, 0), Vector4.__toVector4(Vector3.__new(100, 200, 300)))
        assert.are.equal(Vector4.__new(100, 200, 0, 0), Vector4.__toVector4(Vector2.__new(100, 200)))

        assert.are.equal(Vector3.__new(100, 200, 300), Vector4.__toVector3(Vector4.__new(100, 200, 300, 400)))
        assert.are.equal(Vector2.__new(100, 200), Vector4.__toVector2(Vector4.__new(100, 200, 300, 400)))

        assert.are.equal(Vector4.zero, Vector4.__new())
        assert.are.equal(Vector4.zero, Vector4.__new(500))
        assert.are.equal(Vector4.zero, Vector4.__new(500, 600))
        assert.are.equal(Vector4.__new(500, 600, 700, 0), Vector4.__new(500, 600, 700))

        local v19 = Vector4.__new(10, 200, 3000, 40000)
        v19.set_Item(0, -0.5)
        v19.set_Item(1, 987)
        v19.set_Item(2, 6.5)
        v19.set_Item(3, 33)
        assert.are.equal(Vector4.__new(-0.5, 987, 6.5, 33), v19)

        local v20 = Vector4.__new(3, 4, 5, 6)
        assert.are.equal(9.27362, vci.fake.Round(v20.magnitude, 5))
        assert.are.equal(86, v20.sqrMagnitude)
        assert.are.equal(9.27362, vci.fake.Round(Vector4.Magnitude(v20), 5))
        assert.are.equal(86, v20.SqrMagnitude())
        assert.are.equal(86, Vector4.SqrMagnitude(v20))
        assert.are.equal(0, Vector4.zero.magnitude)

        local v21 = v20.normalized
        assert.are.equal(Vector4.__new(0.3234983086586, 0.431331098079681, 0.539163827896118, 0.6469966173172), v21)
        local v22 = Vector4.__new(5, 12, 13, 17)
        v22.Normalize()
        assert.are.equal(Vector4.__new(0.199680760502815, 0.479233831167221, 0.519169986248016, 0.678914606571198), v22)
        assert.are.equal(Vector4.__new(-0.199680760502815, -0.479233831167221, -0.519169986248016, 0.678914606571198), Vector4.Normalize(Vector4.__new(-5, -12, -13, 17)))
        assert.are.equal(Vector4.__new(0.70710676908493, 0, 0, -0.70710676908493), Vector4.__new(Vector4.kEpsilon, 0, 0, -Vector4.kEpsilon).normalized)
        assert.are.equal(Vector4.__new(0, 0, 0, 0), Vector4.zero.normalized)

        assert.are.equal(-6, Vector4.Dot(Vector4.__new(1, 0, -3, -4), Vector4.__new(2, -3, -4, 5)))
        assert.are.equal(-2, Vector4.Dot(Vector4.__new(1, 0, -1, 0), Vector4.__new(-1, 0, 1, 0)))
        assert.are.equal(0, Vector4.Dot(Vector4.zero, Vector4.__new(2, -3, -4, 5)))
        assert.are.equal(0, Vector4.Dot(Vector4.__new(1, 0, -3, -4), Vector4.zero))

        assert.are.equal(Vector4.__new(0.5, 0, 1, -3.5), Vector4.LerpUnclamped(Vector4.__new(3, 0, -5, 4), Vector4.__new(8, 0, -17, 19), -0.5))
        assert.are.equal(Vector4.__new(3, 0, -5, 4), Vector4.LerpUnclamped(Vector4.__new(3, 0, -5, 4), Vector4.__new(8, 0, -17, 19), 0))
        assert.are.equal(Vector4.__new(4.25, 0, -8, 7.75), Vector4.LerpUnclamped(Vector4.__new(3, 0, -5, 4), Vector4.__new(8, 0, -17, 19), 0.25))
        assert.are.equal(Vector4.__new(6.75, 0, -14, 15.25), Vector4.LerpUnclamped(Vector4.__new(3, 0, -5, 4), Vector4.__new(8, 0, -17, 19), 0.75))
        assert.are.equal(Vector4.__new(8, 0, -17, 19), Vector4.LerpUnclamped(Vector4.__new(3, 0, -5, 4), Vector4.__new(8, 0, -17, 19), 1))
        assert.are.equal(Vector4.__new(10.5, 0, -23, 26.5), Vector4.LerpUnclamped(Vector4.__new(3, 0, -5, 4), Vector4.__new(8, 0, -17, 19), 1.5))

        assert.are.equal(Vector4.__new(-4, 0, 8.5, -9.5), Vector4.LerpUnclamped(Vector4.zero, Vector4.__new(8, 0, -17, 19), -0.5))
        assert.are.equal(Vector4.__new(2, 0, -4.25, 4.75), Vector4.LerpUnclamped(Vector4.zero, Vector4.__new(8, 0, -17, 19), 0.25))
        assert.are.equal(Vector4.__new(8, 0, -17, 19), Vector4.LerpUnclamped(Vector4.zero, Vector4.__new(8, 0, -17, 19), 1))
        assert.are.equal(Vector4.__new(4.5, 0, -7.5, 6), Vector4.LerpUnclamped(Vector4.__new(3, 0, -5, 4), Vector4.zero, -0.5))
        assert.are.equal(Vector4.__new(3, 0, -5, 4), Vector4.LerpUnclamped(Vector4.__new(3, 0, -5, 4), Vector4.zero, 0))
        assert.are.equal(Vector4.__new(2.25, 0, -3.75, 3), Vector4.LerpUnclamped(Vector4.__new(3, 0, -5, 4), Vector4.zero, 0.25))

        -- VCAS@1.6.3c では非実装
        -- assert.are.equal(Vector4.__new(2, -6, 12, -20), Vector4.Scale(Vector4.__new(1, 2, -3, -4), Vector4.__new(2, -3, -4, 5)))

        local hashMap = {}
        local hashTargets = {
            {2, 0, 0, 0},
            {0, 2, 0, 0},
            {0, 0, 2, 0},
            {0, 0, 0, 2},
            {-2, 0, 0, 0},
            {0, -2, 0, 0},
            {0.5, -0.25, -0.125, 0.75},
            {0.5, 0.25, 0.125, 0.75},
            {-0.25, 0.5, -0.125, 0.75},
            {-0.25, 0.5, 0.75, -0.125}
        }
        local hashConflictCount = 0

        for i, iv in pairs(hashTargets) do
            local vec = Vector4.__new(iv[1], iv[2], iv[3], iv[4])
            local hashCode = vec.GetHashCode()
            if hashMap[hashCode] then
                hashConflictCount = hashConflictCount + 1
            else
                hashMap[hashCode] = vec
            end
        end
        assert.are.equal(0, hashConflictCount)
    end)

    it('Quaternion', function ()
        local qIdentity = Quaternion.identity
        qIdentity.x = 0.5
        qIdentity.y = 0.75
        qIdentity.z = -0.25
        qIdentity.w = -0.125
        assert.are.equal(Quaternion.__new(0.5, 0.75, -0.25, -0.125), qIdentity)
        assert.are.equal(Quaternion.__new(0, 0, 0, 1), Quaternion.identity)
        assert.are.equal('(3.0, -2.0, 1.1, -0.5)', tostring(Quaternion.__new(3, -2, 1.125, -0.5)))

        assert.is_true(Quaternion.kEpsilon < 1E-5)

        assert.are.equal(Quaternion.__new(0, 0, 0, 0), Quaternion.__new())
        assert.are.equal(Quaternion.__new(0, 0, 0, 0), Quaternion.__new(500))
        assert.are.equal(Quaternion.__new(0, 0, 0, 0), Quaternion.__new(500, 600))
        assert.are.equal(Quaternion.__new(0, 0, 0, 0), Quaternion.__new(500, 600, 700))
        assert.are.equal(Quaternion.__new(500, 600, 700, 800), Quaternion.__new(500, 600, 700, 800))

        assert.are.equal(Quaternion.__new(0.3234983086586, -0.431331098079681, -0.539163827896118, 0.6469966173172), Quaternion.__new(3, -4, -5, 6).normalized)
        local q22 = Quaternion.__new(3, -4, -5, 6)
        q22.Normalize()
        assert.are.equal(Quaternion.__new(0.3234983086586, -0.431331098079681, -0.539163827896118, 0.6469966173172), q22)
        assert.are.equal(Quaternion.__new(0.3234983086586, -0.431331098079681, -0.539163827896118, 0.6469966173172), Quaternion.Normalize(Quaternion.__new(3, -4, -5, 6)))
        assert.are.equal(Quaternion.__new(0.70710676908493, 0, 0, -0.70710676908493), Quaternion.__new(Quaternion.kEpsilon, 0, 0, -Quaternion.kEpsilon).normalized)
        assert.are.equal(Quaternion.__new(0, 0, 0, 1), Quaternion.__new(0, 0, 0, 0).normalized)

        assert.are.equal(Quaternion.__new(-30, 54, -172, 150), Quaternion.__new(3, 4, 5, -6) * Quaternion.__new(8, -15, 0, -19))
        -- assert.are.equal(Vector3.__new(-1908, 717, 564), Quaternion.__new(3, 4, 5, -6) * Vector3.__new(8, -15, 0))
        assert.are.equal(Vector3.__new(-14.2790679931641, -6.48837280273438, 6.55813884735107), Quaternion.__new(3, 4, 5, -6).normalized * Vector3.__new(8, -15, 0))
        assert.are.equal(Vector3.__new(12.4615592956543, -11.5089797973633, -1.11933636665344), Quaternion.AngleAxis(25, Vector3.__new(-7, 16, 22)) * Vector3.__new(8, -15, 0))

        assert.are.equal(Quaternion.__new(1, 1, 0, 1), Quaternion.__new(1 + 1e-8, 1 - 1e-8, 0, 1))
        assert.are_not.equal(Quaternion.__new(1, 1, 0, 1), Quaternion.__new(1 + 1e-8, 1 - 1e-8, 1e-8, 1))
        assert.are_not.equal(Quaternion.__new(0, 0, 0, 0), Quaternion.__new(1e-8, 0, 0, 0))

        local q50 = Quaternion.__new(3, -4, -5, 6)
        assert.are.equal(Vector3.__new(357.334, 294.775, 282.095), RoundVector3(q50.eulerAngles, 3))
        assert.are.equal(Vector3.__new(357.334, 294.775, 282.095), RoundVector3(q50.normalized.eulerAngles, 3))
        assert.are.equal(Vector3.__new(0.658846855163574, 0.543501675128937, 0.52012175321579), q50.eulerAngles.normalized)
        assert.are.equal(Vector3.__new(-0.0465284362435341, -1.13838863372803, -1.35970294475555), q50.ToEulerAngles())
        assert.are.equal(Vector3.__new(-0.0465284362435341, -1.13838863372803, -1.35970294475555), q50.ToEuler())

        assert.are.equal(Vector3.__new(90, 0, 0), Quaternion.__new(0.70710676908493, 0, 0, 0.70710676908493).eulerAngles)
        assert.are.equal(Vector3.__new(90, 30.0000019073486, 0), Quaternion.__new(0.683012664318085, 0.183012694120407, -0.183012694120407, 0.683012664318085).eulerAngles)
        assert.are.equal(Vector3.__new(270, 30.0000019073486, 0), Quaternion.__new(-0.683012664318085, 0.183012694120407, 0.183012694120407, 0.683012664318085).eulerAngles)

        local q54 = Quaternion.__new(0.0491540282964706, -0.139000475406647, 0.155192941427231, 0.976820409297943)
        assert.are.equal(Vector3.__new(7.99999761581421, 345, 16.9999980926514), q54.eulerAngles)
        assert.are.equal(Vector3.__new(0.139626294374466, -0.261799395084381, 0.296705931425095), q54.ToEulerAngles())
        assert.are.equal(Vector3.__new(0.139626294374466, -0.261799395084381, 0.296705931425095), q54.ToEuler())

        assert.are.equal(Quaternion.__new(0.0491540282964706, -0.139000475406647, 0.155192941427231, 0.976820409297943), Quaternion.Euler(8, -15, 17))
        assert.are.equal(Quaternion.__new(0.70710676908493, 0, 0, 0.70710676908493), Quaternion.Euler(90, 0, 0))
        assert.are.equal(Quaternion.__new(0.683012664318085, 0.183012694120407, -0.183012694120407, 0.683012664318085), Quaternion.Euler(90, 30, 0))
        assert.are.equal(Quaternion.__new(-0.683012664318085, 0.183012694120407, 0.183012694120407, 0.683012664318085), Quaternion.Euler(-90, 30, 0))

        local q60 = Quaternion.Euler(0, 179, 0)
        assert.are.equal(Vector3.__new(0, 179, 0), q60.eulerAngles)
        assert.are.equal(Vector3.__new(0, 3.12413930892944, 0), q60.ToEulerAngles())
        assert.are.equal(Vector3.__new(0, 3.12413930892944, 0), q60.ToEuler())

        local q61 = Quaternion.Euler(0, 180, 0)
        assert.are.equal(Vector3.__new(0, 180, 0), q61.eulerAngles)
        assert.are.equal(Vector3.__new(0, -3.14159250259399, 0), q61.ToEulerAngles())
        assert.are.equal(Vector3.__new(0, -3.14159250259399, 0), q61.ToEuler())

        local q62 = Quaternion.Euler(0, -1, 0)
        assert.are.equal(Vector3.__new(0, 359, 0), q62.eulerAngles)
        assert.are.equal(Vector3.__new(0, -0.0174532923847437, 0), q62.ToEulerAngles())
        assert.are.equal(Vector3.__new(0, -0.0174532923847437, 0), q62.ToEuler())

        local q63 = Quaternion.Euler(0, -181, 0)
        assert.are.equal(Vector3.__new(0, 179, 0), q63.eulerAngles)
        assert.are.equal(Vector3.__new(0, 3.12413930892944, 0), q63.ToEulerAngles())
        assert.are.equal(Vector3.__new(0, 3.12413930892944, 0), q63.ToEuler())

        assert.are.equal(-6, Quaternion.Dot(Quaternion.__new(1, 0, -3, -4), Quaternion.__new(2, -3, -4, 5)))
        assert.are.equal(-2, Quaternion.Dot(Quaternion.__new(1, 0, -1, 0), Quaternion.__new(-1, 0, 1, 0)))
        assert.are.equal(0, Quaternion.Dot(Quaternion.__new(0, 0, 0, 0), Quaternion.__new(2, -3, -4, 5)))
        assert.are.equal(0, Quaternion.Dot(Quaternion.__new(1, 0, -3, -4), Quaternion.__new(0, 0, 0, 0)))

        assert.are.equal(Quaternion.__new(-1, 0, 3, -4), Quaternion.Inverse(Quaternion.__new(1, 0, -3, -4)))
        assert.are.equal(Quaternion.__new(0, 0, 0, 0), Quaternion.Inverse(Quaternion.__new(0, 0, 0, 0)))
        assert.are.equal(Quaternion.__new(- Quaternion.kEpsilon, 0, 0, 0), Quaternion.Inverse(Quaternion.__new(Quaternion.kEpsilon, 0, 0, 0)))

        assert.are.equal(Quaternion.__new(0.70710676908493, 0, 0, 0.70710676908493), Quaternion.AngleAxis(90.0, Vector3.right))
        assert.are.equal(Quaternion.__new(0, 0, 0.70710676908493, 0.70710676908493), Quaternion.AngleAxis(90.0, Vector3.forward))
        assert.are.equal(Quaternion.__new(-0.109807625412941, 0.146410167217255, -0.183012709021568, 0.965925812721252), Quaternion.AngleAxis(-30.0, Vector3.__new(3, -4, 5)))
        assert.are.equal(Quaternion.identity, Quaternion.AngleAxis(0, Vector3.__new(3, -4, 5)))
        assert.are.equal(Quaternion.identity, Quaternion.AngleAxis(30.0, Vector3.zero))
        assert.are.equal(Quaternion.identity, Quaternion.AngleAxis(0, Vector3.zero))
        assert.are.equal(Quaternion.identity, Quaternion.AngleAxis(30, Vector3.__new(Quaternion.kEpsilon, 0, 0)))

        -- assert.are.equal(0, Quaternion.Angle(Quaternion.__new(1, 0, -3, -4), Quaternion.__new(2, -3, -4, 5)))
        assert.are.equal(180, Quaternion.Angle(Quaternion.__new(1, 2, -3, -4), Quaternion.__new(0, 0, 0, 0)))
        assert.are.equal(180, Quaternion.Angle(Quaternion.AngleAxis(30, Vector3.right), Quaternion.__new(0, 0, 0, 0)))
        assert.are.equal(180, Quaternion.Angle(Quaternion.__new(0, 0, 0, 0), Quaternion.AngleAxis(30, Vector3.right)))
        assert.are.equal(120, vci.fake.Round(Quaternion.Angle(Quaternion.AngleAxis(90.0, Vector3.right), Quaternion.AngleAxis(90.0, Vector3.forward)), 5))
        assert.are.equal(90, vci.fake.Round(Quaternion.Angle(Quaternion.AngleAxis(0, Vector3.right), Quaternion.AngleAxis(270.0, Vector3.right)), 5))

        local q120s = Quaternion.__new(3, 0, -5, 4)
        local q120e = Quaternion.__new(8, 0, -17, 19)
        assert.are.equal(Quaternion.__new(0.424264073371887, 0, -0.70710676908493, 0.565685451030731), Quaternion.Lerp(q120s, q120e, -0.5))
        assert.are.equal(Quaternion.__new(0.424264073371887, 0, -0.70710676908493, 0.565685451030731), Quaternion.Lerp(q120s, q120e, 0))
        assert.are.equal(Quaternion.__new(0.356495201587677, 0, -0.671049773693085, 0.650079488754272), Quaternion.Lerp(q120s, q120e, 0.25))
        assert.are.equal(Quaternion.__new(0.309996873140335, 0, -0.642956495285034, 0.700363337993622), Quaternion.Lerp(q120s, q120e, 0.75))
        assert.are.equal(Quaternion.__new(0.299392491579056, 0, -0.636209011077881, 0.711057126522064), Quaternion.Lerp(q120s, q120e, 1))
        assert.are.equal(Quaternion.__new(0.299392491579056, 0, -0.636209011077881, 0.711057126522064), Quaternion.Lerp(q120s, q120e, 1.5))

        local q130s = Quaternion.__new(3, 0, -5, 4)
        local q130e = Quaternion.__new(8, 0, -17, 19)
        assert.are.equal(Quaternion.__new(0.136082768440247, 0, 0.272165536880493, -0.952579319477081), Quaternion.LerpUnclamped(q130s, q130e, -0.5))
        assert.are.equal(Quaternion.__new(0.424264073371887, 0, -0.70710676908493, 0.565685451030731), Quaternion.LerpUnclamped(q130s, q130e, 0))
        assert.are.equal(Quaternion.__new(0.356495201587677, 0, -0.671049773693085, 0.650079488754272), Quaternion.LerpUnclamped(q130s, q130e, 0.25))
        assert.are.equal(Quaternion.__new(0.309996873140335, 0, -0.642956495285034, 0.700363337993622), Quaternion.LerpUnclamped(q130s, q130e, 0.75))
        assert.are.equal(Quaternion.__new(0.299392491579056, 0, -0.636209011077881, 0.711057126522064), Quaternion.LerpUnclamped(q130s, q130e, 1))
        assert.are.equal(Quaternion.__new(0.286677747964859, 0, -0.627960801124573, 0.723520040512085), Quaternion.LerpUnclamped(q130s, q130e, 1.5))

        local q140s = Quaternion.AngleAxis(30, Vector3.__new(3, 0, -5))
        local q140e = Quaternion.AngleAxis(-160, Vector3.__new(8, -17, 19))
        assert.are.equal(Quaternion.__new(0.133161306381226, 0, -0.221935525536537, 0.965925872325897), Quaternion.Slerp(q140s, q140e, -0.5))
        assert.are.equal(Quaternion.__new(0.133161306381226, 0, -0.221935525536537, 0.965925872325897), Quaternion.Slerp(q140s, q140e, 0))
        assert.are.equal(Quaternion.__new(0.0169980637729168, 0.206004470586777, -0.420142501592636, 0.883602619171143), Quaternion.Slerp(q140s, q140e, 0.25))
        assert.are.equal(Quaternion.__new(-0.208504676818848, 0.536110818386078, -0.672153949737549, 0.466176092624664), Quaternion.Slerp(q140s, q140e, 0.75))
        assert.are.equal(Quaternion.__new (-0.294844090938568, 0.626543641090393, -0.700254678726196, 0.173648118972778), Quaternion.Slerp(q140s, q140e, 1))
        assert.are.equal(Quaternion.__new (-0.294844090938568, 0.626543641090393, -0.700254678726196, 0.173648118972778), Quaternion.Slerp(q140s, q140e, 1.5))

        local q150s = Quaternion.AngleAxis(30, Vector3.__new(3, 0, -5))
        local q150e = Quaternion.AngleAxis(-160, Vector3.__new(8, -17, 19))
        assert.are.equal(Quaternion.__new(0.314279705286026, -0.390997529029846, 0.219862401485443, 0.836665868759155), Quaternion.SlerpUnclamped(q150s, q150e, -0.5))
        assert.are.equal(Quaternion.__new(0.133161306381226, 0, -0.221935525536537, 0.965925872325897), Quaternion.SlerpUnclamped(q150s, q150e, 0))
        assert.are.equal(Quaternion.__new(0.0169980637729168, 0.206004470586777, -0.420142501592636, 0.883602619171143), Quaternion.SlerpUnclamped(q150s, q150e, 0.25))
        assert.are.equal(Quaternion.__new(-0.208504676818848, 0.536110818386078, -0.672153949737549, 0.466176092624664), Quaternion.SlerpUnclamped(q150s, q150e, 0.75))
        assert.are.equal(Quaternion.__new(-0.294844090938568, 0.626543641090393, -0.700254678726196, 0.173648118972778), Quaternion.SlerpUnclamped(q150s, q150e, 1))
        assert.are.equal(Quaternion.__new(-0.371566206216812, 0.612990856170654, -0.546607434749603, -0.432898700237274), Quaternion.SlerpUnclamped(q150s, q150e, 1.5))

        local q160s = Quaternion.AngleAxis(0, Vector3.__new(4, 4, 4))
        local q160e = Quaternion.Inverse(q160s)
        q160e.w = - q160e.w
        assert.are.equal(Quaternion.__new(0, 0, 0, 1), Quaternion.SlerpUnclamped(q160s, q160e, -0.5))
        assert.are.equal(Quaternion.__new(0, 0, 0, 1), Quaternion.SlerpUnclamped(q160s, q160e, 0))
        assert.are.equal(Quaternion.__new(0, 0, 0, 1), Quaternion.SlerpUnclamped(q160s, q160e, 0.25))
        -- assert.are.equal(Quaternion.__new(0, 0, 0, 1), Quaternion.SlerpUnclamped(q160s, q160e, 1))
        -- assert.are.equal(Quaternion.__new(0, 0, 0, 1), Quaternion.SlerpUnclamped(q160s, q160e, 1.5))

        local q200s = Quaternion.AngleAxis(30, Vector3.__new(3, 0, -5))
        local q200e = Quaternion.AngleAxis(-15, Vector3.__new(8, -17, 19))
        -- assert.are.equal(Quaternion.__new(0.617034733295441, -0.258086025714874, -0.537521719932556, 0.513546586036682), Quaternion.RotateTowards(q200s, q200e, -135))
        -- assert.are.equal(Quaternion.__new (0.253553628921509, -0.060201957821846, -0.30808761715889, 0.914969027042389), Quaternion.RotateTowards(q200s, q200e, -20))
        assert.are.equal(Quaternion.__new(0.133161306381226, 0, -0.221935510635376, 0.965925812721252), Quaternion.RotateTowards(q200s, q200e, 0))
        assert.are.equal(RoundQuaternion(Quaternion.__new(0.00397309381514788, 0.0626121386885643, -0.125707641243935, 0.990081608295441), 2), RoundQuaternion(Quaternion.RotateTowards(q200s, q200e, 20), 2))
        assert.are.equal(Quaternion.__new(-0.039078563451767, 0.0830419510602951, -0.0928115844726563, 0.991444885730743), Quaternion.RotateTowards(q200s, q200e, 45))
        assert.are.equal(Quaternion.__new(-0.039078563451767, 0.0830419510602951, -0.0928115844726563, 0.991444885730743), Quaternion.RotateTowards(q200s, q200e, 90))
        assert.are.equal(Quaternion.__new(-0.039078563451767, 0.0830419510602951, -0.0928115844726563, 0.991444885730743), Quaternion.RotateTowards(q200s, q200e, 180))

        assert.are.equal(Quaternion.__new(0.707106828689575, 0, 0, 0.707106828689575), Quaternion.FromToRotation(Vector3.up, Vector3.forward))
        -- assert.are.equal(Quaternion.__new(-0.522868275642395, -0.59668505191803, -0.313721001148224, 0.521684587001801), Quaternion.FromToRotation(Vector3.__new(3, 0, -5), Vector3.__new(8, -17, 19)))
        -- assert.are.equal(Quaternion.__new(0.905538499355316, -0.265035688877106, -0.331294596195221, 0), Quaternion.FromToRotation(Vector3.__new(3, 4, 5), Vector3.__new(-3, -4, -5)))
        assert.are.equal(Quaternion.__new(0, 0, 0, 1), Quaternion.FromToRotation(Vector3.__new(3, 4, 5), Vector3.__new(3, 4, 5)))

        assert.are.equal(Quaternion.__new(-0.0790454521775246, 0.920491874217987, 0.285379141569138, 0.254961490631104), Quaternion.LookRotation(Vector3.__new(3, 4, -5)))
        assert.are.equal(Quaternion.__new(-0.0790454521775246, 0.920491874217987, 0.285379141569138, 0.254961490631104), Quaternion.LookRotation(Vector3.__new(3, 4, -5), Vector3.up))
        assert.are.equal(Quaternion.__new(0.920491874217987, 0.0790454521775246, 0.254961490631104, -0.285379141569138), Quaternion.LookRotation(Vector3.__new(3, 4, -5), Vector3.down))
        assert.are.equal(Quaternion.__new(-0.600431323051453, 0.702164947986603, 0.0834529176354408, 0.373473197221756), Quaternion.LookRotation(Vector3.__new(3, 4, -5), Vector3.left))
        assert.are.equal(Quaternion.__new(0.724966704845428, 0.572692573070526, 0.369948267936707, -0.0979026407003403), Quaternion.LookRotation(Vector3.__new(3, 4, -5), Vector3.__new(8, -17, 19)))
        -- assert.are.equal(Quaternion.__new(0, 0, 0, 1), Quaternion.LookRotation(Vector3.__new(0, 0, 1), Vector3.up))
        assert.are.equal(Quaternion.__new(0, 0, 1, 0), Quaternion.LookRotation(Vector3.__new(0, 0, 1), Vector3.down))
        -- assert.are.equal(Quaternion.__new(0, 0, 0.707106828689575, 0.707106828689575), Quaternion.LookRotation(Vector3.__new(0, 0, 1), Vector3.left))
        -- assert.are.equal(Quaternion.__new(-0.707106828689575, 0, 0, 0.707106828689575), Quaternion.LookRotation(Vector3.__new(0, 1, 0), Vector3.up))
        -- assert.are.equal(Quaternion.__new(-0.707106828689575, 0, 0, 0.707106828689575), Quaternion.LookRotation(Vector3.__new(0, 1, 0), Vector3.down))
        -- assert.are.equal(Quaternion.__new(0.5, -0.5, -0.5, -0.5), Quaternion.LookRotation(Vector3.__new(0, 1, 0), Vector3.left))
    end)

    it('Color', function ()
        local cCyan = Color.cyan
        cCyan.r = 0.5
        cCyan.a = 0.75
        assert.are.equal(Color.__new(0.5, 1, 1, 0.75), cCyan)
        assert.are.equal(Color.__new(0, 1, 1, 1), Color.cyan)

        assert.are.equal(Vector4.__new(0.5, 0.25, 1.0, 0.75), Color.__toVector4(Color.__new(0.5, 0.25, 1, 0.75)))
        assert.are.equal(Color.__new(-0.5, -0.25, -1.0, -0.75), Color.__toColor(Vector4.__new(-0.5, -0.25, -1, -0.75)))

        assert.are.equal('RGBA(1.000, 0.000, 1.000, 1.000)', tostring(Color.magenta))
        assert.are.equal(Color.__new(1, 0, 1), Color.magenta)
        assert.are_not.equal(Color.__new(1, 0, 1, 0.5), Color.magenta)
        assert.are.equal(Color.__new(0, 0, 1, 1), Color.blue)
        assert.are.equal('RGBA(1.000, 0.922, 0.016, 1.000)', tostring(Color.yellow))
        assert.are.equal(Color.__new(0, 0, 0, 0), Color.clear)
        assert.are.equal(Color.clear, Color.__new())
        assert.are.equal(Color.clear, Color.__new(0.25))
        assert.are.equal(Color.clear, Color.__new(0.25, 0.5))
        assert.are.equal('RGBA(0.250, 1234.500, 0.200, 1.000)', tostring(Color.__new(0.25, 1234.5, 0.2)))
        assert.are.equal(Color.__new(1, 0, 0, 0), Color.magenta - Color.blue)
        assert.are.equal(Color.__new(1.000, 0.000, -1.000, -1.000), Color.magenta - Color.blue - Color.blue)

        local c2 = Color.magenta - (Color.blue + Color.blue)
        c2.g = 0.25
        c2.r = 0.75
        c2.a = 0.95
        assert.are.equal(Color.__new(0.750, 0.250, -1.000, 0.950), c2)
        assert.are.equal(0.75, c2.maxColorComponent)

        assert.are.equal(Color.__new(1.000, 0.500, 2.000, 2.000), Color.__new(0.5, 0.25, 1) * 2)
        assert.are.equal(Color.__new(0.000, 0.500, 3.000, 1.000), Color.__new(0.5, 0.25, 1) * Color.__new(0, 2, 3))
        assert.are.equal(Color.__new(0.250, 0.125, 0.500, 0.500), Color.__new(0.5, 0.25, 1) / 2)
        assert.are.equal(Color.__new(-0.500, 2.250, 4.000, 0.800), Color.__new(0.5, 0.25, 1) + Color.__new(-1, 2, 3, -0.2))

        local lpa = Color.__new(0.33, 1.0, -2.0, 1.0)
        local lpb = Color.__new(1.5, 3.0, 1.0, -3.0)
        assert.are.equal(Color.__new(1.266, 2.600, 0.400, -2.200), Color.Lerp(lpa, lpb, 0.8))
        assert.are.equal(Color.__new(0.330, 1.000, -2.000, 1.000), Color.Lerp(lpa, lpb, -123))
        assert.are.equal(Color.__new(0.330, 1.000, -2.000, 1.000), Color.Lerp(lpa, lpb, -5.7))
        assert.are.equal(Color.__new(0.6225, 1.500, -1.250, 0.000), Color.Lerp(lpa, lpb, 0.25))
        assert.are.equal(Color.__new(0.330, 1.000, -2.000, 1.000), Color.Lerp(lpa, lpb, -0.25))
        assert.are.equal(Color.__new(1.266, 2.600, 0.400, -2.200), Color.LerpUnclamped(lpa, lpb, 0.8))
        assert.are.equal(Color.__new(-143.580, -245.000, -371.000, 493.000), Color.LerpUnclamped(lpa, lpb, -123))
        assert.are.equal(Color.__new(-6.33899974822998, -10.400, -19.100, 23.800), Color.LerpUnclamped(lpa, lpb, -5.7))
        assert.are.equal(Color.__new(0.6225, 1.500, -1.250, 0.000), Color.LerpUnclamped(lpa, lpb, 0.25))
        assert.are.equal(Color.__new(0.0375, 0.500, -2.750, 2.000), Color.LerpUnclamped(lpa, lpb, -0.25))

        assert.are.equal(Color.__new(0, 0, 0), Color.HSVToRGB(0, 0, 0))
        assert.are.equal(Color.__new(0.21875, 0.25, 0.1875), Color.HSVToRGB(0.25, 0.25, 0.25))
        assert.are.equal(Color.__new(0.25, 0.5, 0.5), Color.HSVToRGB(0.5, 0.5, 0.5))
        assert.are.equal(Color.__new(0.46875, 0.1875, 0.75), Color.HSVToRGB(0.75, 0.75, 0.75))
        assert.are.equal(Color.__new(1, 0, 0), Color.HSVToRGB(1, 1, 1))

        local dictSize = 0
        local dict = {}
        dict[Color.__new(0.5, 0.25, 1).GetHashCode()] = 'one'
        dict[Color.__new(0.9, 0.8, 0.7).GetHashCode()] = 'car'
        dict[Color.__new(0.5, 0.25, 1).GetHashCode()] = 'two'
        for k, v in pairs(dict) do
            dictSize = dictSize + 1
        end
        assert.are.equal(2, dictSize)
        assert.are.equal('two', dict[Color.__new(0.5, 0.25, 1).GetHashCode()])
        assert.are.equal('car', dict[Color.__new(0.9, 0.8, 0.7).GetHashCode()])
    end)

    it('vci.state', function ()
        assert.is_nil(vci.state.Get('foo'))
        vci.state.Set('foo', 12345)
        assert.are.same(12345, vci.state.Get('foo'))
        vci.state.Set('foo', false)
        assert.is_false(vci.state.Get('foo'))
        vci.state.Set('foo', 'orange')
        assert.are.same('orange', vci.state.Get('foo'))
        vci.state.Set('foo', {'table-data', 'not supported'})
        assert.is_nil(vci.state.Get('foo'))

        vci.state.Set('bar', 100)
        vci.state.Add('bar', 20)
        assert.are.same(120, vci.state.Get('bar'))

        vci.fake.ClearState()
        assert.is_nil(vci.state.Get('bar'))
    end)

    it('vci.studio.shared', function ()
        local cbMap = {
            cb1 = function (value) end,
            cb2 = function (value) end,
            cb3 = function (value) end
        }

        stub(cbMap, 'cb1')
        stub(cbMap, 'cb2')
        stub(cbMap, 'cb3')

        vci.studio.shared.Bind('foo', cbMap.cb1)
        vci.studio.shared.Bind('foo', cbMap.cb2)
        vci.studio.shared.Bind('bar', cbMap.cb3)

        assert.is_nil(vci.studio.shared.Get('foo'))
        vci.studio.shared.Set('foo', 12345)
        assert.are.same(12345, vci.studio.shared.Get('foo'))
        assert.stub(cbMap.cb1).was.called(1)
        assert.stub(cbMap.cb1).was.called_with(12345)
        assert.stub(cbMap.cb2).was.called(1)
        assert.stub(cbMap.cb2).was.called_with(12345)
        assert.stub(cbMap.cb3).was.called(0)
        assert.stub(cbMap.cb3).was_not.called_with(12345)

        vci.studio.shared.Set('foo', 12345)
        assert.stub(cbMap.cb1).was.called(1)
        assert.stub(cbMap.cb2).was.called(1)
        assert.stub(cbMap.cb3).was.called(0)

        vci.studio.shared.Set('foo', false)
        assert.is_false(vci.studio.shared.Get('foo'))
        assert.stub(cbMap.cb1).was.called(2)
        assert.stub(cbMap.cb1).was.called_with(false)
        assert.stub(cbMap.cb2).was.called(2)
        assert.stub(cbMap.cb2).was.called_with(false)
        assert.stub(cbMap.cb3).was.called(0)

        vci.fake.UnbindStudioShared('foo', cbMap.cb1)
        vci.studio.shared.Set('foo', 'orange')
        assert.are.same('orange', vci.studio.shared.Get('foo'))
        assert.stub(cbMap.cb1).was.called(2)
        assert.stub(cbMap.cb2).was.called(3)
        assert.stub(cbMap.cb3).was.called(0)

        vci.studio.shared.Set('foo', {'table-data', 'not supported'})
        assert.is_nil(vci.studio.shared.Get('foo'))
        assert.stub(cbMap.cb1).was.called(2)
        assert.stub(cbMap.cb2).was.called(4)
        assert.stub(cbMap.cb3).was.called(0)

        vci.studio.shared.Set('bar', 100)
        assert.stub(cbMap.cb3).was.called(1)
        vci.studio.shared.Add('bar', 20)
        assert.are.same(120, vci.studio.shared.Get('bar'))
        assert.stub(cbMap.cb1).was.called(2)
        assert.stub(cbMap.cb2).was.called(4)
        assert.stub(cbMap.cb3).was.called(2)

        vci.fake.ClearStudioShared()
        assert.is_nil(vci.studio.shared.Get('bar'))

        vci.studio.shared.Set('bar', 404)
        assert.stub(cbMap.cb3).was.called(2)
        assert.stub(cbMap.cb3).was_not.called_with(404)

        cbMap.cb1:revert()
        cbMap.cb2:revert()
        cbMap.cb3:revert()
    end)


    it('vci.message', function ()
        local lastVciName = vci.fake.GetVciName()
        vci.fake.SetVciName('test-msg-vci')

        local cbMap = {
            cb1 = function (sender, name, message) end,
            cb2 = function (sender, name, message) end,
            cb3 = function (sender, name, message) end,
            cbComment = function (sender, name, message) end
        }

        stub(cbMap, 'cb1')
        stub(cbMap, 'cb2')
        stub(cbMap, 'cb3')
        stub(cbMap, 'cbComment')

        vci.message.On('foo', cbMap.cb1)
        vci.message.On('foo', cbMap.cb2)
        vci.message.On('bar', cbMap.cb3)
        vci.message.On('comment', cbMap.cbComment)

        vci.message.Emit('foo', 12345)
        assert.stub(cbMap.cb1).was.called(1)
        assert.stub(cbMap.cb1).was.called_with({type = 'vci', name = 'test-msg-vci'}, 'foo', 12345)
        assert.stub(cbMap.cb2).was.called(1)
        assert.stub(cbMap.cb2).was.called_with({type = 'vci', name = 'test-msg-vci'}, 'foo', 12345)
        assert.stub(cbMap.cb3).was.called(0)
        assert.stub(cbMap.cb3).was_not.called_with({type = 'vci', name = 'test-msg-vci'}, 'foo', 12345)

        vci.fake.EmitVciMessage('other-vci', 'foo', 12.345)
        assert.stub(cbMap.cb1).was.called(2)
        assert.stub(cbMap.cb1).was.called_with({type = 'vci', name = 'other-vci'}, 'foo', 12.345)
        assert.stub(cbMap.cb2).was.called(2)
        assert.stub(cbMap.cb2).was.called_with({type = 'vci', name = 'other-vci'}, 'foo', 12.345)
        assert.stub(cbMap.cb3).was.called(0)

        vci.message.Emit('foo', false)
        assert.stub(cbMap.cb1).was.called(3)
        assert.stub(cbMap.cb1).was.called_with({type = 'vci', name = 'test-msg-vci'}, 'foo', false)
        assert.stub(cbMap.cb2).was.called(3)
        assert.stub(cbMap.cb2).was.called_with({type = 'vci', name = 'test-msg-vci'}, 'foo', false)
        assert.stub(cbMap.cb3).was.called(0)

        vci.fake.OffMessage('foo', cbMap.cb1)
        vci.message.Emit('foo', 'orange')
        assert.stub(cbMap.cb1).was.called(3)
        assert.stub(cbMap.cb2).was.called(4)
        assert.stub(cbMap.cb2).was.called_with({type = 'vci', name = 'test-msg-vci'}, 'foo', 'orange')
        assert.stub(cbMap.cb3).was.called(0)

        vci.message.Emit('foo', {'table-data', 'not supported'})
        assert.stub(cbMap.cb1).was.called(3)
        assert.stub(cbMap.cb2).was.called(5)
        assert.stub(cbMap.cb2).was.called_with({type = 'vci', name = 'test-msg-vci'}, 'foo', nil)
        assert.stub(cbMap.cb3).was.called(0)

        vci.message.Emit('bar', 100)
        assert.stub(cbMap.cb1).was.called(3)
        assert.stub(cbMap.cb2).was.called(5)
        assert.stub(cbMap.cb3).was.called(1)

        vci.fake.EmitCommentMessage('TestUser', 'Hello, World!')
        assert.stub(cbMap.cb1).was.called(3)
        assert.stub(cbMap.cb2).was.called(5)
        assert.stub(cbMap.cb3).was.called(1)
        assert.stub(cbMap.cbComment).was.called_with({type = 'comment', name = 'TestUser'}, 'comment', 'Hello, World!')

        vci.fake.ClearMessageCallbacks()

        vci.message.Emit('bar', 404)
        assert.stub(cbMap.cb3).was.called(1)
        assert.stub(cbMap.cb3).was_not.called_with(404)

        cbMap.cb1:revert()
        cbMap.cb2:revert()
        cbMap.cb3:revert()
        cbMap.cbComment:revert()

        vci.fake.SetVciName(lastVciName)
    end)
end)

describe('Test cytanb_fake_vci setup and teardown', function ()
    it('Setup/Teardown', function ()
        assert.is.falsy(package.loaded['cytanb_fake_vci'])
        assert.is.falsy(vci)
        local startsWithExists = string.startsWith ~= nil
        require('cytanb_fake_vci').vci.fake.Setup(_G)
        assert.is.truthy(package.loaded['cytanb_fake_vci'])
        assert.is.truthy(vci)
        if startsWithExists then
            assert.is.truthy(string.startsWith)
        end
        vci.fake.Teardown(_G)
        assert.is.falsy(package.loaded['cytanb_fake_vci'])
        assert.is.falsy(vci)
        if startsWithExists then
            assert.is.falsy(string.startsWith)
        end
    end)
end)
