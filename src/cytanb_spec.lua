-- SPDX-License-Identifier: MIT
-- Copyright (c) 2019 oO (https://github.com/oocytanb)

local MakeEnv = function (main_env)
    return setmetatable({}, { __index = main_env })
end

---@param cytanb cytanb
local OwnerUserTestCases = function (cytanb, options)
    it('Color constants', function ()
        assert.are.same(cytanb.ColorMapSize, cytanb.ColorHueSamples * cytanb.ColorSaturationSamples * cytanb.ColorBrightnessSamples)
    end)

    it('owner InstanceID', function ()
        assert.are.same(36, #cytanb.InstanceID())
        assert.is_truthy(cytanb.UUIDFromString(cytanb.InstanceID()))
    end)

    it('OwnID', function ()
        local id = cytanb.OwnID()
        assert.is_true(#id > 0)
        assert.is_equal(id, vci.studio.GetLocalAvatar().GetId())
    end)

    it('ClientID', function ()
        assert.is_true(#cytanb.OwnID() > 0)
    end)

    it('Nillable', function ()
        assert.is_true(cytanb.NillableHasValue(123))
        assert.is_true(cytanb.NillableHasValue('hoge'))
        assert.is_true(cytanb.NillableHasValue(''))
        assert.is_true(cytanb.NillableHasValue(true))
        assert.is_true(cytanb.NillableHasValue(false))
        assert.is_false(cytanb.NillableHasValue(nil))

        assert.are.same(0, cytanb.NillableValue(0))
        assert.are.same('', cytanb.NillableValue(''))
        assert.are.same(false, cytanb.NillableValue(false))
        assert.has_error(function () return cytanb.NillableValue(nil) end)

        assert.are.same(123, cytanb.NillableValueOrDefault(nil, 123))
        assert.are.same(0, cytanb.NillableValueOrDefault(0, 123))
        assert.are.same('', cytanb.NillableValueOrDefault(nil, ''))
        assert.are.same('piyo', cytanb.NillableValueOrDefault('piyo', ''))
        assert.are.same(false, cytanb.NillableValueOrDefault(false, true))
        assert.are.same(true, cytanb.NillableValueOrDefault(nil, true))
        assert.are.same(false, cytanb.NillableValueOrDefault(nil, false))
        assert.has_error(function () return cytanb.NillableValueOrDefault(nil, nil) end)


        assert.are.same(nil, cytanb.NillableIfHasValue(nil, function (value) error('invalid') end))
        assert.are.same(0, cytanb.NillableIfHasValue(0, function (value) return value end))
        assert.are.same('', cytanb.NillableIfHasValue('', function (value) return value end))
        assert.are.same(false, cytanb.NillableIfHasValue(false, function (value) return value end))
        assert.are.same(true, cytanb.NillableIfHasValue(true, function (value) return value end))

        assert.are.same('[[EMPTY]]', cytanb.NillableIfHasValueOrElse(nil, function (value) error('invalid') end, function () return '[[EMPTY]]' end))
        assert.are.same(9876.5, cytanb.NillableIfHasValueOrElse(9876, function (value) return value + 0.5 end, function () return -1 end))
    end)

    it('SetConst', function ()
        local table = {foo = 123, bar = 'abc'}
        cytanb.SetConst(table, 'HOGE', -543)
        assert.are.same(-543, table.HOGE)
        cytanb.SetConst(table, 'PIYO', false)
        assert.is_false(table.PIYO)
        cytanb.SetConst(table, 'PIYO', true)
        assert.is_true(table.PIYO)
        assert.has_error(function () table.PIYO = 'changed value' end)
        assert.has_error(function () cytanb.SetConst(table, 'foo', 'CONST VALUE') end)
        assert.are.same(123, table.foo)
        table.foo = 65536
        assert.are.same(65536, table.foo)
    end)

    it('MakeSearchPattern', function ()
        assert.has_error(function() cytanb.MakeSearchPattern({'ab', ''}, -1) end)
        assert.has_error(function() cytanb.MakeSearchPattern({'ab', ''}, -1, 0) end)
        assert.has_error(function() cytanb.MakeSearchPattern({'ab', ''}, 4, 2) end)

        assert.are.same({
            hasEmptySearch = false,
            searchMap = {},
            lengthList = {},
            repeatMin = 1,
            repeatMax = 1
        }, cytanb.MakeSearchPattern({})
        )

        assert.are.same({
            hasEmptySearch = true,
            searchMap = {['ab'] = 2},
            lengthList = {2},
            repeatMin = 3,
            repeatMax = 3
        }, cytanb.MakeSearchPattern({'ab', ''}, 3)
        )

        assert.are.same({
            hasEmptySearch = false,
            searchMap = {['ab'] = 2, ['efgh'] = 4},
            lengthList = {4, 2},
            repeatMin = 3,
            repeatMax = 7
        }, cytanb.MakeSearchPattern({'ab', 'efgh'}, 3, 7)
        )

        assert.are.same({
            hasEmptySearch = false,
            searchMap = {['ab'] = 2, ['efgh'] = 4},
            lengthList = {4, 2},
            repeatMin = 0,
            repeatMax = 7
        }, cytanb.MakeSearchPattern({'ab', 'efgh'}, 0, 7)
        )

        assert.are.same({
            hasEmptySearch = true,
            searchMap = {['ab'] = 2, ['efgh'] = 4, ['jklm'] = 4},
            lengthList = {4, 2},
            repeatMin = 0,
            repeatMax = 0
        }, cytanb.MakeSearchPattern({'jklm', 'ab', 'efgh'}, 0, 0)
        )

        assert.are.same({
            hasEmptySearch = false,
            searchMap = {['ab'] = 2, ['efgh'] = 4},
            lengthList = {4, 2},
            repeatMin = 0,
            repeatMax = -1
        }, cytanb.MakeSearchPattern({'ab', 'efgh'}, 0, -1)
        )

        assert.are.same({
            hasEmptySearch = false,
            searchMap = {['\t'] = 1, ['\n'] = 1, ['\v'] = 1, ['\f'] = 1, ['\r'] = 1, [' '] = 1},
            lengthList = {1},
            repeatMin = 1,
            repeatMax = -1
        }, cytanb.MakeSearchPattern({'\t', '\n', '\v', '\f', '\r', ' '}, 1, -1)
        )
    end)

    it('StringStartsWith', function ()
        assert.are.same({false, -1}, {cytanb.StringStartsWith(nil, '')})
        assert.are.same({false, -1}, {cytanb.StringStartsWith('', nil)})
        assert.are.same({false, -1}, {cytanb.StringStartsWith(nil, nil)})
        assert.are.same({false, -1}, {cytanb.StringStartsWith(nil, '', -10)})
        assert.are.same({false, -1}, {cytanb.StringStartsWith(nil, '', 0)})
        assert.are.same({false, -1}, {cytanb.StringStartsWith('', nil, 1)})
        assert.are.same({false, -1}, {cytanb.StringStartsWith(nil, nil, 2)})

        assert.are.same({true, 0}, {cytanb.StringStartsWith('', '')})
        assert.are.same({true, 0}, {cytanb.StringStartsWith('', '', -1)})
        assert.are.same({true, 0}, {cytanb.StringStartsWith('', '', 0)})
        assert.are.same({true, 0}, {cytanb.StringStartsWith('', '', 1)})
        assert.are.same({true, 0}, {cytanb.StringStartsWith('abcd', '')})
        assert.are.same({true, 0}, {cytanb.StringStartsWith('abcd', '', -1)})
        assert.are.same({true, 0}, {cytanb.StringStartsWith('abcd', '', 0)})
        assert.are.same({true, 0}, {cytanb.StringStartsWith('abcd', '', 1)})
        assert.are.same({true, 0}, {cytanb.StringStartsWith('abcd', '', 2)})
        assert.are.same({true, 0}, {cytanb.StringStartsWith('abcd', '', 99)})
        assert.are.same({false, -1}, {cytanb.StringStartsWith('abcd', 'abcdef')})
        assert.are.same({true, 2}, {cytanb.StringStartsWith('abcd', 'ab')})
        assert.are.same({true, 2}, {cytanb.StringStartsWith('abcd', 'ab', 0)})
        assert.are.same({true, 2}, {cytanb.StringStartsWith('abcd', 'ab', 1)})
        assert.are.same({false, -1}, {cytanb.StringStartsWith('abcd', 'ab', 2)})
        assert.are.same({false, -1}, {cytanb.StringStartsWith('abcd', 'ab', 3)})
        assert.are.same({false, -1}, {cytanb.StringStartsWith('abcd', 'ab', 4)})
        assert.are.same({false, -1}, {cytanb.StringStartsWith('abcd', 'ab', 5)})
        assert.are.same({true, 2}, {cytanb.StringStartsWith('abcd', 'ab', -1)})
        assert.are.same({true, 2}, {cytanb.StringStartsWith('abcd', 'ab', -2)})
        assert.are.same({false, -1}, {cytanb.StringStartsWith('abcd', 'bc')})
        assert.are.same({false, -1}, {cytanb.StringStartsWith('abcd', 'bc', 0)})
        assert.are.same({false, -1}, {cytanb.StringStartsWith('abcd', 'bc', 1)})
        assert.are.same({true, 2}, {cytanb.StringStartsWith('abcd', 'bc', 2)})
        assert.are.same({false, -1}, {cytanb.StringStartsWith('abcd', 'bc', 3)})
        assert.are.same({false, -1}, {cytanb.StringStartsWith('abcd', 'bc', 4)})
        assert.are.same({false, -1}, {cytanb.StringStartsWith('abcd', 'bc', 5)})
        assert.are.same({false, -1}, {cytanb.StringStartsWith('abcd', 'bc', -1)})
        assert.are.same({false, -1}, {cytanb.StringStartsWith('abcd', 'bc', -2)})
        assert.are.same({false, -1}, {cytanb.StringStartsWith('abcd', 'bc', -3)})

        assert.are.same({false, -1}, {cytanb.StringStartsWith('幡a', 'a')})
        assert.are.same({false, -1}, {cytanb.StringStartsWith('幡a', 'a', 1)})
        assert.are.same({true, 1}, {cytanb.StringStartsWith('幡a', 'a', string.len('幡') + 1)})
        assert.are.same({true, string.len('幡')}, {cytanb.StringStartsWith('幡a', '幡')})
        assert.are.same({true, string.len('幡')}, {cytanb.StringStartsWith('幡a', '幡', 1)})
        assert.are.same({false, -1}, {cytanb.StringStartsWith('幡a', '幡', string.len('幡') + 1)})
        assert.are.same({false, -1}, {cytanb.StringStartsWith('a幡', '幡')})
        assert.are.same({false, -1}, {cytanb.StringStartsWith('a幡', '幡', 1)})
        assert.are.same({true, string.len('幡')}, {cytanb.StringStartsWith('a幡', '幡', string.len('a') + 1)})
    end)

    it('StringStartsWith - Pattern', function ()
        assert.are.same({false, -1}, {cytanb.StringStartsWith('abcd', cytanb.MakeSearchPattern({}))})
        assert.are.same({false, -1}, {cytanb.StringStartsWith('abcd', cytanb.MakeSearchPattern({}), 3)})

        assert.are.same({false, -1}, {cytanb.StringStartsWith('abcd', cytanb.MakeSearchPattern({'bc', 'cd'}))})
        assert.are.same({true, 2}, {cytanb.StringStartsWith('abcd', cytanb.MakeSearchPattern({'bc', 'ab', 'cd'}))})
        assert.are.same({true, 2}, {cytanb.StringStartsWith('abcd', cytanb.MakeSearchPattern({'b', 'ab', 'cd'}))})

        local sp10 = cytanb.MakeSearchPattern({'de', 'cd', 'efg'})
        assert.are.same({false, -1}, {cytanb.StringStartsWith('abcd', sp10, -2)})
        assert.are.same({false, -1}, {cytanb.StringStartsWith('abcd', sp10, -1)})
        assert.are.same({false, -1}, {cytanb.StringStartsWith('abcd', sp10, 0)})
        assert.are.same({false, -1}, {cytanb.StringStartsWith('abcd', sp10, 1)})
        assert.are.same({false, -1}, {cytanb.StringStartsWith('abcd', sp10, 2)})
        assert.are.same({true, 2}, {cytanb.StringStartsWith('abcd', sp10, 3)})
        assert.are.same({false, -1}, {cytanb.StringStartsWith('abcd', sp10, 4)})
        assert.are.same({false, -1}, {cytanb.StringStartsWith('abcd', sp10, 5)})

        local sp11 = cytanb.MakeSearchPattern({'b', 'cd', 'efg'})
        assert.are.same({false, -1}, {cytanb.StringStartsWith('abcd', sp11, -3)})
        assert.are.same({false, -1}, {cytanb.StringStartsWith('abcd', sp11, -2)})
        assert.are.same({false, -1}, {cytanb.StringStartsWith('abcd', sp11, -1)})
        assert.are.same({false, -1}, {cytanb.StringStartsWith('abcd', sp11, 0)})
        assert.are.same({false, -1}, {cytanb.StringStartsWith('abcd', sp11, 1)})
        assert.are.same({true, 1}, {cytanb.StringStartsWith('abcd', sp11, 2)})
        assert.are.same({true, 2}, {cytanb.StringStartsWith('abcd', sp11, 3)})
        assert.are.same({false, -1}, {cytanb.StringStartsWith('abcd', sp11, 4)})
        assert.are.same({false, -1}, {cytanb.StringStartsWith('abcd', sp11, 5)})

        local sp12 = cytanb.MakeSearchPattern({'ab', 'cd', 'efg'})
        assert.are.same({true, 2}, {cytanb.StringStartsWith('abcd', sp12, -2)})
        assert.are.same({true, 2}, {cytanb.StringStartsWith('abcd', sp12, -1)})
        assert.are.same({true, 2}, {cytanb.StringStartsWith('abcd', sp12, 0)})
        assert.are.same({true, 2}, {cytanb.StringStartsWith('abcd', sp12, 1)})
        assert.are.same({false, -1}, {cytanb.StringStartsWith('abcd', sp12, 2)})

        local sp13 = cytanb.MakeSearchPattern({ '\t', ' '})
        assert.are.same({true, 1}, {cytanb.StringStartsWith('\t @\t ', sp13)})
        assert.are.same({true, 1}, {cytanb.StringStartsWith('\t @\t ', sp13, 0)})
        assert.are.same({true, 1}, {cytanb.StringStartsWith('\t @\t ', sp13, 1)})
        assert.are.same({true, 1}, {cytanb.StringStartsWith('\t @\t ', sp13, 2)})
        assert.are.same({false, -1}, {cytanb.StringStartsWith('\t @\t ', sp13, 3)})
        assert.are.same({true, 1}, {cytanb.StringStartsWith('\t @\t ', sp13, 4)})
        assert.are.same({true, 1}, {cytanb.StringStartsWith('\t @\t ', sp13, 5)})
        assert.are.same({false, -1}, {cytanb.StringStartsWith('\t @\t ', sp13, 6)})

        local sp14 = cytanb.MakeSearchPattern({'伉', '㤠'})
        assert.are.same({false, -1}, {cytanb.StringStartsWith('\t #伉㤠#\t ', sp14)})
        assert.are.same({false, -1}, {cytanb.StringStartsWith('\t #伉㤠#\t ', sp14, 0)})
        assert.are.same({false, -1}, {cytanb.StringStartsWith('\t #伉㤠#\t ', sp14, 1)})
        assert.are.same({false, -1}, {cytanb.StringStartsWith('\t #伉㤠#\t ', sp14, 2)})
        assert.are.same({false, -1}, {cytanb.StringStartsWith('\t #伉㤠#\t ', sp14, string.len('\t ') + 1)})
        assert.are.same({true, string.len('伉')}, {cytanb.StringStartsWith('\t #伉㤠#\t ', sp14, string.len('\t #') + 1)})
        assert.are.same({true, string.len('㤠')}, {cytanb.StringStartsWith('\t #伉㤠#\t ', sp14, string.len('\t #伉') + 1)})
        assert.are.same({false, -1}, {cytanb.StringStartsWith('\t #伉㤠#\t ', sp14, string.len('\t #伉㤠') + 1)})
        assert.are.same({false, -1}, {cytanb.StringStartsWith('\t #伉㤠#\t ', sp14, string.len('\t #伉㤠#') + 1)})
        assert.are.same({false, -1}, {cytanb.StringStartsWith('\t #伉㤠#\t ', sp14, string.len('\t #伉㤠#\t') + 1)})
        assert.are.same({false, -1}, {cytanb.StringStartsWith('\t #伉㤠#\t ', sp14, string.len('\t #伉㤠#\t' ) + 1)})
        assert.are.same({true, string.len('伉')}, {cytanb.StringStartsWith('伉㤠#\t ', sp14)})
        assert.are.same({true, string.len('伉')}, {cytanb.StringStartsWith('伉㤠#\t ', sp14, 0)})
        assert.are.same({true, string.len('伉')}, {cytanb.StringStartsWith('伉㤠#\t ', sp14, 1)})
        assert.are.same({true, string.len('㤠')}, {cytanb.StringStartsWith('伉㤠#\t ', sp14, string.len('伉') + 1)})
        assert.are.same({false, -1}, {cytanb.StringStartsWith('伉㤠#\t ', sp14, string.len('伉㤠') + 1)})

        local sp15 = cytanb.MakeSearchPattern({'\t', ' '})
        assert.are.same({true, 1}, {cytanb.StringStartsWith('\t #伉㤠#\t ', sp15)})
        assert.are.same({true, 1}, {cytanb.StringStartsWith('\t #伉㤠#\t ', sp15, 0)})
        assert.are.same({true, 1}, {cytanb.StringStartsWith('\t #伉㤠#\t ', sp15, 1)})
        assert.are.same({true, 1}, {cytanb.StringStartsWith('\t #伉㤠#\t ', sp15, 2)})
        assert.are.same({false, -1}, {cytanb.StringStartsWith('\t #伉㤠#\t ', sp15, string.len('\t ') + 1)})
        assert.are.same({false, -1}, {cytanb.StringStartsWith('\t #伉㤠#\t ', sp15, string.len('\t #') + 1)})
        assert.are.same({false, -1}, {cytanb.StringStartsWith('\t #伉㤠#\t ', sp15, string.len('\t #伉') + 1)})
        assert.are.same({false, -1}, {cytanb.StringStartsWith('\t #伉㤠#\t ', sp15, string.len('\t #伉㤠') + 1)})
        assert.are.same({true, 1}, {cytanb.StringStartsWith('\t #伉㤠#\t ', sp15, string.len('\t #伉㤠#') + 1)})
        assert.are.same({true, 1}, {cytanb.StringStartsWith('\t #伉㤠#\t ', sp15, string.len('\t #伉㤠#\t') + 1)})
        assert.are.same({false, -1}, {cytanb.StringStartsWith('\t #伉㤠#\t ', sp15, string.len('\t #伉㤠#\t ') + 1)})
        assert.are.same({false, -1}, {cytanb.StringStartsWith('伉㤠#\t ', sp15)})
        assert.are.same({false, -1}, {cytanb.StringStartsWith('伉㤠#\t ', sp15, 0)})
        assert.are.same({false, -1}, {cytanb.StringStartsWith('伉㤠#\t ', sp15, 1)})
        assert.are.same({false, -1}, {cytanb.StringStartsWith('伉㤠#\t ', sp15, string.len('伉') + 1)})
        assert.are.same({false, -1}, {cytanb.StringStartsWith('伉㤠#\t ', sp15, string.len('伉㤠') + 1)})
        assert.are.same({true, 1}, {cytanb.StringStartsWith('伉㤠#\t ', sp15, string.len('伉㤠#') + 1)})
        assert.are.same({true, 1}, {cytanb.StringStartsWith('伉㤠#\t ', sp15, string.len('伉㤠#\t') + 1)})
        assert.are.same({false, -1}, {cytanb.StringStartsWith('伉㤠#\t ', sp15, string.len('伉㤠#\t ') + 1)})

        local sp50 = cytanb.MakeSearchPattern({'bc'}, 2)
        assert.are.same({true, 4}, {cytanb.StringStartsWith('bcbcde', sp50)})

        local sp51 = cytanb.MakeSearchPattern({'a', 'bc'}, 2)
        assert.are.same({true, 2}, {cytanb.StringStartsWith('aaaa', sp51)})
        assert.are.same({true, 3}, {cytanb.StringStartsWith('abcdefgh', sp51)})

        local sp52 = cytanb.MakeSearchPattern({'a', 'bc', 'def'}, 1, 3)
        assert.are.same({true, 3}, {cytanb.StringStartsWith('aaaa', sp52)})
        assert.are.same({true, 6}, {cytanb.StringStartsWith('abcdefgh', sp52)})
        assert.are.same({false, -1}, {cytanb.StringStartsWith('789abcdefgh', sp52, 3)})
        assert.are.same({true, 6}, {cytanb.StringStartsWith('789abcdefgh', sp52, 4)})
        assert.are.same({true, 5}, {cytanb.StringStartsWith('789abcdefg', sp52, 5)})
        assert.are.same({false, -1}, {cytanb.StringStartsWith('789abcdefg', sp52, 6)})
        assert.are.same({true, 3}, {cytanb.StringStartsWith('bcaXYZ', sp52)})
    end)

    it('StringEndsWith', function ()
        assert.are.same({false, -1}, {cytanb.StringEndsWith(nil, '')})
        assert.are.same({false, -1}, {cytanb.StringEndsWith('', nil)})
        assert.are.same({false, -1}, {cytanb.StringEndsWith(nil, nil)})
        assert.are.same({false, -1}, {cytanb.StringEndsWith(nil, '', -1)})
        assert.are.same({false, -1}, {cytanb.StringEndsWith(nil, '', 0)})
        assert.are.same({false, -1}, {cytanb.StringEndsWith('', nil, 1)})
        assert.are.same({false, -1}, {cytanb.StringEndsWith(nil, nil, 2)})

        assert.are.same({true, 0}, {cytanb.StringEndsWith('', '')})
        assert.are.same({true, 0}, {cytanb.StringEndsWith('', '', -1)})
        assert.are.same({true, 0}, {cytanb.StringEndsWith('', '', 0)})
        assert.are.same({true, 0}, {cytanb.StringEndsWith('', '', 1)})
        assert.are.same({true, 0}, {cytanb.StringEndsWith('abcd', '')})
        assert.are.same({true, 0}, {cytanb.StringEndsWith('abcd', '', -1)})
        assert.are.same({true, 0}, {cytanb.StringEndsWith('abcd', '', 0)})
        assert.are.same({true, 0}, {cytanb.StringEndsWith('abcd', '', 1)})
        assert.are.same({true, 0}, {cytanb.StringEndsWith('abcd', '', 2)})
        assert.are.same({true, 0}, {cytanb.StringEndsWith('abcd', '', 99)})
        assert.are.same({false, -1}, {cytanb.StringEndsWith('abcd', 'a', -2)})
        assert.are.same({false, -1}, {cytanb.StringEndsWith('abcd', 'a', -1)})
        assert.are.same({false, -1}, {cytanb.StringEndsWith('abcd', 'a', 0)})
        assert.are.same({true, 1}, {cytanb.StringEndsWith('abcd', 'a', 1)})
        assert.are.same({false, -1}, {cytanb.StringEndsWith('abcd', 'zxabcd')})
        assert.are.same({true, 2}, {cytanb.StringEndsWith('abcd', 'cd')})
        assert.are.same({true, 2}, {cytanb.StringEndsWith('abcd', 'cd', 5)})
        assert.are.same({true, 2}, {cytanb.StringEndsWith('abcd', 'cd', 4)})
        assert.are.same({false, -1}, {cytanb.StringEndsWith('abcd', 'cd', 3)})
        assert.are.same({false, -1}, {cytanb.StringEndsWith('abcd', 'cd', 2)})
        assert.are.same({false, -1}, {cytanb.StringEndsWith('abcd', 'cd', 1)})
        assert.are.same({false, -1}, {cytanb.StringEndsWith('abcd', 'cd', 0)})
        assert.are.same({false, -1}, {cytanb.StringEndsWith('abcd', 'cd', -1)})
        assert.are.same({false, -1}, {cytanb.StringEndsWith('abcd', 'cd', -2)})
        assert.are.same({false, -1}, {cytanb.StringEndsWith('abcd', 'bc')})
        assert.are.same({false, -1}, {cytanb.StringEndsWith('abcd', 'bc', 5)})
        assert.are.same({false, -1}, {cytanb.StringEndsWith('abcd', 'bc', 4)})
        assert.are.same({true, 2}, {cytanb.StringEndsWith('abcd', 'bc', 3)})
        assert.are.same({false, -1}, {cytanb.StringEndsWith('abcd', 'bc', 2)})
        assert.are.same({false, -1}, {cytanb.StringEndsWith('abcd', 'bc', 1)})
        assert.are.same({false, -1}, {cytanb.StringEndsWith('abcd', 'bc', 0)})
        assert.are.same({false, -1}, {cytanb.StringEndsWith('abcd', 'bc', -1)})
        assert.are.same({false, -1}, {cytanb.StringEndsWith('abcd', 'bc', -2)})
        assert.are.same({false, -1}, {cytanb.StringEndsWith('abcd', 'bc', -3)})
        assert.are.same({false, -1}, {cytanb.StringEndsWith('abcd', 'bc', -4)})
        assert.are.same({false, -1}, {cytanb.StringEndsWith('abcd', 'bc', -5)})

        assert.are.same({false, -1}, {cytanb.StringEndsWith('a幡', 'a')})
        assert.are.same({false, -1}, {cytanb.StringEndsWith('a幡', 'a', string.len('a幡'))})
        assert.are.same({true, 1}, {cytanb.StringEndsWith('a幡', 'a', string.len('a'))})
        assert.are.same({true, string.len('幡')}, {cytanb.StringEndsWith('a幡', '幡')})
        assert.are.same({true, string.len('幡')}, {cytanb.StringEndsWith('a幡', '幡', string.len('a幡'))})
        assert.are.same({false, -1}, {cytanb.StringEndsWith('a幡', '幡', string.len('a'))})
        assert.are.same({false, -1}, {cytanb.StringEndsWith('幡a', '幡')})
        assert.are.same({false, -1}, {cytanb.StringEndsWith('幡a', '幡', string.len('幡a'))})
        assert.are.same({true, string.len('幡')}, {cytanb.StringEndsWith('幡a', '幡', string.len('幡'))})
    end)

    it('StringEndsWith - Pattern', function ()
        assert.are.same({false, -1}, {cytanb.StringEndsWith('abcd', cytanb.MakeSearchPattern({}))})
        assert.are.same({false, -1}, {cytanb.StringEndsWith('abcd', cytanb.MakeSearchPattern({}), 3)})

        assert.are.same({false, -1}, {cytanb.StringEndsWith('abcd', cytanb.MakeSearchPattern({'bc', 'ab'}))})

        local sp10 = cytanb.MakeSearchPattern({'bc', 'cd', 'ab'})
        assert.are.same({true, 2}, {cytanb.StringEndsWith('abcd', sp10)})
        assert.are.same({false, -1}, {cytanb.StringEndsWith('abcd', sp10, -1)})
        assert.are.same({false, -1}, {cytanb.StringEndsWith('abcd', sp10, 0)})

        local sp11 = cytanb.MakeSearchPattern({'c', 'cd', 'ab'})
        assert.are.same({true, 2}, {cytanb.StringEndsWith('abcd', sp11)})
        assert.are.same({false, -1}, {cytanb.StringEndsWith('abcd', sp11, 0)})

        local sp12 = cytanb.MakeSearchPattern({'9a', 'ab', '789'})
        assert.are.same({false, -1}, {cytanb.StringEndsWith('abcd', sp12, -4)})
        assert.are.same({false, -1}, {cytanb.StringEndsWith('abcd', sp12, -3)})
        assert.are.same({false, -1}, {cytanb.StringEndsWith('abcd', sp12, -2)})
        assert.are.same({false, -1}, {cytanb.StringEndsWith('abcd', sp12, -1)})
        assert.are.same({false, -1}, {cytanb.StringEndsWith('abcd', sp12, 0)})
        assert.are.same({false, -1}, {cytanb.StringEndsWith('abcd', sp12, 1)})
        assert.are.same({true, 2}, {cytanb.StringEndsWith('abcd', sp12, 2)})
        assert.are.same({false, -1}, {cytanb.StringEndsWith('abcd', sp12, 3)})
        assert.are.same({false, -1}, {cytanb.StringEndsWith('abcd', sp12, 4)})
        assert.are.same({false, -1}, {cytanb.StringEndsWith('abcd', sp12, 5)})

        local sp13 = cytanb.MakeSearchPattern({'c', 'ab', '789'})
        assert.are.same({false, -1}, {cytanb.StringEndsWith('abcd', sp13, -4)})
        assert.are.same({false, -1}, {cytanb.StringEndsWith('abcd', sp13, -3)})
        assert.are.same({false, -1}, {cytanb.StringEndsWith('abcd', sp13, -2)})
        assert.are.same({false, -1}, {cytanb.StringEndsWith('abcd', sp13, -1)})
        assert.are.same({false, -1}, {cytanb.StringEndsWith('abcd', sp13, 0)})
        assert.are.same({false, -1}, {cytanb.StringEndsWith('abcd', sp13, 1)})
        assert.are.same({true, 2}, {cytanb.StringEndsWith('abcd', sp13, 2)})
        assert.are.same({true, 1}, {cytanb.StringEndsWith('abcd', sp13, 3)})
        assert.are.same({false, -1}, {cytanb.StringEndsWith('abcd', sp13, 4)})
        assert.are.same({false, -1}, {cytanb.StringEndsWith('abcd', sp13, 5)})

        local sp14 = cytanb.MakeSearchPattern({'cd', 'ab', '789'})
        assert.are.same({false, -1}, {cytanb.StringEndsWith('abcd', sp14, -2)})
        assert.are.same({false, -1}, {cytanb.StringEndsWith('abcd', sp14, -1)})
        assert.are.same({false, -1}, {cytanb.StringEndsWith('abcd', sp14, 0)})
        assert.are.same({false, -1}, {cytanb.StringEndsWith('abcd', sp14, 1)})
        assert.are.same({true, 2}, {cytanb.StringEndsWith('abcd', sp14, 2)})
        assert.are.same({false, -1}, {cytanb.StringEndsWith('abcd', sp14, 3)})
        assert.are.same({true, 2}, {cytanb.StringEndsWith('abcd', sp14, 4)})
        assert.are.same({true, 2}, {cytanb.StringEndsWith('abcd', sp14, 5)})

        local sp15 = cytanb.MakeSearchPattern({'a', '789'})
        assert.are.same({false, -1}, {cytanb.StringEndsWith('abcd', sp15, -2)})
        assert.are.same({false, -1}, {cytanb.StringEndsWith('abcd', sp15, -1)})
        assert.are.same({false, -1}, {cytanb.StringEndsWith('abcd', sp15, 0)})
        assert.are.same({true, 1}, {cytanb.StringEndsWith('abcd', sp15, 1)})
        assert.are.same({false, -1}, {cytanb.StringEndsWith('abcd', sp15, 2)})

        local sp16 = cytanb.MakeSearchPattern({ '\t', ' '})
        assert.are.same({true, 1}, {cytanb.StringEndsWith('\t @\t ', sp16)})
        assert.are.same({true, 1}, {cytanb.StringEndsWith('\t @\t ', sp16, 6)})
        assert.are.same({true, 1}, {cytanb.StringEndsWith('\t @\t ', sp16, 5)})
        assert.are.same({true, 1}, {cytanb.StringEndsWith('\t @\t ', sp16, 4)})
        assert.are.same({false, -1}, {cytanb.StringEndsWith('\t @\t ', sp16, 3)})
        assert.are.same({true, 1}, {cytanb.StringEndsWith('\t @\t ', sp16, 2)})
        assert.are.same({true, 1}, {cytanb.StringEndsWith('\t @\t ', sp16, 1)})
        assert.are.same({false, -1}, {cytanb.StringEndsWith('\t @\t ', sp16, 0)})

        local sp17 = cytanb.MakeSearchPattern({'伉', '㤠'})
        assert.are.same({false, -1}, {cytanb.StringEndsWith('\t #伉㤠#\t ', sp17)})
        assert.are.same({false, -1}, {cytanb.StringEndsWith('\t #伉㤠#\t ', sp17, string.len('\t #伉㤠#\t ') + 1)})
        assert.are.same({false, -1}, {cytanb.StringEndsWith('\t #伉㤠#\t ', sp17, string.len('\t #伉㤠#\t '))})
        assert.are.same({false, -1}, {cytanb.StringEndsWith('\t #伉㤠#\t ', sp17, string.len('\t #伉㤠#\t'))})
        assert.are.same({false, -1}, {cytanb.StringEndsWith('\t #伉㤠#\t ', sp17, string.len('\t #伉㤠#'))})
        assert.are.same({true, string.len('㤠')}, {cytanb.StringEndsWith('\t #伉㤠#\t ', sp17, string.len('\t #伉㤠'))})
        assert.are.same({true, string.len('伉')}, {cytanb.StringEndsWith('\t #伉㤠#\t ', sp17, string.len('\t #伉'))})
        assert.are.same({false, -1}, {cytanb.StringEndsWith('\t #伉㤠#\t ', sp17, string.len('\t #'))})
        assert.are.same({false, -1}, {cytanb.StringEndsWith('\t #伉㤠#\t ', sp17, string.len('\t '))})
        assert.are.same({false, -1}, {cytanb.StringEndsWith('\t #伉㤠#\t ', sp17, string.len('\t'))})
        assert.are.same({false, -1}, {cytanb.StringEndsWith('\t #伉㤠#\t ', sp17, 0)})
        assert.are.same({true, string.len('㤠')}, {cytanb.StringEndsWith('\t #伉㤠', sp17)})
        assert.are.same({true, string.len('㤠')}, {cytanb.StringEndsWith('\t #伉㤠', sp17, string.len('\t #伉㤠') + 1)})
        assert.are.same({true, string.len('㤠')}, {cytanb.StringEndsWith('\t #伉㤠', sp17, string.len('\t #伉㤠'))})
        assert.are.same({true, string.len('伉')}, {cytanb.StringEndsWith('\t #伉㤠', sp17, string.len('\t #伉'))})
        assert.are.same({false, -1}, {cytanb.StringEndsWith('\t #伉㤠', sp17, string.len('\t #'))})

        local sp18 = cytanb.MakeSearchPattern({'\t', ' '})
        assert.are.same({true, 1}, {cytanb.StringEndsWith('\t #伉㤠#\t ', sp18)})
        assert.are.same({true, 1}, {cytanb.StringEndsWith('\t #伉㤠#\t ', sp18, string.len('\t #伉㤠#\t ') + 1)})
        assert.are.same({true, 1}, {cytanb.StringEndsWith('\t #伉㤠#\t ', sp18, string.len('\t #伉㤠#\t '))})
        assert.are.same({true, 1}, {cytanb.StringEndsWith('\t #伉㤠#\t ', sp18, string.len('\t #伉㤠#\t'))})
        assert.are.same({false, -1}, {cytanb.StringEndsWith('\t #伉㤠#\t ', sp18, string.len('\t #伉㤠#'))})
        assert.are.same({false, -1}, {cytanb.StringEndsWith('\t #伉㤠#\t ', sp18, string.len('\t #伉㤠'))})
        assert.are.same({false, -1}, {cytanb.StringEndsWith('\t #伉㤠#\t ', sp18, string.len('\t #伉'))})
        assert.are.same({false, -1}, {cytanb.StringEndsWith('\t #伉㤠#\t ', sp18, string.len('\t #'))})
        assert.are.same({true, 1}, {cytanb.StringEndsWith('\t #伉㤠#\t ', sp18, string.len('\t '))})
        assert.are.same({true, 1}, {cytanb.StringEndsWith('\t #伉㤠#\t ', sp18, string.len('\t'))})
        assert.are.same({false, -1}, {cytanb.StringEndsWith('\t #伉㤠#\t ', sp18, 0)})
        assert.are.same({false, -1}, {cytanb.StringEndsWith('\t #伉㤠', sp18)})
        assert.are.same({false, -1}, {cytanb.StringEndsWith('\t #伉㤠', sp18, string.len('\t #伉㤠') + 1)})
        assert.are.same({false, -1}, {cytanb.StringEndsWith('\t #伉㤠', sp18, string.len('\t #伉㤠'))})
        assert.are.same({false, -1}, {cytanb.StringEndsWith('\t #伉㤠', sp18, string.len('\t #伉'))})
        assert.are.same({false, -1}, {cytanb.StringEndsWith('\t #伉㤠', sp18, string.len('\t #'))})
        assert.are.same({true, 1}, {cytanb.StringEndsWith('\t #伉㤠', sp18, string.len('\t '))})
        assert.are.same({true, 1}, {cytanb.StringEndsWith('\t #伉㤠', sp18, string.len('\t'))})
        assert.are.same({false, -1}, {cytanb.StringEndsWith('\t #伉㤠', sp18, 0)})

        local sp50 = cytanb.MakeSearchPattern({'bc'}, 2)
        assert.are.same({true, 4}, {cytanb.StringEndsWith('78bcbc', sp50)})

        local sp51 = cytanb.MakeSearchPattern({'a', 'bc'}, 2)
        assert.are.same({true, 2}, {cytanb.StringEndsWith('aaaa', sp51)})
        assert.are.same({true, 3}, {cytanb.StringEndsWith('789abc', sp51)})

        local sp52 = cytanb.MakeSearchPattern({'a', 'bc', 'def'}, 1, 3)
        assert.are.same({true, 3}, {cytanb.StringEndsWith('aaaa', sp52)})
        assert.are.same({true, 6}, {cytanb.StringEndsWith('789abcdef', sp52)})
        assert.are.same({false, -1}, {cytanb.StringEndsWith('789abcdefg', sp52, 10)})
        assert.are.same({true, 6}, {cytanb.StringEndsWith('789abcdefg', sp52, 9)})
        assert.are.same({false, -1}, {cytanb.StringEndsWith('789abcdefg', sp52, 8)})
        assert.are.same({true, 3}, {cytanb.StringEndsWith('789bca', sp52)})
    end)

    it('StringTrimStart', function ()
        assert.are.same(nil, cytanb.StringTrimStart(nil))
        assert.are.same('', cytanb.StringTrimStart(''))

        assert.are.same('ab \t cd', cytanb.StringTrimStart('ab \t cd'))
        assert.are.same('ab ', cytanb.StringTrimStart(' ab '))
        assert.are.same('a  b  ', cytanb.StringTrimStart('  a  b  '))
        assert.are.same('ab \t cd \f\r', cytanb.StringTrimStart('\t\n\v ab \t cd \f\r'))
        assert.are.same('伉弊尋\t\n\v ab \t cd \f\r希怍㤠', cytanb.StringTrimStart('伉弊尋\t\n\v ab \t cd \f\r希怍㤠'))

        assert.are.same('cdabefg', cytanb.StringTrimStart('abcdabefg', cytanb.MakeSearchPattern({'ab'})))
        assert.are.same('abcdabefg', cytanb.StringTrimStart('abcdabefg', cytanb.MakeSearchPattern({'bc'})))
        assert.are.same('abcdabefg', cytanb.StringTrimStart('abcdabefg', cytanb.MakeSearchPattern({''})))

        assert.are.same('cdabefg', cytanb.StringTrimStart('abcdabefg', cytanb.MakeSearchPattern({'ab', 'cd'})))
        assert.are.same('efg', cytanb.StringTrimStart('abcdabefg', cytanb.MakeSearchPattern({'ab', 'cd'}, 1, -1)))
        assert.are.same('abcdabefg', cytanb.StringTrimStart('abcdabefg', cytanb.MakeSearchPattern({'bc', 'cd'})))
        assert.are.same('abcdabefg', cytanb.StringTrimStart('abcdabefg', cytanb.MakeSearchPattern({'ab', 'cd', ''})))
    end)

    it('StringTrimEnd', function ()
        assert.are.same(nil, cytanb.StringTrimEnd(nil))
        assert.are.same('', cytanb.StringTrimEnd(''))

        assert.are.same('ab \t cd', cytanb.StringTrimEnd('ab \t cd'))
        assert.are.same(' ab', cytanb.StringTrimEnd(' ab '))
        assert.are.same('  a  b', cytanb.StringTrimEnd('  a  b  '))
        assert.are.same('\t\n\v ab \t cd', cytanb.StringTrimEnd('\t\n\v ab \t cd \f\r'))
        assert.are.same('伉弊尋\t\n\v ab \t cd \f\r希怍㤠', cytanb.StringTrimEnd('伉弊尋\t\n\v ab \t cd \f\r希怍㤠'))

        assert.are.same('789abcd', cytanb.StringTrimEnd('789abcdab', cytanb.MakeSearchPattern({'ab'})))
        assert.are.same('abcdabefg', cytanb.StringTrimEnd('abcdabefg', cytanb.MakeSearchPattern({'bc'})))
        assert.are.same('abcdabefg', cytanb.StringTrimEnd('abcdabefg', cytanb.MakeSearchPattern({''})))

        assert.are.same('789abcd', cytanb.StringTrimEnd('789abcdab', cytanb.MakeSearchPattern({'ab', 'cd'})))
        assert.are.same('789', cytanb.StringTrimEnd('789abcdab', cytanb.MakeSearchPattern({'ab', 'cd'}, 1, -1)))
        assert.are.same('abcdabefg', cytanb.StringTrimEnd('abcdabefg', cytanb.MakeSearchPattern({'bc', 'cd'})))
        assert.are.same('abcdabefg', cytanb.StringTrimEnd('abcdabefg', cytanb.MakeSearchPattern({'ab', 'cd', ''})))
    end)

    it('StringTrim', function ()
        assert.are.same('', cytanb.StringTrim(''))
        assert.are.same('', cytanb.StringTrim(' \t\n\v\f\r'))
        assert.are.same('|hoge piyo\t  hogepiyo|', cytanb.StringTrim(' \t\n|hoge piyo\t  hogepiyo|\v\f\r'))

        -- ' \t\n\v\f\r' のそれぞれの文字の、上位バイトが異なるものをテスト。
        assert.are.same('㤠伉弊尋希怍', cytanb.StringTrim('㤠伉弊尋希怍'))

        -- 全角空白など、Unicode の空白は非対応
        assert.are.same('　', cytanb.StringTrim('　'))

        local sp80 = cytanb.MakeSearchPattern({'伯'})
        assert.are.same('㌣た⽟千す協㑁低あ', cytanb.StringTrim('伯㌣た⽟千す協㑁低あ', sp80))
        assert.are.same('伯㌣た⽟千す協㑁低あ', cytanb.StringTrim('伯伯㌣た⽟千す協㑁低あ', sp80))
        assert.are.same('㌣た⽟千す協㑁低あ', cytanb.StringTrim('伯㌣た⽟千す協㑁低あ伯', sp80))
        assert.are.same('㌣た⽟千す協㑁低あ伯', cytanb.StringTrim('伯㌣た⽟千す協㑁低あ伯伯', sp80))

        local sp81 = cytanb.MakeSearchPattern({'伯'}, 2, 4)
        assert.are.same('伯㌣た⽟千す協㑁低あ伯', cytanb.StringTrim('伯㌣た⽟千す協㑁低あ伯', sp81))
        assert.are.same('㌣た⽟千す協㑁低あ', cytanb.StringTrim('伯伯㌣た⽟千す協㑁低あ伯伯', sp81))
        assert.are.same('㌣た⽟千す協㑁低あ', cytanb.StringTrim('伯伯伯㌣た⽟千す協㑁低あ伯伯伯', sp81))
        assert.are.same('㌣た⽟千す協㑁低あ', cytanb.StringTrim('伯伯伯伯㌣た⽟千す協㑁低あ伯伯伯伯', sp81))
        assert.are.same('伯㌣た⽟千す協㑁低あ伯', cytanb.StringTrim('伯伯伯伯伯㌣た⽟千す協㑁低あ伯伯伯伯伯', sp81))

        local sp82 = cytanb.MakeSearchPattern({'伯', '㌣', '低', 'あ'})
        assert.are.same('㌣た⽟千す協㑁低', cytanb.StringTrim('伯㌣た⽟千す協㑁低あ', sp82))

        local sp83 = cytanb.MakeSearchPattern({'伯', '㌣', '低', 'あ'}, 2, 4)
        assert.are.same('㌣た⽟千す協㑁低', cytanb.StringTrim('㌣た⽟千す協㑁低', sp83))
        assert.are.same('た⽟千す協㑁', cytanb.StringTrim('伯㌣た⽟千す協㑁低あ', sp83))
        assert.are.same('伯㌣た⽟千す協㑁低あ', cytanb.StringTrim('伯㌣伯㌣伯㌣た⽟千す協㑁低あ低あ低あ', sp83))

        local sp84 = cytanb.MakeSearchPattern({'伯', '㌣た', '㑁低', 'あ'}, 2, 4)
        assert.are.same('⽟千す協', cytanb.StringTrim('伯㌣た⽟千す協㑁低あ', sp84))
        assert.are.same('/#__CYTANB伯㌣た⽟千す協㑁低あ/#__CYTANB', cytanb.StringTrim('/#__CYTANB伯㌣た⽟千す協㑁低あ/#__CYTANB', sp84))
        assert.are.same('⽟千す協㑁低あ/#__CYTANB伯㌣た⽟千す協', cytanb.StringTrim('伯㌣た⽟千す協㑁低あ/#__CYTANB伯㌣た⽟千す協㑁低あ',sp84))

        local sp85 = cytanb.MakeSearchPattern({'伯', '㌣た', '⽟千', 'す', '協', '㑁低', 'あ'}, 2, 4)
        assert.are.same('/#__CYTANB伯㌣た⽟千す協㑁低あ/#__CYTANB', cytanb.StringTrim('/#__CYTANB伯㌣た⽟千す協㑁低あ/#__CYTANB', sp85))
        assert.are.same('協㑁低あ/#__CYTANB伯㌣た⽟千', cytanb.StringTrim('伯㌣た⽟千す協㑁低あ/#__CYTANB伯㌣た⽟千す協㑁低あ',sp85))
    end)

    it('StringReplace', function ()
        assert.are.same('EM', cytanb.StringReplace('', '', 'EM'))
        assert.are.same('EaEbEcEdE', cytanb.StringReplace('abcd', '', 'E'))
        assert.are.same('', cytanb.StringReplace('', 'ab', 'E'))
        assert.are.same('ba', cytanb.StringReplace('aaa', 'aa', 'b'))
        assert.are.same('XYXYa', cytanb.StringReplace('aaaaa', 'aa', 'XY'))
        assert.are.same('cdcd', cytanb.StringReplace('abcdabcdab', 'ab', ''))
        assert.are.same('abcdabcdab', cytanb.StringReplace('abcdabcdab', 'AB', 'XY'))
        assert.are.same('ましましま', cytanb.StringReplace('たしました', 'た', 'ま'))
        assert.are.same('@|㌣|', cytanb.StringReplace('#|㌣|', '#', '@'))
        assert.are.same('#__CYTANB_SOLIDUS#__CYTANB#__CYTANB|伯|㌣た⽟千す協㑁低あ|#__CYTANB#__CYTANB', cytanb.StringReplace(
            cytanb.StringReplace('/#__CYTANB|伯|㌣た⽟千す協㑁低あ|#__CYTANB', '#__CYTANB', '#__CYTANB#__CYTANB'),
            '/', '#__CYTANB_SOLIDUS'
        ))
    end)

    it('StringEachCode', function ()
        local CodeAccumulator = function (codeString, index, cbArg, beginPos, endPos)
            table.insert(cbArg, {codeString, index, beginPos, endPos})
        end

        local SpriteFilterAccumulator = function (mutableList)
            return function (spriteIndex)
                table.insert(mutableList, {spriteIndex})
                return true
            end
        end

        local ea1 = {}
        local ec1 = {cytanb.StringEachCode('', CodeAccumulator, ea1)}
        assert.are.same({0, 0, 0}, ec1)
        assert.are.same({}, ea1)

        local ea2 = {}
        local ec2 = {cytanb.StringEachCode('a9', CodeAccumulator, ea2)}
        assert.are.same({2, 1, 2}, ec2)
        assert.are.same({
            {'a', 1, 1, 1},
            {'9', 2, 2, 2}
        }, ea2)

        local ea3 = {}
        local ec3 = {cytanb.StringEachCode('abc789', CodeAccumulator, ea3, 3, 4)}
        assert.are.same({2, 3, 4}, ec3)
        assert.are.same({
            {'c', 1, 3, 3},
            {'7', 2, 4, 4}
        }, ea3)

        local ea4 = {}
        local eb4 = 0
        local ec4 = {cytanb.StringEachCode('abc789', function (codeString, index, cbArg, beginPos, endPos)
            table.insert(cbArg, {codeString, index, beginPos, endPos})
            eb4 = eb4 + 1
            if eb4 >= 2 then
                return false
            end
        end, ea4, 2, 6)}
        assert.are.same({2, 2, 3}, ec4)
        assert.are.same({
            {'b', 1, 2, 2},
            {'c', 2, 3, 3}
        }, ea4)

        assert.are.same({3, 2, 4}, {cytanb.StringEachCode('abc789', nil, nil, 2, 4)})
        assert.are.same({1, 6, 6}, {cytanb.StringEachCode('abc789', nil, nil, 6, 6)})

        assert.has_error(function () cytanb.StringEachCode('abc789', nil, nil, 0, 4) end)
        assert.has_error(function () cytanb.StringEachCode('abc789', nil, nil, 2, 1) end)
        assert.has_error(function () cytanb.StringEachCode('abc789', nil, nil, 7, 7) end)

        local ea49 = {}
        local ec49 = {cytanb.StringEachCode('<sprite=0>', CodeAccumulator, ea49)}
        assert.are.same({10, 1, 10}, ec49)
        assert.are.same(10, #ea49)
        assert.are.same({'<', 1, 1, 1}, ea49[1])

        local ea50 = {}
        local ec50 = {cytanb.StringEachCode('<sprite=0>', CodeAccumulator, ea50, nil, nil, true)}
        assert.are.same({1, 1, 10}, ec50)
        assert.are.same({
            {'<sprite=0>', 1, 1, 10}
        }, ea50)

        local ea51 = {}
        local ef51 = {}
        local ec51 = {cytanb.StringEachCode('<SPRITEsprite=0><SPRITE=3182><SPRITE=3183><sprite=dame><sprite=<sprite=0001>>', CodeAccumulator, ea51, nil, nil, true, SpriteFilterAccumulator(ef51))}
        assert.are.same({77 + (- 13 + 1) * 2, 1, 77}, ec51)
        assert.are.same(77 + (- 13 + 1) * 2, #ea51)
        assert.are.same({'<SPRITE=3182>', 17, 17, 29}, ea51[17])
        assert.are.same({'<sprite=0001>', 64 - 13 + 1, 64, 76}, ea51[64 - 13 + 1])
        assert.are.same({
            {3182},
            {1}
        }, ef51)

        local ea52 = {}
        local ef52 = {}
        local ec52 = {cytanb.StringEachCode('<sprite=0><sprite=1><sprite=2><sprite=3><sprite=4><sprite=5><sprite=6><sprite=7>', CodeAccumulator, ea52, 10, 77, true, function (spriteIndex)
            table.insert(ef52, {spriteIndex})
            return spriteIndex ~= 3
        end, 5)}
        assert.are.same({1 + 10 * 2 + 4 + 7, 10, 77}, ec52)
        assert.are.same(1 + 10 * 2 + 4 + 7, #ea52)
        assert.are.same({'<sprite=1>', 2, 11, 20}, ea52[2])
        assert.are.same({'<sprite=2>', 3, 21, 30}, ea52[3])
        assert.are.same({'<', 4, 31, 31}, ea52[4])
        assert.are.same({'<sprite=4>', 14, 41, 50}, ea52[14])
        assert.are.same({'<sprite=5>', 15, 51, 60}, ea52[15])
        assert.are.same({'<', 16, 61, 61}, ea52[16])
        assert.are.same({'<', 26, 71, 71}, ea52[26])
        assert.are.same({
            {1},
            {2},
            {3},
            {4},
            {5}
        }, ef52)

        -- @TODO support unicode
        -- local ea70 = {}
        -- local ec70 = {cytanb.StringEachCode('aあ😀#㌣', CodeAccumulator, ea70)}
        -- assert.are.same({5, 1, string.len('aあ😀#㌣')}, ec70)
        -- assert.are.same({
        --     {'a', 1, 1, string.len('a')},
        --     {'あ', 2, string.len('a') + 1, string.len('aあ')},
        --     {'😀', 3, string.len('aあ') + 1, string.len('aあ😀')},
        --     {'#', 4, string.len('aあ😀') + 1, string.len('aあ😀#')},
        --     {'㌣', 5, string.len('aあ😀#') + 1, string.len('aあ😀#㌣')}
        -- }, ea70)
    end)

    it('Extend', function ()
        local source1 = {foo = 123, bar = 'abc', baz = true, qux = {quux = -9876.5, corge = false}}
        local source2 = {bar = 'opq', qux = {quux = 543, grault = 246}, zyzzy = 'rst'}
        assert.are.same(nil, cytanb.Extend(nil, source1))
        assert.are.same(source1, cytanb.Extend(source1, source1))
        assert.are.same(source1, cytanb.Extend({}, source1))

        local deep1 = cytanb.Extend({}, source1, true)
        assert.are.same(source1, deep1)
        assert.are.same({foo = 123, bar = 'opq', baz = true, qux = {quux = 543, grault = 246}, zyzzy = 'rst'}, cytanb.Extend(deep1, source2))
        assert.are_not.same(source1, deep1)

        local deep2 = cytanb.Extend({}, source1, true)
        assert.are.same(source1, deep2)
        deep2.qux.corge = 'deep copy'
        assert.are_not.same(source1, deep1)

        assert.are.same({foo = 123, bar = 'opq', baz = true, qux = {quux = 543, corge = false, grault = 246}, zyzzy = 'rst'}, cytanb.Extend(cytanb.Extend({}, source1, true), source2, true))

        local meta1_root = {__index = {hoge = 256, piyo = 'metasyntactic variable'}}
        local meta1_qux = {__index = {hogera = 1024, fuga = false}}
        local metaSource1 = {foo = 123, bar = 'abc', baz = true, qux = {quux = -9876.5, corge = false}}
        setmetatable(metaSource1, meta1_root)
        setmetatable(metaSource1.qux, meta1_qux)
        local metaTarget1 = cytanb.Extend({}, metaSource1)
        assert.are.same(metaSource1, metaTarget1)
        assert.are.equal(metaSource1.qux, metaTarget1.qux)
        assert.are.equal(meta1_root, getmetatable(metaTarget1))
        assert.are.equal(meta1_qux, getmetatable(metaTarget1.qux))
        assert.are.same(256, metaTarget1.hoge)
        assert.is_false(metaTarget1.qux.fuga)
        metaTarget1.added_root = true
        assert.is_true(metaTarget1.added_root)
        assert.is_nil(metaSource1.added_root)
        metaTarget1.qux.added_child = true
        assert.is_true(metaTarget1.qux.added_child)
        assert.is_true(metaSource1.qux.added_child)
        meta1_root.__index.hoge = -0.25
        meta1_qux.__index.fuga = true
        assert.are.same(-0.25, metaTarget1.hoge)
        assert.is_true(metaTarget1.qux.fuga)

        local meta2_root = {__index = {hoge = 256, piyo = 'metasyntactic variable'}}
        local meta2_qux = {__index = {hogera = 1024, fuga = false}}
        local metaSource2 = {foo = 123, bar = 'abc', baz = true, qux = {quux = -9876.5, corge = false}}
        setmetatable(metaSource2, meta2_root)
        setmetatable(metaSource2.qux, meta2_qux)
        local metaTarget2 = cytanb.Extend({}, metaSource2, true)
        assert.are.same(metaSource2, metaTarget2)
        assert.are.same(meta2_root, getmetatable(metaTarget2))
        assert.are.same(meta2_qux, getmetatable(metaTarget2.qux))
        assert.are.same(256, metaTarget2.hoge)
        assert.is_false(metaTarget2.qux.fuga)
        metaTarget2.added_root = true
        assert.is_true(metaTarget2.added_root)
        assert.is_nil(metaSource2.added_root)
        metaTarget2.qux.added_child = true
        assert.is_true(metaTarget2.qux.added_child)
        assert.is_nil(metaSource2.qux.added_child)
        meta2_root.__index.hoge = -0.25
        meta2_qux.__index.fuga = true
        assert.are.same(256, metaTarget2.hoge)
        assert.is_false(metaTarget2.qux.fuga)

        local meta3_root = {__index = {hoge = 256, piyo = 'metasyntactic variable'}}
        local meta3_qux = {__index = {hogera = 1024, fuga = false}}
        local metaSource3 = {foo = 123, bar = 'abc', baz = true, qux = {quux = -9876.5, corge = false}}
        setmetatable(metaSource3, meta3_root)
        setmetatable(metaSource3.qux, meta3_qux)
        local metaTarget3 = cytanb.Extend({}, metaSource3, false, true)
        local metaTarget4 = cytanb.Extend({}, metaSource3, true, true)
        assert.is_nil(getmetatable(metaTarget3))
        assert.is_table(getmetatable(metaTarget3.qux))
        assert.is_nil(getmetatable(metaTarget4))
        assert.is_nil(getmetatable(metaTarget4.qux))

        local meta10_root = {__index = {hoge = 256, piyo = 'metasyntactic variable'}}
        local meta11_qux = {__index = {hogera = 1024, fuga = false}}
        local metaSource10 = {foo = 123, bar = 'abc', baz = true, qux = {quux = -9876.5, corge = false}}
        setmetatable(metaSource10, meta10_root)
        setmetatable(metaSource10.qux, meta11_qux)
        local metaTarget10 = {qux = {}}
        setmetatable(metaTarget10, {__index = {tag = '#hash'}})
        setmetatable(metaTarget10.qux, {__index = {sub_tag = '#sub_hash'}})
        cytanb.Extend(metaTarget10, metaSource10)
        assert.are.same('metasyntactic variable', metaTarget10.piyo)
        assert.are.same(1024, metaTarget10.qux.hogera)
        assert.is_nil(metaTarget10.tag)
        assert.is_nil(metaTarget10.qux.sub_tag)

        local meta15_root = {__index = {hoge = 256, piyo = 'metasyntactic variable'}}
        local meta16_qux = {__index = {hogera = 1024, fuga = false}}
        local metaSource15 = {foo = 123, bar = 'abc', baz = true, qux = {quux = -9876.5, corge = false}}
        setmetatable(metaSource15, meta15_root)
        setmetatable(metaSource15.qux, meta16_qux)
        local metaTarget15 = {qux = {}}
        setmetatable(metaTarget15, {__index = {tag = '#hash'}})
        setmetatable(metaTarget15.qux, {__index = {sub_tag = '#sub_hash'}})
        cytanb.Extend(metaTarget15, metaSource15, true)
        assert.are.same('metasyntactic variable', metaTarget15.piyo)
        assert.are.same(1024, metaTarget15.qux.hogera)
        assert.are.same('#hash', metaTarget15.tag)
        assert.are.same('#sub_hash', metaTarget15.qux.sub_tag)

        local cir_40 = { hoge = 256 }
        cir_40.ref = cir_40
        assert.has_error(function ()
            cytanb.Extend({}, cir_40, true)
        end)
    end)

    it('Vars', function ()
        assert.are.same('(boolean) true', cytanb.Vars(true))
        assert.are.same('(boolean) false', cytanb.Vars(false, '-', '*'))
        assert.are.same('(number) -123.45', cytanb.Vars(-123.45))

        local vt1 = { 'apple', { empty_table = {} }, false }
        assert.are.same(
            '(' .. tostring(vt1) .. ') {\n'
            .. '^1 = (string) "apple",\n'
            .. '^2 = (' .. tostring(vt1[2]) .. ') {\n'
            .. '^^empty_table = (' .. tostring(vt1[2].empty_table) .. ') {}\n'
            .. '^},\n'
            .. '^3 = (boolean) false\n'
            .. '}',
            cytanb.Vars(vt1, '^')
        )

        local vt2 = {
            [0] = function () end
        }

        assert.are.same(
            '(' .. tostring(vt2) .. ') {\n'
            .. '  0 = (function)\n'
            .. '}',
            cytanb.Vars(vt2)
        )

        local vt3 = {
            [97.5] = false
        }

        assert.are.same(
            '(' .. tostring(vt3) .. ') {'
            .. '97.5 = (boolean) false'
            .. '}',
            cytanb.Vars(vt3, '__NOLF', '*')
        )

        local vt4 = {
            [false] = 0
        }

        assert.are.same(
            '(' .. tostring(vt4) .. ') {\n'
            .. '*>false = (number) 0\n'
            .. '*}',
            cytanb.Vars(vt4, '>', '*')
        )


        local vt5 = {
            [true] = coroutine.create(function () end)
        }

        assert.are.same(
            '(' .. tostring(vt5) .. ') {\n'
            .. '*true = (thread)\n'
            .. '*}',
            cytanb.Vars(vt5, '', '*')
        )

        local vt6 = {
            [function () end] = 'BAR'
        }

        assert.are.same(
            '(' .. tostring(vt6) .. ') {\n'
            .. '  (function) = (string) "BAR"\n'
            .. '}',
            cytanb.Vars(vt6)
        )

        local vt7 = {
            [coroutine.create(function() end)] = 'CO'
        }

        assert.are.same(
            '(' .. tostring(vt7) .. ') {\n'
            .. '  (thread) = (string) "CO"\n'
            .. '}',
            cytanb.Vars(vt7)
        )

        local vt8 = {}
        vt8.ref = vt8

        assert.are.same(
            '(' .. tostring(vt8) .. ') {\n'
            .. '  ref = (' .. tostring(vt8) .. ')\n'
            .. '}',
            cytanb.Vars(vt8)
        )
    end)

    it('PosixTime', function ()
        local now = os.time()
        assert.are.same(now, cytanb.PosixTime())
        assert.are.same(now, cytanb.PosixTime(now))
        assert.are.same(0, cytanb.PosixTime(0))
    end)

    it('LogLevel', function ()
        assert.are.same(cytanb.LogLevelOff, 0)
        assert.is_true(cytanb.LogLevelFatal > cytanb.LogLevelOff)
        assert.is_true(cytanb.LogLevelError > cytanb.LogLevelFatal)
        assert.is_true(cytanb.LogLevelWarn > cytanb.LogLevelError)
        assert.is_true(cytanb.LogLevelInfo > cytanb.LogLevelWarn)
        assert.is_true(cytanb.LogLevelDebug > cytanb.LogLevelInfo)
        assert.is_true(cytanb.LogLevelTrace > cytanb.LogLevelDebug)
        assert.is_true(cytanb.LogLevelAll > cytanb.LogLevelTrace)
        assert.are.same(cytanb.LogLevelAll, 0x7FFFFFFF)

        local level = cytanb.GetLogLevel()
        local outputLevel = cytanb.IsOutputLogLevelEnabled()
        assert.are.same(level, cytanb.LogLevelInfo)
        assert.is_true(level > cytanb.LogLevelFatal)
        assert.is_false(outputLevel)

        cytanb.SetLogLevel(cytanb.LogLevelFatal)
        cytanb.SetOutputLogLevelEnabled(true)
        assert.are.same(cytanb.LogLevelFatal, cytanb.GetLogLevel())
        assert.is_true(cytanb.IsOutputLogLevelEnabled())

        cytanb.SetLogLevel(level)
        cytanb.SetOutputLogLevelEnabled(outputLevel)
        assert.are_not.same(cytanb.LogLevelFatal, cytanb.GetLogLevel())
        assert.is_false(cytanb.IsOutputLogLevelEnabled())
    end)

    it('Log', function ()
        stub(cytanb, 'Log')
        cytanb.Log(cytanb.LogLevelInfo, 'Level message')
        assert.stub(cytanb.Log).was.called_with(cytanb.LogLevelInfo, 'Level message')

        cytanb.LogFatal('Fatal message', 123)
        assert.stub(cytanb.Log).was.called_with(cytanb.LogLevelFatal, 'Fatal message', 123)

        cytanb.LogError('Error message', {})
        assert.stub(cytanb.Log).was.called_with(cytanb.LogLevelError, 'Error message', {})

        cytanb.LogWarn('Warn message', false)
        assert.stub(cytanb.Log).was.called_with(cytanb.LogLevelWarn, 'Warn message', false)

        cytanb.LogInfo('Info message', 'xyz')
        assert.stub(cytanb.Log).was.called_with(cytanb.LogLevelInfo, 'Info message', 'xyz')

        cytanb.LogDebug('Debug message')
        assert.stub(cytanb.Log).was.called_with(cytanb.LogLevelDebug, 'Debug message')

        cytanb.LogTrace('Trace message', nil)
        assert.stub(cytanb.Log).was.called_with(cytanb.LogLevelTrace, 'Trace message', nil)
        cytanb.Log:revert()

        stub(_G, 'print')
        local callCount = 0
        local lastLevel = cytanb.GetLogLevel()
        local lastOutputLevel = cytanb.IsOutputLogLevelEnabled()
        cytanb.SetLogLevel(cytanb.LogLevelWarn)
        cytanb.LogWarn('foo ', true)
        callCount = callCount + 1
        assert.stub(print).was.called(callCount)
        assert.stub(print).was.called_with('foo true')
        cytanb.LogError('bar ', -1234.5)
        callCount = callCount + 1
        assert.stub(print).was.called(callCount)
        assert.stub(print).was.called_with('bar -1234.5')
        cytanb.LogInfo('baz ', false)
        assert.stub(print).was.called(callCount)
        assert.stub(print).was_not.called_with('baz false')

        cytanb.SetLogLevel(cytanb.LogLevelOff)
        cytanb.SetOutputLogLevelEnabled(true)
        cytanb.LogFatal('qux ', 'apple')
        assert.stub(print).was.called(callCount)
        cytanb.LogTrace('quux ', 'orange')
        assert.stub(print).was.called(callCount)

        cytanb.SetLogLevel(cytanb.LogLevelAll)
        cytanb.LogFatal('qux ', 'apple')
        callCount = callCount + 1
        assert.stub(print).was.called(callCount)
        assert.stub(print).was.called_with('FATAL | qux apple')
        cytanb.LogTrace('quux ', 'orange')
        callCount = callCount + 1
        assert.stub(print).was.called(callCount)
        assert.stub(print).was.called_with('TRACE | quux orange')
        cytanb.LogDebug()
        callCount = callCount + 1
        assert.stub(print).was.called(callCount)
        assert.stub(print).was.called_with('DEBUG | ')
        callCount = callCount + 1
        cytanb.LogError('corge')
        assert.stub(print).was.called(callCount)
        assert.stub(print).was.called_with('ERROR | corge')
        cytanb.Log(32, 'custom level')
        callCount = callCount + 1
        assert.stub(print).was.called(callCount)
        assert.stub(print).was.called_with('LOG LEVEL 32 | custom level')
        cytanb.Log(33, nil)
        callCount = callCount + 1
        assert.stub(print).was.called(callCount)
        assert.stub(print).was.called_with('LOG LEVEL 33 | ')
        cytanb.Log(34)
        callCount = callCount + 1
        assert.stub(print).was.called(callCount)
        assert.stub(print).was.called_with('LOG LEVEL 34 | ')

        cytanb.SetLogLevel(cytanb.LogLevelDebug)
        cytanb.SetOutputLogLevelEnabled(false)
        cytanb.LogTrace('grault ', 'melon')
        assert.stub(print).was.called(callCount)
        assert.stub(print).was_not.called_with('grault melon')
        cytanb.LogDebug('garply')
        callCount = callCount + 1
        assert.stub(print).was.called(callCount)
        assert.stub(print).was.called_with('garply')
        cytanb.LogInfo()
        callCount = callCount + 1
        assert.stub(print).was.called(callCount)
        assert.stub(print).was.called_with('')
        _G.print:revert()
        cytanb.SetLogLevel(lastLevel)
        cytanb.SetOutputLogLevelEnabled(lastOutputLevel)
    end)

    it('ListToMap', function ()
        assert.are.same({foo = 'foo', bar = 'bar', baz = 'baz'}, cytanb.ListToMap({'foo', 'bar', 'baz'}))
        assert.are.same({foo = 543, bar = 543, baz = 543}, cytanb.ListToMap({'foo', 'bar', 'baz'}, 543))
        assert.are.same({[true] = true, [false] = false}, cytanb.ListToMap({true, false}))
        assert.are.same({[true] = 1, [false] = 1}, cytanb.ListToMap({true, false}, 1))
        assert.are.same({foo = 100, bar = 200, baz = 300}, cytanb.ListToMap({{str = 'foo', num = 100}, {str = 'bar', num = 200}, {str = 'baz', num = 300}}, function (value) return value.str, value.num end))
    end)

    it('Round', function ()
        assert.are.same(1, cytanb.Round(1.45))
        assert.are.same(2, cytanb.Round(1.55))
        assert.are.same(123, cytanb.Round(123.456))
        assert.are.same(-123, cytanb.Round(-123.456))
        assert.are.same(1.5, cytanb.Round(1.45, 1))
        assert.are.same(1.6, cytanb.Round(1.55, 1))
        assert.are.same(123.5, cytanb.Round(123.456, 1))
        assert.are.same(-123.5, cytanb.Round(-123.456, 1))
        assert.are.same(1.45, cytanb.Round(1.45, 2))
        assert.are.same(1.55, cytanb.Round(1.55, 2))
        assert.are.same(123.46, cytanb.Round(123.456, 2))
        assert.are.same(-123.46, cytanb.Round(-123.456, 2))
    end)

    it('Clamp', function ()
        assert.are.same(0, cytanb.Clamp(0, 0, 0))
        assert.are.same(0, cytanb.Clamp(0, -1.5, 1.5))
        assert.are.same(-1.5, cytanb.Clamp(-2, -1.5, 1.5))
        assert.are.same(-1.5, cytanb.Clamp(-1.5, -1.5, 1.5))
        assert.are.same(-0.25, cytanb.Clamp(-0.25, -1.5, 1.5))
        assert.are.same(1.25, cytanb.Clamp(1.25, -1.5, 1.5))
        assert.are.same(1.5, cytanb.Clamp(1.5, -1.5, 1.5))
        assert.are.same(1.5, cytanb.Clamp(5, -1.5, 1.5))
    end)

    it('Lerp', function ()
        assert.are.same(1, cytanb.Lerp(1, 2, -1))
        assert.are.same(1, cytanb.Lerp(1, 2, 0))
        assert.are.same(1.1, cytanb.Lerp(1, 2, 0.1))
        assert.are.same(1.9, cytanb.Lerp(1, 2, 0.9))
        assert.are.same(2, cytanb.Lerp(1, 2, 1))
        assert.are.same(2, cytanb.Lerp(1, 2, 2))
        assert.are.same(-1, cytanb.Lerp(-1, -2, -1))
        assert.are.same(-1, cytanb.Lerp(-1, -2, 0))
        assert.are.same(-1.5, cytanb.Lerp(-1, -2, 0.5))
        assert.are.same(-2, cytanb.Lerp(-1, -2, 1))
        assert.are.same(-2, cytanb.Lerp(-1, -2, 2))
    end)

    it('LerpUnclamped', function ()
        assert.are.same(0, cytanb.LerpUnclamped(1, 2, -1))
        assert.are.same(1, cytanb.LerpUnclamped(1, 2, 0))
        assert.are.same(1.1, cytanb.LerpUnclamped(1, 2, 0.1))
        assert.are.same(1.9, cytanb.LerpUnclamped(1, 2, 0.9))
        assert.are.same(2, cytanb.LerpUnclamped(1, 2, 1))
        assert.are.same(3, cytanb.LerpUnclamped(1, 2, 2))
        assert.are.same(0, cytanb.LerpUnclamped(-1, -2, -1))
        assert.are.same(-1, cytanb.LerpUnclamped(-1, -2, 0))
        assert.are.same(-1.5, cytanb.LerpUnclamped(-1, -2, 0.5))
        assert.are.same(-2, cytanb.LerpUnclamped(-1, -2, 1))
        assert.are.same(-3, cytanb.LerpUnclamped(-1, -2, 2))
    end)

    it('PingPong', function ()
        assert.are.same({0, 1}, {cytanb.PingPong(-33, 0)})

        assert.are.same({7, 1}, {cytanb.PingPong(-33, 10)})
        assert.are.same({9, 1}, {cytanb.PingPong(-31, 10)})
        assert.are.same({10, -1}, {cytanb.PingPong(-30, 10)})
        assert.are.same({9, -1}, {cytanb.PingPong(-29, 10)})
        assert.are.same({2, -1}, {cytanb.PingPong(-22, 10)})
        assert.are.same({1, -1}, {cytanb.PingPong(-21, 10)})
        assert.are.same({0, 1}, {cytanb.PingPong(-20, 10)})
        assert.are.same({1, 1}, {cytanb.PingPong(-19, 10)})
        assert.are.same({9, 1}, {cytanb.PingPong(-11, 10)})
        assert.are.same({10, -1}, {cytanb.PingPong(-10, 10)})
        assert.are.same({9, -1}, {cytanb.PingPong(-9, 10)})
        assert.are.same({8, -1}, {cytanb.PingPong(-8, 10)})
        assert.are.same({1, -1}, {cytanb.PingPong(-1, 10)})
        assert.are.same({0, 1}, {cytanb.PingPong(0, 10)})
        assert.are.same({8.25, 1}, {cytanb.PingPong(8.25, 10)})
        assert.are.same({10, -1}, {cytanb.PingPong(10, 10)})
        assert.are.same({9, -1}, {cytanb.PingPong(11, 10)})
        assert.are.same({1, -1}, {cytanb.PingPong(19, 10)})
        assert.are.same({0, 1}, {cytanb.PingPong(20, 10)})
        assert.are.same({1, 1}, {cytanb.PingPong(21, 10)})
        assert.are.same({2, 1}, {cytanb.PingPong(22, 10)})
        assert.are.same({9, 1}, {cytanb.PingPong(29, 10)})
        assert.are.same({10, -1}, {cytanb.PingPong(30, 10)})
        assert.are.same({7, -1}, {cytanb.PingPong(33, 10)})

        assert.are.same({-7, -1}, {cytanb.PingPong(-33, -10)})
        assert.are.same({-9, -1}, {cytanb.PingPong(-31, -10)})
        assert.are.same({-10, -1}, {cytanb.PingPong(-30, -10)})
        assert.are.same({-9, 1}, {cytanb.PingPong(-29, -10)})
        assert.are.same({-2, 1}, {cytanb.PingPong(-22, -10)})
        assert.are.same({0, 1}, {cytanb.PingPong(-20, -10)})
        assert.are.same({-1, -1}, {cytanb.PingPong(-19, -10)})
        assert.are.same({-9, -1}, {cytanb.PingPong(-11, -10)})
        assert.are.same({-10, -1}, {cytanb.PingPong(-10, -10)})
        assert.are.same({-8, 1}, {cytanb.PingPong(-8, -10)})
        assert.are.same({-1, 1}, {cytanb.PingPong(-1, -10)})
        assert.are.same({0, 1}, {cytanb.PingPong(0, -10)})
        assert.are.same({-8.25, -1}, {cytanb.PingPong(8.25, -10)})
        assert.are.same({-10, -1}, {cytanb.PingPong(10, -10)})
        assert.are.same({-9, 1}, {cytanb.PingPong(11, -10)})
        assert.are.same({0, 1}, {cytanb.PingPong(20, -10)})
        assert.are.same({-2, -1}, {cytanb.PingPong(22, -10)})
        assert.are.same({-10, -1}, {cytanb.PingPong(30, -10)})
        assert.are.same({-7, 1}, {cytanb.PingPong(33, -10)})
    end)

    it('VectorApproximatelyEquals', function ()
        assert.is_false(cytanb.VectorApproximatelyEquals(Vector2.__new(1, 1, 0), Vector2.__new(1.0 + 1E-05, 1.0 - 1E-05, 0)))
        assert.is_true(cytanb.VectorApproximatelyEquals(Vector2.__new(1, 1, 0), Vector2.__new(1.0 + 1E-06, 1.0 - 1E-06, 0)))
        assert.is_false(cytanb.VectorApproximatelyEquals(Vector2.__new(0, 0), Vector2.__new(1E-05, 0)))
        assert.is_true(cytanb.VectorApproximatelyEquals(Vector2.__new(0, 0), Vector2.__new(1E-06, 0)))

        assert.is_false(cytanb.VectorApproximatelyEquals(Vector3.__new(1, 1, 0), Vector3.__new(1.0 + 1E-04, 1.0 - 1E-04, 0)))
        assert.is_false(cytanb.VectorApproximatelyEquals(Vector3.__new(1, 1, 0), Vector3.__new(1.0 + 1E-05, 1.0 - 1E-05, 0)))
        assert.is_true(cytanb.VectorApproximatelyEquals(Vector3.__new(1, 1, 0), Vector3.__new(1.0 + 1E-06, 1.0 - 1E-06, 0)))
        assert.is_true(cytanb.VectorApproximatelyEquals(Vector3.__new(1, 1, 0), Vector3.__new(1.0 + 1E-07, 1.0 - 1E-07, 0)))
        assert.is_false(cytanb.VectorApproximatelyEquals(Vector3.__new(0, 0, 0), Vector3.__new(1E-05, 0, 0)))
        assert.is_true(cytanb.VectorApproximatelyEquals(Vector3.__new(0, 0, 0), Vector3.__new(1E-06, 0, 0)))
        assert.is_true(cytanb.VectorApproximatelyEquals(Vector3.__new(0, 0, 0), Vector3.__new(1E-07, 0, 0)))

        assert.is_false(cytanb.VectorApproximatelyEquals(Vector4.__new(1, 1, 0, 0), Vector4.__new(1.0 + 1E-05, 1.0 - 1E-05, 0, 0)))
        assert.is_true(cytanb.VectorApproximatelyEquals(Vector4.__new(1, 1, 0, 0), Vector4.__new(1.0 + 1E-06, 1.0 - 1E-06, 0, 0)))
        assert.is_false(cytanb.VectorApproximatelyEquals(Vector4.__new(0, 0, 0, 0), Vector4.__new(1E-05, 0, 0, 0)))
        assert.is_true(cytanb.VectorApproximatelyEquals(Vector4.__new(0, 0, 0, 0), Vector4.__new(1E-06, 0, 0, 0)))
    end)

    it('QuaternionApproximatelyEquals', function ()
        assert.is_false(cytanb.QuaternionApproximatelyEquals(Quaternion.AngleAxis(25, Vector3.right), Quaternion.AngleAxis(25 + 0.5, Vector3.right)))
        assert.is_true(cytanb.QuaternionApproximatelyEquals(Quaternion.AngleAxis(25, Vector3.right), Quaternion.AngleAxis(25 + 0.1, Vector3.right)))

        assert.is_false(cytanb.QuaternionApproximatelyEquals(Quaternion.AngleAxis(0, Vector3.right), Quaternion.AngleAxis(360, Vector3.right)))
        assert.is_true(cytanb.QuaternionApproximatelyEquals(Quaternion.AngleAxis(0, Vector3.right), Quaternion.AngleAxis(720, Vector3.right)))

        assert.is_false(cytanb.QuaternionApproximatelyEquals(Quaternion.AngleAxis(25, Vector3.right), Quaternion.AngleAxis(25 + 360, Vector3.right)))
        assert.is_true(cytanb.QuaternionApproximatelyEquals(Quaternion.AngleAxis(25, Vector3.right), Quaternion.AngleAxis(25 + 720, Vector3.right)))
    end)

    it('QuaternionToAngleAxis', function ()
        local a1, v1 = cytanb.QuaternionToAngleAxis(Quaternion.AngleAxis(0, Vector3.__new(3, -5, 7)))
        assert.are.equal(0, a1)
        assert.are.equal(Vector3.__new(1, 0, 0), v1)

        local a2, v2 = cytanb.QuaternionToAngleAxis(Quaternion.AngleAxis(90, Vector3.__new(3, -5, 7)))
        assert.are.equal(90, a2)
        assert.are.equal(Vector3.__new(0.3292928000, -0.5488213000, 0.7683498000), v2)

        local a3, v3 = cytanb.QuaternionToAngleAxis(Quaternion.AngleAxis(180, Vector3.__new(3, -5, 7)))
        assert.are.equal(180, a3)
        assert.are.equal(Vector3.__new(0.3292928000, -0.5488213000, 0.7683498000), v3)

        local a4, v4 = cytanb.QuaternionToAngleAxis(Quaternion.AngleAxis(360, Vector3.__new(3, -5, 7)))
        assert.are.equal(360, a4)
        assert.are.equal(Vector3.__new(1, 0, 0), v4)
        -- Unity では、360°の倍数 (ゼロを除く)のときは、axis のコンポーネントは、`+- Infinity` となる。
        -- Vector3.__new(-Infinity, Infinity, -Infinity)

        local a5, v5 = cytanb.QuaternionToAngleAxis(Quaternion.AngleAxis(-90, Vector3.__new(3, -5, 7)))
        assert.are.equal(90, a5)
        assert.are.equal(Vector3.__new(-0.3292928000, 0.5488213000, -0.7683498000), v5)

        local a6, v6 = cytanb.QuaternionToAngleAxis(Quaternion.AngleAxis(390, Vector3.__new(3, -5, 7)))
        assert.is_true(math.abs(330 - a6) <= 1E-06)
        assert.are.equal(Vector3.__new(-0.3292927000, 0.5488213000, -0.7683498000), v6)

        local a40, v40 = cytanb.QuaternionToAngleAxis(Quaternion.__new(10, 20, 30, 40))
        assert.are.equal(cytanb.Round(86.17744, 4), cytanb.Round(a40, 4))
        assert.are.equal(Vector3.__new(0.2672612000, 0.5345224000, 0.8017837000), v40)

        local a41, v41 = cytanb.QuaternionToAngleAxis(Quaternion.__new(0.000000000001, 0.000000000002, 0.000000000003, 0.000000000004))
        assert.are.equal(0, a41)
        assert.are.equal(Vector3.__new(1, 0, 0), v41)
    end)

    it('QuaternionTwist', function ()
        local q0 = Quaternion.AngleAxis(30, Vector3.__new(0, 0, 1))
        local d0 = Vector3.__new(0, 0, 0)
        local t0 = cytanb.QuaternionTwist(q0, d0)
        assert.are.equal(Quaternion.identity, t0)

        local q10 = Quaternion.AngleAxis(0, Vector3.__new(0, 0, 1))
        local d10 = Vector3.__new(0, 1, 1)
        local t10 = cytanb.QuaternionTwist(q10, d10)
        assert.are.equal(Quaternion.identity, t10)

        local q50axis = Vector3.__new(0, 0, 1)
        local q50dir = Vector3.__new(0, 1, 1)
        local q50 = Quaternion.AngleAxis(30, q50axis)
        local t50 = cytanb.QuaternionTwist(q50, q50dir)
        assert.are.equal(Quaternion.AngleAxis(21.45717, q50dir), t50)
        assert.are.equal(Quaternion.AngleAxis(21.09058, Vector3.__new(0.18616, -0.69475, 0.69475)), q50 * Quaternion.Inverse(t50))

        local q51 = Quaternion.AngleAxis(60, q50axis)
        local t51 = cytanb.QuaternionTwist(q51, q50dir)
        assert.are.equal(Quaternion.AngleAxis(44.41531, q50dir), t51)
        assert.are.equal(Quaternion.AngleAxis(41.40961, Vector3.__new(0.37796, -0.65465, 0.65465)), q51 * Quaternion.Inverse(t51))

        local q52 = Quaternion.AngleAxis(90, q50axis)
        local t52 = cytanb.QuaternionTwist(q52, q50dir)
        assert.are.equal(Quaternion.AngleAxis(70.52877, q50dir), t52)
        assert.are.equal(Quaternion.AngleAxis(60, Vector3.__new(0.57735, -0.57735, 0.57735)), q52 * Quaternion.Inverse(t52))

        local q53 = Quaternion.AngleAxis(180, q50axis)
        local t53 = cytanb.QuaternionTwist(q53, q50dir)
        assert.are.equal(Quaternion.AngleAxis(180, q50dir), t53)
        -- assert.are.equal(Quaternion.AngleAxis(90, Vector3.__new(1, 0, 0)), q53 * Quaternion.Inverse(t53))

        local q54 = Quaternion.AngleAxis(270, q50axis)
        local t54 = cytanb.QuaternionTwist(q54, q50dir)
        assert.are.equal(Quaternion.AngleAxis(289.4712, q50dir), t54)
        assert.are.equal(Quaternion.AngleAxis(60, Vector3.__new(0.57735, 0.57735, -0.57735)), q54 * Quaternion.Inverse(t54))

        local q55 = Quaternion.AngleAxis(330, q50axis)
        local t55 = cytanb.QuaternionTwist(q55, q50dir)
        assert.are.equal(Quaternion.AngleAxis(338.5429, q50dir), t55)
        assert.are.equal(Quaternion.AngleAxis(21.09058, Vector3.__new(0.18616, 0.69475, -0.69475)), q55 * Quaternion.Inverse(t55))

        local q56 = Quaternion.AngleAxis(360, q50axis)
        local t56 = cytanb.QuaternionTwist(q56, q50dir)
        assert.are.equal(Quaternion.AngleAxis(360, q50dir), t56)
        assert.are.equal(360, cytanb.QuaternionToAngleAxis(t56))

        local q57 = Quaternion.AngleAxis(720, q50axis)
        local t57 = cytanb.QuaternionTwist(q57, q50dir)
        assert.are.equal(Quaternion.AngleAxis(0, q50dir), t57)
        assert.are.equal(0, cytanb.QuaternionToAngleAxis(t57))

        local q58 = Quaternion.AngleAxis(1080, q50axis)
        local t58 = cytanb.QuaternionTwist(q58, q50dir)
        assert.are.equal(Quaternion.AngleAxis(360, q50dir), t58)
        assert.are.equal(360, cytanb.QuaternionToAngleAxis(t58))

        local q60 = Quaternion.AngleAxis(-30, q50axis)
        local t60 = cytanb.QuaternionTwist(q60, q50dir)
        assert.are.equal(Quaternion.AngleAxis(-21.45717, q50dir), t60)
        assert.are.equal(Quaternion.AngleAxis(21.09058, Vector3.__new(0.18616, 0.69475, -0.69475)), q60 * Quaternion.Inverse(t60))

        local q61 = Quaternion.AngleAxis(-180, q50axis)
        local t61 = cytanb.QuaternionTwist(q61, q50dir)
        assert.are.equal(Quaternion.AngleAxis(-180, q50dir), t61)
        -- assert.are.equal(Quaternion.AngleAxis(90, Vector3.__new(1, 0, 0)), q61 * Quaternion.Inverse(t61))

        local q62 = Quaternion.AngleAxis(-360, q50axis)
        local t62 = cytanb.QuaternionTwist(q62, q50dir)
        assert.are.equal(Quaternion.AngleAxis(-360, q50dir), t62)
        assert.are.equal(360, cytanb.QuaternionToAngleAxis(t62))

        local q63 = Quaternion.AngleAxis(-720, q50axis)
        local t63 = cytanb.QuaternionTwist(q63, q50dir)
        assert.are.equal(Quaternion.AngleAxis(0, q50dir), t63)
        assert.are.equal(0, cytanb.QuaternionToAngleAxis(t63))

        local q64 = Quaternion.AngleAxis(-1080, q50axis)
        local t64 = cytanb.QuaternionTwist(q64, q50dir)
        assert.are.equal(Quaternion.AngleAxis(-360, q50dir), t64)
        assert.are.equal(360, cytanb.QuaternionToAngleAxis(t64))

        local q70axis = Vector3.__new(0, 0, 1)
        local q70dir = Vector3.__new(0, 1, 0)
        local q70 = Quaternion.AngleAxis(30, q70axis)
        local t70 = cytanb.QuaternionTwist(q70, q70dir)
        assert.are.equal(Quaternion.AngleAxis(0, q70dir), t70)
        assert.are.equal(Quaternion.AngleAxis(30, Vector3.__new(0, 0, 1)), q70 * Quaternion.Inverse(t70))
    end)

    it('ApplyQuaternionToVector3', function ()
        assert.are.equal(Vector3.__new(6.0980760000, -5.0000000000, 4.5621780000), cytanb.ApplyQuaternionToVector3(Quaternion.AngleAxis(30, Vector3.up), Vector3.__new(3, -5, 7)))
        assert.are.equal(Vector3.__new(2.1036720000, -6.9570910000, 5.4930360000), cytanb.ApplyQuaternionToVector3(Quaternion.Euler(10, 20, -30), Vector3.__new(3, -5, 7)))
    end)

    it('RotateAround', function ()
        local v1, q1 = cytanb.RotateAround(Vector3.__new(2.0, 3.0, -5.0), Quaternion.AngleAxis(25, Vector3.__new(7.0, -9.0, 2.5)), Vector3.__new(-4.0, 13.0, 17.0), Quaternion.AngleAxis(15, Vector3.__new(4.5, 6.0, -5.5)))
        assert.is_true(cytanb.VectorApproximatelyEquals(Vector3.__new(-3.25236200, 5.38540600, -6.69512600), v1))
        assert.is_true(cytanb.QuaternionApproximatelyEquals(Quaternion.__new(0.18136640, -0.09619174, -0.05086813, 0.97737700), q1))

        local v20, q20 = cytanb.RotateAround(Vector3.__new(2.0, 3.0, 0.0), Quaternion.AngleAxis(90, Vector3.__new(1.0, 0.0, 0.0)), Vector3.__new(0.0, 2.0, 0.0), Quaternion.AngleAxis(90, Vector3.__new(0.0, 1.0, 0.0)))
        assert.is_true(cytanb.VectorApproximatelyEquals(Vector3.__new(0.0, 3.0, -2.0), v20))
        assert.is_true(cytanb.QuaternionApproximatelyEquals(Quaternion.__new(0.5, 0.5, -0.5, 0.5), q20))

        local v21, q21 = cytanb.RotateAround(Vector3.__new(2.0, 3.0, 0.0), Quaternion.AngleAxis(90, Vector3.__new(1.0, 0.0, 0.0)), Vector3.__new(0.0, 2.0, 0.0), Quaternion.AngleAxis(-30, Vector3.__new(0.0, 1.0, 1.0)))
        assert.is_true(cytanb.VectorApproximatelyEquals(Vector3.__new(2.08560400, 2.22590600, 0.77409410), v21))
        assert.is_true(cytanb.QuaternionApproximatelyEquals(Quaternion.__new(0.68301270, -0.25881910, 0.00000000, 0.68301270), q21))
    end)

    it('UUID', function ()
        local us_empty = '00000000-0000-0000-0000-000000000000'
        local uuid_empty = cytanb.UUIDFromNumbers(0, 0, 0, 0)
        assert.are.equal(us_empty, tostring(uuid_empty))
        assert.are.equal(uuid_empty, cytanb.UUIDFromNumbers())
        assert.are.equal(uuid_empty, cytanb.UUIDFromNumbers(0))
        assert.are.equal(uuid_empty, cytanb.UUIDFromNumbers(0, 0, 0))
        assert.are.equal(uuid_empty, cytanb.UUIDFromNumbers({}))
        assert.are.equal(uuid_empty, cytanb.UUIDFromNumbers({0}))
        assert.are.equal(uuid_empty, cytanb.UUIDFromNumbers({0, 0, 0, 0}))
        assert.are.equal(uuid_empty, cytanb.UUIDFromNumbers({0, 0, 0, 0}))
        assert.are.equal(uuid_empty, cytanb.UUIDFromNumbers(uuid_empty))
        assert.is_true(uuid_empty == cytanb.UUIDFromString(us_empty))
        assert.is_true(uuid_empty <= cytanb.UUIDFromString(us_empty))
        assert.is_false(uuid_empty < cytanb.UUIDFromString(us_empty))
        assert.is_true(uuid_empty < cytanb.UUIDFromNumbers(0, 0, 0, 1))
        assert.is_true(uuid_empty < cytanb.UUIDFromNumbers({1}))

        local uuid_std1 = '069f80ac-e66e-448c-b17c-5a54ea94dccc'
        local uuid_hex1 = '069F80acE66e448cb17c5A54ea94dcCc'
        local uuid1 = cytanb.UUIDFromString(uuid_hex1)
        assert.are.same(4, #uuid1)
        assert.are.same(0x069f80ac, uuid1[1])
        assert.are.same(0xe66e448c, uuid1[2])
        assert.are.same(0xb17c5a54, uuid1[3])
        assert.are.same(0xea94dccc, uuid1[4])
        assert.are.same(uuid1, cytanb.UUIDFromString(uuid_std1))
        assert.are.same(uuid_std1, tostring(uuid1))
        assert.is_true(uuid1 == cytanb.UUIDFromString(uuid_std1))
        assert.is_true(uuid1 <= cytanb.UUIDFromString(uuid_std1))
        assert.is_true(uuid_empty < uuid1)
        assert.is_true(uuid_empty <= uuid1)
        assert.is_true(uuid1 > cytanb.UUIDFromString('069f80ac-e66e-448c-b17c-5a54ea94dcca'))
        assert.is_true(uuid1 >= cytanb.UUIDFromString('069f80ac-e66e-448c-b17c-5a54ea94dcca'))
        assert.are.same(uuid_std1, tostring(cytanb.UUIDFromNumbers(uuid1)))
        assert.is_true(uuid1 == cytanb.UUIDFromNumbers(uuid1))

        assert.are.same('urn:uuid:00000000-0000-0000-0000-000000000000', 'urn:uuid:' .. uuid_empty)
        assert.are.same('00000000-0000-0000-0000-00000000000098765', uuid_empty .. 98765)
        assert.are.same('069f80ac-e66e-448c-b17c-5a54ea94dccc00000000-0000-0000-0000-000000000000', uuid1 .. uuid_empty)

        assert.is_nil(cytanb.UUIDFromString('069f80ac@e66e-448c-b17c-5a54ea94dccc'))
        assert.is_nil(cytanb.UUIDFromString('069f80ac-e66e%448c-b17c-5a54ea94dccc'))
        assert.is_nil(cytanb.UUIDFromString('069f80ac-e66e-448c$b17c-5a54ea94dccc'))
        assert.is_nil(cytanb.UUIDFromString('069f80ac-e66e-448c-b17cA5a54ea94dccc'))
        assert.is_nil(cytanb.UUIDFromString('G69f80ac-e66e-448c-b17c-5a54ea94dccc'))
        assert.is_nil(cytanb.UUIDFromString('069f80ac-Z66e-448c-b17c-5a54ea94dccc'))
        assert.is_nil(cytanb.UUIDFromString('069f80ac-e66e--48c-b17c-5a54ea94dccc'))
        assert.is_nil(cytanb.UUIDFromString('069f80ac-e66e-448c-Z17c-5a54ea94dccc'))
        assert.is_nil(cytanb.UUIDFromString('069f80ac-e66e-448c-b17c-Ha54ea94dccc'))
        assert.is_nil(cytanb.UUIDFromString('069f80ac-e66e-448c-b17c-5a54ea94dccc0'))
        assert.is_nil(cytanb.UUIDFromString('069f80ac-e66e-448c-b17c-5a54ea94dcc'))
        assert.is_nil(cytanb.UUIDFromString('069F8ac-E66e448cb17c5A54ea94dcCc'))
        assert.is_nil(cytanb.UUIDFromString('069f80ac-e66e-448c-b17c-5a54Za94dccc'))

        assert.is_nil(cytanb.UUIDFromString('帰弱怲帳弴崵崶強常弹孡形幣孤履てぁ⽂千恄居商0000000000'))
        assert.is_nil(cytanb.UUIDFromString('帰弱怲帳弴崵崶強-常弹孡形-幣孤履てЭぁ⽂千恄-居商0000000000'))

        local uuidTable = {}
        local samples = {}
        local sampleSize = 16
        for i = 1, 256 do
            local uuidN = cytanb.RandomUUID()
            assert.are.same(4, #uuidN)
            assert.are.same(4, bit32.band(bit32.rshift(uuidN[2], 12), 0xF))
            assert.are.same(2, bit32.band(bit32.rshift(uuidN[3], 30), 0x3))
            local uuidstrN = tostring(uuidN)
            assert.are.same(36, #uuidstrN)
            assert.are.same(uuidN, cytanb.UUIDFromString(uuidstrN))
            assert.is_nil(uuidTable[uuidstrN])
            uuidTable[uuidstrN] = uuidN

            for j = 1, 4 do
                local r = uuidN[j]
                for k = 0, 28, 4 do
                    -- バージョンビットは無視する
                    if (j ~= 2 or k ~= 12) and (j ~= 3 or k ~= 28) then
                        local s = bit32.band(bit32.rshift(r, k), 0xF) + 1
                        samples[s] = (samples[s] or 0) + 1
                    end
                end
            end
        end

        if options.calcUUIDVariance then
            print('---- UUID Random Variance ----')
            local sum = 0
            for i = 1, sampleSize do
                sum = sum + (samples[i] or 0)
            end
            local average = sum / sampleSize
            local varianceSum = 0
            for i = 1, sampleSize do
                varianceSum = varianceSum + math.pow((samples[i] or 0) - average, 2)
                print((i - 1) .. ' | ' .. samples[i] .. ' | ' .. ((samples[i] or 0) - average))
            end
            local variance = varianceSum / sampleSize
            print('variance | ' .. variance)
            print('--------')
        end
    end)

    it('CircularQueue', function ()
        stub(cytanb, 'Log')
        assert.has_error(function () cytanb.CreateCircularQueue(0) end)
        assert.has_error(function () cytanb.CreateCircularQueue(0.9) end)
        assert.has_error(function () cytanb.CreateCircularQueue(-2) end)

        assert.are.same(1, cytanb.CreateCircularQueue(1).MaxSize())
        assert.are.same(1, cytanb.CreateCircularQueue(1.8).MaxSize())
        assert.are.same(2, cytanb.CreateCircularQueue(2.1).MaxSize())

        local q1 = cytanb.CreateCircularQueue(4)
        assert.are.same(4, q1.MaxSize())
        assert.are.same(0, q1.Size())
        assert.is_true(q1.IsEmpty())
        assert.is_false(q1.IsFull())

        assert.are.same(nil, q1.Poll())
        assert.are.same(nil, q1.PollLast())
        assert.are.same(nil, q1.Peek())
        assert.are.same(nil, q1.PeekLast())
        assert.are.same(nil, q1.Get(1))
        assert.are.same(nil, q1.Get(2))

        assert.is_true(q1.Offer('apple'))
        assert.are.same(1, q1.Size())
        assert.is_false(q1.IsEmpty())
        assert.is_false(q1.IsFull())
        assert.are.same('apple', q1.Peek())
        assert.are.same('apple', q1.PeekLast())

        assert.is_true(q1.Offer('orange'))
        assert.are.same(2, q1.Size())
        assert.is_false(q1.IsEmpty())
        assert.is_false(q1.IsFull())
        assert.are.same('apple', q1.Peek())
        assert.are.same('orange', q1.PeekLast())
        assert.are.same(nil, q1.Get(0))
        assert.are.same('apple', q1.Get(1))
        assert.are.same('orange', q1.Get(2))
        assert.are.same(nil, q1.Get(3))

        assert.is_true(q1.Offer('banana'))
        assert.are.same(3, q1.Size())
        assert.is_false(q1.IsEmpty())
        assert.is_false(q1.IsFull())
        assert.are.same('banana', q1.Get(3))
        assert.are.same('apple', q1.Poll())
        assert.are.same(2, q1.Size())
        assert.are.same('orange', q1.Peek())
        assert.are.same('banana', q1.PeekLast())
        assert.are.same('orange', q1.Get(1))
        assert.are.same('banana', q1.Get(2))
        assert.are.same(nil, q1.Get(3))

        assert.is_true(q1.Offer('pineapple'))
        assert.are.same(3, q1.Size())
        assert.are.same('pineapple', q1.PollLast())
        assert.are.same(2, q1.Size())
        assert.is_true(q1.Offer('cherry'))
        assert.are.same(3, q1.Size())

        assert.is_true(q1.Offer('peach'))
        assert.are.same(4, q1.Size())
        assert.is_false(q1.IsEmpty())
        assert.is_true(q1.IsFull())
        assert.are.same('orange', q1.Get(1))
        assert.are.same('peach', q1.Get(4))

        assert.is_true(q1.Offer('melon'))
        assert.are.same(4, q1.Size())
        assert.is_false(q1.IsEmpty())
        assert.is_true(q1.IsFull())
        assert.are.same('banana', q1.Peek())
        assert.are.same('melon', q1.Get(4))

        assert.are.same('banana', q1.Poll())
        assert.are.same(3, q1.Size())
        assert.is_false(q1.IsEmpty())
        assert.is_false(q1.IsFull())

        assert.are.same('cherry', q1.Poll())
        assert.are.same(2, q1.Size())

        assert.are.same('peach', q1.Poll())
        assert.are.same(1, q1.Size())

        assert.are.same('melon', q1.Poll())
        assert.are.same(0, q1.Size())
        assert.is_true(q1.IsEmpty())
        assert.is_false(q1.IsFull())
        assert.are.same(nil, q1.Poll())
        assert.are.same(nil, q1.Peek())

        assert.is_true(q1.Offer('grape'))
        assert.are.same('grape', q1.Peek())
        assert.are.same(1, q1.Size())
        assert.is_false(q1.IsEmpty())

        q1.Clear()
        assert.are.same(4, q1.MaxSize())
        assert.are.same(0, q1.Size())
        assert.is_true(q1.IsEmpty())
        assert.is_false(q1.IsFull())

        assert.is_true(q1.Offer('strawberry'))
        assert.are.same(1, q1.Size())
        assert.is_false(q1.IsEmpty())
        assert.are.same('strawberry', q1.PollLast())
        assert.is_true(q1.IsEmpty())

        assert.is_true(q1.OfferFirst('lemon'))
        assert.are.same(1, q1.Size())
        assert.are.same('lemon', q1.Peek())
        assert.are.same('lemon', q1.PeekLast())
        assert.is_true(q1.OfferFirst('blueberry'))
        assert.are.same(2, q1.Size())
        assert.are.same('blueberry', q1.Peek())
        assert.are.same('lemon', q1.PeekLast())
        assert.is_true(q1.Offer('mango'))
        assert.are.same(3, q1.Size())
        assert.is_false(q1.IsFull())
        assert.are.same('blueberry', q1.Peek())
        assert.are.same('mango', q1.PeekLast())
        assert.is_true(q1.OfferFirst('pineapple'))
        assert.are.same(4, q1.Size())
        assert.is_true(q1.IsFull())
        assert.are.same('pineapple', q1.Peek())
        assert.are.same('mango', q1.PeekLast())
        assert.is_true(q1.OfferFirst('plum'))
        assert.are.same(4, q1.Size())
        assert.is_true(q1.IsFull())
        assert.are.same('plum', q1.Poll())
        assert.are.same(3, q1.Size())
        assert.are.same('lemon', q1.PollLast())
        assert.are.same(2, q1.Size())
        assert.are.same('pineapple', q1.Poll())
        assert.are.same(1, q1.Size())
        assert.are.same('blueberry', q1.PollLast())
        assert.are.same(0, q1.Size())
        assert.is_true(q1.IsEmpty())

        cytanb.Log:revert()
    end)

    it('Color', function ()
        local indexColorList = {
            {iv = {0, 0, 0}, rgb24 = 0xff0000, hsv = {h = 0, s = 1, v = 1}},
            {iv = {1, 1, 0}, rgb24 = 0xffbf40, hsv = {h = 0.1108202, s = 0.7490196, v = 1}},
            {iv = {2, 2, 0}, rgb24 = 0xd5ff80, hsv = {h = 0.2217848, s = 0.4980392, v = 1}},
            {iv = {3, 3, 0}, rgb24 = 0xbfffbf, hsv = {h = 0.3333333, s = 0.2509804, v = 1}},
            {iv = {4, 0, 1}, rgb24 = 0x00cc88, hsv = {h = 0.4444444, s = 1, v = 0.8}},
            {iv = {5, 2, 1}, rgb24 = 0x66aacc, hsv = {h = 0.5555555, s = 0.5, v = 0.8}},
            {iv = {6, 1, 2}, rgb24 = 0x262699, hsv = {h = 0.6666667, s = 0.751634, v = 0.6}},
            {iv = {7, 3, 2}, rgb24 = 0x8c7399, hsv = {h = 0.7763157, s = 0.248366, v = 0.6}},
            {iv = {8, 0, 3}, rgb24 = 0x660044, hsv = {h = 0.8888889, s = 1, v = 0.4}},
            {iv = {9, 1, 1}, rgb24 = 0x444444, hsv = {h = 0, s = 0, v = 0.2666667}},
            {iv = {9, 1, 3}, rgb24 = 0x222222, hsv = {h = 0, s = 0, v = 0.1333333}, alt_iv = {9, 2, 4}},
            {iv = {9, 2, 4}, rgb24 = 0x222222, hsv = {h = 0, s = 0, v = 0.1333333}},
            {iv = {9, 0, 0}, rgb24 = 0x000000, hsv = {h = 0, s = 0, v = 0}},
            {iv = {9, 2, 0}, rgb24 = 0xaaaaaa, hsv = {h = 0, s = 0, v = 0.6666667}},
            {iv = {9, 3, 0}, rgb24 = 0xffffff, hsv = {h = 0, s = 0, v = 1}}
        }

        for i, colorValues in ipairs(indexColorList) do
            local iv = colorValues.iv
            local index = iv[1] + cytanb.ColorHueSamples * (iv[2] + cytanb.ColorSaturationSamples * iv[3])
            local rgb32 = bit32.bor(0xff000000, colorValues.rgb24)
            local c32 = cytanb.ColorFromARGB32(rgb32)
            local cidx = cytanb.ColorFromIndex(index)
            local cidx_rgb32 = cytanb.ColorToARGB32(cidx)
            local diff = cidx - c32
            local rdiff = Color.__new(cytanb.Round(diff.r, 2), cytanb.Round(diff.g, 2), cytanb.Round(diff.b, 2), cytanb.Round(diff.a, 2))
            -- print(string.format('rgb32 = 0x%08x, cidx_rgb32 = 0x%08x, diff = {r = %f, g = %f, b = %f}', rgb32, cidx_rgb32, diff.r, diff.g, diff.b))
            assert.are.equal(Color.clear, rdiff)
            assert.are.equal(rgb32, cidx_rgb32)

            local chsv = colorValues.hsv
            local h, s, v = cytanb.ColorRGBToHSV(c32)
            -- print(string.format('rgb32 = 0x%08x: h = %f, s = %f, v = %f', rgb32, h, s, v))
            assert.are.equal(cytanb.Round(chsv.h, 5), cytanb.Round(h, 5))
            assert.are.equal(cytanb.Round(chsv.s, 5), cytanb.Round(s, 5))
            assert.are.equal(cytanb.Round(chsv.v, 5), cytanb.Round(v, 5))

            local ridx = cytanb.ColorToIndex(c32)
            -- print(string.format('rgb32 = 0x%08x: idx = %d, ridx = %d', rgb32, index, ridx))
            if colorValues.alt_iv then
                local alt_iv = colorValues.alt_iv
                local tidx = index == ridx and index or (alt_iv[1] + cytanb.ColorHueSamples * (alt_iv[2] + cytanb.ColorSaturationSamples * alt_iv[3]))
                assert.are.equal(tidx, ridx)
            else
                assert.are.equal(index, ridx)
            end
        end

        local conflictCount = 0
        local colorMap = {}
        for i = 1, cytanb.ColorMapSize do
            local cidx = cytanb.ColorFromIndex(i - 1)
            local hashCode = cidx.GetHashCode()
            local ce = colorMap[hashCode]
            local conflict
            if ce then
                local diff = cidx - ce
                local rdiff = Color.__new(cytanb.Round(diff.r, 5), cytanb.Round(diff.g, 5), cytanb.Round(diff.b, 5), cytanb.Round(diff.a, 5))
                conflict = rdiff ~= Color.clear
            else
                conflict = false
            end

            if conflict then
                conflictCount = conflictCount + 1
            else
                colorMap[hashCode] = cidx
            end
        end
        assert.are.equal(0, conflictCount)
    end)

    it('ValueTableConversion', function ()
        assert.is_nil(cytanb.ColorToTable(nil))
        assert.is_nil(cytanb.ColorFromTable(nil))
        local v100 = Color.__new(0, 0.75, 1.25, 0.5)
        local t100 = {__CYTANB_TYPE = 'Color', r = 0, g = 0.75, b = 1.25, a = 0.5}
        assert.are.same(t100, cytanb.ColorToTable(v100))
        local vf100, uf100 = cytanb.ColorFromTable(t100)
        assert.are.equal(v100, vf100)
        assert.is_false(uf100)

        local vf101, uf101 = cytanb.ColorFromTable({__CYTANB_TYPE = 'Color', r = 0, g = 0.75, b = 1.25, a = 0.5, addition = 98765})
        assert.are.equal(v100, vf101)
        assert.is_true(uf101)

        local vf102, uf102 = cytanb.ColorFromTable({r = 0, g = 0.75, b = 1.25, a = 0.5, addition = 98765})
        assert.are.equal(v100, vf102)
        assert.is_true(uf102)

        assert.is_nil(cytanb.ColorFromTable({r = 0, b = 1.25, a = 0.5, addition = 98765}))
        assert.is_nil(cytanb.ColorFromTable({__CYTANB_TYPE = 'INVALID_TYPE', r = 0, g = 0.75, b = 1.25, a = 0.5}))
        assert.is_nil(cytanb.ColorFromTable({__CYTANB_TYPE = 'Vector4', x = 0, y = 0, z = 0, w = 1}))

        assert.is_nil(cytanb.Vector2ToTable(nil))
        assert.is_nil(cytanb.Vector2FromTable(nil))
        local v200 = Vector2.__new(123, -49.75)
        local t200 = {__CYTANB_TYPE = 'Vector2', x = 123, y = -49.75}
        assert.are.same(t200, cytanb.Vector2ToTable(v200))
        local vf200, uf200 = cytanb.Vector2FromTable(t200)
        assert.are.equal(v200, vf200)
        assert.is_false(uf200)

        local vf201, uf201 = cytanb.Vector2FromTable({__CYTANB_TYPE = 'Vector2', x = 123, y = -49.75, addition = 98765})
        assert.are.equal(v200, vf201)
        assert.is_true(uf201)

        local vf202, uf202 = cytanb.Vector2FromTable({x = 123, y = -49.75, addition = 98765})
        assert.are.equal(v200, vf202)
        assert.is_true(uf202)

        assert.is_nil(cytanb.Vector2FromTable({y = -49.75, addition = 98765}))
        assert.is_nil(cytanb.Vector2FromTable({__CYTANB_TYPE = 'INVALID_TYPE', x = 123, y = -49.75}))
        assert.is_nil(cytanb.Vector2FromTable({__CYTANB_TYPE = 'Quaternion', x = 0, y = 0, z = 0, w = 1}))

        assert.is_nil(cytanb.Vector3ToTable(nil))
        assert.is_nil(cytanb.Vector3FromTable(nil))
        local v300 = Vector3.__new(123, -49.75, 0)
        local t300 = {__CYTANB_TYPE = 'Vector3', x = 123, y = -49.75, z = 0}
        assert.are.same(t300, cytanb.Vector3ToTable(v300))
        local vf300, uf300 = cytanb.Vector3FromTable(t300)
        assert.are.equal(v300, vf300)
        assert.is_false(uf300)

        local vf301, uf301 = cytanb.Vector3FromTable({__CYTANB_TYPE = 'Vector3', x = 123, y = -49.75, z = 0, addition = 98765})
        assert.are.equal(v300, vf301)
        assert.is_true(uf301)

        local vf302, uf302 = cytanb.Vector3FromTable({x = 123, y = -49.75, z = 0, addition = 98765})
        assert.are.equal(v300, vf302)
        assert.is_true(uf302)

        assert.is_nil(cytanb.Vector3FromTable({x = 123, z = 0, addition = 98765}))
        assert.is_nil(cytanb.Vector3FromTable({__CYTANB_TYPE = 'INVALID_TYPE', x = 123, y = -49.75, z = 0}))
        assert.is_nil(cytanb.Vector3FromTable({__CYTANB_TYPE = 'Quaternion', x = 0, y = 0, z = 0, w = 1}))

        assert.is_nil(cytanb.Vector4ToTable(nil))
        assert.is_nil(cytanb.Vector4FromTable(nil))
        local v400 = Vector4.__new(123, -49.75, 0, 0.25)
        local t400 = {__CYTANB_TYPE = 'Vector4', x = 123, y = -49.75, z = 0, w = 0.25}
        assert.are.same(t400, cytanb.Vector4ToTable(v400))
        local vf400, uf400 = cytanb.Vector4FromTable(t400)
        assert.are.equal(v400, vf400)
        assert.is_false(uf400)

        local vf401, uf401 = cytanb.Vector4FromTable({__CYTANB_TYPE = 'Vector4', x = 123, y = -49.75, z = 0, w = 0.25, addition = 98765})
        assert.are.equal(v400, vf401)
        assert.is_true(uf401)

        local vf402, uf402 = cytanb.Vector4FromTable({x = 123, y = -49.75, z = 0, w = 0.25, addition = 98765})
        assert.are.equal(v400, vf402)
        assert.is_true(uf402)

        assert.is_nil(cytanb.Vector4FromTable({x = 123, y = -49.75, w = 0.25, addition = 98765}))
        assert.is_nil(cytanb.Vector4FromTable({__CYTANB_TYPE = 'INVALID_TYPE', x = 123, y = -49.75, z = 0, w = 0.25}))
        assert.is_nil(cytanb.Vector4FromTable({__CYTANB_TYPE = 'Quaternion', x = 0, y = 0, z = 0, w = 1}))

        assert.is_nil(cytanb.QuaternionToTable(nil))
        assert.is_nil(cytanb.QuaternionFromTable(nil))
        local v500 = Quaternion.__new(-0.109807625412941, 0.146410167217255, -0.183012709021568, 0.965925812721252)
        local t500 = {__CYTANB_TYPE = 'Quaternion', x = -0.109807625412941, y = 0.146410167217255, z = -0.183012709021568, w = 0.965925812721252}
        assert.are.same(t500, cytanb.QuaternionToTable(v500))
        local vf500, uf500 = cytanb.QuaternionFromTable(t500)
        assert.are.equal(v500, vf500)
        assert.is_false(uf500)

        local vf501, uf501 = cytanb.QuaternionFromTable({__CYTANB_TYPE = 'Quaternion', x = -0.109807625412941, y = 0.146410167217255, z = -0.183012709021568, w = 0.965925812721252, addition = 98765})
        assert.are.equal(v500, vf501)
        assert.is_true(uf501)

        local vf502, uf502 = cytanb.QuaternionFromTable({x = 0, y = 0, z = 0, w = 1, addition = 98765})
        assert.are.equal(Quaternion.identity, vf502)
        assert.is_true(uf502)

        assert.is_nil(cytanb.QuaternionFromTable({y = 0.146410167217255, z = -0.183012709021568, w = 0.965925812721252, addition = 98765}))
        assert.is_nil(cytanb.QuaternionFromTable({__CYTANB_TYPE = 'INVALID_TYPE', x = 0, y = 0, z = 0, w = 1}))
    end)

    it('TableToSerializable', function ()
        -- test for [unicode replace string bug?](https://github.com/moonsharp-devs/moonsharp/issues/187)
        -- but only affect on MoonSharp script engine
        assert.are.same('|㌣|', string.gsub('|㌣|', '#', '@'))
        assert.are.same('|㌣|', string.gsub('|㌣|', '#', {['#'] = '@'}))
        assert.are.same({solidas_and_cytanb_tag_data = '#__CYTANB_SOLIDUS#__CYTANB#__CYTANB|伯|㌣た⽟千す協㑁低あ|#__CYTANB#__CYTANB'}, cytanb.TableToSerializable({solidas_and_cytanb_tag_data = '/#__CYTANB|伯|㌣た⽟千す協㑁低あ|#__CYTANB'}))

        assert.are.same({}, cytanb.TableToSerializable({}))
        assert.are.same({foo = 123.25, bar = 'abc', baz = true, qux = {['quux#__CYTANB_NEGATIVE_NUMBER'] = '-9876.5', corge = false}}, cytanb.TableToSerializable({foo = 123.25, bar = 'abc', baz = true, qux = {quux = -9876.5, corge = false}}))
        assert.are.same({['#__CYTANB_NEGATIVE_NUMBER'] = '-100', bar = 'abc'}, cytanb.TableToSerializable({[''] = -100, bar = 'abc'}))

        assert.are.same({['1#__CYTANB_ARRAY_NUMBER'] = 100, ['2#__CYTANB_ARRAY_NUMBER'] = 200, ['3#__CYTANB_ARRAY_NUMBER'] = 300, ['4#__CYTANB_ARRAY_NUMBER'] = 400}, cytanb.TableToSerializable({100, 200, 300, 400}))
        assert.are.same({['1#__CYTANB_ARRAY_NUMBER#__CYTANB_NEGATIVE_NUMBER'] = '-100'}, cytanb.TableToSerializable({-100}))
        assert.are.same({['1#__CYTANB_ARRAY_NUMBER'] = 100, ['2#__CYTANB_ARRAY_NUMBER'] = 200, ['3#__CYTANB_ARRAY_NUMBER#__CYTANB_NEGATIVE_NUMBER'] = '-300', ['4#__CYTANB_ARRAY_NUMBER'] = 400}, cytanb.TableToSerializable({100, 200, -300, 400}))
        assert.are.same({['1#__CYTANB_ARRAY_NUMBER'] = 'apple', ['2#__CYTANB_ARRAY_NUMBER'] = 'orange', ['3#__CYTANB_ARRAY_NUMBER'] = {['1#__CYTANB_ARRAY_NUMBER'] = 'cyan', ['2#__CYTANB_ARRAY_NUMBER'] = 'magenta'}}, cytanb.TableToSerializable({'apple', 'orange', {'cyan', 'magenta'}}))
        assert.are.same({['1#__CYTANB_ARRAY_NUMBER'] = 100, ['2#__CYTANB_ARRAY_NUMBER'] = 200, ['3#__CYTANB_ARRAY_NUMBER'] = {['1#__CYTANB_ARRAY_NUMBER'] = 2010, ['2#__CYTANB_ARRAY_NUMBER#__CYTANB_NEGATIVE_NUMBER'] = '-2020', ['3#__CYTANB_ARRAY_NUMBER'] = 2030}}, cytanb.TableToSerializable({100, 200, {2010, -2020, 2030}}))
        assert.are.same({['1#__CYTANB_ARRAY_NUMBER'] = {['1#__CYTANB_ARRAY_NUMBER'] = 100, ['2#__CYTANB_ARRAY_NUMBER'] = 200}}, cytanb.TableToSerializable({{100, 200}}))
        assert.are.same({['1#__CYTANB_ARRAY_NUMBER'] = {['1#__CYTANB_ARRAY_NUMBER'] = 'a'}, ['2#__CYTANB_ARRAY_NUMBER'] = {['1#__CYTANB_ARRAY_NUMBER'] = 'b'}}, cytanb.TableToSerializable({{'a'}, {'b'}}))

        assert.are.same({['foo#__CYTANB_SOLIDUSbar'] = 'apple#__CYTANB_SOLIDUSorange', ['fake_negative#__CYTANB#__CYTANB_NEGATIVE_NUMBERtypeIsString'] = '-6', qux = {['quux#__CYTANB_NEGATIVE_NUMBER'] = '-9876.5', ['color\\#__CYTANB_SOLIDUSnote'] = 'red#__CYTANB_SOLIDUSblue', ['fake_array#__CYTANB#__CYTANB_ARRAY_NUMBER'] = 'fake#__CYTANB#__CYTANB_SOLIDUSsolidus'}}, cytanb.TableToSerializable({['foo/bar'] = 'apple/orange', ['fake_negative#__CYTANB_NEGATIVE_NUMBERtypeIsString'] = '-6', qux = {quux = -9876.5, ['color\\/note'] = 'red/blue', ['fake_array#__CYTANB_ARRAY_NUMBER'] = 'fake#__CYTANB_SOLIDUSsolidus'}}))

        assert.are.same(
            {
                foo = 'apple',
                position = {['__CYTANB_TYPE'] = 'Vector3', x = 123, ['y#__CYTANB_NEGATIVE_NUMBER'] = '-456', z = 789},
                rotation = {['__CYTANB_TYPE'] = 'Quaternion', x = 0.683012664318085, y = 0.1830126941204, ['z#__CYTANB_NEGATIVE_NUMBER'] = '-0.1830126941204', w = 0.683012664318085}
            },
            cytanb.TableToSerializable({
                foo = 'apple',
                position = cytanb.Vector3ToTable(Vector3.__new(123, -456, 789)),
                rotation = cytanb.QuaternionToTable(Quaternion.__new(0.683012664318085, 0.1830126941204, -0.1830126941204, 0.683012664318085))
            })
        )

        assert.are.same(
            {
                color = {['__CYTANB_TYPE'] = 'Color', r = 0, g = 0.25, b = 1, a = 0.5},
                uv = {['__CYTANB_TYPE'] = 'Vector2', x = 123, ['y#__CYTANB_NEGATIVE_NUMBER'] = '-456'},
                column = {['__CYTANB_TYPE'] = 'Vector4', x = 5, y = 6, ['z#__CYTANB_NEGATIVE_NUMBER'] = '-7', w = 8}
            },
            cytanb.TableToSerializable({
                color = cytanb.ColorToTable(Color.__new(0, 0.25, 1, 0.5)),
                uv = cytanb.Vector2ToTable(Vector2.__new(123, -456)),
                column = cytanb.Vector4ToTable(Vector4.__new(5, 6, -7, 8))
            })
        )

        -- @TODO ignore invalid type keys (`function` or `thread` or `userdata`)
        -- local fun_key = function () end
        -- local co_key = coroutine.create(function () end)
        -- assert.are.same(
        --     {},
        --     cytanb.TableToSerializable({
        --         [fun_key] = 123,
        --         [co_key] = 456
        --     })
        -- )

        local circularTable = {foo = 123.25}
        circularTable.ref = circularTable
        assert.has_error(function () cytanb.TableToSerializable(circularTable) end)
    end)

    it('TableFromSerializable', function ()
        assert.are.same({solidas_and_cytanb_tag_data = '/#__CYTANB|伯|㌣た⽟千す協㑁低あ|#__CYTANB'}, cytanb.TableFromSerializable({solidas_and_cytanb_tag_data = '#__CYTANB_SOLIDUS#__CYTANB#__CYTANB|伯|㌣た⽟千す協㑁低あ|#__CYTANB#__CYTANB'}))

        assert.are.same({}, cytanb.TableFromSerializable({}))
        assert.are.same({foo = 123.25, bar = 'abc', baz = true, qux = {quux = -9876.5, corge = false}}, cytanb.TableFromSerializable({foo = 123.25, bar = 'abc', baz = true, qux = {['quux#__CYTANB_NEGATIVE_NUMBER'] = '-9876.5', corge = false}}))
        assert.are.same({[''] = -100, bar = 'abc'}, cytanb.TableFromSerializable({['#__CYTANB_NEGATIVE_NUMBER'] = '-100', bar = 'abc'}))

        assert.are.same({100, 200, 300, 400}, cytanb.TableFromSerializable({100, 200, 300, 400}))
        assert.are.same({-100}, cytanb.TableFromSerializable({['1#__CYTANB_ARRAY_NUMBER#__CYTANB_NEGATIVE_NUMBER'] = '-100'}))
        assert.are.same({100, 200, -300, 400}, cytanb.TableFromSerializable({['1#__CYTANB_ARRAY_NUMBER'] = 100, ['2#__CYTANB_ARRAY_NUMBER'] = 200, ['3#__CYTANB_ARRAY_NUMBER#__CYTANB_NEGATIVE_NUMBER'] = '-300', ['4#__CYTANB_ARRAY_NUMBER'] = 400}))
        assert.are.same({'apple', 'orange', {'cyan', 'magenta'}}, cytanb.TableFromSerializable({'apple', 'orange', {'cyan', 'magenta'}}))
        assert.are.same({100, 200, {2010, -2020, 2030}}, cytanb.TableFromSerializable({100, 200, {['1#__CYTANB_ARRAY_NUMBER'] = 2010, ['2#__CYTANB_ARRAY_NUMBER#__CYTANB_NEGATIVE_NUMBER'] = '-2020', ['3#__CYTANB_ARRAY_NUMBER'] = 2030}}))
        assert.are.same({{100, 200}}, cytanb.TableFromSerializable({['1#__CYTANB_ARRAY_NUMBER'] = {['1#__CYTANB_ARRAY_NUMBER'] = 100, ['2#__CYTANB_ARRAY_NUMBER'] = 200}}))
        assert.are.same({{'a'}, {'b'}}, cytanb.TableFromSerializable({['1#__CYTANB_ARRAY_NUMBER'] = {['1#__CYTANB_ARRAY_NUMBER'] = 'a'}, ['2#__CYTANB_ARRAY_NUMBER'] = {['1#__CYTANB_ARRAY_NUMBER'] = 'b'}}))

        assert.are.same({['foo/bar'] = 'apple/orange', ['fake_negative#__CYTANB_NEGATIVE_NUMBERtypeIsString'] = '-6', qux = {quux = -9876.5, ['color\\/note'] = 'red/blue', ['fake_array#__CYTANB_ARRAY_NUMBER'] = 'fake#__CYTANB_SOLIDUSsolidus'}}, cytanb.TableFromSerializable({['foo#__CYTANB_SOLIDUSbar'] = 'apple#__CYTANB_SOLIDUSorange', ['fake_negative#__CYTANB#__CYTANB_NEGATIVE_NUMBERtypeIsString'] = '-6', qux = {['quux#__CYTANB_NEGATIVE_NUMBER'] = '-9876.5', ['color\\#__CYTANB_SOLIDUSnote'] = 'red#__CYTANB_SOLIDUSblue', ['fake_array#__CYTANB#__CYTANB_ARRAY_NUMBER'] = 'fake#__CYTANB#__CYTANB_SOLIDUSsolidus'}}))
        assert.are.same({['#__CYTANB_invalid_key'] = 'unknown#__CYTANB#__CYTANB_escape_sequence'}, cytanb.TableFromSerializable({['#__CYTANB_invalid_key'] = 'unknown#__CYTANB#__CYTANB#__CYTANB_escape_sequence'}))

        local s700 = {foo = 'apple', position = {['__CYTANB_TYPE'] = 'Vector3', x = 123, ['y#__CYTANB_NEGATIVE_NUMBER'] = '-456', z = 789}, rotation = {['__CYTANB_TYPE'] = 'Quaternion', x = 0.683012664318085, y = 0.1830126941204, ['z#__CYTANB_NEGATIVE_NUMBER'] = '-0.1830126941204', w = 0.683012664318085}}
        local t700 = cytanb.TableFromSerializable(s700)
        assert.are.equal('apple', t700.foo)
        assert.are.equal(Vector3.__new(123, -456, 789), t700.position)
        assert.are.equal(Quaternion.__new(0.683012664318085, 0.1830126941204, -0.1830126941204, 0.683012664318085), t700.rotation)

        local t701 = cytanb.TableFromSerializable(s700, true)
        assert.are.same('apple', t701.foo)
        assert.are.same({['__CYTANB_TYPE'] = 'Vector3', x = 123, y = -456, z = 789}, t701.position)
        assert.are.same({['__CYTANB_TYPE'] = 'Quaternion', x = 0.683012664318085, y = 0.1830126941204, z = -0.1830126941204, w = 0.683012664318085}, t701.rotation)

        local s710 = {foo = 'apple', position = {['__CYTANB_TYPE'] = 'Vector3', x = 123, ['y#__CYTANB_NEGATIVE_NUMBER'] = '-456', z = 789, addition = 'black'}, rotation = {x = 0.683012664318085, y = 0.1830126941204, ['z#__CYTANB_NEGATIVE_NUMBER'] = '-0.1830126941204', w = 0.683012664318085}}
        local t710 = cytanb.TableFromSerializable(s710)
        assert.are.same('apple', t710.foo)
        assert.are.same({['__CYTANB_TYPE'] = 'Vector3', x = 123, y = -456, z = 789, addition = 'black'}, t710.position)
        assert.are.same({x = 0.683012664318085, y = 0.1830126941204, z = -0.1830126941204, w = 0.683012664318085}, t710.rotation)

        local s720 = {color = {['__CYTANB_TYPE'] = 'Color', r = 0, g = 0.25, b = 1, a = 0.5}, uv = {['__CYTANB_TYPE'] = 'Vector2', x = 123, ['y#__CYTANB_NEGATIVE_NUMBER'] = '-456'}, column = {['__CYTANB_TYPE'] = 'Vector4', x = 5, y = 6, ['z#__CYTANB_NEGATIVE_NUMBER'] = '-7', w = 8}}
        local t720 = cytanb.TableFromSerializable(s720)
        assert.are.equal(Color.__new(0, 0.25, 1, 0.5), t720.color)
        assert.are.equal(Vector2.__new(123, -456), t720.uv)
        assert.are.equal(Vector4.__new(5, 6, -7, 8), t720.column)
    end)

    it('Message', function ()
        local lastVciName = vci.fake.GetVciName()
        vci.fake.SetVciName('test-cytanb-module')

        local cbMap = {
            cb1 = function (sender, name, parameterMap) end,
            cb2 = function (sender, name, parameterMap) end,
            cb3 = function (sender, name, parameterMap) end,
            cbMapComment = function (sender, name, parameterMap) end,
            cbMapNotification = function (sender, name, parameterMap) end,
            cbCytanbComment = function (sender, name, parameterMap) end,
            cbCytanbNotification = function (sender, name, parameterMap) end,
            cbComment = function (sender, name, message) end,
            cbNotification = function (sender, name, message) end,
        }

        for key, val in pairs(cbMap) do
            stub(cbMap, key)
        end

        local dp1 = cytanb.OnMessage('foo', cbMap.cb1)
        local dp2 = cytanb.OnMessage('foo', cbMap.cb2)
        local dp3 = cytanb.OnMessage('bar', cbMap.cb3)
        local dpMapComment = cytanb.OnMessage('comment', cbMap.cbMapComment)
        local dpMapNotification = cytanb.OnMessage('notification', cbMap.cbMapNotification)
        local dpCytanbComment = cytanb.OnMessage(cytanb.DedicatedCommentMessageName, cbMap.cbCytanbComment)
        local dpCytanbNotification = cytanb.OnMessage(cytanb.DedicatedNotificationMessageName, cbMap.cbCytanbNotification)
        local dpComment = cytanb.OnCommentMessage(cbMap.cbComment)
        local dpNotification = cytanb.OnNotificationMessage(cbMap.cbNotification)

        assert.has_error(function () cytanb.EmitMessage('INVALID', true) end)
        assert.has_error(function () cytanb.EmitMessage('INVALID', false) end)
        assert.has_error(function () cytanb.EmitMessage('INVALID', 0) end)
        assert.has_error(function () cytanb.EmitMessage('INVALID', '') end)
        assert.has_error(function () cytanb.EmitMessage('INVALID', 'hogepiyo') end)

        cytanb.EmitMessage('foo')
        assert.stub(cbMap.cb1).was.called(1)
        assert.stub(cbMap.cb1).was.called_with({type = 'vci', name = 'test-cytanb-module', commentSource = ''}, 'foo', {[cytanb.InstanceIDParameterName] = cytanb.InstanceID()})
        assert.stub(cbMap.cb2).was.called(1)
        assert.stub(cbMap.cb3).was.called(0)

        cytanb.EmitMessage('bar', {hoge = 123.45, piyo = 'abc', fuga = true, hogera = {hogehoge = -9876.5, piyopiyo = false}})
        assert.stub(cbMap.cb1).was.called(1)
        assert.stub(cbMap.cb2).was.called(1)
        assert.stub(cbMap.cb3).was.called(1)
        assert.stub(cbMap.cb3).was.called_with({type = 'vci', name = 'test-cytanb-module', commentSource = ''}, 'bar', {[cytanb.InstanceIDParameterName] = cytanb.InstanceID(), hoge = 123.45, piyo = 'abc', fuga = true, hogera = {hogehoge = -9876.5, piyopiyo = false}})

        vci.message.Emit('foo', -36.5)
        assert.stub(cbMap.cb1).was.called(2)
        assert.stub(cbMap.cb2).was.called(2)
        assert.stub(cbMap.cb2).was.called_with({type = 'vci', name = 'test-cytanb-module', commentSource = ''}, 'foo', {[cytanb.MessageValueParameterName] = -36.5})
        assert.stub(cbMap.cb3).was.called(1)

        vci.message.Emit('bar', '')
        assert.stub(cbMap.cb1).was.called(2)
        assert.stub(cbMap.cb2).was.called(2)
        assert.stub(cbMap.cb3).was.called(2)
        assert.stub(cbMap.cb3).was.called_with({type = 'vci', name = 'test-cytanb-module', commentSource = ''}, 'bar', {[cytanb.MessageValueParameterName] = ''})

        vci.message.Emit('bar', '{"num":123}')
        assert.stub(cbMap.cb1).was.called(2)
        assert.stub(cbMap.cb2).was.called(2)
        assert.stub(cbMap.cb3).was.called(3)
        assert.stub(cbMap.cb3).was.called_with({type = 'vci', name = 'test-cytanb-module', commentSource = ''}, 'bar', {[cytanb.MessageValueParameterName] = '{"num":123}'})

        vci.message.Emit('bar', '{"__CYTANB_INSTANCE_ID":"","num_cy":789}')
        assert.stub(cbMap.cb1).was.called(2)
        assert.stub(cbMap.cb2).was.called(2)
        assert.stub(cbMap.cb3).was.called(4)
        assert.stub(cbMap.cb3).was.called_with({type = 'vci', name = 'test-cytanb-module', commentSource = ''}, 'bar', {[cytanb.InstanceIDParameterName] = '', num_cy = 789})

        assert.stub(cbMap.cbMapComment).was.called(0)
        assert.stub(cbMap.cbCytanbComment).was.called(0)
        assert.stub(cbMap.cbComment).was.called(0)

        vci.fake.EmitVciNicoliveCommentMessage('TestUser', 'Hello, World!')
        assert.stub(cbMap.cbMapComment).was.called(1)
        assert.stub(cbMap.cbMapComment).was.called_with({type = 'comment', name = 'TestUser', commentSource = 'Nicolive'}, 'comment', {[cytanb.MessageValueParameterName] = 'Hello, World!'})
        assert.stub(cbMap.cbCytanbComment).was.called(0)
        assert.stub(cbMap.cbComment).was.called(1)
        assert.stub(cbMap.cbComment).was.called_with({type = 'comment', name = 'TestUser', commentSource = 'Nicolive'}, 'comment', 'Hello, World!')

        vci.fake.EmitVciTwitterCommentMessage('TwitterUser', '')
        assert.stub(cbMap.cbMapComment).was.called(2)
        assert.stub(cbMap.cbMapComment).was.called_with({type = 'comment', name = 'TwitterUser', commentSource = 'Twitter'}, 'comment', {[cytanb.MessageValueParameterName] = ''})
        assert.stub(cbMap.cbCytanbComment).was.called(0)
        assert.stub(cbMap.cbComment).was.called(2)
        assert.stub(cbMap.cbComment).was.called_with({type = 'comment', name = 'TwitterUser', commentSource = 'Twitter'}, 'comment', '')

        vci.fake.EmitVciShowroomCommentMessage('ShowroomUser', '50')
        assert.stub(cbMap.cbMapComment).was.called(3)
        assert.stub(cbMap.cbMapComment).was.called_with({type = 'comment', name = 'ShowroomUser', commentSource = 'Showroom'}, 'comment', {[cytanb.MessageValueParameterName] = '50'})
        assert.stub(cbMap.cbCytanbComment).was.called(0)
        assert.stub(cbMap.cbComment).was.called(3)
        assert.stub(cbMap.cbComment).was.called_with({type = 'comment', name = 'ShowroomUser', commentSource = 'Showroom'}, 'comment', '50')

        cytanb.EmitCommentMessage('DummyComment sender-omitted')
        assert.stub(cbMap.cbMapComment).was.called(3)
        assert.stub(cbMap.cbCytanbComment).was.called(1)
        assert.stub(cbMap.cbCytanbComment).was.called_with({
            type = 'comment',
            name = '',
            commentSource = '',
            [cytanb.MessageOriginalSender] = {type = 'vci', name = 'test-cytanb-module', commentSource = ''}
        }, cytanb.DedicatedCommentMessageName, {
            [cytanb.InstanceIDParameterName] = cytanb.InstanceID(),
            [cytanb.MessageSenderOverride] = {type = 'comment', name = '', commentSource = ''},
            [cytanb.MessageValueParameterName] = 'DummyComment sender-omitted'}
        )

        assert.stub(cbMap.cbComment).was.called(4)
        assert.stub(cbMap.cbComment).was.called_with({
            type = 'comment',
            name = '',
            commentSource = '',
            [cytanb.MessageOriginalSender] = {type = 'vci', name = 'test-cytanb-module', commentSource = ''}
        }, 'comment', 'DummyComment sender-omitted')

        cytanb.EmitCommentMessage('', {name = 'NicoUser', commentSource = 'Nicolive'})
        assert.stub(cbMap.cbMapComment).was.called(3)
        assert.stub(cbMap.cbCytanbComment).was.called(2)
        assert.stub(cbMap.cbCytanbComment).was.called_with({
            type = 'comment',
            name = 'NicoUser',
            commentSource = 'Nicolive',
            [cytanb.MessageOriginalSender] = {type = 'vci', name = 'test-cytanb-module', commentSource = ''}
        }, cytanb.DedicatedCommentMessageName, {
            [cytanb.InstanceIDParameterName] = cytanb.InstanceID(),
            [cytanb.MessageSenderOverride] = {type = 'comment', name = 'NicoUser', commentSource = 'Nicolive'},
            [cytanb.MessageValueParameterName] = ''}
        )

        assert.stub(cbMap.cbComment).was.called(5)
        assert.stub(cbMap.cbComment).was.called_with({
            type = 'comment',
            name = 'NicoUser',
            commentSource = 'Nicolive',
            [cytanb.MessageOriginalSender] = {type = 'vci', name = 'test-cytanb-module', commentSource = ''}
        }, 'comment', '')

        cytanb.EmitCommentMessage('{"DummyTwitterComment":""}', {name = 'Twitter user A', commentSource = 'Twitter'})
        assert.stub(cbMap.cbMapComment).was.called(3)
        assert.stub(cbMap.cbCytanbComment).was.called(3)
        assert.stub(cbMap.cbCytanbComment).was.called_with({
            type = 'comment',
            name = 'Twitter user A',
            commentSource = 'Twitter',
            [cytanb.MessageOriginalSender] = {type = 'vci', name = 'test-cytanb-module', commentSource = ''}
        }, cytanb.DedicatedCommentMessageName, {
            [cytanb.InstanceIDParameterName] = cytanb.InstanceID(),
            [cytanb.MessageSenderOverride] = {type = 'comment', name = 'Twitter user A', commentSource = 'Twitter'},
            [cytanb.MessageValueParameterName] = '{"DummyTwitterComment":""}'}
        )

        assert.stub(cbMap.cbComment).was.called(6)
        assert.stub(cbMap.cbComment).was.called_with({
            type = 'comment',
            name = 'Twitter user A',
            commentSource = 'Twitter',
            [cytanb.MessageOriginalSender] = {type = 'vci', name = 'test-cytanb-module', commentSource = ''}
        }, 'comment', '{"DummyTwitterComment":""}')

        cytanb.EmitCommentMessage('1', {name = 'SR user C', commentSource = 'Showroom'})
        assert.stub(cbMap.cbMapComment).was.called(3)
        assert.stub(cbMap.cbCytanbComment).was.called(4)
        assert.stub(cbMap.cbCytanbComment).was.called_with({
            type = 'comment',
            name = 'SR user C',
            commentSource = 'Showroom',
            [cytanb.MessageOriginalSender] = {type = 'vci', name = 'test-cytanb-module', commentSource = ''}
        }, cytanb.DedicatedCommentMessageName, {
            [cytanb.InstanceIDParameterName] = cytanb.InstanceID(),
            [cytanb.MessageSenderOverride] = {type = 'comment', name = 'SR user C', commentSource = 'Showroom'},
            [cytanb.MessageValueParameterName] = '1'}
        )

        assert.stub(cbMap.cbComment).was.called(7)
        assert.stub(cbMap.cbComment).was.called_with({
            type = 'comment',
            name = 'SR user C',
            commentSource = 'Showroom',
            [cytanb.MessageOriginalSender] = {type = 'vci', name = 'test-cytanb-module', commentSource = ''}
        }, 'comment', '1')

        cytanb.EmitMessage('comment', {
            [cytanb.MessageSenderOverride] = 'invalid-sender',
            [cytanb.MessageValueParameterName] = 'test-invalid-sender-override'
        })
        assert.stub(cbMap.cbMapComment).was.called(4)
        assert.stub(cbMap.cbMapComment).was.called_with({
            type = 'vci',
            name = 'test-cytanb-module',
            commentSource = ''
        }, 'comment', {
            [cytanb.InstanceIDParameterName] = cytanb.InstanceID(),
            [cytanb.MessageSenderOverride] = 'invalid-sender',
            [cytanb.MessageValueParameterName] = 'test-invalid-sender-override'}
        )

        assert.stub(cbMap.cbCytanbComment).was.called(4)

        assert.stub(cbMap.cbComment).was.called(8)
        assert.stub(cbMap.cbComment).was.called_with({
            type = 'vci',
            name = 'test-cytanb-module',
            commentSource = ''
        }, 'comment', 'test-invalid-sender-override')

        cytanb.EmitMessage('comment', {
            [cytanb.MessageSenderOverride] = {type = 123, name = 'loose-sender2', commentSource = true},
            [cytanb.MessageValueParameterName] = 'loose-sender-message2'
        })
        assert.stub(cbMap.cbMapComment).was.called(5)
        assert.stub(cbMap.cbMapComment).was.called_with({
            type = '123',
            name = 'loose-sender2',
            commentSource = 'true',
            [cytanb.MessageOriginalSender] = {type = 'vci', name = 'test-cytanb-module', commentSource = ''}
        }, 'comment', {
            [cytanb.InstanceIDParameterName] = cytanb.InstanceID(),
            [cytanb.MessageSenderOverride] = {type = 123, name = 'loose-sender2', commentSource = true},
            [cytanb.MessageValueParameterName] = 'loose-sender-message2'}
        )

        assert.stub(cbMap.cbCytanbComment).was.called(4)

        assert.stub(cbMap.cbComment).was.called(9)
        assert.stub(cbMap.cbComment).was.called_with({
            type = '123',
            name = 'loose-sender2',
            commentSource = 'true',
            [cytanb.MessageOriginalSender] = {type = 'vci', name = 'test-cytanb-module', commentSource = ''}
        }, 'comment', 'loose-sender-message2')

        cytanb.EmitMessage('comment', {
            [cytanb.MessageSenderOverride] = {type = false, unsupportedParameter = 'unsupportedValue'},
            [cytanb.MessageValueParameterName] = 'loose-sender-message3'
        })
        assert.stub(cbMap.cbMapComment).was.called(6)
        assert.stub(cbMap.cbMapComment).was.called_with({
            type = 'false',
            name = 'test-cytanb-module',
            commentSource = '',
            [cytanb.MessageOriginalSender] = {type = 'vci', name = 'test-cytanb-module', commentSource = ''}
        }, 'comment', {
            [cytanb.InstanceIDParameterName] = cytanb.InstanceID(),
            [cytanb.MessageSenderOverride] = {type = false, unsupportedParameter = 'unsupportedValue'},
            [cytanb.MessageValueParameterName] = 'loose-sender-message3'}
        )

        assert.stub(cbMap.cbCytanbComment).was.called(4)

        assert.stub(cbMap.cbComment).was.called(10)
        assert.stub(cbMap.cbComment).was.called_with({
            type = '123',
            name = 'loose-sender2',
            commentSource = 'true',
            [cytanb.MessageOriginalSender] = {type = 'vci', name = 'test-cytanb-module', commentSource = ''}
        }, 'comment', 'loose-sender-message2')

        cytanb.EmitCommentMessage('{"content":"nested"}', {name = 'NestedTestUser', commentSource = 'BarTV'})
        assert.stub(cbMap.cbMapComment).was.called(6)
        assert.stub(cbMap.cbCytanbComment).was.called(5)
        assert.stub(cbMap.cbCytanbComment).was.called_with({
            type = 'comment',
            name = 'NestedTestUser',
            commentSource = 'BarTV',
            [cytanb.MessageOriginalSender] = {type = 'vci', name = 'test-cytanb-module', commentSource = ''}
        }, cytanb.DedicatedCommentMessageName, {
            [cytanb.InstanceIDParameterName] = cytanb.InstanceID(),
            [cytanb.MessageSenderOverride] = {type = 'comment', name = 'NestedTestUser', commentSource = 'BarTV'},
            [cytanb.MessageValueParameterName] = '{"content":"nested"}'}
        )

        assert.stub(cbMap.cbComment).was.called(11)
        assert.stub(cbMap.cbComment).was.called_with({
            type = 'comment',
            name = 'NestedTestUser',
            commentSource = 'BarTV',
            [cytanb.MessageOriginalSender] = {type = 'vci', name = 'test-cytanb-module', commentSource = ''}
        }, 'comment', '{"content":"nested"}')

        cytanb.EmitMessage('comment', {
            [cytanb.MessageSenderOverride] = {name = 'TestInvalidJsonUser', commentSource = 'BazTV'},
            [cytanb.MessageValueParameterName] = '{invalid json 404}'
        })
        assert.stub(cbMap.cbMapComment).was.called(7)
        assert.stub(cbMap.cbMapComment).was.called_with({
            type = 'vci',
            name = 'TestInvalidJsonUser',
            commentSource = 'BazTV',
            [cytanb.MessageOriginalSender] = {type = 'vci', name = 'test-cytanb-module', commentSource = ''}
        }, 'comment', {
            [cytanb.InstanceIDParameterName] = cytanb.InstanceID(),
            [cytanb.MessageSenderOverride] = {name = 'TestInvalidJsonUser', commentSource = 'BazTV'},
            [cytanb.MessageValueParameterName] = '{invalid json 404}'}
        )

        assert.stub(cbMap.cbCytanbComment).was.called(5)

        assert.stub(cbMap.cbComment).was.called(12)
        assert.stub(cbMap.cbComment).was.called_with({
            type = 'vci',
            name = 'TestInvalidJsonUser',
            commentSource = 'BazTV',
            [cytanb.MessageOriginalSender] = {type = 'vci', name = 'test-cytanb-module', commentSource = ''}
        }, 'comment', '{invalid json 404}')

        assert.stub(cbMap.cbMapNotification).was.called(0)
        assert.stub(cbMap.cbNotification).was.called(0)

        vci.fake.EmitVciJoinedNotificationMessage('joined-user-d')
        assert.stub(cbMap.cbMapNotification).was.called(1)
        assert.stub(cbMap.cbMapNotification).was.called_with({type = 'notification', name = 'joined-user-d', commentSource = ''}, 'notification', {[cytanb.MessageValueParameterName] = 'joined'})
        assert.stub(cbMap.cbCytanbNotification).was.called(0)
        assert.stub(cbMap.cbNotification).was.called(1)
        assert.stub(cbMap.cbNotification).was.called_with({type = 'notification', name = 'joined-user-d', commentSource = ''}, 'notification', 'joined')

        vci.fake.EmitVciLeftNotificationMessage('left-user-e')
        assert.stub(cbMap.cbMapNotification).was.called(2)
        assert.stub(cbMap.cbMapNotification).was.called_with({type = 'notification', name = 'left-user-e', commentSource = ''}, 'notification', {[cytanb.MessageValueParameterName] = 'left'})
        assert.stub(cbMap.cbCytanbNotification).was.called(0)
        assert.stub(cbMap.cbNotification).was.called(2)
        assert.stub(cbMap.cbNotification).was.called_with({type = 'notification', name = 'left-user-e', commentSource = ''}, 'notification', 'left')

        cytanb.EmitNotificationMessage('DummyNotification sender-omitted')
        assert.stub(cbMap.cbMapNotification).was.called(2)
        assert.stub(cbMap.cbCytanbNotification).was.called(1)
        assert.stub(cbMap.cbCytanbNotification).was.called_with({
            type = 'notification',
            name = '',
            commentSource = '',
            [cytanb.MessageOriginalSender] = {type = 'vci', name = 'test-cytanb-module', commentSource = ''}
        }, cytanb.DedicatedNotificationMessageName, {
            [cytanb.InstanceIDParameterName] = cytanb.InstanceID(),
            [cytanb.MessageSenderOverride] = {type = 'notification', name = '', commentSource = ''},
            [cytanb.MessageValueParameterName] = 'DummyNotification sender-omitted'
        })

        assert.stub(cbMap.cbNotification).was.called(3)
        assert.stub(cbMap.cbNotification).was.called_with({
            type = 'notification',
            name = '',
            commentSource = '',
            [cytanb.MessageOriginalSender] = {type = 'vci', name = 'test-cytanb-module', commentSource = ''}
        }, 'notification', 'DummyNotification sender-omitted')

        cytanb.EmitNotificationMessage('joined', {name = 'dummy-joined-user-f'})
        assert.stub(cbMap.cbMapNotification).was.called(2)
        assert.stub(cbMap.cbCytanbNotification).was.called(2)
        assert.stub(cbMap.cbCytanbNotification).was.called_with({
            type = 'notification',
            name = 'dummy-joined-user-f',
            commentSource = '',
            [cytanb.MessageOriginalSender] = {type = 'vci', name = 'test-cytanb-module', commentSource = ''}
        }, cytanb.DedicatedNotificationMessageName, {
            [cytanb.InstanceIDParameterName] = cytanb.InstanceID(),
            [cytanb.MessageSenderOverride] = {type = 'notification', name = 'dummy-joined-user-f', commentSource = ''},
            [cytanb.MessageValueParameterName] = 'joined'
        })

        assert.stub(cbMap.cbNotification).was.called(4)
        assert.stub(cbMap.cbNotification).was.called_with({
            type = 'notification',
            name = 'dummy-joined-user-f',
            commentSource = '',
            [cytanb.MessageOriginalSender] = {type = 'vci', name = 'test-cytanb-module', commentSource = ''}
        }, 'notification', 'joined')

        cytanb.EmitNotificationMessage('left', {name = 'dummy-left-user-g'})
        assert.stub(cbMap.cbMapNotification).was.called(2)
        assert.stub(cbMap.cbCytanbNotification).was.called(3)
        assert.stub(cbMap.cbCytanbNotification).was.called_with({
            type = 'notification',
            name = 'dummy-left-user-g',
            commentSource = '',
            [cytanb.MessageOriginalSender] = {type = 'vci', name = 'test-cytanb-module', commentSource = ''}
        }, cytanb.DedicatedNotificationMessageName, {
            [cytanb.InstanceIDParameterName] = cytanb.InstanceID(),
            [cytanb.MessageSenderOverride] = {type = 'notification', name = 'dummy-left-user-g', commentSource = ''},
            [cytanb.MessageValueParameterName] = 'left'
        })

        assert.stub(cbMap.cbNotification).was.called(5)
        assert.stub(cbMap.cbNotification).was.called_with({
            type = 'notification',
            name = 'dummy-left-user-g',
            commentSource = '',
            [cytanb.MessageOriginalSender] = {type = 'vci', name = 'test-cytanb-module', commentSource = ''}
        }, 'notification', 'left')

        assert.stub(cbMap.cb1).was.called(2)
        assert.stub(cbMap.cb2).was.called(2)
        assert.stub(cbMap.cb3).was.called(4)
        assert.stub(cbMap.cbMapComment).was.called(7)
        assert.stub(cbMap.cbCytanbComment).was.called(5)
        assert.stub(cbMap.cbComment).was.called(12)

        dp1.Off()
        dp2.Off()
        dp3.Off()
        dpMapComment.Off()
        dpMapNotification.Off()
        dpCytanbComment.Off()
        dpCytanbNotification.Off()
        dpComment.Off()
        dpNotification.Off()

        vci.fake.ClearMessageCallbacks()

        for key, val in pairs(cbMap) do
            cbMap[key]:revert()
        end

        --------
        local looseMapCommentSender = nil
        local looseMapCommentParameterMap = nil
        local looseCommentSender = nil
        local looseCommentMessage = nil

        cytanb.OnMessage('comment', function (sender, name, parameterMap)
            looseMapCommentSender = sender
            looseMapCommentParameterMap = parameterMap
        end)

        cytanb.OnCommentMessage(function (sender, name, message)
            looseCommentSender = sender
            looseCommentMessage = message
        end)

        cytanb.EmitMessage('comment', {
            [cytanb.MessageValueParameterName] = {strProp = 'foobar', numProp = -302},
            [cytanb.MessageSenderOverride] = {name = 'TableMessenger', commentSource = 'TableLive'}
        })
        assert.are.same(looseMapCommentSender, looseCommentSender)
        assert.are.same({
            type = 'vci',
            name = 'TableMessenger',
            commentSource = 'TableLive',
            [cytanb.MessageOriginalSender] = {type = 'vci', name = 'test-cytanb-module', commentSource = ''}
        }, looseCommentSender)
        assert.are.same({name = 'TableMessenger', commentSource = 'TableLive'}, looseMapCommentParameterMap[cytanb.MessageSenderOverride])
        assert.are.same({strProp = 'foobar', numProp = -302}, looseMapCommentParameterMap[cytanb.MessageValueParameterName])
        assert.are.same('table', string.sub(looseCommentMessage, 1, #'table'))

        local looseNotificationSender = nil
        local looseNotificationParameterMap = nil
        cytanb.OnMessage(cytanb.DedicatedNotificationMessageName, function (sender, name, parameterMap)
            looseNotificationSender = sender
            looseNotificationParameterMap = parameterMap
        end)

        cytanb.EmitNotificationMessage(false, {
            type = -7.5,
            name = cytanb.Vector3ToTable(Vector3.__new(5, -6, 7)),
            commentSource = {foo = 'HOGE'}
        });
        assert.are.same('-7.5', looseNotificationSender.type)
        assert.are.same('(5.0, -6.0, 7.0)', looseNotificationSender.name)
        assert.are.same('table', string.sub(looseNotificationSender.commentSource, 1, #'table'))
        assert.are.same('false', looseNotificationParameterMap[cytanb.MessageValueParameterName])
        assert.are.same(-7.5, looseNotificationParameterMap[cytanb.MessageSenderOverride].type)
        assert.are.equal(Vector3.__new(5, -6, 7), looseNotificationParameterMap[cytanb.MessageSenderOverride].name)
        assert.are.same({foo = 'HOGE'}, looseNotificationParameterMap[cytanb.MessageSenderOverride].commentSource)

        vci.fake.ClearMessageCallbacks()
        --------

        vci.fake.SetVciName(lastVciName)
    end)

    it('Instance message', function ()
        local lastVciName = vci.fake.GetVciName()
        vci.fake.SetVciName('test-instance-module')

        local cbMap = {
            cb1 = function (sender, name, parameterMap) end,
            cb2 = function (sender, name, parameterMap) end
        }

        for key, val in pairs(cbMap) do
            stub(cbMap, key)
        end

        cytanb.OnInstanceMessage('foo', cbMap.cb1)
        cytanb.OnMessage('foo', cbMap.cb2)

        cytanb.EmitMessage('foo')
        assert.stub(cbMap.cb1).was.called(1)
        assert.stub(cbMap.cb1).was.called_with({type = 'vci', name = 'test-instance-module', commentSource = ''}, 'foo', {[cytanb.InstanceIDParameterName] = cytanb.InstanceID()})
        assert.stub(cbMap.cb2).was.called(1)

        cytanb.EmitMessage('foo', {hoge = 123.45, piyo = 'abc', fuga = true, hogera = {hogehoge = -9876.5, piyopiyo = false}})
        assert.stub(cbMap.cb1).was.called(2)
        assert.stub(cbMap.cb2).was.called_with({type = 'vci', name = 'test-instance-module', commentSource = ''}, 'foo', {[cytanb.InstanceIDParameterName] = cytanb.InstanceID(), hoge = 123.45, piyo = 'abc', fuga = true, hogera = {hogehoge = -9876.5, piyopiyo = false}})
        assert.stub(cbMap.cb2).was.called(2)

        vci.fake.EmitVciMessage('test-instance-module', 'foo', '{"__CYTANB_INSTANCE_ID":"12345678-1234-1234-1234-123456789abc","num":256}')
        assert.stub(cbMap.cb1).was.called(2)
        assert.stub(cbMap.cb2).was.called(3)
        assert.stub(cbMap.cb2).was.called_with({type = 'vci', name = 'test-instance-module', commentSource = ''}, 'foo', {[cytanb.InstanceIDParameterName] = '12345678-1234-1234-1234-123456789abc', num = 256})

        vci.fake.ClearMessageCallbacks()

        for key, val in pairs(cbMap) do
            cbMap[key]:revert()
        end

        vci.fake.SetVciName(lastVciName)
    end)

    it('MessageTo', function ()
        local lastVciName = vci.fake.GetVciName()
        vci.fake.SetVciName('test-message-to-module')

        local cbMap = {
            cb1 = function (sender, name, parameterMap) end,
            cb2 = function (sender, name, parameterMap) end
        }

        for key, val in pairs(cbMap) do
            stub(cbMap, key)
        end

        stub(cytanb, 'Log')

        cytanb.OnInstanceMessage('foo', cbMap.cb1)
        cytanb.OnMessage('foo', cbMap.cb2)

        cytanb.EmitInstanceMessage('foo')
        assert.stub(cbMap.cb1).was.called(1)
        assert.stub(cbMap.cb1).was.called_with({type = 'vci', name = 'test-message-to-module', commentSource = ''}, 'foo', {[cytanb.InstanceIDParameterName] = cytanb.InstanceID()})
        assert.stub(cbMap.cb2).was.called(1)

        cytanb.EmitInstanceMessage('foo', {hoge = 123.45, piyo = 'abc', fuga = true, hogera = {hogehoge = -9876.5, piyopiyo = false}})
        assert.stub(cbMap.cb1).was.called(2)
        assert.stub(cbMap.cb2).was.called(2)
        assert.stub(cbMap.cb2).was.called_with({type = 'vci', name = 'test-message-to-module', commentSource = ''}, 'foo', {[cytanb.InstanceIDParameterName] = cytanb.InstanceID(), hoge = 123.45, piyo = 'abc', fuga = true, hogera = {hogehoge = -9876.5, piyopiyo = false}})

        cytanb.EmitMessageTo('foo', { num = 256 }, cytanb.InstanceID())
        assert.stub(cbMap.cb1).was.called(3)
        assert.stub(cbMap.cb2).was.called(3)
        assert.stub(cbMap.cb2).was.called_with({type = 'vci', name = 'test-message-to-module', commentSource = ''}, 'foo', {[cytanb.InstanceIDParameterName] = cytanb.InstanceID(), num = 256})

        vci.fake.EmitVciMessageTo('test-message-to-module', 'foo', '{"__CYTANB_INSTANCE_ID":"12345678-1234-1234-1234-123456789abc","num":256}', cytanb.InstanceID())
        assert.stub(cbMap.cb1).was.called(3)
        assert.stub(cbMap.cb2).was.called(4)
        assert.stub(cbMap.cb2).was.called_with({type = 'vci', name = 'test-message-to-module', commentSource = ''}, 'foo', {[cytanb.InstanceIDParameterName] = '12345678-1234-1234-1234-123456789abc', num = 256})

        cytanb.EmitMessageTo('foo', { num = 500 }, '')
        assert.stub(cbMap.cb1).was.called(3)
        assert.stub(cbMap.cb2).was.called(4)
        assert.stub(cytanb.Log).was.called(1)
        assert.stub(cytanb.Log).was.called_with(cytanb.LogLevelWarn, 'EmitMessageTo: targetID is not specified: ')

        cytanb.EmitMessageTo('foo', { num = 501 }, nil)
        assert.stub(cbMap.cb1).was.called(3)
        assert.stub(cbMap.cb2).was.called(4)
        assert.stub(cytanb.Log).was.called(2)
        assert.stub(cytanb.Log).was.called_with(cytanb.LogLevelWarn, 'EmitMessageTo: targetID is not specified: nil')

        cytanb.EmitMessageTo('foo', { num = 502 }, 'INVALID_ID')
        cytanb.EmitMessageTo('foo', { num = 503 }, false)

        assert.stub(cbMap.cb1).was.called(3)
        assert.stub(cbMap.cb2).was.called(4)
        assert.stub(cytanb.Log).was.called(2)

        vci.fake.ClearMessageCallbacks()

        cytanb.Log:revert()

        for key, val in pairs(cbMap) do
            cbMap[key]:revert()
        end

        vci.fake.SetVciName(lastVciName)
    end)

    it('ParseTagString', function ()
        local m1, n1 = cytanb.ParseTagString('foo#bar#baz=123')
        assert.are.same('foo', n1)
        assert.are.same({bar = 'bar', baz = '123'}, m1)

        local m2, n2 = cytanb.ParseTagString('#()!~*\'%  #qux%E3%81%82=(-3.14!1e-16)')
        assert.are.same('', n2)
        assert.are.same({['()!~*\'%'] = '()!~*\'%', ['qux%E3%81%82'] = '(-3.14!1e-16)'}, m2)

        local m3, n3 = cytanb.ParseTagString('###=#corge=##grault=')
        assert.are.same('', n3)
        assert.are.same({corge = '', grault = ''}, m3)

        local m4, n4 = cytanb.ParseTagString('')
        assert.are.same('', n4)
        assert.are.same({}, m4)

        local m5, n5 = cytanb.ParseTagString('Hello, world!')
        assert.are.same('Hello, world!', n5)
        assert.are.same({}, m5)

        local m6, n6 = cytanb.ParseTagString('#')
        assert.are.same('', n6)
        assert.are.same({}, m6)

        local m7, n7 = cytanb.ParseTagString('  #garply=waldo#')
        assert.are.same('  ', n7)
        assert.are.same({ garply = 'waldo'}, m7)

        -- '㌣' は '#' と下位バイトが同じ
        -- '㌽' は '=' と下位バイトが同じ
        local m50, n50 = cytanb.ParseTagString('㌣なまえ#garply=waldo㌣孡形幣㌽孤履て#123=_987㌣⽂千恄')
        assert.are.same('㌣なまえ', n50)
        assert.are.same({ garply = 'waldo', ['123'] = '_987'}, m50)

        local m51, n51 = cytanb.ParseTagString('なまえ#孡形幣=⽂千恄')
        assert.are.same('なまえ', n51)
        assert.are.same({}, m51)

        local m52, n52 = cytanb.ParseTagString('なまえ#ab孡形幣=cd⽂千恄')
        assert.are.same('なまえ', n52)
        assert.are.same({ab = 'ab'}, m52)
    end)

    it('CalculateSIPrefix', function ()
        assert.are.same({0, '', 0}, {cytanb.CalculateSIPrefix(0)})
        assert.are.same({1, '', 0}, {cytanb.CalculateSIPrefix(1)})
        assert.are.same({-1, '', 0}, {cytanb.CalculateSIPrefix(-1)})
        assert.are.same({999.9, '', 0}, {cytanb.CalculateSIPrefix(999.9)})
        assert.are.same({-999.9, '', 0}, {cytanb.CalculateSIPrefix(-999.9)})

        assert.are.same({1, 'k', 3}, {cytanb.CalculateSIPrefix(1000)})
        assert.are.same({-1, 'k', 3}, {cytanb.CalculateSIPrefix(-1000)})
        assert.are.same({999.75, 'k', 3}, {cytanb.CalculateSIPrefix(999750)})
        assert.are.same({-999.75, 'k', 3}, {cytanb.CalculateSIPrefix(-999750)})
        assert.are.same({1, 'M', 6}, {cytanb.CalculateSIPrefix(1e+6)})
        assert.are.same({-1, 'M', 6}, {cytanb.CalculateSIPrefix(-1e+6)})
        assert.are.same({1.25, 'M', 6}, {cytanb.CalculateSIPrefix(1.25e+6)})
        assert.are.same({-1.25, 'M', 6}, {cytanb.CalculateSIPrefix(-1.25e+6)})
        assert.are.same({1, 'G', 9}, {cytanb.CalculateSIPrefix(1e+9)})
        assert.are.same({1.0625, 'T', 12}, {cytanb.CalculateSIPrefix(1.0625e+12)})
        assert.are.same({-1, 'P', 15}, {cytanb.CalculateSIPrefix(-1e+15)})
        assert.are.same({-1.0625, 'E', 18}, {cytanb.CalculateSIPrefix(-1.0625e+18)})
        assert.are.same({1, 'Z', 21}, {cytanb.CalculateSIPrefix(1e+21)})
        assert.are.same({-999.0625, 'Z', 21}, {cytanb.CalculateSIPrefix(-999.0625e+21)})
        assert.are.same({-1.0625, 'Y', 24}, {cytanb.CalculateSIPrefix(-1.0625e+24)})
        assert.are.same({999.0625, 'Y', 24}, {cytanb.CalculateSIPrefix(999.0625e+24)})
        assert.are.same({1000, 'Y', 24}, {cytanb.CalculateSIPrefix(1000e+24)})
        assert.are.same({-1000, 'Y', 24}, {cytanb.CalculateSIPrefix(-1000e+24)})
        assert.are.same({1000000.75, 'Y', 24}, {cytanb.CalculateSIPrefix(1000000.75e+24)})

        assert.are.same({999.9, 'm', -3}, {cytanb.CalculateSIPrefix(0.9999)})
        assert.are.same({-999.9, 'm', -3}, {cytanb.CalculateSIPrefix(-0.9999)})
        assert.are.same({1, 'm', -3}, {cytanb.CalculateSIPrefix(1e-3)})
        assert.are.same({-1, 'm', -3}, {cytanb.CalculateSIPrefix(-1e-3)})
        assert.are.same({750, 'u', -6}, {cytanb.CalculateSIPrefix(0.75e-3)})
        assert.are.same({-750, 'u', -6}, {cytanb.CalculateSIPrefix(-0.75e-3)})
        assert.are.same({1, 'u', -6}, {cytanb.CalculateSIPrefix(1e-6)})
        assert.are.same({-937.5, 'n', -9}, {cytanb.CalculateSIPrefix(-937.5e-9)})
        assert.are.same({-1, 'n', -9}, {cytanb.CalculateSIPrefix(-1e-9)})
        assert.are.same({999.9375, 'p', -12}, {cytanb.CalculateSIPrefix(999.9375e-12)})
        assert.are.same({1, 'p', -12}, {cytanb.CalculateSIPrefix(1e-12)})
        assert.are.same({-999.9375, 'f', -15}, {cytanb.CalculateSIPrefix(-999.9375e-15)})
        assert.are.same({-1, 'f', -15}, {cytanb.CalculateSIPrefix(-1e-15)})
        assert.are.same({1.125, 'a', -18}, {cytanb.CalculateSIPrefix(1.125e-18)})
        assert.are.same({1, 'a', -18}, {cytanb.CalculateSIPrefix(1e-18)})
        assert.are.same({-1.125, 'z', -21}, {cytanb.CalculateSIPrefix(-1.125e-21)})
        assert.are.same({-1, 'z', -21}, {cytanb.CalculateSIPrefix(-1e-21)})
        assert.are.same({999.9375, 'y', -24}, {cytanb.CalculateSIPrefix(999.9375e-24)})
        assert.are.same({1, 'y', -24}, {cytanb.CalculateSIPrefix(1e-24)})
        assert.are.same({0.5, 'y', -24}, {cytanb.CalculateSIPrefix(0.5e-24)})
        assert.are.same({-0.0009765625, 'y', -24}, {cytanb.CalculateSIPrefix(-0.0009765625e-24)})
    end)
end

---@param cytanb cytanb
local GuestUserTestCases = function (cytanb)
    it('guest InstanceID', function ()
        local cbMap = {
            cbEmpty = function (sender ,name, parameterMap) end
        }

        for key, val in pairs(cbMap) do
            spy.on(cbMap, key)
        end

        cytanb.OnMessage('empty-InstanceID', cbMap.cbEmpty)

        local instanceId = cytanb.InstanceID()
        assert.is_truthy(cytanb.UUIDFromString(instanceId))
        assert.are.same(instanceId, cytanb.InstanceID())

        assert.spy(cbMap.cbEmpty).was.called(0)
        stub(cytanb, 'Log')
        cytanb.EmitMessage('empty-InstanceID', {label = 'id-is-empty'})
        assert.spy(cbMap.cbEmpty).was.called(1)

        cytanb.EmitMessage('empty-InstanceID', {label = 'id-is-not-empty'})
        assert.spy(cbMap.cbEmpty).was.called(2)
        cytanb.Log:revert()

        for key, val in pairs(cbMap) do
            cbMap[key]:revert()
        end
    end)
end

local InvalidEnvTestCases = function (module)
    it('should raise error', function ()
        local s = spy.new(function(message, level) error(message, (level or 1) + 1) end)
        assert.has_error(function () return module({ error = s }) end)
        assert.spy(s).was.called(1)
        assert.spy(s).was.called_with('Invalid _ENV: Enable `__CYTANB_EXPORT_MODULE = true` line and pass valid _ENV of VCI-main if use cytanb.lua as module.',3)
    end)
end

insulate('cytanb [with owner user]', function ()
    local module

    setup(function ()
        math.randomseed(os.time() - os.clock() * 10000)
        require('cytanb_fake_vci').vci.fake.Setup(_G)
        _G.__CYTANB_EXPORT_MODULE = true
        module = require('cytanb')
    end)

    teardown(function ()
        package.loaded['cytanb'] = nil
        _G.__CYTANB_EXPORT_MODULE = nil
        vci.fake.Teardown(_G)
    end)

    describe('feature', function ()
        OwnerUserTestCases(module(MakeEnv(_ENV)), { calcUUIDVariance = false })
    end)
end)

insulate('cytanb_min [with owner user]', function ()
    local module

    setup(function ()
        math.randomseed(os.time() - os.clock() * 10000)
        require('cytanb_fake_vci').vci.fake.Setup(_G)
        _G.__CYTANB_EXPORT_MODULE = true
        module = require('cytanb_min')
        package.loaded['cytanb'] = cytanb
    end)

    teardown(function ()
        package.loaded['cytanb_min'] = nil
        package.loaded['cytanb'] = nil
        _G.__CYTANB_EXPORT_MODULE = nil
        vci.fake.Teardown(_G)
    end)

    describe('feature', function ()
        OwnerUserTestCases(module(MakeEnv(_ENV)), { calcUUIDVariance = false })
    end)
end)

insulate('cytanb [with guest user]', function ()
    local module

    setup(function ()
        math.randomseed(os.time() - os.clock() * 10000)
        require('cytanb_fake_vci').vci.fake.Setup(_G)
        vci.fake.SetAssetsIsMine(false)

        _G.__CYTANB_EXPORT_MODULE = true
        module = require('cytanb')
    end)

    teardown(function ()
        package.loaded['cytanb'] = nil
        _G.__CYTANB_EXPORT_MODULE = nil
        vci.fake.Teardown(_G)
    end)

    describe('feature', function ()
        GuestUserTestCases(module(MakeEnv(_ENV)))
    end)

    describe('invalid _ENV', function ()
        InvalidEnvTestCases(module)
    end)
end)

insulate('cytanb_min [with guest user]', function ()
    local module

    setup(function ()
        math.randomseed(os.time() - os.clock() * 10000)
        require('cytanb_fake_vci').vci.fake.Setup(_G)
        vci.fake.SetAssetsIsMine(false)

        _G.__CYTANB_EXPORT_MODULE = true
        module = require('cytanb_min')
        package.loaded['cytanb'] = cytanb
    end)

    teardown(function ()
        package.loaded['cytanb_min'] = nil
        package.loaded['cytanb'] = nil
        _G.__CYTANB_EXPORT_MODULE = nil
        vci.fake.Teardown(_G)
    end)

    describe('feature', function ()
        GuestUserTestCases(module(MakeEnv(_ENV)))
    end)

    describe('invalid _ENV', function ()
        InvalidEnvTestCases(module)
    end)
end)

insulate('cytanb as non-module', function ()
    local module
    setup(function ()
        math.randomseed(os.time() - os.clock() * 10000)
        require('cytanb_fake_vci').vci.fake.Setup(_G)
        module = require('cytanb')
    end)

    teardown(function ()
        package.loaded['cytanb'] = nil
        vci.fake.Teardown(_G)
    end)

    it('should not have impl', function ()
        -- モジュールが `nil` を返した場合は、`package.loaded[modname]` に `true` が格納される。`require` の戻り値として、`true` が返される。
        assert.is_true(module)
        assert.is_true(package.loaded['cytanb'])
    end)
end)

insulate('Complex-require', function ()
    local sleep = function (sec)
        local startTime = os.clock()
        if os.execute() ~= 0 then
            local osVar = os.getenv('OS') or ''
            if string.find(osVar, 'Windows', 1, true) then
                os.execute('timeout /T ' .. sec .. ' > NUL 2>&1')
            else
                os.execute('sleep ' .. sec .. ' > /dev/null 2>&1')
            end
        end

        while os.clock() - startTime <= sec do end
    end

    it('lsp container', function ()
        local lsp_container_id = '137a14de-3cbe-48fe-8c5f-7226dce4db01'

        ---@type cytanb
        local cytanb

        do
            require('cytanb_fake_vci').vci.fake.Setup(_G)

            _G.__CYTANB_EXPORT_MODULE = true
            local module_env = MakeEnv(_ENV)

            assert.is_nil(_G.coroutine[lsp_container_id])
            assert.is_nil(module_env[lsp_container_id])

            cytanb = require('cytanb')(module_env)
            assert.are.equal(_G, cytanb.LspContainer())

            assert.is_nil(_G.coroutine[lsp_container_id])
            assert.is_nil(module_env[lsp_container_id])

            package.loaded['cytanb'] = nil
            _G.__CYTANB_EXPORT_MODULE = nil
            vci.fake.Teardown(_G)
        end

        do
            require('cytanb_fake_vci').vci.fake.Setup(_G)

            _G.__CYTANB_EXPORT_MODULE = true
            local module_env = MakeEnv(_ENV)
            module_env._G = false

            assert.is_nil(_G.coroutine[lsp_container_id])
            assert.is_nil(module_env[lsp_container_id])

            cytanb = require('cytanb')(module_env)

            assert.is_nil(_G.coroutine[lsp_container_id])
            assert.is_nil(module_env[lsp_container_id])

            assert.are.same({}, cytanb.LspContainer())

            assert.is_not_nil(_G.coroutine[lsp_container_id])
            assert.is_nil(module_env[lsp_container_id])

            package.loaded['cytanb'] = nil
            _G.__CYTANB_EXPORT_MODULE = nil
            vci.fake.Teardown(_G)
        end

        do
            require('cytanb_fake_vci').vci.fake.Setup(_G)

            _G.__CYTANB_EXPORT_MODULE = true
            local module_env = MakeEnv(_ENV)
            module_env._G = false

            assert.is_nil(_G.coroutine[lsp_container_id])
            assert.is_nil(module_env[lsp_container_id])

            cytanb = require('cytanb')(module_env)

            assert.is_nil(_G.coroutine[lsp_container_id])
            assert.is_nil(module_env[lsp_container_id])
            assert.is_nil(_ENV[lsp_container_id])
            assert.is_nil(_G[lsp_container_id])

            module_env.require = function (modname)
                if modname == 'coroutine' then
                    return nil
                else
                    return _G.require(modname)
                end
            end

            assert.are.same({}, cytanb.LspContainer())

            assert.is_nil(_G.coroutine[lsp_container_id])
            assert.is_not_nil(module_env[lsp_container_id])
            assert.is_nil(_ENV[lsp_container_id])
            assert.is_nil(_G[lsp_container_id])

            package.loaded['cytanb'] = nil
            _G.__CYTANB_EXPORT_MODULE = nil
            vci.fake.Teardown(_G)
        end
    end)

    it('multiple times', function ()
        ---@type cytanb
        local cytanb

        require('cytanb_fake_vci').vci.fake.Setup(_G)
        _G.__CYTANB_EXPORT_MODULE = true
        cytanb = require('cytanb')(MakeEnv(_ENV))
        local firstPosixTime = cytanb.PosixTime()

        package.loaded['cytanb'] = nil
        _G.__CYTANB_EXPORT_MODULE = nil
        vci.fake.Teardown(_G)

        sleep(1)

        require('cytanb_fake_vci').vci.fake.Setup(_G)
        _G.__CYTANB_EXPORT_MODULE = true
        cytanb = require('cytanb')(MakeEnv(_ENV))
        local secondPosixTime = cytanb.PosixTime()
        assert.is_true(firstPosixTime < secondPosixTime)

        package.loaded['cytanb'] = nil
        _G.__CYTANB_EXPORT_MODULE = nil
        vci.fake.Teardown(_G)

        require('cytanb_fake_vci').vci.fake.Setup(_G)
        _G.__CYTANB_EXPORT_MODULE = true
        cytanb = require('cytanb')(MakeEnv(_ENV))
        local thirdPosixTime = cytanb.PosixTime()
        assert.is_true(firstPosixTime < thirdPosixTime)
    end)
end)
