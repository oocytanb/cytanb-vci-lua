----------------------------------------------------------------
--  Copyright (c) 2019 oO (https://github.com/oocytanb)
--  MIT Licensed
----------------------------------------------------------------

-- [busted](https://olivinelabs.com/busted/) のサンプル用のテストコードです。
-- ファイル名に `_spec` が含まれている lua ファイルがテスト対象となります。
describe('Test hello busted', function ()
    it('boolean assertions', function ()
        assert.is_true(true)
        assert.is_false(false)
    end)

    it('number assertions', function ()
        assert.are.equal(2, 1 + 1)
        assert.are_not.equal(1, '1')
    end)

    it('string assertions', function ()
        assert.are.equal('Hello, World!', 'Hello'..', World!')
        assert.are_not.equal('Hello, World!', 'Hello')
    end)

    it('error assertions', function ()
        assert.has_no.errors(function () end)
        assert.has.errors(function () error('an error occurred.') end)
    end)
end)
