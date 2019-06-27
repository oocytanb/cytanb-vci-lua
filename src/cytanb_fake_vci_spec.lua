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

	it('Color', function ()
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

		assert.are.equal(Color.__new(0.000, 0.500, 3.000, 1.000), Color.__new(0.5, 0.25, 1) * Color.__new(0, 2, 3))
		assert.are.equal(Color.__new(0.250, 0.125, 0.500, 0.500), Color.__new(0.5, 0.25, 1) / 2)

		local lpa = Color.__new(0.33, 1.0, -2.0, 1.0)
		local lpb = Color.__new(1.5, 3.0, 1.0, -3.0)
		assert.are.equal(Color.__new(1.266, 2.600, 0.400, -2.200), vci.fake.RoundColor(Color.Lerp(lpa, lpb, 0.8), 5))
		assert.are.equal(Color.__new(0.330, 1.000, -2.000, 1.000), vci.fake.RoundColor(Color.Lerp(lpa, lpb, -123), 5))
		assert.are.equal(Color.__new(0.330, 1.000, -2.000, 1.000), vci.fake.RoundColor(Color.Lerp(lpa, lpb, -5.7), 5))
		assert.are.equal(Color.__new(0.6225, 1.500, -1.250, 0.000), vci.fake.RoundColor(Color.Lerp(lpa, lpb, 0.25), 5))
		assert.are.equal(Color.__new(0.330, 1.000, -2.000, 1.000), vci.fake.RoundColor(Color.Lerp(lpa, lpb, -0.25), 5))
		assert.are.equal(Color.__new(1.266, 2.600, 0.400, -2.200), vci.fake.RoundColor(Color.LerpUnclamped(lpa, lpb, 0.8), 5))
		assert.are.equal(Color.__new(-143.580, -245.000, -371.000, 493.000), vci.fake.RoundColor(Color.LerpUnclamped(lpa, lpb, -123), 5))
		assert.are.equal(Color.__new(-6.339, -10.400, -19.100, 23.800), vci.fake.RoundColor(Color.LerpUnclamped(lpa, lpb, -5.7), 5))
		assert.are.equal(Color.__new(0.6225, 1.500, -1.250, 0.000), vci.fake.RoundColor(Color.LerpUnclamped(lpa, lpb, 0.25), 5))
		assert.are.equal(Color.__new(0.0375, 0.500, -2.750, 2.000), vci.fake.RoundColor(Color.LerpUnclamped(lpa, lpb, -0.25), 5))

		assert.are.equal(Color.__new(0, 0, 0), Color.HSVToRGB(0, 0, 0))
		assert.are.equal(Color.__new(0.21875, 0.25, 0.1875), Color.HSVToRGB(0.25, 0.25, 0.25))
		assert.are.equal(Color.__new(0.25, 0.5, 0.5), Color.HSVToRGB(0.5, 0.5, 0.5))
		assert.are.equal(Color.__new(0.46875, 0.1875, 0.75), Color.HSVToRGB(0.75, 0.75, 0.75))
		assert.are.equal(Color.__new(1, 0, 0), Color.HSVToRGB(1, 1, 1))

		-- local dictSize = 0
		-- local dict = {}
		-- dict[Color.__new(0.5, 0.25, 1)] = 'one'
		-- dict[Color.__new(0.5, 0.25, 1)] = 'two'
		-- for k, v in pairs(dict) do
		-- 	dictSize = dictSize + 1
		-- end
		-- assert.are.equal(1, dictSize)
		-- assert.are.equal('two', dict[Color.__new(0.5, 0.25, 1)])
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

		vci.fake.ClearMessage()

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
