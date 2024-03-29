-- SPDX-License-Identifier: MIT
-- Copyright (c) 2019 oO (https://github.com/oocytanb)

insulate('cytanb_min as module', function ()
    local min, full

    setup(function ()
        require('cytanb_fake_vci').vci.fake.Setup(_G)
        _G.__CYTANB_EXPORT_MODULE = true
        min = require('cytanb_min')(_ENV)
        package.loaded['cytanb'] = nil
        package.loaded['cytanb_min'] = nil
        full = require('cytanb')(_ENV)
    end)

    teardown(function ()
        package.loaded['cytanb'] = nil
        package.loaded['cytanb_min'] = nil
        _G.__CYTANB_EXPORT_MODULE = nil
        vci.fake.Teardown(_G)
    end)

    it('check identifier', function ()
        local sourceInfo = debug.getinfo(min.Vars, 'S').source or ''
        local infoLen = #sourceInfo
        if infoLen >= 2 and string.sub(sourceInfo, 1, 1) == '@' then
            local minPath = string.sub(sourceInfo, 2)
            local file = io.open(minPath, 'r')
            assert.truthy(file)
            local text = file:read(1024)
            io.close(file)
            assert.truthy(text)
            assert.truthy(string.find(text, '%s+local%s+cytanb%s*='))
        end
    end)

    it('check fields', function ()
        assert.are.same('table', type(min))
        assert.are.same('table', type(full))

        local fieldCount = 0
        for key, fullValue in pairs(full) do
            local minValue = min[key]
            assert.are.same(type(fullValue), type(minValue))

            local valueType = type(fullValue)
            if valueType == 'number' or valueType == 'string' or valueType == 'boolean' then
                assert.are.same(fullValue, minValue)
            end

            fieldCount = fieldCount + 1
        end
        assert.is_true(fieldCount > 10)
    end)
end)

insulate('cytanb_min as non-module', function ()
    local min

    setup(function ()
        math.randomseed(os.time() - os.clock() * 10000)
        require('cytanb_fake_vci').vci.fake.Setup(_G)
        min = require('cytanb_min')
    end)

    teardown(function ()
        package.loaded['cytanb_min'] = nil
        vci.fake.Teardown(_G)
    end)

    it('should not have impl', function ()
        -- モジュールが `nil` を返した場合は、`package.loaded[modname]` に `true` が格納される。`require` の戻り値として、`true` が返される。
        assert.is_true(min)
        assert.is_true(package.loaded['cytanb_min'])
        assert.is_nil(package.loaded['cytanb'])
    end)
end)
