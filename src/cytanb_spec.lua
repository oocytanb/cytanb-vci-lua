----------------------------------------------------------------
--  Copyright (c) 2019 oO (https://github.com/oocytanb)
--  MIT Licensed
----------------------------------------------------------------

describe('Test cytanb owner user', function ()
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
		assert.is_true(cytanb.FatalLogLevel > 0)
		assert.is_true(cytanb.ErrorLogLevel > cytanb.FatalLogLevel)
		assert.is_true(cytanb.WarnLogLevel > cytanb.ErrorLogLevel)
		assert.is_true(cytanb.InfoLogLevel > cytanb.WarnLogLevel)
		assert.is_true(cytanb.DebugLogLevel > cytanb.InfoLogLevel)
		assert.is_true(cytanb.TraceLogLevel > cytanb.DebugLogLevel)
		assert.has_error(function () cytanb.FatalLogLevel = 123456789 end)
		local level = cytanb.GetLogLevel()
		assert.is_true(cytanb.FatalLogLevel > 0)
		assert.is_true(level > cytanb.FatalLogLevel)
		assert.are.same(level, cytanb.InfoLogLevel)
		cytanb.SetLogLevel(cytanb.FatalLogLevel)
		assert.are.same(cytanb.FatalLogLevel, cytanb.GetLogLevel())
		cytanb.SetLogLevel(level)
		assert.are_not.same(cytanb.FatalLogLevel, cytanb.GetLogLevel())
	end)

	it('Log', function ()
		stub(cytanb, 'Log')
		cytanb.Log(cytanb.InfoLogLevel, 'Level message')
		assert.stub(cytanb.Log).was.called_with(cytanb.InfoLogLevel, 'Level message')

		cytanb.FatalLog('Fatal message', 123)
		assert.stub(cytanb.Log).was.called_with(cytanb.FatalLogLevel, 'Fatal message', 123)

		cytanb.ErrorLog('Error message', {})
		assert.stub(cytanb.Log).was.called_with(cytanb.ErrorLogLevel, 'Error message', {})

		cytanb.WarnLog('Warn message', false)
		assert.stub(cytanb.Log).was.called_with(cytanb.WarnLogLevel, 'Warn message', false)

		cytanb.InfoLog('Info message', 'xyz')
		assert.stub(cytanb.Log).was.called_with(cytanb.InfoLogLevel, 'Info message', 'xyz')

		cytanb.DebugLog('Debug message')
		assert.stub(cytanb.Log).was.called_with(cytanb.DebugLogLevel, 'Debug message')

		cytanb.TraceLog('Trace message', nil)
		assert.stub(cytanb.Log).was.called_with(cytanb.TraceLogLevel, 'Trace message', nil)
		cytanb.Log:revert()

		stub(_G, 'print')
		local lastLevel = cytanb.GetLogLevel()
		cytanb.SetLogLevel(cytanb.WarnLogLevel)
		cytanb.WarnLog('foo ', true)
		assert.stub(print).was.called_with('foo true')
		cytanb.ErrorLog('bar ', -1234.5)
		assert.stub(print).was.called_with('bar -1234.5')
		cytanb.InfoLog('baz ', false)
		assert.stub(print).was_not.called_with('baz false')
		_G.print:revert()
		cytanb.SetLogLevel(lastLevel)
	end)
end)

describe('Test cytanb guest user', function ()
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
