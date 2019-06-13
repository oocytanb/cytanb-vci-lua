----------------------------------------------------------------
--  Copyright (c) 2019 oO (https://github.com/oocytanb)
--  MIT Licensed
----------------------------------------------------------------

describe('Test cytanb_vci_mock', function ()
	setup(function ()
		require('cytanb_vci_mock')
	end)

	teardown(function ()
		string.contains = nil
		string.startsWith = nil
		string.endsWith = nil

		local globals = {
			"_MOONSHARP",
			"dynamic",
			"json",
			"vci",
			"Vector2",
			"Vector3",
			"Vector4",
			"Color",
			"Quaternion",
			"Matrix4x4",
			"TimeSpan"
		}

		for key, val in pairs(globals) do
			_G[val] = nil
		end
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
end)
