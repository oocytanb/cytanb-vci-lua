-- SPDX-License-Identifier: MIT
-- Copyright (c) 2019 oO (https://github.com/oocytanb)

describe('Test cytanb owner user', function ()
    ---@type cytanb
    local cytanb

    setup(function ()
        require('cytanb_fake_vci').vci.fake.Setup(_G)
        cytanb = require('cytanb')
    end)

    teardown(function ()
        package.loaded['cytanb'] = nil
        vci.fake.Teardown(_G)
    end)

    it('Color constants', function ()
        assert.are.same(cytanb.ColorMapSize, cytanb.ColorHueSamples * cytanb.ColorSaturationSamples * cytanb.ColorBrightnessSamples)
    end)

    it('owner InstanceID', function ()
        assert.are.same(36, #cytanb.InstanceID())
        assert.is_truthy(cytanb.UUIDFromString(cytanb.InstanceID()))
    end)

    it('ClientID', function ()
        assert.are.same(36, #cytanb.ClientID())
        assert.is_truthy(cytanb.UUIDFromString(cytanb.ClientID()))
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

    it('String', function ()
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
    end)

    it('Vars', function ()
        assert.are.same('(boolean) true', cytanb.Vars(true))
        assert.are.same('(boolean) false', cytanb.Vars(false, '-', '*'))
        assert.are.same('(number) -123.45', cytanb.Vars(-123.45))
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
        assert.has_error(function () cytanb.LogLevelFatal = 123456789 end)

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
        assert.are.equal(330, a6)
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

        assert.is_nil(cytanb.UUIDFromString('G69f80ac-e66e-448c-b17c-5a54ea94dccc'))
        assert.is_nil(cytanb.UUIDFromString('069f80ac-e66e-448c-b17c-5a54ea94dccc0'))
        assert.is_nil(cytanb.UUIDFromString('069f80ac-e66e-448c-b17c-5a54ea94dcc'))

        local uuidTable = {}
        local samples = {}
        local sampleSize = 16
        for i = 1, 128 do
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

        local calcVariance = false
        if calcVariance then
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
            cb1 = function (sender ,name, parameterMap) end,
            cb2 = function (sender ,name, parameterMap) end,
            cb3 = function (sender ,name, parameterMap) end,
            cbMapComment = function (sender, name, parameterMap) end,
            cbMapNotification = function (sender, name, parameterMap) end,
            cbComment = function (sender, name, message) end,
            cbNotification = function (sender, name, message) end,
        }

        for key, val in pairs(cbMap) do
            stub(cbMap, key)
        end

        cytanb.OnMessage('foo', cbMap.cb1)
        cytanb.OnMessage('foo', cbMap.cb2)
        cytanb.OnMessage('bar', cbMap.cb3)
        cytanb.OnMessage('comment', cbMap.cbMapComment)
        cytanb.OnMessage('notification', cbMap.cbMapNotification)
        cytanb.OnCommentMessage(cbMap.cbComment)
        cytanb.OnNotificationMessage(cbMap.cbNotification)

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
        assert.stub(cbMap.cbComment).was.called(0)

        vci.fake.EmitVciNicoliveCommentMessage('TestUser', 'Hello, World!')
        assert.stub(cbMap.cbMapComment).was.called(1)
        assert.stub(cbMap.cbMapComment).was.called_with({type = 'comment', name = 'TestUser', commentSource = 'Nicolive'}, 'comment', {[cytanb.MessageValueParameterName] = 'Hello, World!'})
        assert.stub(cbMap.cbComment).was.called(1)
        assert.stub(cbMap.cbComment).was.called_with({type = 'comment', name = 'TestUser', commentSource = 'Nicolive'}, 'comment', 'Hello, World!')

        vci.fake.EmitVciTwitterCommentMessage('TwitterUser', '')
        assert.stub(cbMap.cbMapComment).was.called(2)
        assert.stub(cbMap.cbMapComment).was.called_with({type = 'comment', name = 'TwitterUser', commentSource = 'Twitter'}, 'comment', {[cytanb.MessageValueParameterName] = ''})
        assert.stub(cbMap.cbComment).was.called(2)
        assert.stub(cbMap.cbComment).was.called_with({type = 'comment', name = 'TwitterUser', commentSource = 'Twitter'}, 'comment', '')

        vci.fake.EmitVciShowroomCommentMessage('ShowroomUser', '50')
        assert.stub(cbMap.cbMapComment).was.called(3)
        assert.stub(cbMap.cbMapComment).was.called_with({type = 'comment', name = 'ShowroomUser', commentSource = 'Showroom'}, 'comment', {[cytanb.MessageValueParameterName] = '50'})
        assert.stub(cbMap.cbComment).was.called(3)
        assert.stub(cbMap.cbComment).was.called_with({type = 'comment', name = 'ShowroomUser', commentSource = 'Showroom'}, 'comment', '50')

        cytanb.EmitCommentMessage('DummyComment sender-omitted')
        assert.stub(cbMap.cbMapComment).was.called(4)
        assert.stub(cbMap.cbMapComment).was.called_with({
            type = 'comment',
            name = '',
            commentSource = '',
            [cytanb.MessageOriginalSender] = {type = 'vci', name = 'test-cytanb-module', commentSource = ''}
        }, 'comment', {
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
        assert.stub(cbMap.cbMapComment).was.called(5)
        assert.stub(cbMap.cbMapComment).was.called_with({
            type = 'comment',
            name = 'NicoUser',
            commentSource = 'Nicolive',
            [cytanb.MessageOriginalSender] = {type = 'vci', name = 'test-cytanb-module', commentSource = ''}
        }, 'comment', {
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
        assert.stub(cbMap.cbMapComment).was.called(6)
        assert.stub(cbMap.cbMapComment).was.called_with({
            type = 'comment',
            name = 'Twitter user A',
            commentSource = 'Twitter',
            [cytanb.MessageOriginalSender] = {type = 'vci', name = 'test-cytanb-module', commentSource = ''}
        }, 'comment', {
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
        assert.stub(cbMap.cbMapComment).was.called(7)
        assert.stub(cbMap.cbMapComment).was.called_with({
            type = 'comment',
            name = 'SR user C',
            commentSource = 'Showroom',
            [cytanb.MessageOriginalSender] = {type = 'vci', name = 'test-cytanb-module', commentSource = ''}
        }, 'comment', {
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
        });
        assert.stub(cbMap.cbMapComment).was.called(8)
        assert.stub(cbMap.cbMapComment).was.called_with({
            type = 'vci',
            name = 'test-cytanb-module',
            commentSource = '',
            [cytanb.MessageOriginalSender] = {type = 'vci', name = 'test-cytanb-module', commentSource = ''}
        }, 'comment', {
            [cytanb.InstanceIDParameterName] = cytanb.InstanceID(),
            [cytanb.MessageSenderOverride] = 'invalid-sender',
            [cytanb.MessageValueParameterName] = 'test-invalid-sender-override'}
        )

        assert.stub(cbMap.cbComment).was.called(8)
        assert.stub(cbMap.cbComment).was.called_with({
            type = 'vci',
            name = 'test-cytanb-module',
            commentSource = '',
            [cytanb.MessageOriginalSender] = {type = 'vci', name = 'test-cytanb-module', commentSource = ''}
        }, 'comment', 'test-invalid-sender-override')

        assert.stub(cbMap.cbMapNotification).was.called(0)
        assert.stub(cbMap.cbNotification).was.called(0)

        vci.fake.EmitVciJoinedNotificationMessage('joined-user-d')
        assert.stub(cbMap.cbMapNotification).was.called(1)
        assert.stub(cbMap.cbMapNotification).was.called_with({type = 'notification', name = 'joined-user-d', commentSource = ''}, 'notification', {[cytanb.MessageValueParameterName] = 'joined'})
        assert.stub(cbMap.cbNotification).was.called(1)
        assert.stub(cbMap.cbNotification).was.called_with({type = 'notification', name = 'joined-user-d', commentSource = ''}, 'notification', 'joined')

        vci.fake.EmitVciLeftNotificationMessage('left-user-e')
        assert.stub(cbMap.cbMapNotification).was.called(2)
        assert.stub(cbMap.cbMapNotification).was.called_with({type = 'notification', name = 'left-user-e', commentSource = ''}, 'notification', {[cytanb.MessageValueParameterName] = 'left'})
        assert.stub(cbMap.cbNotification).was.called(2)
        assert.stub(cbMap.cbNotification).was.called_with({type = 'notification', name = 'left-user-e', commentSource = ''}, 'notification', 'left')

        cytanb.EmitNotificationMessage('DummyNotification sender-omitted')
        assert.stub(cbMap.cbMapNotification).was.called(3)
        assert.stub(cbMap.cbMapNotification).was.called_with({
            type = 'notification',
            name = '',
            commentSource = '',
            [cytanb.MessageOriginalSender] = {type = 'vci', name = 'test-cytanb-module', commentSource = ''}
        }, 'notification', {
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
        assert.stub(cbMap.cbMapNotification).was.called(4)
        assert.stub(cbMap.cbMapNotification).was.called_with({
            type = 'notification',
            name = 'dummy-joined-user-f',
            commentSource = '',
            [cytanb.MessageOriginalSender] = {type = 'vci', name = 'test-cytanb-module', commentSource = ''}
        }, 'notification', {
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
        assert.stub(cbMap.cbMapNotification).was.called(5)
        assert.stub(cbMap.cbMapNotification).was.called_with({
            type = 'notification',
            name = 'dummy-left-user-g',
            commentSource = '',
            [cytanb.MessageOriginalSender] = {type = 'vci', name = 'test-cytanb-module', commentSource = ''}
        }, 'notification', {
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
        assert.stub(cbMap.cbMapComment).was.called(8)
        assert.stub(cbMap.cbComment).was.called(8)

        vci.fake.ClearMessageCallbacks()

        for key, val in pairs(cbMap) do
            cbMap[key]:revert()
        end

        vci.fake.SetVciName(lastVciName)
    end)

    it('Instance message', function ()
        local lastVciName = vci.fake.GetVciName()
        vci.fake.SetVciName('test-instance-module')

        local cbMap = {
            cb1 = function (sender ,name, parameterMap) end,
            cb2 = function (sender ,name, parameterMap) end
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

    it('TransformParameters', function ()
        local p1, r1, s1 = cytanb.RestoreCytanbTransform(
            {
                positionX = 123,
                positionY = -49.75,
                positionZ = 0,
                rotationX = -0.109807625412941,
                rotationY = 0.146410167217255,
                rotationZ = -0.183012709021568,
                rotationW = 0.965925812721252,
                scaleX = 0,
                scaleY = 0.25,
                scaleZ = 1.5
            }
        )
        assert.are.equal(Vector3.__new(123, -49.75, 0), p1)
        assert.are.equal(Quaternion.__new(-0.109807625412941, 0.146410167217255, -0.183012709021568, 0.965925812721252), r1)
        assert.are.equal(Vector3.__new(0, 0.25, 1.5), s1)

        local p40, r40, s40 = cytanb.RestoreCytanbTransform(
            {
                positionX = 123,
                positionZ = 0,
                rotationX = -0.109807625412941,
                rotationY = 0.146410167217255,
                rotationW = 0.965925812721252,
                scaleX = 0,
                scaleZ = 1.5
            }
        )
        assert.is_nil(p40)
        assert.is_nil(r40)
        assert.is_nil(s40)

        local p41, r41, s41 = cytanb.RestoreCytanbTransform(
            {
                positionX = 0,
                positionY = 0,
                positionZ = 0,
                rotationX = 0,
                rotationY = 0,
                rotationZ = 0,
                rotationW = 1,
                scaleY = 0.8,
                scaleZ = 1.5
            }
        )
        assert.are.equal(Vector3.zero, p41)
        assert.are.equal(Quaternion.identity, r41)
        assert.is_nil(s41)
    end)
end)

describe('Test cytanb guest user', function ()
    ---@type cytanb
    local cytanb

    setup(function ()
        require('cytanb_fake_vci').vci.fake.Setup(_G)
        vci.fake.SetAssetsIsMine(false)

        cytanb = require('cytanb')
    end)

    teardown(function ()
        package.loaded['cytanb'] = nil
        vci.fake.Teardown(_G)
    end)

    it('guest InstanceID', function ()
        assert.are.same('', cytanb.InstanceID())
        vci.state.Set('__CYTANB_INSTANCE_ID', '12345678-90ab-cdef-1234-567890abcdef')
        assert.are.same('12345678-90ab-cdef-1234-567890abcdef', cytanb.InstanceID())
    end)
end)
