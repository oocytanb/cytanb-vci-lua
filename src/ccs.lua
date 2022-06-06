--! SPDX-License-Identifier: MIT
--! SPDX-FileCopyrightText: 2020 oO (https://github.com/oocytanb)

-- **モジュールとして利用する場合は、次の行を有効にします。**
-- local __CYTANB_EXPORT_MODULE = true

-- モジュールの利用側は、本ファイルの名前を `ccs.lua` モジュール名を `ccs` として登録した上で、
-- VCI の `main.lua` から `local ccs = require('ccs')(_ENV)` として利用します。

--- cytanb-comment-source v0.9.3
local ccs = (function ()
  local make_impl = function (_ENV)
    if not vci then
      error('Invalid _ENV: vci module is not available', 2)
    end

    local function is_utf16_supported()
      if type(string.unicode) == 'function' then
        local a, b = string.unicode('😀', 1, 2)
        return a == 0xD83D and b == 0xDE00
      else
        return false
      end
    end

    local function is_utf8_supported()
      return type(utf8) == 'table'
        and type(utf8.codes) == 'function'
        and type(utf8.codepoint) == 'function'
        and utf8.codepoint('😀') == 0x1F600
    end

    ---@generic A
    ---@param str string
    ---@param f fun (prev: A, letter: string, index: number, original_index: number): A
    ---@param init A
    ---@return A
    local function string_reduce_utf16(str, f, init)
      local prev = init
      local ci = 1
      local i = 1
      local c = string.unicode(str, i, i)
      while c do
        local letter
        local j = i + 1
        if c >= 0xD800 and c <= 0xDBFF then
          -- Surrogate Code Point
          local lsg = string.unicode(str, j, j)
          if lsg and lsg >= 0xDC00 and lsg <= 0xDFFF then
            letter = string.char(c, lsg)
            j = j + 1
            c = string.unicode(str, j, j)
          else
            letter = string.char(c)
            c = lsg
          end
        else
          letter = string.char(c)
          c = string.unicode(str, j, j)
        end

        prev = f(prev, letter, ci, i)
        ci = ci + 1
        i = j
      end

      return prev
    end

    ---@generic A
    ---@param str string
    ---@param f fun (prev: A, letter: string, index: number, original_index: number): A
    ---@param init A
    ---@return A
    local function string_reduce_utf8(str, f, init)
      local prev = init
      local ci = 1
      for i, c in utf8.codes(str) do
        prev = f(prev, utf8.char(c), ci, i)
        ci = ci + 1
      end

      return prev
    end

    ---@generic A
    ---@param str string
    ---@param f fun (prev: A, letter: string, index: number, original_index: number): A
    ---@param init A
    ---@return A
    local function string_reduce_fallback(str, f, init)
      local prev = init
      for i = 1, string.len(str) do
        prev = f(prev, string.sub(str, i, i), i, i)
      end

      return prev
    end

    local string_reduce =
      is_utf16_supported()
      and string_reduce_utf16
      or is_utf8_supported()
      and string_reduce_utf8
      or string_reduce_fallback

    ---@param str string
    ---@param target string
    ---@param replacement string
    ---@return string
    local function string_replace(str, target, replacement)
      if target == '' then
        return string_reduce(
          str,
          function (prev, letter)
            return prev .. letter .. replacement
          end,
          replacement)
      else
        local ret = ''
        local len = string.len(str)
        local i = 1
        while i <= len do
          local si, ei = string.find(str, target, i, true)
          if si then
            ret = ret .. string.sub(str, i, si - 1) .. replacement
            i = ei + 1
          else
            ret = i == 1 and str or ret .. string.sub(str, i)
            i = len + 1
          end
        end
        return ret
      end
    end

    ---@param name string
    ---@param sender_type string
    local function dedicated_message_emitter(name, sender_type)
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
            __CYTANB_NO_ESCAPING = true,
          })
        )
      end
    end

    local conversion_dict = {
      ['nil'] = function (_val) return nil end,
      ['number'] = function (val) return tonumber(val) end,
      ['string'] = function (val) return tostring(val) end,
      ['boolean'] =
        function (val)
          if val then
            return true
          else
            return false
          end
        end,
    }

    ---@param type_string string
    ---@param value any
    ---@return any
    local function value_as(type_string, value)
      local vt = type(value)
      if vt == type_string then
        return value
      else
        local f_ = conversion_dict[type_string]
        if f_ then
          return f_(value)
        else
          return nil
        end
      end
    end

    ---@param sender table
    ---@param sender_override table
    ---@return table
    local function merge_message_sender(sender, sender_override)
      local ns = {}
      for k, v in pairs(sender) do
        local ov_ = sender_override[k]
        local nv
        if ov_ == nil then
          nv = v
        else
          local tv_ = value_as(type(v), ov_)
          if tv_ == nil then
            nv = v
          else
            nv = tv_
          end
        end

        ns[k] = nv
      end

      for k, v in pairs(sender_override) do
        if ns[k] == nil then
          ns[k] = v
        end
      end

      ns.__CYTANB_MESSAGE_ORIGINAL_SENDER = sender
      return ns
    end

    local escape_sequence_tag = '#__CYTANB'
    local escape_sequence_tag_len = string.len(escape_sequence_tag)
    local solidus_tag = '#__CYTANB_SOLIDUS'

    local escape_sequence_replacement_list = {
      {
        tag = solidus_tag,
        search = solidus_tag,
        replacement = '/'
      },
      {
        tag = escape_sequence_tag,
        search = escape_sequence_tag .. escape_sequence_tag,
        replacement = escape_sequence_tag
      },
    }

    ---@param str string
    ---@return string
    local function unescape_message_string(str)
      local len = string.len(str)
      if len < escape_sequence_tag_len then
        return str
      end

      local buf = ''
      local i = 1
      while i < len do
        local ei, ee = string.find(str, escape_sequence_tag, i, true)
        if not ei then
          if i == 1 then
            buf = str
          else
            buf = buf .. string.sub(str, i)
          end
          break
        end

        if ei > i then
          buf = buf .. string.sub(str, i, ei - 1)
        end

        local replaced = false
        for _, entry in ipairs(escape_sequence_replacement_list) do
          local si = string.find(str, entry.search, ei, true)
          if si == ei then
            buf = buf .. entry.replacement
            i = ei + string.len(entry.search)
            replaced = true
            break
          end
        end

        if not replaced then
          -- unknown sequence
          buf = buf .. escape_sequence_tag
          i = ee + 1
        end
      end
      return buf
    end

    ---@param tbl table
    ---@return table
    local function unescape_message_table(tbl)
      local data = {}
      for k, v in pairs(tbl) do
        local nk
        if type(k) == 'string' then
          nk = unescape_message_string(k)
        else
          nk = k
        end

        local vt = type(v)
        if vt == 'string' then
          data[nk] = unescape_message_string(v)
        elseif vt == 'table' then
          data[nk] = unescape_message_table(v)
        else
          data[nk] = v
        end
      end
      return data
    end

    ---@param name string
    ---@param record_name string
    ---@param official_name string
    local function dedicated_message_receiver(name, record_name, official_name)
      ---@param callback fun(sender: table, name: string, message: string)
      return function (callback)
        vci.message.On(
          name,
          function (sender, _message_name, message)
            local s = sender
            local m = message

            if type(message) == 'string' and
              string.sub(message, 1, 1) == '{'
            then
              local b, decoded = pcall(json.parse, message)
              if b and type(decoded) == 'table' and
                type(decoded.__CYTANB_INSTANCE_ID) == 'string'
              then
                local data =
                  decoded.__CYTANB_NO_ESCAPING
                  and decoded
                  or unescape_message_table(decoded)

                local so_ = data.__CYTANB_MESSAGE_SENDER_OVERRIDE
                if type(so_) == 'table' then
                  s = merge_message_sender(sender, so_)
                end
                m = data.__CYTANB_MESSAGE_VALUE or ''
              end
            end

            callback(s, official_name, tostring(m))
          end
        )

        vci.message.On(
          record_name,
          function (sender, _message_name, message)
            if type(message) == 'table' then
              local so_ = message.sender
              local s =
                type(so_) == 'table'
                and merge_message_sender(sender, so_)
                or sender

              callback(s, official_name, tostring(message.value or ''))
            end
          end
        )

        vci.message.On(official_name, function (sender, message_name, message)
          callback(sender, message_name, tostring(message))
        end)
      end
    end

    return {
      StringReduce = string_reduce,

      StringReplace = string_replace,

      EmitCommentMessage =
        dedicated_message_emitter(
          'cytanb.comment.a2a6a035-6b8d-4e06-b4f9-07e6209b0639',
          'comment'),

      OnCommentMessage =
        dedicated_message_receiver(
          'cytanb.comment.a2a6a035-6b8d-4e06-b4f9-07e6209b0639',
          'cytanb.comment.record',
          'comment'),

      EmitNotificationMessage =
        dedicated_message_emitter(
          'cytanb.notification.698ba55f-2b69-47f2-a68d-bc303994cff3',
          'notification'),

      OnNotificationMessage =
        dedicated_message_receiver(
          'cytanb.notification.698ba55f-2b69-47f2-a68d-bc303994cff3',
          'cytanb.notification.record',
          'notification'),
      }
  end

  if __CYTANB_EXPORT_MODULE then
    return setmetatable({}, {
      __call = function (_, main_env)
        return make_impl(main_env)
      end,
    })
  else
    return make_impl(_ENV)
  end
