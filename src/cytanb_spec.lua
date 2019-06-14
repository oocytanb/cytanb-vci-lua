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

		assert.are.same({foo = 123, bar = 'opq', baz = true, qux = {quux = 543, corge = false, grault = 246}, zyzzy = 'rst'}, cytanb.Extend(cytanb.Extend({}, source1, true), source2, true))
		assert.are.same({foo = 123, bar = 'abc', baz = true, qux = {quux = -9876.5, corge = false, grault = 246}, zyzzy = 'rst'}, cytanb.Extend(cytanb.Extend({}, source1, true, true), source2, true, true))

		local meta1 = {__index = {hoge = 256, piyo = 'metasyntactic variable'}}
		local meta2 = {__index = {hogera = 1024, fuga = false}}
		local metaSource1 = {foo = 123, bar = 'abc', baz = true, qux = {quux = -9876.5, corge = false}}
		setmetatable(metaSource1, meta1)
		setmetatable(metaSource1.qux, meta2)
		local metaTarget1 = cytanb.Extend({}, metaSource1)
		assert.are.same(metaSource1, metaTarget1)
		assert.are.same(meta1, getmetatable(metaTarget1))
		assert.are.same(meta2, getmetatable(metaTarget1.qux))
		assert.are.same(256, metaTarget1.hoge)
		assert.is_false(metaTarget1.qux.fuga)

		local metaTarget2 = cytanb.Extend({}, metaSource1, true, true)
		assert.are.same(metaSource1, metaTarget2)
		assert.are.same(meta1, getmetatable(metaTarget2))
		assert.are.same(meta2, getmetatable(metaTarget2.qux))
		assert.are.same(256, metaTarget2.hoge)
		assert.is_false(metaTarget2.qux.fuga)
	end)

	it('Vars', function ()
		assert.are.same('(boolean) true', cytanb.Vars(true))
		assert.are.same('(boolean) false', cytanb.Vars(false, '-', '*'))
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
