----------------------------------------------------------------
--  Copyright (c) 2019 oO (https://github.com/oocytanb)
--  MIT Licensed
----------------------------------------------------------------

describe('Test cytanb_vci_mock', function ()
	setup(function ()
		require('cytanb_vci_mock')
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
end)