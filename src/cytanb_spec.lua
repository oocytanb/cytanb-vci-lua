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

	teardown(function()
		package.loaded['cytanb'] = nil
		vci.fake.Teardown(_G)
	end)

	it('LogLevel', function ()
		assert.is_true(cytanb.FatalLogLevel > 0)
		assert.has_error(function() cytanb.FatalLogLevel = 123456789 end)
		local level = cytanb.GetLogLevel()
		assert.is_true(cytanb.FatalLogLevel > 0)
		assert.is_true(level > cytanb.FatalLogLevel)
		assert.are.same(level, cytanb.InfoLogLevel)
		cytanb.SetLogLevel(cytanb.FatalLogLevel)
		assert.are.same(cytanb.FatalLogLevel, cytanb.GetLogLevel())
		cytanb.SetLogLevel(level)
		assert.are_not.same(cytanb.FatalLogLevel, cytanb.GetLogLevel())
	end)

	it('owner InstanceID', function ()
		assert.are.same(36, #cytanb.InstanceID())
	end)
end)

describe('Test cytanb guest user', function ()
	local cytanb

	setup(function ()
		require('cytanb_fake_vci').vci.fake.Setup(_G)
		vci.fake.SetAssetsIsMine(false)

		cytanb = require('cytanb')
	end)

	teardown(function()
		package.loaded['cytanb'] = nil
		vci.fake.Teardown(_G)
	end)

	it('guest InstanceID', function ()
		assert.are.same('', cytanb.InstanceID())
		vci.state.Set('__CYTANB_INSTANCE_ID', '12345678-90ab-cdef-1234-567890abcdef')
		assert.are.same('12345678-90ab-cdef-1234-567890abcdef', cytanb.InstanceID())
	end)
end)
