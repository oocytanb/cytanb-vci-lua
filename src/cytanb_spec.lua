----------------------------------------------------------------
--  Copyright (c) 2019 oO (https://github.com/oocytanb)
--  MIT Licensed
----------------------------------------------------------------

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
		assert.is_true(cytanb.LogLevelFatal > 0)
		assert.is_true(cytanb.LogLevelError > cytanb.LogLevelFatal)
		assert.is_true(cytanb.LogLevelWarn > cytanb.LogLevelError)
		assert.is_true(cytanb.LogLevelInfo > cytanb.LogLevelWarn)
		assert.is_true(cytanb.LogLevelDebug > cytanb.LogLevelInfo)
		assert.is_true(cytanb.LogLevelTrace > cytanb.LogLevelDebug)
		assert.has_error(function () cytanb.LogLevelFatal = 123456789 end)
		local level = cytanb.GetLogLevel()
		assert.is_true(cytanb.LogLevelFatal > 0)
		assert.is_true(level > cytanb.LogLevelFatal)
		assert.are.same(level, cytanb.LogLevelInfo)
		cytanb.SetLogLevel(cytanb.LogLevelFatal)
		assert.are.same(cytanb.LogLevelFatal, cytanb.GetLogLevel())
		cytanb.SetLogLevel(level)
		assert.are_not.same(cytanb.LogLevelFatal, cytanb.GetLogLevel())
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
		local lastLevel = cytanb.GetLogLevel()
		cytanb.SetLogLevel(cytanb.LogLevelWarn)
		cytanb.LogWarn('foo ', true)
		assert.stub(print).was.called_with('foo true')
		cytanb.LogError('bar ', -1234.5)
		assert.stub(print).was.called_with('bar -1234.5')
		cytanb.LogInfo('baz ', false)
		assert.stub(print).was_not.called_with('baz false')
		_G.print:revert()
		cytanb.SetLogLevel(lastLevel)
	end)

	it('ListToMap', function ()
		assert.are.same({foo = 'foo', bar = 'bar', baz = 'baz'}, cytanb.ListToMap({'foo', 'bar', 'baz'}))
		assert.are.same({foo = 543, bar = 543, baz = 543}, cytanb.ListToMap({'foo', 'bar', 'baz'}, 543))
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

	it('Color', function ()
		local indexRgbList = {
			[{0, 0, 0}] = 0xff0000,
			[{1, 1, 0}] = 0xffbf40,
			[{2, 2, 0}] = 0xd5ff80,
			[{3, 3, 0}] = 0xbfffbf,
			[{4, 0, 1}] = 0x00cc88,
			[{5, 2, 1}] = 0x66aacc,
			[{6, 1, 2}] = 0x262699,
			[{7, 3, 2}] = 0x8c7399,
			[{8, 0, 3}] = 0x660044,
			[{9, 2, 4}] = 0x222222,
			[{9, 0, 0}] = 0x000000,
			[{9, 2, 0}] = 0xaaaaaa,
			[{9, 3, 0}] = 0xffffff
		}

		for iv, rgb24 in pairs(indexRgbList) do
			local index = iv[1] + iv[2] * cytanb.ColorHueSamples + iv[3] * cytanb.ColorHueSamples * cytanb.ColorSaturationSamples
			local rgb32 = bit32.bor(0xff000000, rgb24)
			local c32 = cytanb.ColorFromARGB32(rgb32)
			local cidx = cytanb.ColorFromIndex(index)
			local diff = cidx - c32
			assert.are.equal(Color.clear, vci.fake.RoundColor(diff, 2))
			assert.are.equal(rgb32, cytanb.ColorToARGB32(c32))
		end
	end)

	it('TableToSerializable', function ()
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

		local circularTable = {foo = 123.25}
		circularTable.ref = circularTable
		assert.has_error(function () cytanb.TableToSerializable(circularTable) end)
	end)

	it('TableFromSerializable', function ()
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
	end)

	it('Message', function ()
		local lastVciName = vci.fake.GetVciName()
		vci.fake.SetVciName('test-cytanb-module')

		local cbMap = {
			cb1 = function (sender ,name, parameterMap) end,
			cb2 = function (sender ,name, parameterMap) end,
			cb3 = function (sender ,name, parameterMap) end,
			cbComment = function (sender, name, parameterMap) end
		}

		stub(cbMap, 'cb1')
		stub(cbMap, 'cb2')
		stub(cbMap, 'cb3')
		stub(cbMap, 'cbComment')

		cytanb.OnMessage('foo', cbMap.cb1)
		cytanb.OnMessage('foo', cbMap.cb2)
		cytanb.OnMessage('bar', cbMap.cb3)
		cytanb.OnMessage('comment', cbMap.cbComment)

		cytanb.EmitMessage('foo')
		assert.stub(cbMap.cb1).was.called(1)
		assert.stub(cbMap.cb1).was.called_with({type = 'vci', name = 'test-cytanb-module'}, 'foo', {[cytanb.InstanceIDParameterName] = cytanb.InstanceID()})
		assert.stub(cbMap.cb2).was.called(1)
		assert.stub(cbMap.cb3).was.called(0)
		assert.stub(cbMap.cbComment).was.called(0)

		cytanb.EmitMessage('bar', {hoge = 123.45, piyo = 'abc', fuga = true, hogera = {hogehoge = -9876.5, piyopiyo = false}})
		assert.stub(cbMap.cb1).was.called(1)
		assert.stub(cbMap.cb2).was.called(1)
		assert.stub(cbMap.cb3).was.called(1)
		assert.stub(cbMap.cb3).was.called_with({type = 'vci', name = 'test-cytanb-module'}, 'bar', {[cytanb.InstanceIDParameterName] = cytanb.InstanceID(), hoge = 123.45, piyo = 'abc', fuga = true, hogera = {hogehoge = -9876.5, piyopiyo = false}})
		assert.stub(cbMap.cbComment).was.called(0)

		vci.message.Emit('foo', -36.5)
		assert.stub(cbMap.cb1).was.called(2)
		assert.stub(cbMap.cb2).was.called(2)
		assert.stub(cbMap.cb2).was.called_with({type = 'vci', name = 'test-cytanb-module'}, 'foo', {[cytanb.MessageValueParameterName] = -36.5})
		assert.stub(cbMap.cb3).was.called(1)
		assert.stub(cbMap.cbComment).was.called(0)

		vci.fake.EmitCommentMessage('TestUser', 'Hello, World!')
		assert.stub(cbMap.cb1).was.called(2)
		assert.stub(cbMap.cb2).was.called(2)
		assert.stub(cbMap.cb3).was.called(1)
		assert.stub(cbMap.cbComment).was.called(1)
		assert.stub(cbMap.cbComment).was.called_with({type = 'comment', name = 'TestUser'}, 'comment', {[cytanb.MessageValueParameterName] = 'Hello, World!'})

		cbMap.cb1:revert()
		cbMap.cb2:revert()
		cbMap.cb3:revert()
		cbMap.cbComment:revert()

		vci.fake.SetVciName(lastVciName)
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
