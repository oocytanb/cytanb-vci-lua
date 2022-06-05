--! SPDX-License-Identifier: MIT
--! SPDX-FileCopyrightText: 2020 oO (https://github.com/oocytanb)

local function make_env(main_env)
  return setmetatable({}, { __index = main_env })
end

local utf16_capable = not not (string.unicode or utf8)
local utf8_capable = not not utf8

if utf16_capable then
  insulate('ccs String UTF16', function ()
    local ccs
    setup(function ()
      require('cytanb_fake_vci').vci.fake.Setup(_G)
      _G.__CYTANB_EXPORT_MODULE = true
      local module = require('ccs')
      ccs = module(make_env(_ENV))
    end)

    teardown(function ()
      package.loaded['ccs'] = nil
      _G.__CYTANB_EXPORT_MODULE = nil
      vci.fake.Teardown(_G)
    end)

    describe('StringReduce', function ()
      local function tbl_reducer(prev, letter, index, original_index)
        table.insert(prev, { letter, index, original_index })
        return prev
      end

      it('empty', function ()
        local r = ccs.StringReduce(
          '',
          function (prev, letter)
            error('NEVER')
            return prev
          end,
          {})
        assert.are.same({}, r)
      end)

      it('alpha-num', function ()
        local r = ccs.StringReduce('a9', tbl_reducer, {})
        assert.are.same(
          {
            { 'a', 1, 1 },
            { '9', 2, 2 }
          },
          r)
      end)

      it('Unicode', function ()
        local r = ccs.StringReduce('aあ😀', function (prev, letter)
          return prev .. '-' .. letter
        end, '')
        assert.are.same('-a-あ-😀', r)
      end)
    end)

    describe('StringReplace', function ()
      it('empty', function ()
        assert.are.same('EM', ccs.StringReplace('', '', 'EM'))
        assert.are.same('', ccs.StringReplace('', 'ab', 'E'))
      end)

      it('empty target', function ()
        assert.are.same('EaEbEcEdE', ccs.StringReplace('abcd', '', 'E'))
      end)

      it('basics', function ()
        assert.are.same('ba', ccs.StringReplace('aaa', 'aa', 'b'))
        assert.are.same('XYXYa', ccs.StringReplace('aaaaa', 'aa', 'XY'))
        assert.are.same('cdcd', ccs.StringReplace('abcdabcdab', 'ab', ''))
        assert.are.same('abcdabcdab', ccs.StringReplace('abcdabcdab', 'AB', 'XY'))
      end)

      it('non ascii', function ()
        assert.are.same('ましましま', ccs.StringReplace('たしました', 'た', 'ま'))
        assert.are.same('@|㌣|', ccs.StringReplace('#|㌣|', '#', '@'))
      end)

      it('cytanb escaping', function ()
        assert.are.same('#__CYTANB_SOLIDUS#__CYTANB#__CYTANB|伯|㌣た⽟千す協㑁低あ|#__CYTANB#__CYTANB', ccs.StringReplace(
          ccs.StringReplace('/#__CYTANB|伯|㌣た⽟千す協㑁低あ|#__CYTANB', '#__CYTANB', '#__CYTANB#__CYTANB'),
          '/', '#__CYTANB_SOLIDUS'
        ))
      end)

      it('Unicode', function ()
        assert('/a/あ/😀/b/', ccs.StringReplace('aあ😀b', '', '/'))
        assert('a/b', ccs.StringReplace('aあ😀b', 'あ😀', '/'))
      end)
    end)
  end)
end

if utf8_capable then
  insulate('ccs String UTF8', function ()
    local ccs
    setup(function ()
      require('cytanb_fake_vci').vci.fake.Setup(_G)
      _G.string.unicode = nil
      _G.__CYTANB_EXPORT_MODULE = true
      local module = require('ccs')
      ccs = module(make_env(_ENV))
    end)

    teardown(function ()
      package.loaded['ccs'] = nil
      _G.__CYTANB_EXPORT_MODULE = nil
      vci.fake.Teardown(_G)
    end)

    describe('StringReduce', function ()
      local function tbl_reducer(prev, letter, index, original_index)
        table.insert(prev, { letter, index, original_index })
        return prev
      end

      it('empty', function ()
        local r = ccs.StringReduce(
          '',
          function (prev, letter)
            error('NEVER')
            return prev
          end,
          {})
        assert.are.same({}, r)
      end)

      it('alpha-num', function ()
        local r = ccs.StringReduce('a9', tbl_reducer, {})
        assert.are.same(
          {
            { 'a', 1, 1 },
            { '9', 2, 2 }
          },
          r)
      end)

      it('Unicode', function ()
        local r = ccs.StringReduce('aあ😀', function (prev, letter)
          return prev .. '-' .. letter
        end, '')
        assert.are.same('-a-あ-😀', r)
      end)
    end)

    describe('StringReplace', function ()
      it('empty', function ()
        assert.are.same('EM', ccs.StringReplace('', '', 'EM'))
        assert.are.same('', ccs.StringReplace('', 'ab', 'E'))
      end)

      it('empty target', function ()
        assert.are.same('EaEbEcEdE', ccs.StringReplace('abcd', '', 'E'))
      end)

      it('basics', function ()
        assert.are.same('ba', ccs.StringReplace('aaa', 'aa', 'b'))
        assert.are.same('XYXYa', ccs.StringReplace('aaaaa', 'aa', 'XY'))
        assert.are.same('cdcd', ccs.StringReplace('abcdabcdab', 'ab', ''))
        assert.are.same('abcdabcdab', ccs.StringReplace('abcdabcdab', 'AB', 'XY'))
      end)

      it('non ascii', function ()
        assert.are.same('ましましま', ccs.StringReplace('たしました', 'た', 'ま'))
        assert.are.same('@|㌣|', ccs.StringReplace('#|㌣|', '#', '@'))
      end)

      it('cytanb escaping', function ()
        assert.are.same('#__CYTANB_SOLIDUS#__CYTANB#__CYTANB|伯|㌣た⽟千す協㑁低あ|#__CYTANB#__CYTANB', ccs.StringReplace(
          ccs.StringReplace('/#__CYTANB|伯|㌣た⽟千す協㑁低あ|#__CYTANB', '#__CYTANB', '#__CYTANB#__CYTANB'),
          '/', '#__CYTANB_SOLIDUS'
        ))
      end)

      it('Unicode', function ()
        assert('/a/あ/😀/b/', ccs.StringReplace('aあ😀b', '', '/'))
        assert('a/b', ccs.StringReplace('aあ😀b', 'あ😀', '/'))
      end)
    end)
  end)
end

insulate('ccs String fallback', function ()
  local utf8_module
  local ccs
  setup(function ()
    require('cytanb_fake_vci').vci.fake.Setup(_G)
    utf8_module = _G.utf8
    _G.utf8 = nil
    _G.string.unicode = nil
    _G.__CYTANB_EXPORT_MODULE = true
    local module = require('ccs')
    ccs = module(make_env(_ENV))
  end)

  teardown(function ()
    package.loaded['ccs'] = nil
    _G.__CYTANB_EXPORT_MODULE = nil
    vci.fake.Teardown(_G)
    _G.utf8 = utf8_module
  end)

  describe('StringReduce', function ()
    local function tbl_reducer(prev, letter, index, original_index)
      table.insert(prev, { letter, index, original_index })
      return prev
    end

    it('empty', function ()
      local r = ccs.StringReduce(
        '',
        function (prev, letter)
          error('NEVER')
          return prev
        end,
        {})
      assert.are.same({}, r)
    end)

    it('alpha-num', function ()
      local r = ccs.StringReduce('a9', tbl_reducer, {})
      assert.are.same(
        {
          { 'a', 1, 1 },
          { '9', 2, 2 }
        },
        r)
    end)
  end)

  describe('StringReplace', function ()
    it('empty', function ()
      assert.are.same('EM', ccs.StringReplace('', '', 'EM'))
      assert.are.same('', ccs.StringReplace('', 'ab', 'E'))
    end)

    it('empty target', function ()
      assert.are.same('EaEbEcEdE', ccs.StringReplace('abcd', '', 'E'))
    end)

    it('basics', function ()
      assert.are.same('ba', ccs.StringReplace('aaa', 'aa', 'b'))
      assert.are.same('XYXYa', ccs.StringReplace('aaaaa', 'aa', 'XY'))
      assert.are.same('cdcd', ccs.StringReplace('abcdabcdab', 'ab', ''))
      assert.are.same('abcdabcdab', ccs.StringReplace('abcdabcdab', 'AB', 'XY'))
    end)

    it('non ascii', function ()
      assert.are.same('ましましま', ccs.StringReplace('たしました', 'た', 'ま'))
      assert.are.same('@|㌣|', ccs.StringReplace('#|㌣|', '#', '@'))
    end)

    it('cytanb escaping', function ()
      assert.are.same('#__CYTANB_SOLIDUS#__CYTANB#__CYTANB|伯|㌣た⽟千す協㑁低あ|#__CYTANB#__CYTANB', ccs.StringReplace(
        ccs.StringReplace('/#__CYTANB|伯|㌣た⽟千す協㑁低あ|#__CYTANB', '#__CYTANB', '#__CYTANB#__CYTANB'),
        '/', '#__CYTANB_SOLIDUS'
      ))
    end)
  end)
end)

insulate('ccs as module', function ()
  local ccs

  local dedicated_comment_name = 'cytanb.comment.a2a6a035-6b8d-4e06-b4f9-07e6209b0639'
  local comment_record_name = 'cytanb.comment.record'
  local dedicated_notification_name = 'cytanb.notification.698ba55f-2b69-47f2-a68d-bc303994cff3'
  local notification_record_name = 'cytanb.notification.record'

  local function special_dedicated_message_emitter(name, sender_type)
    ---@param message string
    ---@param sender_override table | nil
    return function (message, sender_override)
      local sender = { type = sender_type, name = '', commentSource = '' }
      if type(sender_override) == 'table' then
        for k, v in pairs(sender_override) do
          local o = sender[k]
          if o == nil or type(o) == type(v) then
            sender[k] = v
          else
            sender[k] = tostring(v)
          end
        end
      end

      vci.message.Emit(
        name,
        json.serialize({
          __CYTANB_INSTANCE_ID = vci.assets.GetInstanceId() or '',
          __CYTANB_MESSAGE_VALUE = tostring(message),
          __CYTANB_MESSAGE_SENDER_OVERRIDE = sender,
          __CYTANB_SPECIAL_TEST_DATA = { true },
        })
      )
    end
  end

  local emit_special_comment_message =
    special_dedicated_message_emitter(dedicated_comment_name, 'comment')

  local function on_cytanb_message(name, callback)
    vci.message.On(name, function (sender, message_name, message)
      local decoded = json.parse(message)
      callback(sender, message_name, decoded or tostring(message))
    end)
  end

  setup(function ()
    require('cytanb_fake_vci').vci.fake.Setup(_G)
    _G.__CYTANB_EXPORT_MODULE = true
    local module = require('ccs')
    ccs = module(make_env(_ENV))
  end)

  teardown(function ()
    package.loaded['ccs'] = nil
    _G.__CYTANB_EXPORT_MODULE = nil
    vci.fake.Teardown(_G)
  end)

  describe('CommentMessage', function ()
    local cbm

    before_each(function ()
      cbm = {
        official = function () end,
        record = function () end,
        dedicated = function () end,
        cytanb = function () end,
      }

      for k, _ in pairs(cbm) do
        stub(cbm, k)
      end

      vci.message.On('comment', cbm.official)
      vci.message.On(comment_record_name, cbm.record)
      on_cytanb_message(dedicated_comment_name, cbm.dedicated)
      ccs.OnCommentMessage(cbm.cytanb)
    end)

    after_each(function()
      vci.fake.ClearMessageCallbacks()

      for _, v in pairs(cbm) do
        v:revert()
      end
    end)

    it('Empty comment', function ()
      vci.fake.EmitVciCommentMessage('', '', '')

      assert.stub(cbm.official).was.called(1)
      assert.stub(cbm.record).was.called(0)
      assert.stub(cbm.dedicated).was.called(0)

      assert.stub(cbm.cytanb).was.called_with(
        {
          type = 'comment',
          name = '',
          commentSource = ''
        },
        'comment',
        '')
    end)

    it('JSON comment', function ()
      vci.fake.EmitVciCommentMessage('JS', '{"__CYTANB_MESSAGE_VALUE":"hot"}', 'Twitter')

      assert.stub(cbm.official).was.called(1)
      assert.stub(cbm.record).was.called(0)
      assert.stub(cbm.dedicated).was.called(0)

      assert.stub(cbm.cytanb).was.called_with(
        {
          type = 'comment',
          name = 'JS',
          commentSource = 'Twitter'
        },
        'comment',
        '{"__CYTANB_MESSAGE_VALUE":"hot"}')
    end)

    it('JSON not cytanb comment', function ()
      vci.message.Emit(dedicated_comment_name, '{"__CYTANB_MESSAGE_VALUE":987}')

      assert.stub(cbm.official).was.called(0)
      assert.stub(cbm.record).was.called(0)

      assert.stub(cbm.dedicated).was.called_with(
        {
          type = 'vci',
          name = 'cytanb_fake_vci',
          commentSource = '',
        },
        dedicated_comment_name,
        {
          __CYTANB_MESSAGE_VALUE = 987,
        })

      assert.stub(cbm.cytanb).was.called_with(
        {
          type = 'vci',
          name = 'cytanb_fake_vci',
          commentSource = '',
        },
        'comment',
        '{"__CYTANB_MESSAGE_VALUE":987}')
    end)

    it('non JSON comment', function ()
      vci.message.Emit(dedicated_comment_name, '{"__CYTANB_MESSAGE_VALUE":987')

      assert.stub(cbm.official).was.called(0)
      assert.stub(cbm.record).was.called(0)

      assert.stub(cbm.dedicated).was.called_with(
        {
          type = 'vci',
          name = 'cytanb_fake_vci',
          commentSource = '',
        },
        dedicated_comment_name,
        '{"__CYTANB_MESSAGE_VALUE":987')

      assert.stub(cbm.cytanb).was.called_with(
        {
          type = 'vci',
          name = 'cytanb_fake_vci',
          commentSource = '',
        },
        'comment',
        '{"__CYTANB_MESSAGE_VALUE":987')
    end)

    it('JSON cytanb comment', function ()
      vci.message.Emit(dedicated_comment_name, '{"__CYTANB_MESSAGE_VALUE":987,"__CYTANB_INSTANCE_ID":"123abc"}')

      assert.stub(cbm.official).was.called(0)
      assert.stub(cbm.record).was.called(0)

      assert.stub(cbm.dedicated).was.called_with(
        {
          type = 'vci',
          name = 'cytanb_fake_vci',
          commentSource = '',
        },
        dedicated_comment_name,
        {
          __CYTANB_INSTANCE_ID = '123abc',
          __CYTANB_MESSAGE_VALUE = 987,
        })

      assert.stub(cbm.cytanb).was.called_with(
        {
          type = 'vci',
          name = 'cytanb_fake_vci',
          commentSource = '',
        },
        'comment',
        '987')
    end)

    it('Showroom comment', function ()
      vci.fake.EmitVciShowroomCommentMessage('ShowroomUser', '50/#__CYTANB_SOLIDUS\\z')

      assert.stub(cbm.official).was.called(1)
      assert.stub(cbm.record).was.called(0)
      assert.stub(cbm.dedicated).was.called(0)

      assert.stub(cbm.cytanb).was.called_with(
        {
          type = 'comment',
          name = 'ShowroomUser',
          commentSource = 'Showroom',
        },
        'comment',
        '50/#__CYTANB_SOLIDUS\\z')
      end)

    it('cytanb sender-omitted', function ()
      ccs.EmitCommentMessage('DummyComment sender-omitted')

      assert.stub(cbm.official).was.called(0)
      assert.stub(cbm.record).was.called(0)

      assert.stub(cbm.dedicated).was.called_with(
        {
          type = 'vci',
          name = 'cytanb_fake_vci',
          commentSource = '',
        },
        dedicated_comment_name,
        {
          __CYTANB_INSTANCE_ID = vci.assets.GetInstanceId(),
          __CYTANB_MESSAGE_SENDER_OVERRIDE = {
            type = 'comment',
            name = '',
            commentSource = '',
          },
          __CYTANB_MESSAGE_VALUE = 'DummyComment sender-omitted',
          __CYTANB_NO_ESCAPING = true,
        })

      assert.stub(cbm.cytanb).was.called_with(
        {
          type = 'comment',
          name = '',
          commentSource = '',
          __CYTANB_MESSAGE_ORIGINAL_SENDER = {
            type = 'vci',
            name = 'cytanb_fake_vci',
            commentSource = '',
          },
        },
        'comment',
        'DummyComment sender-omitted')
    end)

    it('cytanb sender-Nicolive', function ()
      ccs.EmitCommentMessage(
        'Dummy Nico/#__CYTANB_SOLIDUS\\z\nLF',
        { name = 'NicoUser', commentSource = 'Nicolive' })

      assert.stub(cbm.official).was.called(0)
      assert.stub(cbm.record).was.called(0)

      assert.stub(cbm.dedicated).was.called_with(
        {
          type = 'vci',
          name = 'cytanb_fake_vci',
          commentSource = '',
        },
        dedicated_comment_name,
        {
          __CYTANB_INSTANCE_ID = vci.assets.GetInstanceId(),
          __CYTANB_MESSAGE_SENDER_OVERRIDE = {
            type = 'comment',
            name = 'NicoUser',
            commentSource = 'Nicolive',
          },
          __CYTANB_MESSAGE_VALUE = 'Dummy Nico/#__CYTANB_SOLIDUS\\z\nLF',
          __CYTANB_NO_ESCAPING = true,
        })

      assert.stub(cbm.cytanb).was.called_with(
        {
          type = 'comment',
          name = 'NicoUser',
          commentSource = 'Nicolive',
          __CYTANB_MESSAGE_ORIGINAL_SENDER = {
            type = 'vci',
            name = 'cytanb_fake_vci',
            commentSource = '',
          },
        },
        'comment',
        'Dummy Nico/#__CYTANB_SOLIDUS\\z\nLF')
    end)

    it('cytanb sender-Twitter empty', function ()
      ccs.EmitCommentMessage(
        '',
        { name = 'T/user', commentSource = 'Twitter' })

      assert.stub(cbm.official).was.called(0)
      assert.stub(cbm.record).was.called(0)

      assert.stub(cbm.dedicated).was.called_with(
        {
          type = 'vci',
          name = 'cytanb_fake_vci',
          commentSource = '',
        },
        dedicated_comment_name,
        {
          __CYTANB_INSTANCE_ID = vci.assets.GetInstanceId(),
          __CYTANB_MESSAGE_SENDER_OVERRIDE = {
            type = 'comment',
            name = 'T/user',
            commentSource = 'Twitter',
          },
          __CYTANB_MESSAGE_VALUE = '',
          __CYTANB_NO_ESCAPING = true,
        })

      assert.stub(cbm.cytanb).was.called_with(
        {
          type = 'comment',
          name = 'T/user',
          commentSource = 'Twitter',
          __CYTANB_MESSAGE_ORIGINAL_SENDER = {
            type = 'vci',
            name = 'cytanb_fake_vci',
            commentSource = '',
          },
        },
        'comment',
        '')
    end)

    it('cytanb sender-invalid', function ()
      ccs.EmitCommentMessage(
        'test sender-invalid',
        'invalid')

      assert.stub(cbm.official).was.called(0)
      assert.stub(cbm.record).was.called(0)

      assert.stub(cbm.dedicated).was.called_with(
        {
          type = 'vci',
          name = 'cytanb_fake_vci',
          commentSource = '',
        },
        dedicated_comment_name,
        {
          __CYTANB_INSTANCE_ID = vci.assets.GetInstanceId(),
          __CYTANB_MESSAGE_SENDER_OVERRIDE = {
            type = 'comment',
            name = '',
            commentSource = '',
          },
          __CYTANB_MESSAGE_VALUE = 'test sender-invalid',
          __CYTANB_NO_ESCAPING = true,
        })

      assert.stub(cbm.cytanb).was.called_with(
        {
          type = 'comment',
          name = '',
          commentSource = '',
          __CYTANB_MESSAGE_ORIGINAL_SENDER = {
            type = 'vci',
            name = 'cytanb_fake_vci',
            commentSource = '',
          },
        },
        'comment',
        'test sender-invalid')
    end)

    it('cytanb sender-loose', function ()
      ccs.EmitCommentMessage(
        'test sender-loose',
        {
          type = 123,
          name = 'loose',
          commentSource = true,
          __EXT_FALSE = false,
          __EXT_NEGATIVE = -1,
        })

      assert.stub(cbm.official).was.called(0)
      assert.stub(cbm.record).was.called(0)

      assert.stub(cbm.dedicated).was.called_with(
        {
          type = 'vci',
          name = 'cytanb_fake_vci',
          commentSource = '',
        },
        dedicated_comment_name,
        {
          __CYTANB_INSTANCE_ID = vci.assets.GetInstanceId(),
          __CYTANB_MESSAGE_SENDER_OVERRIDE = {
            type = '123',
            name = 'loose',
            commentSource = 'true',
            __EXT_FALSE = false,
            __EXT_NEGATIVE = -1,
            },
          __CYTANB_MESSAGE_VALUE = 'test sender-loose',
          __CYTANB_NO_ESCAPING = true,
        })

      assert.stub(cbm.cytanb).was.called_with(
        {
          type = '123',
          name = 'loose',
          commentSource = 'true',
          __EXT_FALSE = false,
          __EXT_NEGATIVE = -1,
          __CYTANB_MESSAGE_ORIGINAL_SENDER = {
            type = 'vci',
            name = 'cytanb_fake_vci',
            commentSource = '',
          },
        },
        'comment',
        'test sender-loose')
    end)

    it('cytanb escaping tag', function ()
      ccs.EmitCommentMessage(
        '/test#__CYTANB_SOLIDUS>#__CYTANB_>/>\\>\\n>\\z/',
        {
          name = '/escaping tag#__CYTANB_SOLIDUS>/',
          commentSource = "/EscapingTag",
        })

      assert.stub(cbm.official).was.called(0)
      assert.stub(cbm.record).was.called(0)

      assert.stub(cbm.dedicated).was.called_with(
        {
          type = 'vci',
          name = 'cytanb_fake_vci',
          commentSource = '',
        },
        dedicated_comment_name,
        {
          __CYTANB_INSTANCE_ID = vci.assets.GetInstanceId(),
          __CYTANB_MESSAGE_SENDER_OVERRIDE = {
            type = 'comment',
            name = '/escaping tag#__CYTANB_SOLIDUS>/',
            commentSource = '/EscapingTag',
          },
          __CYTANB_MESSAGE_VALUE = '/test#__CYTANB_SOLIDUS>#__CYTANB_>/>\\>\\n>\\z/',
          __CYTANB_NO_ESCAPING = true,
        })

      assert.stub(cbm.cytanb).was.called_with(
        {
          type = 'comment',
          name = '/escaping tag#__CYTANB_SOLIDUS>/',
          commentSource = '/EscapingTag',
          __CYTANB_MESSAGE_ORIGINAL_SENDER = {
            type = 'vci',
            name = 'cytanb_fake_vci',
            commentSource = '',
          },
        },
        'comment',
        '/test#__CYTANB_SOLIDUS>#__CYTANB_>/>\\>\\n>\\z/')
    end)

    it('cytanb nested', function ()
      ccs.EmitCommentMessage(
        '{"content":"nested"}',
        {
          name = ' ns ',
          commentSource = ' [NS] ',
        })

      assert.stub(cbm.official).was.called(0)
      assert.stub(cbm.record).was.called(0)

      assert.stub(cbm.dedicated).was.called_with(
        {
          type = 'vci',
          name = 'cytanb_fake_vci',
          commentSource = '',
        },
        dedicated_comment_name,
        {
          __CYTANB_INSTANCE_ID = vci.assets.GetInstanceId(),
          __CYTANB_MESSAGE_SENDER_OVERRIDE = {
            type = 'comment',
            name = ' ns ',
            commentSource = ' [NS] ',
          },
          __CYTANB_MESSAGE_VALUE = '{"content":"nested"}',
          __CYTANB_NO_ESCAPING = true,
        })

      assert.stub(cbm.cytanb).was.called_with(
        {
          type = 'comment',
          name = ' ns ',
          commentSource = ' [NS] ',
          __CYTANB_MESSAGE_ORIGINAL_SENDER = {
            type = 'vci',
            name = 'cytanb_fake_vci',
            commentSource = '',
          },
        },
        'comment',
        '{"content":"nested"}')
    end)

    it('cytanb escaped', function ()
      emit_special_comment_message(
        '#__CYTANB_SOLIDUS#__CYTANB#__CYTANB|伯|㌣た⽟千す協㑁低あ|#__CYTANB#__CYTANB',
        {
          name = '#__CYTANB_UNKTAG',
          commentSource = ' [NS] ',
        })

      assert.stub(cbm.official).was.called(0)
      assert.stub(cbm.record).was.called(0)

      assert.stub(cbm.dedicated).was.called_with(
        {
          type = 'vci',
          name = 'cytanb_fake_vci',
          commentSource = '',
        },
        dedicated_comment_name,
        {
          __CYTANB_INSTANCE_ID = vci.assets.GetInstanceId(),
          __CYTANB_MESSAGE_SENDER_OVERRIDE = {
            type = 'comment',
            name = '#__CYTANB_UNKTAG',
            commentSource = ' [NS] ',
          },
          __CYTANB_MESSAGE_VALUE = '#__CYTANB_SOLIDUS#__CYTANB#__CYTANB|伯|㌣た⽟千す協㑁低あ|#__CYTANB#__CYTANB',
          __CYTANB_SPECIAL_TEST_DATA = { true },
        })

      assert.stub(cbm.cytanb).was.called_with(
        {
          type = 'comment',
          name = '#__CYTANB_UNKTAG',
          commentSource = ' [NS] ',
          __CYTANB_MESSAGE_ORIGINAL_SENDER = {
            type = 'vci',
            name = 'cytanb_fake_vci',
            commentSource = '',
          },
        },
        'comment',
        '/#__CYTANB|伯|㌣た⽟千す協㑁低あ|#__CYTANB')
    end)

    it('record invalid format', function ()
      vci.message.Emit(comment_record_name, 'invalid format')

      assert.stub(cbm.official).was.called(0)
      assert.stub(cbm.dedicated).was.called(0)

      assert.stub(cbm.record).was.called_with(
        {
          type = 'vci',
          name = 'cytanb_fake_vci',
          commentSource = '',
        },
        comment_record_name,
        'invalid format')

      assert.stub(cbm.cytanb).was.called(0)
    end)

    it('record empty table', function ()
      vci.message.Emit(comment_record_name, {})

      assert.stub(cbm.official).was.called(0)
      assert.stub(cbm.dedicated).was.called(0)

      assert.stub(cbm.record).was.called_with(
        {
          type = 'vci',
          name = 'cytanb_fake_vci',
          commentSource = '',
        },
        comment_record_name,
        {})

      assert.stub(cbm.cytanb).was.called_with(
        {
          type = 'vci',
          name = 'cytanb_fake_vci',
          commentSource = '',
        },
        'comment',
        '')
    end)

    it('record loose', function ()
      vci.message.Emit(
        comment_record_name,
        {
          value = '{"content":"nested"}',
          sender = {
            type = false,
            name = -5,
            __EXT_ARRAY = { { 'foo', 'bar' }, { 'baz' } },
            __EXT_TRUE = true,
            __EXT_FALSE = false,
          },
          __EXT_PARAM = 123,
        })

      assert.stub(cbm.official).was.called(0)
      assert.stub(cbm.dedicated).was.called(0)

      assert.stub(cbm.record).was.called_with(
        {
          type = 'vci',
          name = 'cytanb_fake_vci',
          commentSource = '',
        },
        comment_record_name,
        {
          value = '{"content":"nested"}',
          sender = {
            type = false,
            name = -5,
            __EXT_ARRAY = { { 'foo', 'bar' }, { 'baz' } },
            __EXT_TRUE = true,
            __EXT_FALSE = false,
          },
          __EXT_PARAM = 123,
        })

      assert.stub(cbm.cytanb).was.called_with(
        {
          type = 'false',
          name = '-5',
          commentSource = '',
          __EXT_ARRAY = { { 'foo', 'bar' }, { 'baz' } },
          __EXT_TRUE = true,
          __EXT_FALSE = false,
          __CYTANB_MESSAGE_ORIGINAL_SENDER = {
            type = 'vci',
            name = 'cytanb_fake_vci',
            commentSource = '',
          },
        },
        'comment',
        '{"content":"nested"}')
    end)
  end)

  describe('NotificationMessage', function ()
    local cbm

    before_each(function ()
      cbm = {
        official = function () end,
        record = function () end,
        dedicated = function () end,
        cytanb = function () end,
      }

      for k, _ in pairs(cbm) do
        stub(cbm, k)
      end

      vci.message.On('notification', cbm.official)
      vci.message.On(notification_record_name, cbm.record)
      on_cytanb_message(dedicated_notification_name, cbm.dedicated)
      ccs.OnNotificationMessage(cbm.cytanb)
    end)

    after_each(function()
      vci.fake.ClearMessageCallbacks()

      for _, v in pairs(cbm) do
        v:revert()
      end
    end)

    it('Joined', function ()
      vci.fake.EmitVciJoinedNotificationMessage('/#__CYTANB|伯|㌣た⽟千す協㑁低あ|#__CYTANB')

      assert.stub(cbm.official).was.called(1)
      assert.stub(cbm.record).was.called(0)
      assert.stub(cbm.dedicated).was.called(0)

      assert.stub(cbm.cytanb).was.called_with(
        {
          type = 'notification',
          name = '/#__CYTANB|伯|㌣た⽟千す協㑁低あ|#__CYTANB',
          commentSource = '',
        },
        'notification',
        'joined')
      end)

    it('cytanb sender-omitted', function ()
      ccs.EmitNotificationMessage('left')

      assert.stub(cbm.official).was.called(0)
      assert.stub(cbm.record).was.called(0)

      assert.stub(cbm.dedicated).was.called_with(
        {
          type = 'vci',
          name = 'cytanb_fake_vci',
          commentSource = '',
        },
        dedicated_notification_name,
        {
          __CYTANB_INSTANCE_ID = vci.assets.GetInstanceId(),
          __CYTANB_MESSAGE_SENDER_OVERRIDE = {
            type = 'notification',
            name = '',
            commentSource = '',
          },
          __CYTANB_MESSAGE_VALUE = 'left',
          __CYTANB_NO_ESCAPING = true,
        })

      assert.stub(cbm.cytanb).was.called_with(
        {
          type = 'notification',
          name = '',
          commentSource = '',
          __CYTANB_MESSAGE_ORIGINAL_SENDER = {
            type = 'vci',
            name = 'cytanb_fake_vci',
            commentSource = '',
          },
        },
        'notification',
        'left')
    end)

    it('cytanb sender', function ()
      ccs.EmitNotificationMessage(-1, {
        name = '/#__CYTANB|伯|㌣た⽟千す協㑁低あ|#__CYTANB',
        commentSource = false,
      })

      assert.stub(cbm.official).was.called(0)
      assert.stub(cbm.record).was.called(0)

      assert.stub(cbm.dedicated).was.called_with(
        {
          type = 'vci',
          name = 'cytanb_fake_vci',
          commentSource = '',
        },
        dedicated_notification_name,
        {
          __CYTANB_INSTANCE_ID = vci.assets.GetInstanceId(),
          __CYTANB_MESSAGE_SENDER_OVERRIDE = {
            type = 'notification',
            name = '/#__CYTANB|伯|㌣た⽟千す協㑁低あ|#__CYTANB',
            commentSource = 'false',
          },
          __CYTANB_MESSAGE_VALUE = '-1',
          __CYTANB_NO_ESCAPING = true,
        })

      assert.stub(cbm.cytanb).was.called_with(
        {
          type = 'notification',
          name = '/#__CYTANB|伯|㌣た⽟千す協㑁低あ|#__CYTANB',
          commentSource = 'false',
          __CYTANB_MESSAGE_ORIGINAL_SENDER = {
            type = 'vci',
            name = 'cytanb_fake_vci',
            commentSource = '',
          },
        },
        'notification',
        '-1')
    end)

    it('record', function ()
      vci.message.Emit(
        notification_record_name,
        {
          value = 'joined',
          sender = {
            type = 'notification',
            name = '#__CYTANB#__CYTANB',
            __EXT_ARRAY = { { 'foo', 'bar' }, { 'baz' } },
            __EXT_TRUE = true,
            __EXT_FALSE = false,
          },
          __EXT_PARAM = 123,
        })

      assert.stub(cbm.official).was.called(0)
      assert.stub(cbm.dedicated).was.called(0)

      assert.stub(cbm.record).was.called_with(
        {
          type = 'vci',
          name = 'cytanb_fake_vci',
          commentSource = '',
        },
        notification_record_name,
        {
          value = 'joined',
          sender = {
            type = 'notification',
            name = '#__CYTANB#__CYTANB',
            __EXT_ARRAY = { { 'foo', 'bar' }, { 'baz' } },
            __EXT_TRUE = true,
            __EXT_FALSE = false,
          },
          __EXT_PARAM = 123,
        })

      assert.stub(cbm.cytanb).was.called_with(
        {
          type = 'notification',
          name = '#__CYTANB#__CYTANB',
          commentSource = '',
          __EXT_ARRAY = { { 'foo', 'bar' }, { 'baz' } },
          __EXT_TRUE = true,
          __EXT_FALSE = false,
          __CYTANB_MESSAGE_ORIGINAL_SENDER = {
            type = 'vci',
            name = 'cytanb_fake_vci',
            commentSource = '',
          },
        },
        'notification',
        'joined')
    end)
  end)
end)

insulate('ccs with invalid _ENV', function ()
  local module

  setup(function ()
    require('cytanb_fake_vci').vci.fake.Setup(_G)
    _G.__CYTANB_EXPORT_MODULE = true
    module = require('ccs')
  end)

  teardown(function ()
    package.loaded['ccs'] = nil
    vci.fake.Teardown(_G)
  end)

  describe('invalid _ENV', function ()
    it('should raise error', function ()
      local s = spy.new(function(message, level) error(message, (level or 1) + 1) end)
      assert.has_error(function () return module({ error = s }) end)
      assert.spy(s).was.called(1)
      assert.spy(s).was.called_with('Invalid _ENV: vci module is not available', 2)
    end)
  end)
end)

insulate('ccs as non-module', function ()
  local module

  setup(function ()
    require('cytanb_fake_vci').vci.fake.Setup(_G)
    module = require('ccs')
  end)

  teardown(function ()
    package.loaded['ccs'] = nil
    vci.fake.Teardown(_G)
  end)

  it('should not have impl', function ()
    assert.is_true(module)
    assert.is_true(package.loaded['ccs'])
  end)
end)
