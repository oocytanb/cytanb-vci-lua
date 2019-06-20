----------------------------------------------------------------
--  Copyright (c) 2019 oO (https://github.com/oocytanb)
--  MIT Licensed
----------------------------------------------------------------

describe('Test cytanb_fake_vci', function ()
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
			cb1 = function (value)
			end,

			cb2 = function (value)
			end,

			cb3 = function (value)
			end
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
		assert.stub(cbMap.cb1).was.called_with(12345)
		assert.stub(cbMap.cb1).was.called(1)
		assert.stub(cbMap.cb2).was.called_with(12345)
		assert.stub(cbMap.cb2).was.called(1)
		assert.stub(cbMap.cb3).was_not.called_with(12345)
		assert.stub(cbMap.cb3).was.called(0)

		vci.studio.shared.Set('foo', 12345)
		assert.stub(cbMap.cb1).was.called(1)
		assert.stub(cbMap.cb2).was.called(1)
		assert.stub(cbMap.cb3).was.called(0)

		vci.studio.shared.Set('foo', false)
		assert.is_false(vci.studio.shared.Get('foo'))
		assert.stub(cbMap.cb1).was.called_with(false)
		assert.stub(cbMap.cb1).was.called(2)
		assert.stub(cbMap.cb2).was.called_with(false)
		assert.stub(cbMap.cb2).was.called(2)
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
		assert.stub(cbMap.cb3).was_not.called_with(404)
		assert.stub(cbMap.cb3).was.called(2)

		cbMap.cb1:revert()
		cbMap.cb2:revert()
		cbMap.cb3:revert()
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