end)()

if __CYTANB_EXPORT_MODULE then
  return ccs
end

--[[
# 説明

このスクリプトには、cytanb.lua の `EmitCommentMessage` `OnCommentMessage`
`EmitNotificationMessage` `OnNotificationMessage` 関数の代替実装が含まれています。

cytanb.lua 全体のサイズが大きいため、送信と受信、それぞれで必要な部分を利用できるように
目指しました。

## コメントメッセージの送信例

```
if vci.assets.IsMine then
  ccs.EmitCommentMessage('Dummy Nico Comment', { name = 'DummyUser', commentSource = 'Nicolive' })
  ccs.EmitCommentMessage('【広告貢献oo位】ooさんがooptニコニ広告しました', { name = '', commentSource = 'NicoliveAd' })
  ccs.EmitCommentMessage('ooさんがギフト「oo（oopt）」を贈りました', { name = '', commentSource = 'NicoliveGift' })
  ccs.EmitCommentMessage('「oo」がリクエストされました', { name = '', commentSource = 'NicoliveSpi' })
  ccs.EmitCommentMessage('いい風', { name = '', commentSource = 'NicoliveEmotion' })
  ccs.EmitCommentMessage('「oo」が好きな1人が来場しました', { name = '', commentSource = 'NicoliveInfo' })
  ccs.EmitCommentMessage('切断しました', { name = '', commentSource = 'NicoliveDisconnected' })

  ccs.EmitCommentMessage('Dummy YT Comment', { name = 'DummyUser', commentSource = 'Youtubelive' })
  ccs.EmitCommentMessage('Dummy YT Membership', { name = 'DummyUser', commentSource = 'YoutubeliveMembership' })
  ccs.EmitCommentMessage('￥oo Dummy YT Superchat', { name = 'DummyUser', commentSource = 'YoutubeliveSuperchat' })
  ccs.EmitCommentMessage('Dummy YT Disconnected', { name = '', commentSource = 'YoutubeliveDisconnected' })
end
```

送信コード全体の実装は、プラグインが出力するファイルをご参照ください。
https://github.com/oocytanb/cytanb-vci-comment-plugin

## コメントメッセージの受信例

```
ccs.OnCommentMessage(function(sender, message_name, message)
  print(
    'on comment: name = ' .. sender.name ..
    ', commentSource = ' .. sender.commentSource ..
    ', message = ' .. message ..
    ' [length = ' .. string.len(message) .. ']')
end)
```

## 通知メッセージの送信例

```
if vci.assets.IsMine then
  ccs.EmitNotificationMessage('joined', { name = 'DummyNotificationUser' })
  ccs.EmitNotificationMessage('left', { name = 'DummyNotificationUser' })
end
```

## 通知メッセージの受信例

```
ccs.OnNotificationMessage(function(sender, message_name, message)
  print('on notification: name = ' .. sender.name .. ', message = ' .. message)
end)
```

## 新形式によるメッセージの送信例

`ccs.OnCommentMessage` と `ccs.OnNotificationMessage` 関数に対して、テーブル形式の
メッセージを受信できるように、機能拡張を行いました。
`vci.message.Emit` を使用して、直接テーブル形式を送信できるようになります。
(**旧 `cytanb.lua` では対応していませんので、ご注意ください。**)

コメントメッセージの形式

```
vci.message.Emit(
  'cytanb.comment.record',
  {
    value = 'コメントの内容',
    sender = {
      type = 'comment',
      name = 'ユーザー名',
      commentSource = '送信元',
    },
  })
```

`sender` に拡張パラメーターを追加する例

```
vci.message.Emit(
  'cytanb.comment.record',
  {
    value = 'コメントの内容',
    sender = {
      type = 'comment',
      name = 'ユーザー名',
      commentSource = '送信元',
      __EXT_POSIX_TIMESTAMP = 1577836800,
      __EXT_FOO_BAR = '拡張パラメーターの例',
    },
  })
```

通知メッセージの形式

```
vci.message.Emit(
  'cytanb.notification.record',
  {
    value = 'joined または left',
    sender = {
      type = 'notification',
      name = 'ユーザー名',
      commentSource = '',
    },
  })
```

## Unicode サロゲートペアを考慮して、文字列の処理をする例

```
local function append_letter_and_new_line(str, letter)
  return str .. letter .. ' [len: ' .. string.len(letter) .. ']\n'
end

local result = ccs.StringReduce('aあ😀', append_letter_and_new_line, '')
print(result)
```

出力結果

```
a [len: 1]
あ [len: 1]
😀 [len: 2]
```
--]]
