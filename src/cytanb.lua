--! SPDX-License-Identifier: MIT
--! Copyright (c) 2019 oO (https://github.com/oocytanb)

-- `cytanb.lua` をモジュールとして利用する場合は、以下の通り。
--   1. この手順の説明の下にある `local __CYTANB_EXPORT_MODULE = true` の行を有効にする。
--   2. `VCI Object` コンポーンネントの `Scripts` に、`cytanb.lua` をモジュール名 `cytanb` として追加設定する。
--   3. VCI の `require` 関数を `main.lua` スクリプトから `cytanb = cytanb or require('cytanb')(_ENV)` として呼び出す。

-- **`cytanb.lua` をモジュールとして利用する場合は、次の行を有効にすること。**
-- local __CYTANB_EXPORT_MODULE = true

---@type cytanb @Final Version. See `cytanb_annotations.lua`
local cytanb = (function ()
    local makeImpl = function (_ENV)
        if not require or not vci then
            error('Invalid _ENV: Enable `__CYTANB_EXPORT_MODULE = true` line and pass valid _ENV of VCI-main if use cytanb.lua as module.', 3)
        end

        --- 既定のホワイトスペースの検索パターン。
        local defaultWhiteSpaceSearchPattern

        --- TMP Sprite のノード名の検索パターン。
        local tmpSpriteNodeNamePattern

        --- TMP Sprite のインデックスの検索パターン。
        local tmpSpriteIndexPattern

        --- 16 進数の検索パターン。
        local hexSearchPattern_4
        local hexSearchPattern_8

        --- タグコンポーネントの検索パターン。
        local tagComponentSearchPattern

        --- エスケープシーケンスの置換リスト。
        local escapeSequenceReplacementList

        --- 値の変換マップ。
        local valueConversionMap

        -- パラメーター値の置換マップ。
        local parameterValueReplacementMap

        --- 出力するログレベル。
        local logLevel

        --- ログ出力する時に、ログレベルの文字列を出力するか。
        local outputLogLevelEnabled = false

        --- ログレベルの文字列マップ。
        local logLevelStringMap

        --- 自身の ID の文字列。
        local ownID = ''

        local cytanb

        local SearchStartsWithPred = function (position, searchLen)
            local ni = position + searchLen - 1
            return position, ni, ni + 1
        end

        local SearchEndsWithPred = function (position, searchLen)
            local ni = position - searchLen + 1
            return ni, position, ni - 1
        end

        local SearchPatternClass = function (str, strLen, searchPattern, position, pred)
            local searchMap = searchPattern.searchMap
            for _idx, searchLen in pairs(searchPattern.lengthList) do
                if searchLen <= 0 then
                    error('SearchPattern: Invalid parameter: searchLen <= 0')
                else
                    local si, ei, ni = pred(position, searchLen)
                    if si >= 1 and ei <= strLen then
                        local sub = string.sub(str, si, ei)
                        if searchMap[sub] then
                            return true, searchLen, ni
                        end
                    end
                end
            end
            return false, -1, -1
        end

        -- 正規表現のパターンマッチングは、Unicode で問題が出るので使わずに実装する。(https://github.com/moonsharp-devs/moonsharp/pull/184)
        local SearchPatternExec = function (str, searchPattern, position, pred)
            if str == nil or searchPattern == nil then
                return false, -1
            end

            if searchPattern.hasEmptySearch then
                -- 検索文字列に空文字列が含まれているなら、常に true を返す。
                return true, 0
            end

            local strLen = string.len(str)
            local repeatMin = searchPattern.repeatMin
            local repeatMax = searchPattern.repeatMax
            local repeatInfinite = repeatMax < 0

            local pi = position
            local retLen = 0
            local repeatN = 0
            while repeatInfinite or repeatN < repeatMax do
                local b, ml, ni = SearchPatternClass(str, strLen, searchPattern, pi, pred)
                if b then
                    if ml <= 0 then
                        -- searchPattern.hasEmptySearch でリターンしているはずなので、ここに来てはいけない。
                        error('SearchPattern: Invalid parameter')
                    end
                    pi = ni
                    retLen = retLen + ml
                    repeatN = repeatN + 1
                else
                    break
                end
            end

            if repeatN >= repeatMin then
                return true, retLen
            else
                return false, -1
            end
        end

        -- 正規表現のパターンマッチングは、Unicode で問題が出るので使わずに実装する。(https://github.com/moonsharp-devs/moonsharp/pull/184)
        local StringSearchEdge = function (str, search, position, positionIsEdge, pred, cmp)
            if str == nil or search == nil then
                return false, -1
            end

            local searchLen = string.len(search)
            if positionIsEdge then
                -- 端の位置が指定された場合は、そのまま渡す。
                local b = cmp(str, search)
                return b, b and searchLen or -1
            else
                -- 端の位置以外が指定された場合は、search で指定された文字列の長さ分を切り出して判定する
                if searchLen == 0 then
                    -- 検索文字列が空文字列であれば、常に true を返す。
                    return true, searchLen
                end

                local strLen = string.len(str)
                local si, ei = pred(position, searchLen)
                if si >= 1 and ei <= strLen then
                    local sub = string.sub(str, si, ei)
                    local b = cmp(sub, search)
                    return b, b and searchLen or -1
                else
                    return false, -1
                end
            end
        end

        --- Unicode のサロゲートペアを処理する。
        ---@param secondPos number @ハイサロゲートに続く、2番目の位置を指定する。
        ---@param endPos number @終了位置を指定する。
        ---@return boolean, number, number | nil @1番目にマッチしたか、2番目にマッチした場合の終了位置、3番目にマッチした場合のローサロゲート値を返す。
        local ParseSurrogatePart = function (str, secondPos, endPos)
            if secondPos <= endPos then
                local c = string.unicode(str, secondPos, secondPos)
                if c >= 0xDC00 or c <= 0xDFFF then
                    -- ローサロゲートペアにマッチした
                    return true, 1, c
                end
            end
            return false, -1, nil
        end

        --- TextMesh Pro の `sprite` タグを処理する。`<sprite=index>` 形式のみサポートする。
        ---@param secondPos number @`<` に続く、2番目の位置を指定する。
        ---@param endPos number @終了位置を指定する。
        ---@param tmpSpriteMaxIndex number @スプライトの最大インデックスを指定する。
        ---@return boolean, number, number | nil @1番目にマッチしたか、2番目にマッチした場合の終了位置、3番目にマッチした場合のスプライトインデックス値を返す。
        local ParseTmpSpritePart = function (str, secondPos, endPos, tmpSpriteMaxIndex)
            if secondPos <= endPos then
                local bNodeName, mlNodeName = cytanb.StringStartsWith(str, tmpSpriteNodeNamePattern, secondPos)
                if bNodeName then
                    local indexPos = secondPos + mlNodeName
                    if indexPos <= endPos then
                        local bIndex, mlIndex = cytanb.StringStartsWith(str, tmpSpriteIndexPattern, indexPos)
                        if bIndex then
                            local gtPos = indexPos + mlIndex
                            if gtPos <= endPos and string.unicode(str, gtPos, gtPos) == 0x3E then
                                local spriteIndex = tonumber(string.sub(str, indexPos, indexPos + mlIndex - 1))
                                if spriteIndex <= tmpSpriteMaxIndex then
                                    return true, gtPos - secondPos + 1, spriteIndex
                                end
                            end
                        end
                    end
                end
            end
            return false, -1, nil
        end

        local UUIDCompare = function (op1, op2)
            for i = 1, 4 do
                local diff = op1[i] - op2[i]
                if diff ~= 0 then
                    return diff
                end
            end
            return 0
        end

        local UUIDMetatable
        UUIDMetatable = {
            __eq = function (op1, op2)
                return op1[1] == op2[1] and op1[2] == op2[2] and op1[3] == op2[3] and op1[4] == op2[4]
            end,

            __lt = function (op1, op2)
                return UUIDCompare(op1, op2) < 0
            end,

            __le = function (op1, op2)
                return UUIDCompare(op1, op2) <= 0
            end,

            __tostring = function (value)
                local second = value[2] or 0
                local third = value[3] or 0
                return string.format(
                    '%08x-%04x-%04x-%04x-%04x%08x',
                    bit32.band(value[1] or 0, 0xFFFFFFFF),
                    bit32.band(bit32.rshift(second, 16), 0xFFFF),
                    bit32.band(second, 0xFFFF),
                    bit32.band(bit32.rshift(third, 16), 0xFFFF),
                    bit32.band(third, 0xFFFF),
                    bit32.band(value[4] or 0, 0xFFFFFFFF)
                )
            end,

            __concat = function (op1, op2)
                local meta1 = getmetatable(op1)
                local c1 = meta1 == UUIDMetatable or (type(meta1) == 'table' and meta1.__concat == UUIDMetatable.__concat)
                local meta2 = getmetatable(op2)
                local c2 = meta2 == UUIDMetatable or (type(meta2) == 'table' and meta2.__concat == UUIDMetatable.__concat)
                if not c1 and not c2 then
                    error('UUID: attempt to concatenate illegal values', 2)
                end
                return (c1 and UUIDMetatable.__tostring(op1) or op1) .. (c2 and UUIDMetatable.__tostring(op2) or op2)
            end
        }

        local ConstVariablesFieldName = '__CYTANB_CONST_VARIABLES'

        local ConstIndexHandler = function (table, key)
            local meta = getmetatable(table)
            if meta then
                local mc = rawget(meta, ConstVariablesFieldName)
                if mc then
                    local h = rawget(mc, key)
                    if type(h) == 'function' then
                        return (h(table, key))
                    else
                        return h
                    end
                end
            end
            return nil
        end

        local ConstNewIndexHandler = function (table, key, v)
            local meta = getmetatable(table)
            if meta then
                local mc = rawget(meta, ConstVariablesFieldName)
                if mc then
                    if rawget(mc, key) ~= nil then
                        error('Cannot assign to read only field "' .. key .. '"', 2)
                    end
                end
            end
            rawset(table, key, v)
        end

        local TestValueFromTable = function (tbl, typeName)
            if not tbl then
                return false, false
            end

            local nillableType = tbl[cytanb.TypeParameterName]
            if cytanb.NillableHasValue(nillableType) and cytanb.NillableValue(nillableType) ~= typeName then
                -- 型が一致していない
                return false, false
            end

            return cytanb.NillableIfHasValueOrElse(
                valueConversionMap[typeName],
                function (conv)
                    local fieldNames = conv.compositionFieldNames
                    local remain = conv.compositionFieldLength
                    local unknownFieldContains = false

                    for k, v in pairs(tbl) do
                        if fieldNames[k] then
                            remain = remain - 1
                            if remain <= 0 and unknownFieldContains then
                                break
                            end
                        elseif k ~= cytanb.TypeParameterName then
                            unknownFieldContains = true
                            if remain <= 0 then
                                break
                            end
                        end
                    end

                    return remain <= 0, unknownFieldContains
                end,
                function ()
                    return false, false
                end
            )
        end

        local EscapeForSerialization = function (str)
            -- エスケープタグの文字列を処理したあと、フォワードスラッシュをエスケープする。
            -- [forward slash bug](https://github.com/moonsharp-devs/moonsharp/issues/180)
            return cytanb.StringReplace(
                cytanb.StringReplace(str, cytanb.EscapeSequenceTag, cytanb.EscapeSequenceTag .. cytanb.EscapeSequenceTag),
                '/', cytanb.SolidusTag
            )
        end

        local UnescapeForDeserialization = function (str, replacer)
            local len = string.len(str)
            local tagLen = string.len(cytanb.EscapeSequenceTag)
            if tagLen > len then
                return str
            end

            local buf = ''
            local i = 1
            while i < len do
                local ei, ee = string.find(str, cytanb.EscapeSequenceTag, i, true)
                if not ei then
                    if i == 1 then
                        -- 初回の検索で見つからなければ、処理する必要がないので、str をそのまま返す
                        buf = str
                    else
                        -- 残りの文字列をアペンドする
                        buf = buf .. string.sub(str, i)
                    end
                    break
                end

                if ei > i then
                    buf = buf .. string.sub(str, i, ei - 1)
                end

                local replaced = false
                for entryIndex, entry in ipairs(escapeSequenceReplacementList) do
                    local b = cytanb.StringStartsWith(str, entry.search, ei)
                    if b then
                        buf = buf .. (replacer and replacer(entry.tag) or entry.replacement)
                        i = ei + string.len(entry.search)
                        replaced = true
                        break
                    end
                end

                if not replaced then
                    -- エスケープタグが開始されたが、未知の形式であるため、そのままアペンドする
                    buf = buf .. cytanb.EscapeSequenceTag
                    i = ee + 1
                end
            end
            return buf
        end

        local InternalTableToSerializable
        InternalTableToSerializable = function (data, refTable)
            if type(data) ~= 'table' then
                return data
            end

            if not refTable then
                refTable = {}
            end

            if refTable[data] then
                error('circular reference')
            end

            refTable[data] = true
            local serData = {}
            for k, v in pairs(data) do
                local keyType = type(k)
                local nk
                if keyType == 'string' then
                    -- 文字列であれば、エスケープ処理をする
                    nk = EscapeForSerialization(k)
                elseif keyType == 'number' then
                    -- 数値インデックスであれば、タグを付加する
                    nk = tostring(k) .. cytanb.ArrayNumberTag
                else
                    nk = k
                end

                local valueType = type(v)
                if valueType == 'string' then
                    -- 文字列であれば、エスケープ処理をする
                    serData[nk] = EscapeForSerialization(v)
                elseif valueType == 'number' and v < 0 then
                    -- 負の数値であれば、タグを付加する
                    serData[tostring(nk) .. cytanb.NegativeNumberTag] = tostring(v)
                else
                    serData[nk] = InternalTableToSerializable(v, refTable)
                end
            end

            refTable[data] = nil
            return serData
        end

        local InternalTableFromSerializable
        InternalTableFromSerializable = function (serData, noValueConversion)
            if type(serData) ~= 'table' then
                return serData
            end

            local data = {}
            for k, v in pairs(serData) do
                local nk
                local valueIsNegativeNumber = false
                if type(k) == 'string' then
                    local keyIsArrayNumber = false
                    nk = UnescapeForDeserialization(k, function (tag)
                        if tag == cytanb.NegativeNumberTag then
                            valueIsNegativeNumber = true
                        elseif tag == cytanb.ArrayNumberTag then
                            keyIsArrayNumber = true
                        end
                        return nil
                    end)

                    if keyIsArrayNumber then
                        -- 数値インデックスの文字列のキーを数値へ戻す
                        nk = tonumber(nk) or nk
                    end
                else
                    nk = k
                    valueIsNegativeNumber = false
                end

                if valueIsNegativeNumber and type(v) == 'string' then
                    data[nk] = tonumber(v)
                elseif type(v) == 'string' then
                    data[nk] = UnescapeForDeserialization(v, function (tag)
                        return parameterValueReplacementMap[tag]
                    end)
                else
                    data[nk] = InternalTableFromSerializable(v, noValueConversion)
                end
            end

            if not noValueConversion then
                cytanb.NillableIfHasValue(data[cytanb.TypeParameterName], function (typeValue)
                    -- 値の変換を試みる
                    cytanb.NillableIfHasValue(valueConversionMap[typeValue], function (conv)
                        local nillableValue, unknownFieldContains = conv.fromTableFunc(data)
                        -- 値の変換に成功し、成分フィールド以外が含まれていない場合は、変換した値を返す
                        if not unknownFieldContains then
                            cytanb.NillableIfHasValue(nillableValue, function (value)
                                data = value
                            end)
                        end
                    end)
                end)
            end

            return data
        end

        local typeConversionMap = {
            ['nil'] = function (val) return nil end,
            ['number'] = function (val) return tonumber(val) end,
            ['string'] = function (val) return tostring(val) end,
            ['boolean'] = function (val) if val then return true else return false end end
        }

        local ToType = function (val, targetType)
            local valType = type(val)
            if valType == targetType then
                return val
            else
                local f = typeConversionMap[targetType]
                if f then
                    return f(val)
                else
                    return nil
                end
            end
        end

        -- 送信者情報置換処理
        local TreatMessegeSender = function (sender, senderOverride)
            if senderOverride and type(senderOverride) == 'table' then
                local newSender = {}
                for key, val in pairs(sender) do
                    local overrideVal = senderOverride[key]
                    local newVal
                    if overrideVal == nil then
                        newVal = val
                    else
                        local tVal = ToType(overrideVal, type(val))
                        if tVal == nil then
                            newVal = val
                        else
                            -- 変換できた場合だけオーバーライドする
                            newVal = tVal
                        end
                    end
                    newSender[key] = newVal
                end

                -- 送信者情報置換処理を行った場合は、オリジナルの送信者情報を残しておく
                newSender[cytanb.MessageOriginalSender] = sender
                return newSender
            else
                -- senderOverride が指定されていない場合は、そのまま返す
                return sender
            end
        end

        local MakeMessageData = function (parameterMap)
            local serData = cytanb.NillableIfHasValueOrElse(
                parameterMap,
                function (data)
                    if type(data) ~= 'table' then
                        error('MakeMessageData: Invalid argument: table expected', 4)
                    end
                    return cytanb.TableToSerializable(data)
                end,
                function ()
                    return {}
                end
            )
            local id = cytanb.InstanceID()
            if id == '' then
                cytanb.LogWarn('MakeMessageData: InstanceID is empty.')
            end
            serData[cytanb.InstanceIDParameterName] = id
            return json.serialize(serData)
        end

        local EmitDedicatedMessage = function (name, message, senderOverride, defaultSenderType)
            local defaultSender = {type = defaultSenderType, name = '', commentSource = ''}
            local parameterMap = {
                [cytanb.MessageValueParameterName] = tostring(message),
                [cytanb.MessageSenderOverride] = type(senderOverride) == 'table' and cytanb.Extend(defaultSender, senderOverride, true) or defaultSender
            }
            cytanb.EmitMessage(name, parameterMap)
        end

        local OnDedicatedMessage = function (name, officialName, callback)
            local r1, r2 = (function ()
                local f = function (sender, messageName, parameterMap)
                    local message = tostring(parameterMap[cytanb.MessageValueParameterName] or '')
                    callback(sender, officialName, message)
                end
                local r1 = cytanb.OnMessage(name, f)
                local r2 = cytanb.OnMessage(officialName, f)
                return r1, r2
            end)()
            return {
                Off = function ()
                    r1.Off()
                    r2.Off()
                end
            }
        end

        cytanb = {
            InstanceID = function ()
                return vci.assets.GetInstanceId() or ''
            end,

            --- **EXPERIMENTAL:実験的な機能。`vci.studio.GetLocalAvatar()` で得られるアバターの ID を取得する。ID を得られない場合は、空文字列を返す。
            ---@return string
            OwnID = function ()
                if ownID == '' then
                    local ava_ = vci.studio.GetLocalAvatar()
                    if ava_ then
                        ownID = ava_.GetId() or ''
                    end
                end
                return ownID
            end,

            --@deprecated 廃止予定。クライアント ID を取得する。
            ClientID = function ()
                return cytanb.OwnID()
            end,

            NillableHasValue = function (nillable)
                return nillable ~= nil
            end,

            NillableValue = function (nillable)
                if nillable == nil then
                    error('nillable: value is nil', 2)
                end
                return nillable
            end,

            NillableValueOrDefault = function (nillable, defaultValue)
                if nillable == nil then
                    if defaultValue == nil then
                        error('nillable: defaultValue is nil', 2)
                    end
                    return defaultValue
                else
                    return nillable
                end
            end,

            NillableIfHasValue = function (nillable, callback)
                if nillable == nil then
                    return nil
                else
                    return callback(nillable)
                end
            end,

            NillableIfHasValueOrElse = function (nillable, callback, emptyCallback)
                if nillable == nil then
                    return emptyCallback()
                else
                    return callback(nillable)
                end
            end,

            ---@class cytanb_search_pattern_t 検索パターン。

            --- **EXPERIMENTAL:実験的な機能。検索パターンを作成する。
            ---@param searchList string[] @検索する文字列のリスト。
            ---@param optRepeatMin number @繰り返し回数の最小値。ゼロ以上の値を指定する。省略した場合の値は `1`。
            ---@param optRepeatMax number@繰り返し回数の最大値。optRepeatMin 以上の値を指定する。負の値を指定した場合は、無限大として扱われる。省略した場合の値は `optRepeatMin`。
            ---@return cytanb_search_pattern_t
            MakeSearchPattern = function (searchList, optRepeatMin, optRepeatMax)
                local repeatMin = optRepeatMin and math.floor(optRepeatMin) or 1
                if repeatMin < 0 then
                    error('SearchPattern: Invalid parameter: optRepeatMin < 0')
                end

                local repeatMax = optRepeatMax and math.floor(optRepeatMax) or repeatMin
                -- optRepeatMax に負の値を指定した場合は、無限とする。

                if repeatMax >=0 and repeatMax < repeatMin then
                    error('SearchPattern: Invalid parameter: repeatMax < repeatMin')
                end

                local hasEmptySearch = repeatMax == 0
                local searchMap = {}
                local lengthMap = {}
                local lengthList = {}
                local listSize = 0
                for _key, searchStr in pairs(searchList) do
                    local searchLen = string.len(searchStr)
                    if searchLen == 0 then
                        hasEmptySearch = true
                    else
                        searchMap[searchStr] = searchLen
                        if not lengthMap[searchLen] then
                            lengthMap[searchLen] = true
                            listSize = listSize + 1
                            lengthList[listSize] = searchLen
                        end
                    end
                end
                table.sort(lengthList, function (a, b) return a > b end)
                return {
                    hasEmptySearch = hasEmptySearch,
                    searchMap = searchMap,
                    lengthList = lengthList,
                    repeatMin = repeatMin,
                    repeatMax = repeatMax
                }
            end,

            StringStartsWith = function (str, search, optPosition)
                local pi = optPosition and math.max(1, math.floor(optPosition)) or 1
                if type(search) == 'table' then
                    -- **EXPERIMENTAL:実験的な機能として、`search` には、 `MakeSearchPattern` で作成した検索パターンを指定することもできる。
                    return SearchPatternExec(str, search, pi, SearchStartsWithPred)
                else
                    return StringSearchEdge(str, search, pi, pi == 1, SearchStartsWithPred, string.startsWith)
                end
            end,

            StringEndsWith = function (str, search, optLength)
                if str == nil then
                    return false, -1
                end
                local strLen = string.len(str)
                local pi = optLength and math.min(strLen, math.floor(optLength)) or strLen
                if type(search) == 'table' then
                    -- **EXPERIMENTAL:実験的な機能として、`search` には、 `MakeSearchPattern` で作成した検索パターンを指定することもできる。
                    return SearchPatternExec(str, search, pi, SearchEndsWithPred)
                else
                    return StringSearchEdge(str, search, pi, pi == strLen, SearchEndsWithPred, string.endsWith)
                end
            end,

            StringTrimStart = function (str, optSearchPattern)
                if str == nil or str == '' then
                    return str
                end

                local b, ml = cytanb.StringStartsWith(str, optSearchPattern or defaultWhiteSpaceSearchPattern)
                if b and ml >= 1 then
                    return string.sub(str, ml + 1)
                else
                    return str
                end
            end,

            StringTrimEnd = function (str, optSearchPattern)
                if str == nil or str == '' then
                    return str
                end

                local b, ml = cytanb.StringEndsWith(str, optSearchPattern or defaultWhiteSpaceSearchPattern)
                if b and ml >= 1 then
                    return string.sub(str, 1, string.len(str) - ml)
                else
                    return str
                end
            end,

            StringTrim = function (str, optSearchPattern)
                return cytanb.StringTrimEnd(cytanb.StringTrimStart(str, optSearchPattern), optSearchPattern)
            end,

            StringReplace = function (str, target, replacement)
                -- 正規表現のパターンマッチングは、Unicode で問題が出るので使わずに実装する。(https://github.com/moonsharp-devs/moonsharp/pull/184)
                local ret
                local len = string.len(str)
                if target == '' then
                    ret = replacement
                    for i = 1, len do
                        ret = ret .. string.sub(str, i, i) .. replacement
                    end
                else
                    ret = ''
                    local i = 1
                    while true do
                        local si, ei = string.find(str, target, i, true)
                        if si then
                            ret = ret .. string.sub(str, i, si - 1) .. replacement
                            i = ei + 1
                            if i > len then
                                break
                            end
                        else
                            ret = i == 1 and str or ret .. string.sub(str, i)
                            break
                        end
                    end
                end
                return ret
            end,

            --- **EXPERIMENTAL:実験的な機能。文字列をコードポイントごとに処理する。**
            ---@param str string @対象の文字列を指定する。
            ---@param callback fun(codeString: string, index: number, cbArg: any, beginPos: number, endPos: number): boolean | nil @コードポイントごとに呼び出されるコールバック関数(省略可能)。`codeString` には、コードポイントの文字列が渡される。`index` には、コードポイントのインデックスが渡される。`cbArg` には、関数呼び出し時に指定された値が渡される。`beginPos` には、コードポイントの開始位置が渡される。`endPos` には、コードポイントの終了位置が渡される。コールバック関数が `false` を返した場合は、処理を終了する。
            ---@param cbArg any @コールバック関数に渡される引数を指定する(省略可能)。
            ---@param i number @開始位置を指定する。省略した場合の値は `1`。
            ---@param j number @終了位置を指定する。省略した場合の値は文字列長。
            ---@param optTmpSpriteEnabled boolean @TextMesh Pro の `sprite` タグを、コードポイントとして処理するかを指定する。`<sprite=index>` 形式のみサポートする。省略した場合の値は `false`。
            ---@param optTmpSpriteFilter fun(spriteIndex: number): boolean @TextMesh Pro の `sprite` タグを、フィルターするための関数を指定する(省略可能)。フィルターが `true` を返した場合は、 `sprite` タグがコードポイントとして処理される。
            ---@param optTmpSpriteMaxIndex number @TextMesh Pro の `sprite` の最大インデックスを指定する。省略した場合の値は、現在のところ `3182`。アップデートにより変更される可能性がある。
            ---@return number, number, number @戻り値の1番目に処理したコードポイントの数を、2番目に開始位置を、3番目に終了位置を返す。
            StringEachCode = function (str, callback, cbArg, i, j, optTmpSpriteEnabled, optTmpSpriteFilter, optTmpSpriteMaxIndex)
                local len = string.len(str)
                if len == 0 then
                    return 0, 0, 0
                end

                local beginPos = i and math.floor(i) or 1
                local endPos = j and math.floor(j) or len
                local tmpSpriteMaxIndex = math.min(optTmpSpriteMaxIndex or 3182, 0x1FFFFF)

                if beginPos <= 0 or endPos > len or beginPos > endPos then
                    error('StringEachCode: invalid range')
                end

                local count = 0
                local pos = beginPos
                local definitePos = pos
                while pos <= endPos do
                    local si = pos
                    local c = string.unicode(str, pos, pos)
                    if c >= 0xD800 and c <= 0xDBFF then
                        -- サロゲートペアを処理する。
                        local b, ml = ParseSurrogatePart(str, pos + 1, endPos)
                        if b then
                            pos = pos + ml
                        end
                    elseif optTmpSpriteEnabled and c == 0x3C then
                        -- `sprite` タグを処理する。
                        local b, ml, spriteIndex = ParseTmpSpritePart(str, pos + 1, endPos, tmpSpriteMaxIndex)
                        if b and (not optTmpSpriteFilter or optTmpSpriteFilter(spriteIndex)) then
                            pos = pos + ml
                        end
                    end

                    count = count + 1
                    definitePos = pos

                    if callback and callback(string.sub(str, si, pos), count, cbArg, si, pos) == false then
                        break
                    end

                    pos = pos + 1
                end

                return count, beginPos, definitePos
            end,

            --- deprecated VCAS 2.0.8a で `rawget` `rawset` が削除されたため廃止。`target` に、定数フィールドを設定し、target 自身を返す。`name` に、定数名を指定する。`value` に、定数値を指定する。`value` に、関数を指定した場合は getter として呼び出される。
            ---@param target table
            ---@param name string
            ---@param value any
            ---@return table
            SetConst = function (target, name, value)
                if type(target) ~= 'table' then
                    error('Cannot set const to non-table target', 2)
                end

                local curMeta = getmetatable(target)
                local meta = curMeta or {}
                local metaConstVariables = rawget(meta, ConstVariablesFieldName)
                if rawget(target, name) ~= nil then
                    error('Non-const field "' .. name .. '" already exists', 2)
                end

                if not metaConstVariables then
                    metaConstVariables = {}
                    rawset(meta, ConstVariablesFieldName, metaConstVariables)
                    meta.__index = ConstIndexHandler
                    meta.__newindex = ConstNewIndexHandler
                end

                rawset(metaConstVariables, name, value)

                if not curMeta then
                    setmetatable(target, meta)
                end

                return target
            end,

            --- deprecated VCAS 2.0.8a で `rawget` `rawset` が削除されたため廃止。`entries` のそれぞれの要素について `SetConst` を行い、target 自身を返す。
            ---@param target table
            ---@param entries table<string, any>
            ---@return table
            SetConstEach = function (target, entries)
                for k, v in pairs(entries) do
                    cytanb.SetConst(target, k, v)
                end
                return target
            end,

            Extend = function (target, source, deep, omitMetaTable, refTable)
                if target == source or type(target) ~= 'table' or type(source) ~= 'table' then
                    return target
                end

                if deep then
                    if not refTable then
                        refTable = {}
                    end

                    if refTable[source] then
                        error('circular reference')
                    end

                    refTable[source] = true
                end

                for k, v in pairs(source) do
                    if deep and type(v) == 'table' then
                        local targetChild = target[k]
                        target[k] = cytanb.Extend(type(targetChild) == 'table' and targetChild or {}, v, deep, omitMetaTable, refTable)
                    else
                        target[k] = v
                    end
                end

                if not omitMetaTable then
                    local sourceMetatable = getmetatable(source)
                    if type(sourceMetatable) == 'table' then
                        if deep then
                            local targetMetatable = getmetatable(target)
                            setmetatable(target, cytanb.Extend(type(targetMetatable) == 'table' and targetMetatable or {}, sourceMetatable, true))
                        else
                            setmetatable(target, sourceMetatable)
                        end
                    end
                end

                if deep then
                    refTable[source] = nil
                end

                return target
            end,

            Vars = function (v, padding, indent, refTable)
                local feed
                if padding then
                    feed = padding ~= '__NOLF'
                else
                    padding = '  '
                    feed = true
                end

                if not indent then
                    indent = ''
                end

                if not refTable then
                    refTable = {}
                end

                local t = type(v)
                if t == 'table' then
                    refTable[v] = refTable[v] and refTable[v] + 1 or 1

                    local childIndent = feed and (indent .. padding) or ''
                    local str = '(' .. tostring(v) .. ') {'

                    local firstEntry = true
                    for key, val in pairs(v) do
                        if firstEntry then
                            firstEntry = false
                        else
                            str = str .. (feed and ',' or ', ')
                        end

                        if feed then
                            str = str .. '\n' .. childIndent
                        end

                        local kt = type(key)
                        local ks = (kt == 'function' or kt == 'thread' or kt == 'userdata' or kt == 'table')
                            and '(' .. kt .. ')'
                            or tostring(key)

                        if type(val) == 'table' and refTable[val] and refTable[val] > 0 then
                            str = str .. ks .. ' = (' .. tostring(val) .. ')'
                        else
                            str = str .. ks .. ' = ' .. cytanb.Vars(val, padding, childIndent, refTable)
                        end
                    end

                    if not firstEntry and feed then
                        str = str .. '\n' .. indent
                    end
                    str = str .. '}'

                    refTable[v] = refTable[v] - 1
                    if (refTable[v] <= 0) then
                        refTable[v] = nil
                    end
                    return str
                elseif t == 'function' or t == 'thread' or t == 'userdata' then
                    return '(' .. t .. ')'
                elseif t == 'string' then
                    return '(' .. t .. ') ' .. string.format('%q', v)
                else
                    return '(' .. t .. ') ' .. tostring(v)
                end
            end,

            PosixTime = (function ()
                -- `os.time(table)` の結果が負の値になるような場合は、`nil` が返されることがあるため、`day = 2` を基準にする。
                -- `os.time(table)` へ渡した日付時刻データが、UTC かローカルタイムの、いずれとして扱われるかは実装依存。
                local baseTime = os.time({year = 1970, month = 1, day = 2, hour = 0, min = 0, sec = 0, isdst = false})
                if not baseTime then
                    error('unexpected')
                end

                local baseUtcDate = os.date('!*t', baseTime)
                local offset = (((baseUtcDate.day - 1) * 24 + baseUtcDate.hour) * 60 + baseUtcDate.min) * 60 + baseUtcDate.sec

                return function (optTime)
                    return os.difftime(optTime or os.time(), baseTime) + offset
                end
            end)(),

            GetLogLevel = function ()
                return logLevel
            end,

            SetLogLevel = function (level)
                logLevel = level
            end,

            IsOutputLogLevelEnabled = function ()
                return outputLogLevelEnabled
            end,

            SetOutputLogLevelEnabled = function (enabled)
                outputLogLevelEnabled = not not enabled
            end,

            Log = function (level, ...)
                if level <= logLevel then
                    local levelString = outputLogLevelEnabled and ((logLevelStringMap[level] or 'LOG LEVEL ' .. tostring(level)) .. ' | ') or ''
                    local args = table.pack(...)
                    if args.n == 1 then
                        local v = args[1]
                        if v ~= nil then
                            local str = type(v) == 'table' and cytanb.Vars(v) or tostring(v)
                            print(outputLogLevelEnabled and levelString .. str or str)
                        else
                            print(levelString)
                        end
                    else
                        local str = levelString
                        for i = 1, args.n do
                            local v = args[i]
                            if v ~= nil then
                                str = str .. (type(v) == 'table' and cytanb.Vars(v) or tostring(v))
                            end
                        end
                        print(str)
                    end
                end
            end,

            LogFatal = function (...) cytanb.Log(cytanb.LogLevelFatal, ...) end,

            LogError = function (...) cytanb.Log(cytanb.LogLevelError, ...) end,

            LogWarn = function (...) cytanb.Log(cytanb.LogLevelWarn, ...) end,

            LogInfo = function (...) cytanb.Log(cytanb.LogLevelInfo, ...) end,

            LogDebug = function (...) cytanb.Log(cytanb.LogLevelDebug, ...) end,

            LogTrace = function (...) cytanb.Log(cytanb.LogLevelTrace, ...) end,

            -- @deprecated
            FatalLog = function (...) cytanb.LogFatal(...) end,

            -- @deprecated
            ErrorLog = function (...) cytanb.LogError(...) end,

            -- @deprecated
            WarnLog = function (...) cytanb.LogWarn(...) end,

            -- @deprecated
            InfoLog = function (...) cytanb.LogInfo(...) end,

            -- @deprecated
            DebugLog = function (...) cytanb.LogDebug(...) end,

            -- @deprecated
            TraceLog = function (...) cytanb.LogTrace(...) end,

            ListToMap = function (list, itemValue)
                local map = {}
                if itemValue == nil then
                    for k, v in pairs(list) do
                        map[v] = v
                    end
                elseif type(itemValue) == 'function' then
                    for k, v in pairs(list) do
                        local ik, iv = itemValue(v)
                        map[ik] = iv
                    end
                else
                    for k, v in pairs(list) do
                        map[v] = itemValue
                    end
                end
                return map
            end,

            Round = function (num, decimalPlaces)
                if decimalPlaces then
                    local m = 10 ^ decimalPlaces
                    return math.floor(num * m + 0.5) / m
                else
                    return math.floor(num + 0.5)
                end
            end,

            Clamp = function (value, min, max)
                return math.max(min, math.min(value, max))
            end,

            Lerp = function (a, b, t)
                if t <= 0.0 then
                    return a
                elseif t >= 1.0 then
                    return b
                else
                    return a + (b - a) * t
                end
            end,

            LerpUnclamped = function (a, b, t)
                if t == 0.0 then
                    return a
                elseif t == 1.0 then
                    return b
                else
                    return a + (b - a) * t
                end
            end,

            PingPong = function (t, length)
                if length == 0 then
                    return 0, 1
                end

                local q = math.floor(t / length)
                local r = t - q * length
                if q < 0 then
                    if (q + 1) % 2 == 0 then
                        return length - r, -1
                    else
                        return r, 1
                    end
                else
                    if q % 2 == 0 then
                        return r, 1
                    else
                        return length - r, -1
                    end
                end
            end,

            VectorApproximatelyEquals = function (lhs, rhs)
                return (lhs - rhs).sqrMagnitude < 1E-10
            end,

            QuaternionApproximatelyEquals = function (lhs, rhs)
                local dot = Quaternion.Dot(lhs, rhs)
                return dot < 1.0 + 1E-06 and dot > 1.0 - 1E-06
            end,

            QuaternionToAngleAxis = function (quat)
                local q = quat.normalized
                local halfTheta = math.acos(q.w)
                local st = math.sin(halfTheta)
                local angle = math.deg(halfTheta * 2.0)
                local vec
                if math.abs(st) <= Quaternion.kEpsilon then
                    vec = Vector3.right
                else
                    local si = 1.0 / st
                    vec = Vector3.__new(q.x * si, q.y * si, q.z * si)
                end
                return angle, vec
            end,

            --- **EXPERIMENTAL:実験的な機能。任意の回転 `quat` に対する `direction` における捻り (twist) を計算する。振り (swing) を求める場合は `quat * Quaternion.Inverse(twist)` で得られる。**
            ---@param quat Quaternion @任意の回転を指定する。
            ---@param direction Vector3 @捻りを得る方向を指定する。
            ---@return Quaternion @`direction` における捻り (twist)。
            QuaternionTwist = function (quat, direction)
                if direction.sqrMagnitude < Vector3.kEpsilonNormalSqrt then
                    return Quaternion.identity
                end

                local rotAxis = Vector3.__new(quat.x, quat.y, quat.z)
                if rotAxis.sqrMagnitude >= Vector3.kEpsilonNormalSqrt then
                    local prj = Vector3.Project(rotAxis, direction)
                    if prj.sqrMagnitude >= Vector3.kEpsilonNormalSqrt then
                        local twist = Quaternion.__new(prj.x, prj.y, prj.z, quat.w)
                        twist.Normalize()
                        return twist
                    else
                        return Quaternion.AngleAxis(0, direction)
                    end
                else
                    local rotAngle = cytanb.QuaternionToAngleAxis(quat)
                    return Quaternion.AngleAxis(rotAngle, direction)
                end
            end,

            -- @deprecated `Quaternion * Vector3` 演算子を使用すること。'vec3' に 'quat' の回転を適用し、新しい Vector3 オブジェクトを返す。
            ApplyQuaternionToVector3 = function (quat, vec3)
                -- (quat * Quaternion.__new(vec3.x, vec3.y, vec3.z, 0)) * Quaternion.Inverse(quat)
                local qpx = quat.w * vec3.x + quat.y * vec3.z - quat.z * vec3.y
                local qpy = quat.w * vec3.y - quat.x * vec3.z + quat.z * vec3.x
                local qpz = quat.w * vec3.z + quat.x * vec3.y - quat.y * vec3.x
                local qpw = - quat.x * vec3.x - quat.y * vec3.y - quat.z * vec3.z

                return Vector3.__new(
                    qpw * - quat.x + qpx * quat.w + qpy * - quat.z - qpz * - quat.y,
                    qpw * - quat.y - qpx * - quat.z + qpy * quat.w + qpz * - quat.x,
                    qpw * - quat.z + qpx * - quat.y - qpy * - quat.x + qpz * quat.w
                )
            end,

            RotateAround = function (targetPosition, targetRotation, centerPosition, rotation)
                return centerPosition + rotation * (targetPosition - centerPosition), rotation * targetRotation
            end,

            Random32 = function ()
                -- MoonSharp では整数値の場合 32bit int 型にキャストされ、2147483646 が渡すことのできる最大値。
                return bit32.band(math.random(-2147483648, 2147483646) + 2147483648, 0xFFFFFFFF)
            end,

            RandomUUID = function ()
                return cytanb.UUIDFromNumbers(
                    cytanb.Random32(),
                    bit32.bor(0x4000, bit32.band(cytanb.Random32(), 0xFFFF0FFF)),
                    bit32.bor(0x80000000, bit32.band(cytanb.Random32(), 0x3FFFFFFF)),
                    cytanb.Random32()
                )
            end,

            -- @deprecated use tostring(uuid)
            UUIDString = function (uuid)
                return UUIDMetatable.__tostring(uuid)
            end,

            UUIDFromNumbers = function (...)
                local first = ...
                local t = type(first)
                local num1, num2, num3, num4
                if t == 'table' then
                    num1 = first[1]
                    num2 = first[2]
                    num3 = first[3]
                    num4 = first[4]
                else
                    num1, num2, num3, num4 = ...
                end

                local uuid = {
                    bit32.band(num1 or 0, 0xFFFFFFFF),
                    bit32.band(num2 or 0, 0xFFFFFFFF),
                    bit32.band(num3 or 0, 0xFFFFFFFF),
                    bit32.band(num4 or 0, 0xFFFFFFFF)
                }
                setmetatable(uuid, UUIDMetatable)
                return uuid
            end,

            UUIDFromString = function (str)
                local len = string.len(str)
                if len == 32 then
                    local uuid = cytanb.UUIDFromNumbers(0, 0, 0, 0)
                    for i = 1, 4 do
                        local si = 1 + (i - 1) * 8
                        if not cytanb.StringStartsWith(str, hexSearchPattern_8, si) then
                            return nil
                        end
                        uuid[i] = tonumber(string.sub(str, si, si + 7), 16)
                    end
                    return uuid
                elseif len == 36 then
                    if not cytanb.StringStartsWith(str, hexSearchPattern_8, 1) then
                        return nil
                    end
                    local num1 = tonumber(string.sub(str, 1, 8), 16)

                    if not cytanb.StringStartsWith(str, '-', 9) or
                            not cytanb.StringStartsWith(str, hexSearchPattern_4, 10) or
                            not cytanb.StringStartsWith(str, '-', 14) or
                            not cytanb.StringStartsWith(str, hexSearchPattern_4, 15) then
                        return nil
                    end
                    local num2 = tonumber(string.sub(str, 10, 13) .. string.sub(str, 15, 18), 16)

                    if not cytanb.StringStartsWith(str, '-', 19) or
                            not cytanb.StringStartsWith(str, hexSearchPattern_4, 20) or
                            not cytanb.StringStartsWith(str, '-', 24) or
                            not cytanb.StringStartsWith(str, hexSearchPattern_4, 25) then
                        return nil
                    end
                    local num3 = tonumber(string.sub(str, 20, 23) .. string.sub(str, 25, 28), 16)

                    if not cytanb.StringStartsWith(str, hexSearchPattern_8, 29) then
                        return nil
                    end
                    local num4 = tonumber(string.sub(str, 29), 16)

                    return cytanb.UUIDFromNumbers(num1, num2, num3, num4)
                else
                    return nil
                end
            end,

            -- @deprecated use UUIDFromString
            ParseUUID = function (str)
                return cytanb.UUIDFromString(str)
            end,

            CreateCircularQueue = function (capacity)
                if type(capacity) ~= 'number' or capacity < 1 then
                    error('CreateCircularQueue: Invalid argument: capacity = ' .. tostring(capacity), 2)
                end

                local self
                local maxSize = math.floor(capacity)
                local buf = {}
                local top = 0
                local bottom = 0
                local size = 0

                self = {
                    Size = function ()
                        return size
                    end,

                    Clear = function ()
                        top = 0
                        bottom = 0
                        size = 0
                    end,

                    IsEmpty = function ()
                        return size == 0
                    end,

                    Offer = function (element)
                        buf[top + 1] = element
                        top = (top + 1) % maxSize
                        if size < maxSize then
                            size = size + 1
                        else
                            -- バッファーがフルになっているので、古い要素を捨てるために bottom を進める。
                            bottom = (bottom + 1) % maxSize
                        end
                        return true
                    end,

                    OfferFirst = function (element)
                        bottom = (maxSize + bottom - 1) % maxSize
                        buf[bottom + 1] = element
                        if size < maxSize then
                            size = size + 1
                        else
                            -- バッファーがフルになっているので、古い要素を捨てるために top を戻す。
                            top = (maxSize + top - 1) % maxSize
                        end
                        return true
                    end,

                    Poll = function ()
                        if size == 0 then
                            return nil
                        else
                            local element = buf[bottom + 1]
                            bottom = (bottom + 1) % maxSize
                            size = size - 1
                            return element
                        end
                    end,

                    PollLast = function ()
                        if size == 0 then
                            return nil
                        else
                            top = (maxSize + top - 1) % maxSize
                            local element = buf[top + 1]
                            size = size - 1
                            return element
                        end
                    end,

                    Peek = function ()
                        if size == 0 then
                            return nil
                        else
                            return buf[bottom + 1]
                        end
                    end,

                    PeekLast = function ()
                        if size == 0 then
                            return nil
                        else
                            return buf[(maxSize + top - 1) % maxSize + 1]
                        end
                    end,

                    Get = function (index)
                        if index < 1 or index > size then
                            cytanb.LogError('CreateCircularQueue.Get: index is outside the range: ' .. index)
                            return nil
                        end
                        return buf[(bottom + (index - 1)) % maxSize + 1]
                    end,

                    IsFull = function ()
                        return size >= maxSize
                    end,

                    MaxSize = function ()
                        return maxSize
                    end
                }
                return self
            end,

            DetectClicks = function (lastClickCount, lastTime, clickTiming)
                local count = lastClickCount or 0
                local timing = clickTiming or TimeSpan.FromMilliseconds(500)
                local now = vci.me.Time
                local result = (lastTime and now > lastTime + timing) and 1 or count + 1
                return result, now
            end,

            ColorRGBToHSV = function (color)
                local _, h, s, v = Color.RGBToHSV(color)
                return h, s, v
            end,

            ColorFromARGB32 = function (argb32)
                local n = (type(argb32) == 'number') and argb32 or 0xFF000000
                return Color.__new(
                    bit32.band(bit32.rshift(n, 16), 0xFF) / 0xFF,
                    bit32.band(bit32.rshift(n, 8), 0xFF) / 0xFF,
                    bit32.band(n, 0xFF) / 0xFF,
                    bit32.band(bit32.rshift(n, 24), 0xFF) / 0xFF
                )
            end,

            ColorToARGB32 = function (color)
                return bit32.bor(
                    bit32.lshift(bit32.band(cytanb.Round(0xFF * color.a), 0xFF), 24),
                    bit32.lshift(bit32.band(cytanb.Round(0xFF * color.r), 0xFF), 16),
                    bit32.lshift(bit32.band(cytanb.Round(0xFF * color.g), 0xFF), 8),
                    bit32.band(cytanb.Round(0xFF * color.b), 0xFF)
                )
            end,

            ColorFromIndex = function (colorIndex, hueSamples, saturationSamples, brightnessSamples, omitScale)
                local hueN = math.max(math.floor(hueSamples or cytanb.ColorHueSamples), 1)
                local toneN = omitScale and hueN or (hueN - 1)
                local saturationN = math.max(math.floor(saturationSamples or cytanb.ColorSaturationSamples), 1)
                local valueN = math.max(math.floor(brightnessSamples or cytanb.ColorBrightnessSamples), 1)
                local index = cytanb.Clamp(math.floor(colorIndex or 0), 0, hueN * saturationN * valueN - 1)

                local x = index % hueN
                local y = math.floor(index / hueN)
                local si = y % saturationN
                local vi = math.floor(y / saturationN)

                if omitScale or x ~= toneN then
                    local h = x / toneN
                    local s = (saturationN - si) / saturationN
                    local v = (valueN - vi) / valueN
                    return Color.HSVToRGB(h, s, v)
                else
                    local v = (valueN - vi) / valueN * si / (saturationN - 1)
                    return Color.HSVToRGB(0.0, 0.0, v)
                end
            end,

            --- **EXPERIMENTAL:実験的な機能。`Color` オブジェクトから近似するカラーインデックスを計算する。**
            ColorToIndex = function (color, hueSamples, saturationSamples, brightnessSamples, omitScale)
                local hueN = math.max(math.floor(hueSamples or cytanb.ColorHueSamples), 1)
                local toneN = omitScale and hueN or (hueN - 1)
                local saturationN = math.max(math.floor(saturationSamples or cytanb.ColorSaturationSamples), 1)
                local valueN = math.max(math.floor(brightnessSamples or cytanb.ColorBrightnessSamples), 1)

                local h, s, v = cytanb.ColorRGBToHSV(color)
                local si = cytanb.Round(saturationN * (1.0 - s))
                if omitScale or si < saturationN then
                    local hi = cytanb.Round(toneN * h)
                    if hi >= toneN then
                        hi = 0
                    end

                    if si >= saturationN then
                        si = saturationN - 1
                    end

                    local vi = math.min(valueN - 1, cytanb.Round(valueN * (1.0 - v)))
                    return hi + hueN * (si + saturationN * vi)
                else
                    local msi = cytanb.Round((saturationN - 1) * v)
                    if msi == 0 then
                        local mvi = cytanb.Round(valueN * (1.0 - v))
                        if mvi >= valueN then
                            return hueN - 1
                        else
                            return hueN * (1 + cytanb.Round(v * (saturationN - 1) / (valueN - mvi) * valueN) + saturationN * mvi) - 1
                        end
                    else
                        return hueN * (1 + msi + saturationN * cytanb.Round(valueN * (1.0 - v * (saturationN - 1) / msi))) - 1
                    end
                end
            end,

            ColorToTable = function (color)
                return color and {[cytanb.TypeParameterName] = cytanb.ColorTypeName, r = color.r, g = color.g, b = color.b, a = color.a} or nil
            end,

            ColorFromTable = function (tbl)
                local b, unknownFieldContains = TestValueFromTable(tbl, cytanb.ColorTypeName)
                return (b and Color.__new(tbl.r, tbl.g, tbl.b, tbl.a) or nil), unknownFieldContains
            end,

            Vector2ToTable = function (value)
                return value and {[cytanb.TypeParameterName] = cytanb.Vector2TypeName, x = value.x, y = value.y} or nil
            end,

            Vector2FromTable = function (tbl)
                local b, unknownFieldContains = TestValueFromTable(tbl, cytanb.Vector2TypeName)
                return (b and Vector2.__new(tbl.x, tbl.y) or nil), unknownFieldContains
            end,

            Vector3ToTable = function (value)
                return value and {[cytanb.TypeParameterName] = cytanb.Vector3TypeName, x = value.x, y = value.y, z = value.z} or nil
            end,

            Vector3FromTable = function (tbl)
                local b, unknownFieldContains = TestValueFromTable(tbl, cytanb.Vector3TypeName)
                return (b and Vector3.__new(tbl.x, tbl.y, tbl.z) or nil), unknownFieldContains
            end,

            Vector4ToTable = function (value)
                return value and {[cytanb.TypeParameterName] = cytanb.Vector4TypeName, x = value.x, y = value.y, z = value.z, w = value.w} or nil
            end,

            Vector4FromTable = function (tbl)
                local b, unknownFieldContains = TestValueFromTable(tbl, cytanb.Vector4TypeName)
                return (b and Vector4.__new(tbl.x, tbl.y, tbl.z, tbl.w) or nil), unknownFieldContains
            end,

            QuaternionToTable = function (value)
                return value and {[cytanb.TypeParameterName] = cytanb.QuaternionTypeName, x = value.x, y = value.y, z = value.z, w = value.w} or nil
            end,

            QuaternionFromTable = function (tbl)
                local b, unknownFieldContains = TestValueFromTable(tbl, cytanb.QuaternionTypeName)
                return (b and Quaternion.__new(tbl.x, tbl.y, tbl.z, tbl.w) or nil), unknownFieldContains
            end,

            TableToSerializable = function (data)
                return InternalTableToSerializable(data)
            end,

            TableFromSerializable = function (serData, noValueConversion)
                return InternalTableFromSerializable(serData, noValueConversion)
            end,

            -- @deprecated use TableToSerializable
            TableToSerialiable = function (data)
                return InternalTableToSerializable(data)
            end,

            -- @deprecated use TableFromSerializable
            TableFromSerialiable = function (serData, noValueConversion)
                return InternalTableFromSerializable(serData, noValueConversion)
            end,

            EmitMessage = function (name, parameterMap)
                vci.message.Emit(name, MakeMessageData(parameterMap))
            end,

            --- **EXPERIMENTAL:実験的な機能。`targetID` で指定された ID で `vci.message.EmitWithId` を呼び出す。その他の事項については `EmitMessage` を参照。
            EmitMessageTo = function (name, parameterMap, targetID)
                if targetID ~= nil and targetID ~= '' then
                    vci.message.EmitWithId(name, MakeMessageData(parameterMap), targetID)
                else
                    cytanb.LogWarn('EmitMessageTo: targetID is not specified: ' .. tostring(targetID))
                end
            end,

            --- **EXPERIMENTAL:実験的な機能。`cytanb.EmitMessageTo(name, parameterMap, cytanb.InstanceID())` と等価。
            EmitInstanceMessage = function (name, parameterMap)
                cytanb.EmitMessageTo(name, parameterMap, cytanb.InstanceID())
            end,

            OnMessage = function (name, callback)
                local f = function (sender, messageName, message)
                    if type(message) == 'string' and string.startsWith(message, '{') then
                        -- JSON デコードを試みる
                        local pcallStatus, serData = pcall(json.parse, message)
                        if pcallStatus and type(serData) == 'table' and serData[cytanb.InstanceIDParameterName] then
                            local decodedData = cytanb.TableFromSerializable(serData)
                            callback(TreatMessegeSender(sender, decodedData[cytanb.MessageSenderOverride]), messageName, decodedData)
                            return
                        end
                    end

                    -- `cytanb.EmitMessage` を通して送信されたデータでなければ、パラメーターフィールド `__CYTANB_MESSAGE_VALUE` に値をセットする。
                    callback(sender, messageName, {[cytanb.MessageValueParameterName] = message})
                end

                vci.message.On(name, f)

                return {
                    Off = function ()
                        if f then
                            -- Off が実装されたら、ここで処理をする。
                            -- vci.message.Off(name, f)
                            f = nil
                        end
                    end
                }
            end,

            OnInstanceMessage = function (name, callback)
                local f = function (sender, messageName, parameterMap)
                    local id = cytanb.InstanceID()
                    if id ~= '' and id == parameterMap[cytanb.InstanceIDParameterName] then
                        callback(sender, messageName, parameterMap)
                    end
                end
                return cytanb.OnMessage(name, f)
            end,

            EmitCommentMessage = function (message, senderOverride)
                EmitDedicatedMessage(cytanb.DedicatedCommentMessageName, message, senderOverride, 'comment')
            end,

            OnCommentMessage = function (callback)
                return OnDedicatedMessage(cytanb.DedicatedCommentMessageName, 'comment', callback)
            end,

            EmitNotificationMessage = function (message, senderOverride)
                EmitDedicatedMessage(cytanb.DedicatedNotificationMessageName, message, senderOverride, 'notification')
            end,

            OnNotificationMessage = function (callback)
                return OnDedicatedMessage(cytanb.DedicatedNotificationMessageName, 'notification', callback)
            end,

            GetEffekseerEmitterMap = function (name)
                local efkList = vci.assets.GetEffekseerEmitters(name)
                if not efkList then
                    return nil
                end

                local map = {}
                for i, efk in pairs(efkList) do
                    map[efk.EffectName] = efk
                end
                return map
            end,

            --- **EXPERIMENTAL:実験的な機能。** `ExportTransform.GetAudioSources` で取得したリストを、`ClipName` をキーとするマップにして返す。
            ---@param item ExportTransform @`AudioSource` コンポーネントが設定されている、オブジェクトを指定する。
            ---@return table<string, ExportAudioSource> @戻り値の1番目にタグのマップを、2番目にベース名を返す。
            GetAudioSourceMap = function (item)
                local map = {}
                for _, audio in pairs(item.GetAudioSources() or {}) do
                    map[audio.ClipName or ''] = audio
                end
                return map
            end,

            --- **EXPERIMENTAL:実験的な機能。** タグ文字列をパースする。文字列全体の書式は、ベース名に 0 個以上のタグが続く。`basename#tag1#tag2...#tagN` タグの書式は、ハッシュ記号 `#` にタグ名、省略可能な値の指定が続く。`#name[=value]` 値を省略した場合は、タグ名が値となる。タグ名と値に使用可能な文字は、`A-Z a-z 0-9 _ - .` および、予約文字として `( ) ! ~ * ' %` となっている。(例: `foo#bar#baz=123`)
            ---@return table<string, string>, string @戻り値の1番目にタグのマップを、2番目にベース名を返す。
            ParseTagString = function (str)
                local pos = string.find(str, '#', 1, true)
                if not pos then
                    -- タグが存在しなかった
                    return {}, str
                end

                local tagMap = {}
                local baseName = string.sub(str, 1, pos - 1)
                pos = pos + 1
                local len = string.len(str)

                while pos <= len do
                    local b1, t1 = cytanb.StringStartsWith(str, tagComponentSearchPattern, pos)
                    if b1 then
                        local n1 = pos + t1
                        local tagKey = string.sub(str, pos, n1 - 1)
                        -- タグの値が指定されない場合は、キー値とする
                        local tagValue = tagKey
                        pos = n1
                        if pos <= len and cytanb.StringStartsWith(str, '=', pos) then
                            pos = pos + 1
                            local b2, t2 = cytanb.StringStartsWith(str, tagComponentSearchPattern, pos)
                            if b2 then
                                -- タグの値が指定された
                                local n2 = pos + t2
                                tagValue = string.sub(str, pos, n2 - 1)
                                pos = n2
                            else
                                -- 空のタグの値が指定された
                                tagValue = ''
                            end
                        end
                        tagMap[tagKey] = tagValue
                    end

                    -- 次のタグを検索する
                    pos = string.find(str, '#', pos, true)
                    if not pos then
                        break
                    end
                    pos = pos + 1
                end

                return tagMap, baseName
            end,

            --- **EXPERIMENTAL:実験的な機能。** 与えられた数値の SI 接頭辞を計算する。
            ---@param num number @数値を指定する。
            ---@return number, string, number @戻り値の1番目に計算した SI 接頭辞での数値を、2番目に SI 接頭辞を、3番目に 10 の累乗数を返す。
            CalculateSIPrefix = (function ()
                local baseIndex = 9
                local unitList = {'y', 'z', 'a', 'f', 'p', 'n', 'u', 'm', '', 'k', 'M', 'G', 'T', 'P', 'E', 'Z', 'Y'}
                local unitLength = #unitList

                return function (num)
                    local exp = num == 0 and 0 or cytanb.Clamp(math.floor(math.log(math.abs(num), 1000)), 1 - baseIndex, unitLength - baseIndex)
                    return (exp == 0 and num or num / (1000 ^ exp)), unitList[baseIndex + exp], exp * 3
                end
            end)(),

            --- DO_NOT_USE
            LspContainer = (function ()
                local nillableLspContainer = nil

                local containerId = '137a14de-3cbe-48fe-8c5f-7226dce4db01'

                local GlobalContainer = function ()
                    local target_ = _ENV['_G']
                    if type(target_) == 'table' then
                        -- test writable
                        target_[containerId] = false
                        local bt = type(target_[containerId]) == 'boolean'
                        target_[containerId] = nil
                        return bt and target_ or nil
                    else
                        return nil
                    end
                end

                local FallbackToPackage = function ()
                    local target_ = require('coroutine')
                    if type(target_) == 'table' then
                        local container_ = target_[containerId]
                        if type(container_) == 'table' then
                            return container_
                        else
                            target_[containerId] = {}
                            return target_[containerId]
                        end
                    else
                        return nil
                    end
                end

                local FallbackToEnv = function ()
                    local target_ = _ENV
                    local container_ = target_[containerId]
                    if type(container_) == 'table' then
                        return container_
                    else
                        target_[containerId] = {}
                        return target_[containerId]
                    end
                end

                local MakeContainer = function ()
                    local globalOk, globalValue = pcall(GlobalContainer)
                    if globalOk and globalValue then
                        return globalValue
                    else
                        local packageOk, packageValue = pcall(FallbackToPackage)
                        if packageOk and packageValue then
                            return packageValue
                        else
                            return FallbackToEnv()
                        end
                    end
                end

                return function ()
                    if not nillableLspContainer then
                        nillableLspContainer = MakeContainer()
                    end
                    return nillableLspContainer
                end
            end)(),

            ---@class cytanb_local_shared_properties_t deprecated VCAS 2.0.8a で `_G` が削除されたため廃止。ローカルの共有プロパティ

            --- deprecated VCAS 2.0.8a で `_G` が削除されたため廃止。ローカルの共有プロパティを作成する。
            ---@param lspid string @プロパティ ID の文字列を指定する。プロパティを識別するための固定 ID。
            ---@param loadid string @ロード ID の文字列を指定する。スクリプトがロードされるごとに生成される一意な ID。
            ---@return cytanb_local_shared_properties_t
            CreateLocalSharedProperties = function (lspid, loadid)
                local maxAliveTime = TimeSpan.FromSeconds(5)
                local aliveLspid = '33657f0e-7c44-4ee7-acd9-92dd8b8d807a'
                local listenerMapKey = '__CYTANB_LOCAL_SHARED_PROPERTIES_LISTENER_MAP'

                if type(lspid) ~= 'string' or string.len(lspid) <= 0 or type(loadid) ~= 'string' or string.len(loadid) <= 0 then
                    error('LocalSharedProperties: Invalid arguments', 2)
                end

                local lspContainer = cytanb.LspContainer()
                local aliveMap = lspContainer[aliveLspid]
                if not aliveMap then
                    aliveMap = {}
                    lspContainer[aliveLspid] = aliveMap
                end
                aliveMap[loadid] = vci.me.UnscaledTime

                local pmap = lspContainer[lspid]
                if not pmap then
                    pmap = {[listenerMapKey] = {}}
                    lspContainer[lspid] = pmap
                end
                local listenerMap = pmap[listenerMapKey]

                local self
                self = {
                    --- プロパティ ID を取得する。
                    ---@return string
                    GetLspID = function ()
                        return lspid
                    end,

                    --- ロード ID を取得する。
                    ---@return string
                    GetLoadID = function ()
                        return loadid
                    end,

                    --- プロパティの値を取得する。
                    ---@param key string @プロパティのキー値を指定する。
                    ---@param defaultValue any @プロパティ値が `nil` であった場合の既定値を指定する。
                    ---@return any @取得したプロパティ値。
                    GetProperty = function (key, defaultValue)
                        local value = pmap[key]
                        if value == nil then
                            return defaultValue
                        else
                            return value
                        end
                    end,

                    --- プロパティの値を設定する。
                    ---@param key string @プロパティのキー値を指定する。
                    ---@param value any @プロパティの値を指定する。
                    SetProperty = function (key, value)
                        if key == listenerMapKey then
                            error('LocalSharedProperties: Invalid argument: key = ', key, 2)
                        end

                        local now = vci.me.UnscaledTime
                        local oldValue = pmap[key]
                        pmap[key] = value

                        for listener, id in pairs(listenerMap) do
                            local t = aliveMap[id]
                            if t and t + maxAliveTime >= now then
                                listener(self, key, value, oldValue)
                            else
                                -- 期限切れしたリスナーを解除する
                                listener(self, cytanb.LOCAL_SHARED_PROPERTY_EXPIRED_KEY, true, false)
                                listenerMap[listener] = nil
                                aliveMap[id] = nil
                            end
                        end
                    end,

                    --- プロパティを消去する。
                    Clear = function ()
                        for key, value in pairs(pmap) do
                            if key ~= listenerMapKey then
                                -- next で巡回中に、既存のフィールドを変更・消去することは可能とマニュアルに明記してある。
                                self.SetProperty(key, nil)
                            end
                        end
                    end,

                    --- `callback(value, key, lsp)` には、各要素に対して実行するコールバック関数を指定する。コールバック関数内から、新しいプロパティを設定する操作は未定義の動作を引き起こす。`
                    Each = function (callback)
                        for key, value in pairs(pmap) do
                            if key ~= listenerMapKey and callback(value, key, self) == false then
                                return false
                            end
                        end
                    end,

                    --- プロパティの変更イベントを受け取るリスナーを追加する。
                    ---@param listener fun(source: cytanb_local_shared_properties_t, key: string, value: any, oldValue: any) @`source` は、イベントの発生元が渡される。`key` は、プロパティのキー値が渡される。`value` は、プロパティの値が渡される。`oldValue` は、以前のプロパティの値が渡される。
                    AddListener = function (listener)
                        listenerMap[listener] = loadid
                    end,

                    --- 登録したリスナーを削除する。
                    ---@param listener fun(source: cytanb_local_shared_properties_t, key: string, value: any, oldValue: any)
                    RemoveListener = function (listener)
                        listenerMap[listener] = nil
                    end,

                    --- `updateAll` 関数で、この関数を呼び出すこと。5 秒以上この関数が呼び出されなかった場合は、期限切れしたことをキー値 `cytanb.LOCAL_SHARED_PROPERTY_EXPIRED_KEY` としてリスナーに通知し、リスナーの登録を解除する。
                    UpdateAlive = function ()
                        aliveMap[loadid] = vci.me.UnscaledTime
                    end
                }

                return self
            end,

            ---@class cytanb_estimate_fixed_timestep_parameters_t `EstimateFixedTimestep` のオプションのパラメーターテーブル。
            ---@field mass number @質量。省略した場合は `1`。
            ---@field acceleration number @加速度。省略した場合は `1000`。
            ---@field startCalcTime TimeSpan @計算を開始する時間。省略した場合は 5 秒。
            ---@field stopCalcTime TimeSpan @計算を終了する時間。省略した場合は 30 秒。
            ---@field minCalcInterval TimeSpan @計算を行う最小インターバール。省略した場合は `TimeSpan.MaxValue`。
            ---@field maxCalcInterval TimeSpan @計算を行う最大インターバール。省略した場合は `TimeSpan.MaxValue`。
            ---@field defaultTimestep number @既定の Timestep。省略した場合は `0.02`。
            ---@field queueSize number @既定のキューのサイズ。省略した場合は `64`。

            --- **EXPERIMENTAL:実験的な機能のため変更される可能性がある。** 物理演算の実行間隔を推定する。`updateAll` 関数から呼び出して使う。`physicalObject` に `AddForce` し、オブジェクトの時間当たりの移動量から計算を行う。`physicalObject` は `Rigidbody` コンポーネントを設定 (`Mass: 1`, `Drag: 0`, `Use Gravity: OFF`, `Is Kinematic: OFF`, `Interpolate: None`, `Freeze Position: OFF`) したオブジェクト。`Collider` や `VCI Sub Item` コンポーネントをセットしてはいけない。
            ---@param options cytanb_estimate_fixed_timestep_parameters_t オプションのパラメーター。省略可能。
            EstimateFixedTimestep = function (physicalObject, options)
                local opt = options or {}

                local mass = opt.mass or 1
                if mass <= 0 then
                    error('EstimateFixedTimestep: Invalid argument: mass <= 0', 2)
                end

                local acceleration = opt.acceleration or 1000
                if acceleration <= 0 then
                    error('EstimateFixedTimestep: Invalid argument: acceleration <= 0', 2)
                end

                local startCalcTime = opt.startCalcTime or TimeSpan.FromSeconds(5)

                local stopCalcTime = opt.stopCalcTime or TimeSpan.FromSeconds(30)
                if startCalcTime < TimeSpan.Zero or startCalcTime > stopCalcTime then
                    error('EstimateFixedTimestep: Invalid argument: startCalcTime < Zero or startCalcTime > stopCalcTime', 2)
                end

                local minCalcInterval = opt.minCalcInterval or TimeSpan.MaxValue

                local maxCalcInterval = opt.maxCalcInterval or TimeSpan.MaxValue
                if minCalcInterval <= TimeSpan.Zero or minCalcInterval > maxCalcInterval then
                    error('EstimateFixedTimestep: Invalid argument: minCalcInterval <= Zero or minCalcInterval > maxCalcInterval', 2)
                end

                local calcInterval = minCalcInterval
                local calcIntervalEnabled = minCalcInterval < TimeSpan.MaxValue

                local timestep = opt.defaultTimestep or TimeSpan.FromSeconds(0.02)
                local interimTimestep = timestep
                if timestep <= TimeSpan.Zero then
                    error('EstimateFixedTimestep: Invalid argument: timestep <= Zero', 2)
                end

                local defaultTimestepPrecision = 0xFFFF
                local timestepPrecision = defaultTimestepPrecision
                local interimTimestepPrecision = defaultTimestepPrecision

                local timestepQueue = cytanb.CreateCircularQueue(opt.queueSize or 64)
                if timestepQueue.MaxSize() <= 1 then
                    error('EstimateFixedTimestep: Invalid argument: queueSize <= 1', 2)
                end

                local startTime = vci.me.Time
                local updateTime = startTime

                local prevTime = startTime

                -- 開始位置の X, Y 座標はランダムに、Z 座標はゼロとする。
                local rnd32 = cytanb.Random32()
                local startPosition = Vector3.__new(
                    bit32.bor(0x100, bit32.band(rnd32, 0x3F)),
                    bit32.bor(0x100, bit32.band(bit32.rshift(rnd32, 8), 0x3F)),
                    0
                )

                local stage = 1

                local nextCalcInterval = function (min, max)
                    local mr = min == minCalcInterval and 120 or 1200
                    local st = min.TotalSeconds
                    return TimeSpan.FromSeconds(
                        math.min(
                            st + math.random() * math.min(mr, max.TotalSeconds - st),
                            TimeSpan.MaxValue.TotalSeconds - 1
                        )
                    )
                end

                local stageFunctions = {
                    function ()
                        timestepQueue.Clear()
                        physicalObject.SetPosition(startPosition)
                        physicalObject.SetRotation(Quaternion.identity)
                        physicalObject.SetVelocity(Vector3.zero)
                        physicalObject.SetAngularVelocity(Vector3.zero)
                        stage = stage + 1
                        return timestep
                    end,

                    function ()
                        -- Z 軸方向に力を加える。
                        physicalObject.AddForce(Vector3.__new(0.0, 0.0, mass * acceleration))
                        startTime = vci.me.Time
                        prevTime = startTime
                        stage = stage + 1
                        return timestep
                    end,

                    function ()
                        local currTime = prevTime
                        prevTime = vci.me.Time
                        local elapsedTime = currTime - startTime
                        local dt = elapsedTime.TotalSeconds
                        if dt <= 1E-10 then
                            return timestep
                        end

                        local dz = physicalObject.GetPosition().z - startPosition.z
                        local ts = dz / dt / acceleration
                        if ts <= 1E-10 then
                            return timestep
                        end

                        timestepQueue.Offer(ts)
                        local queueSize = timestepQueue.Size()
                        if queueSize >= 2 and elapsedTime >= startCalcTime then
                            -- 平均と分散を計算する
                            local sum = 0.0
                            for i = 1, queueSize do
                                sum = sum + timestepQueue.Get(i)
                            end
                            local average = sum / queueSize

                            local vSum = 0.0
                            for i = 1, queueSize do
                                vSum = vSum + (timestepQueue.Get(i) - average) ^ 2
                            end
                            local variance = vSum / queueSize

                            if variance < interimTimestepPrecision then
                                -- 分散が小さければ採用する
                                interimTimestepPrecision = variance
                                interimTimestep = TimeSpan.FromSeconds(average)
                                updateTime = currTime
                            end

                            if elapsedTime > stopCalcTime then
                                -- 計算終了
                                if math.abs((interimTimestep - timestep).TotalSeconds) >= 0.001 or interimTimestepPrecision < timestepPrecision then
                                    -- timestep の変化が大きいか、新しい値のほうが精度が高い場合は更新する
                                    timestep = interimTimestep
                                    timestepPrecision = interimTimestepPrecision
                                end

                                updateTime = currTime
                                if calcInterval < TimeSpan.MaxValue then
                                    calcInterval = nextCalcInterval(calcInterval, maxCalcInterval)
                                end

                                physicalObject.SetPosition(startPosition)
                                physicalObject.SetRotation(Quaternion.identity)
                                physicalObject.SetVelocity(Vector3.zero)
                                physicalObject.SetAngularVelocity(Vector3.zero)
                                stage = stage + 1
                            end
                        else
                            interimTimestep = TimeSpan.FromSeconds(ts)
                            updateTime = currTime
                        end

                        if timestepPrecision >= defaultTimestepPrecision then
                            timestepPrecision = interimTimestepPrecision
                            timestep = interimTimestep
                        end

                        return timestep
                    end,

                    function ()
                        prevTime = vci.me.Time
                        return timestep
                    end,
                }

                local stageSize = #stageFunctions

                local self = {
                    --- 推定した物理演算の実行間隔を返す。
                    Timestep = function ()
                        return timestep
                    end,

                    --- 推定した timestep の精度を返す。
                    Precision = function ()
                        return timestepPrecision
                    end,

                    -- @deprecated 非推奨。計算が完了したかを返す。
                    IsFinished = function ()
                        return stage == stageSize
                    end,

                    --- `updateAll` 関数で、この関数を呼び出すこと。timestep を計算し、その値を返す。
                    Update = function ()
                        if calcIntervalEnabled and stage == stageSize and prevTime - calcInterval >= updateTime then
                            stage = 1
                        end
                        return stageFunctions[stage]()
                    end
                }
                return self
            end,

            --- **EXPERIMENTAL:実験的な機能のため変更される可能性がある。** サブアイテムオブジェクトの位置と回転を、基準となるオブジェクトに合わせる。`velocityReset` に `true` が指定されていた場合は、`SetVelocity` と `SetAngularVelocity` も実行され、ゼロベクトルにリセットされる。
            AlignSubItemOrigin = function (refItem, item, velocityReset)
                local refRot = refItem.GetRotation()
                if not cytanb.QuaternionApproximatelyEquals(item.GetRotation(), refRot) then
                    item.SetRotation(refRot)
                end

                local refPos = refItem.GetPosition()
                if not cytanb.VectorApproximatelyEquals(item.GetPosition(), refPos) then
                    item.SetPosition(refPos)
                end

                if velocityReset then
                    item.SetVelocity(Vector3.zero)
                    item.SetAngularVelocity(Vector3.zero)
                end
            end,

            --- **EXPERIMENTAL:実験的な機能のため変更される可能性がある。** サブアイテムオブジェクトの位置と回転を合わせるための、接着剤を作成する。
            CreateSubItemGlue = function ()
                local itemMap = {}

                local self
                self = {
                    --- `parent` に `child` が含まれているかを調べる。
                    Contains = function (parent, child)
                        return cytanb.NillableIfHasValueOrElse(
                            itemMap[parent],
                            function (entries) return cytanb.NillableHasValue(entries[child]) end,
                            function () return false end
                        )
                    end,

                    --- `parent` と `children` の組み合わせを指定する。`Update` 関数を呼び出すと、`parent` オブジェクトの位置と回転をが `children` に適用される。`velocityReset` に `true` が指定されていた場合は、`SetVelocity` と `SetAngularVelocity` も実行され、ゼロベクトルにリセットされる。
                    Add = function (parent, children, velocityReset)
                        if not parent or not children then
                            local msg = 'SubItemGlue.Add: Invalid arguments ' ..
                                        (not parent and (', parent = ' .. tostring(parent)) or '') ..
                                        (not children and (', children = ' .. tostring(children)) or '')
                            error(msg, 2)
                        end

                        local entries = cytanb.NillableIfHasValueOrElse(
                            itemMap[parent],
                            function (childMap)
                                return childMap
                            end,
                            function ()
                                local childMap = {}
                                itemMap[parent] = childMap
                                return childMap
                            end
                        )

                        if type(children) == 'table' then
                            for key, val in pairs(children) do
                                entries[val] = {velocityReset = not not velocityReset}
                            end
                        else
                            entries[children] = {velocityReset = not not velocityReset}
                        end
                    end,

                    --- `parent` から `child` を削除する。
                    Remove = function (parent, child)
                        return cytanb.NillableIfHasValueOrElse(
                            itemMap[parent],
                            function (entries)
                                if cytanb.NillableHasValue(entries[child]) then
                                    entries[child] = nil
                                    return true
                                else
                                    return false
                                end
                            end,
                            function ()
                                return false
                            end
                        )
                    end,

                    --- `parent` とその子要素を削除する。
                    RemoveParent = function (parent)
                        if cytanb.NillableHasValue(itemMap[parent]) then
                            itemMap[parent] = nil
                            return true
                        else
                            return false
                        end
                    end,

                    --- すべての要素を削除する。
                    RemoveAll = function ()
                        itemMap = {}
                        return true
                    end,

                    --- `callback(child, parent, glue)` には、各要素に対して実行するコールバック関数を指定する。`nillableParent` に親のオブジェクトを指定した場合は、その子要素が対象となる。省略した場合はすべての要素が対象となる。
                    Each = function (callback, nillableParent)
                        return cytanb.NillableIfHasValueOrElse(
                            nillableParent,
                            function (parent)
                                return cytanb.NillableIfHasValue(
                                    itemMap[parent],
                                    function (entries)
                                        for child, options in pairs(entries) do
                                            if callback(child, parent, self) == false then
                                                return false
                                            end
                                        end
                                    end
                                )
                            end,
                            function ()
                                for parent, entries in pairs(itemMap) do
                                    if self.Each(callback, parent) == false then
                                        return false
                                    end
                                end
                            end
                        )
                    end,

                    --- `child.IsMine` が `true` あるいは `force` を指定した場合に、 `parent` の位置と回転を `child` に適用する。`velocityReset` に `true` が指定されていた場合は、`SetVelocity` と `SetAngularVelocity` を行い、ゼロベクトルにリセットする。
                    Update = function (force)
                        for parent, entries in pairs(itemMap) do
                            local parentPos = parent.GetPosition()
                            local parentRot = parent.GetRotation()

                            for child, options in pairs(entries) do
                                if force or child.IsMine then
                                    if not cytanb.QuaternionApproximatelyEquals(child.GetRotation(), parentRot) then
                                        child.SetRotation(parentRot)
                                    end

                                    if not cytanb.VectorApproximatelyEquals(child.GetPosition(), parentPos) then
                                        child.SetPosition(parentPos)
                                    end

                                    if options.velocityReset then
                                        child.SetVelocity(Vector3.zero)
                                        child.SetAngularVelocity(Vector3.zero)
                                    end
                                end
                            end
                        end
                    end
                }
                return self
            end,

            --- **EXPERIMENTAL:実験的な機能のため変更される可能性がある。アップデートルーチンを作成する。`updateAll` 関数で、作成したルーチンを呼び出すこと。
            ---@param updateCallback fun(deltaTime: TimeSpan, unscaledDeltaTime: TimeSpan) @毎フレーム呼び出されるコールバック関数。
            ---@param optFirstTimeCallback fun() @初回のアップデート時に、一度だけ呼び出されるコールバック関数。省略可能。
            ---@param optErrorCallback fun(reason: string) @エラーの発生時に、呼び出されるコールバック関数。省略可能。
            ---@param optMaxWaitTime TimeSpan @同期が完了するまでの、最大の待ち時間。省略した場合の既定値は 60 秒。
            CreateUpdateRoutine = function (updateCallback, optFirstTimeCallback, optErrorCallback, optMaxWaitTime)
                return coroutine.wrap(function ()
                    -- InstanceID と OwnID を取得できるまで待つ。
                    local maxWaitTime = optMaxWaitTime or TimeSpan.FromSeconds(60)
                    local unscaledStartTime = vci.me.UnscaledTime
                    local unscaledLastTime = unscaledStartTime
                    local lastTime = vci.me.Time
                    local needWaiting = true
                    while cytanb.InstanceID() == '' or cytanb.OwnID() == '' do
                        local unscaledNow = vci.me.UnscaledTime
                        if unscaledNow - maxWaitTime > unscaledStartTime then
                            local reason = 'TIMEOUT: Could not get ' ..
                                (cytanb.InstanceID() == '' and 'Instance ID' or 'Own ID')
                            cytanb.LogError(reason)
                            if optErrorCallback then
                                optErrorCallback(reason)
                            end
                            return -1
                        end

                        unscaledLastTime = unscaledNow
                        lastTime = vci.me.Time
                        needWaiting = false
                        coroutine.yield(100)
                    end

                    if needWaiting then
                        -- VCI アイテムを出して 1 フレーム目の update 後に、onUngrab が発生するのを待つ。
                        unscaledLastTime = vci.me.UnscaledTime
                        lastTime = vci.me.Time
                        coroutine.yield(100)
                    end

                    -- ロード完了。
                    if optFirstTimeCallback then
                        optFirstTimeCallback()
                    end

                    while true do
                        local now = vci.me.Time
                        local delta = now - lastTime
                        local unscaledNow = vci.me.UnscaledTime
                        local unscaledDelta = unscaledNow - unscaledLastTime
                        updateCallback(delta, unscaledDelta)
                        lastTime = now
                        unscaledLastTime = unscaledNow
                        coroutine.yield(100)
                    end
                    -- return 0
                end)
            end,

            ---@class cytanb_slide_switch_t スライドスイッチ。

            ---@class cytanb_slide_switch_parameters_t スライドスイッチを作成するためのパラメーターテーブル。ゲームオブジェクトのスケールは、すべて `1` であることを前提としている。
            ---@field colliderItem ExportTransform @スイッチを操作するための `VCI Sub Item` コンポーネントが設定されたコライダーオブジェクト。`baseItem` の原点位置を基準に移動する。通常は透明なオブジェクトとして設定する。
            ---@field baseItem ExportTransform @スイッチの基準位置となるオブジェクト。原点がスイッチの中央位置となる。
            ---@field knobItem ExportTransform @スイッチのノブとなるオブジェクト。`baseItem` の子オブジェクトを指定する。`baseItem` の原点位置を基準に移動する。
            ---@field minValue number @スイッチの最小値。`minValue >= maxValue` である場合はエラーとなる。省略した場合は `0`。
            ---@field maxValue number @スイッチの最大値。省略した場合は `10`。
            ---@field value number @スイッチの値。省略した場合は `0`。
            ---@field tickFrequency number @目盛りの間隔。値の範囲を割り切れる数値を指定する。ゼロ以下である場合はエラーとなる。省略した場合は値の範囲を 10 等分した値。
            ---@field tickVector Vector3 @1 目盛りのベクトル。ゼロに近いベクトルを指定した場合はエラーとなる。省略した場合は `Vector3.__new(0.01, 0.0, 0.0)`
            ---@field snapToTick boolean @目盛りにスナップするかを指定する。省略した場合は `true`。
            ---@field lsp cytanb_local_shared_properties_t @deprecated VCAS 2.0.8a で `_G` が削除されたため廃止。`LocalSharedProperties` を使用する場合は指定する。省略可能。
            ---@field propertyName string @`LocalSharedProperties` を使用する場合は、プロパティ名を指定する。使用しない場合は省略可能。
            ---@field valueTextName string @値をテキスト表示する場合は、`TextMesh Pro` のオブジェクト名を指定する。省略可能。
            ---@field valueToText fun(source: cytanb_slide_switch_t, value: string): string @値をテキスト表示する際に、値を文字列へ変換するための関数を指定することができる。使用しない場合は省略可能。
            ---@field alignPeriod TimeSpan @スイッチのコライダーオブジェクトを整列する間隔。省略した場合は 500 ミリ秒。

            --- **EXPERIMENTAL:実験的な機能のため変更される可能性がある。** スライドスイッチを作成する。トリガーでつまみをつかんで値の変更、および、グリップによる値の変更ができる。ユーザー間での値の同期処理は行わないため、必要であれば別途実装すること。
            ---@param parameters cytanb_slide_switch_parameters_t @スライドスイッチを作成するためのパラメーターテーブルを指定する。
            CreateSlideSwitch = function (parameters)
                local colliderItem = cytanb.NillableValue(parameters.colliderItem)
                local baseItem = cytanb.NillableValue(parameters.baseItem)
                local knobItem = cytanb.NillableValue(parameters.knobItem)

                local minValue = cytanb.NillableValueOrDefault(parameters.minValue, 0)
                local maxValue = cytanb.NillableValueOrDefault(parameters.maxValue, 10)
                if minValue >= maxValue then
                    error('SlideSwitch: Invalid argument: minValue >= maxValue', 2)
                end
                local halfValue = (minValue + maxValue) * 0.5

                local CalcValue = function (val)
                    local pp, pd = cytanb.PingPong(val - minValue, maxValue - minValue)
                    return pp + minValue, pd
                end

                local value = CalcValue(cytanb.NillableValueOrDefault(parameters.value, 0))

                local tickFrequency = cytanb.NillableIfHasValueOrElse(
                    parameters.tickFrequency,
                    function (freqency)
                        if freqency <= 0 then
                            error('SlideSwitch: Invalid argument: tickFrequency <= 0', 3)
                        end
                        return math.min(freqency, maxValue - minValue)
                    end,
                    function ()
                        return (maxValue - minValue) / 10.0
                    end
                )

                local tickVector = cytanb.NillableIfHasValueOrElse(
                    parameters.tickVector,
                    function (vec)
                        return Vector3.__new(vec.x, vec.y, vec.z)
                    end,
                    function ()
                        return Vector3.__new(0.01, 0.0, 0.0)
                    end
                )

                local tickMagnitude = tickVector.magnitude
                if tickMagnitude < Vector3.kEpsilon then
                    error('SlideSwitch: Invalid argument: tickVector is too small', 2)
                end

                local snapToTick = cytanb.NillableValueOrDefault(parameters.snapToTick, true)

                local nillableValueTextName = parameters.valueTextName
                local valueToText = cytanb.NillableValueOrDefault(parameters.valueToText, tostring)

                local gripWaitTime = TimeSpan.FromMilliseconds(1000)
                local gripTickPeriod = TimeSpan.FromMilliseconds(50)
                local alignPeriod = cytanb.NillableValueOrDefault(parameters.alignPeriod, TimeSpan.FromMilliseconds(500))

                local propertyGetter, propertySetter
                local listenerMap = {}

                local self

                local grabbed = false
                local grabbedDeltaTicks = 0
                local gripPressed = false
                local gripStartTime = TimeSpan.Zero
                local gripChangeTime = TimeSpan.Zero
                local prevAlignTime = TimeSpan.Zero

                local UpdateValue = function (newValue, forceNotification)
                    -- 中央値を基準位置の原点として計算する
                    knobItem.SetLocalPosition((newValue - halfValue) / tickFrequency * tickVector)
                    -- cytanb.LogInfo('on update value [', colliderItem.GetName(), ']: value = ', value)

                    if nillableValueTextName then
                        vci.assets.SetText(nillableValueTextName, valueToText(newValue, self))
                    end

                    if forceNotification or newValue ~= value then
                        local oldValue = value
                        value = newValue
                        for listener, v in pairs(listenerMap) do
                            listener(self, value, oldValue)
                        end
                    end
                end

                local NextTickByUse = function ()
                    -- 最小値/最大値で折り返すときには、最小値/最大値を踏むようにする。
                    local curp = propertyGetter()
                    local cpp, cpd = CalcValue(curp)
                    local nextp = curp + tickFrequency
                    local npp, npd = CalcValue(nextp)
                    assert(npp)
                    local newValue
                    if cpd == npd or cpp == maxValue or cpp == minValue then
                        newValue = nextp
                    else
                        newValue = cpd >= 0 and maxValue or minValue
                    end

                    gripChangeTime = vci.me.UnscaledTime
                    if newValue == maxValue or newValue == minValue then
                        -- 最小値/最大値のときには、スタートタイムをセットする
                        gripStartTime = gripChangeTime
                    end

                    propertySetter(newValue)
                end

                cytanb.NillableIfHasValueOrElse(
                    parameters.lsp,
                    function (lsp)
                        if not cytanb.NillableHasValue(parameters.propertyName) then
                            error('SlideSwitch: Invalid argument: propertyName is nil', 3)
                        end

                        local propertyName = cytanb.NillableValue(parameters.propertyName)
                        propertyGetter = function ()
                            return lsp.GetProperty(propertyName, value)
                        end

                        propertySetter = function (val)
                            lsp.SetProperty(propertyName, val)
                        end

                        lsp.AddListener(function (source, key, propValue, oldPropValue)
                            if key == propertyName then
                                -- cytanb.LogInfo('lsp: key = ', key, ', propValue = ', propValue)
                                UpdateValue(CalcValue(propValue), true)
                            end
                        end)
                    end,
                    function ()
                        local propValue = value
                        propertyGetter = function ()
                            return propValue
                        end

                        propertySetter = function (val)
                            propValue = val
                            UpdateValue(CalcValue(val), true)
                        end
                    end
                )

                self = {
                    --- スイッチを操作するためのコライダーオブジェクトを取得する。
                    ---@return ExportTransform
                    GetColliderItem = function ()
                        return colliderItem
                    end,

                    --- スイッチの基準位置となるオブジェクトを取得する。
                    ---@return ExportTransform
                    GetBaseItem = function ()
                        return baseItem
                    end,

                    --- スイッチのノブとなるオブジェクトを取得する。
                    ---@return ExportTransform
                    GetKnobItem = function ()
                        return knobItem
                    end,

                    --- スイッチの最小値を取得する。
                    ---@return number
                    GetMinValue = function ()
                        return minValue
                    end,

                    --- スイッチの最大値を取得する。
                    ---@return number
                    GetMaxValue = function ()
                        return maxValue
                    end,

                    --- スイッチの値を取得する。
                    ---@return number
                    GetValue = function ()
                        return value
                    end,

                    --- スイッチのスケール値を取得する。
                    ---@param minScale number @最小のスケール値を指定する。
                    ---@param maxScale number @最大のスケール値を指定する。
                    ---@return number
                    GetScaleValue = function (minScale, maxScale)
                        assert(minScale <= maxScale)
                        return minScale + (maxScale - minScale) * (value - minValue) / (maxValue - minValue)
                    end,

                    --- スイッチの値を設定する。
                    ---@param val number @設定する数値を指定する。
                    SetValue = function (val)
                        propertySetter(CalcValue(val))
                    end,

                    --- 目盛りの間隔を取得する。
                    ---@return number
                    GetTickFrequency = function ()
                        return tickFrequency
                    end,

                    --- 目盛りにスナップするかを調べる。
                    ---@return boolean
                    IsSnapToTick = function ()
                        return snapToTick
                    end,

                    --- スイッチの変更イベントを受け取るリスナーを追加する。
                    ---@param listener fun(source: cytanb_slide_switch_t, value: number, oldValue: number) @`source` は、イベントの発生元のスイッチが渡される。`value` は、スイッチの値が渡される。`oldValue` は、以前のスイッチの値が渡される。
                    AddListener = function (listener)
                        listenerMap[listener] = listener
                    end,

                    --- 登録したリスナーを削除する。
                    ---@param listener fun(source: cytanb_slide_switch_t, value: number, oldValue: number)
                    RemoveListener = function (listener)
                        listenerMap[listener] = nil
                    end,

                    --- `onUse` 関数で、スイッチがユーズされたときに、この関数を呼び出すこと。
                    DoUse = function ()
                        if not grabbed then
                            gripPressed = true
                            gripStartTime = vci.me.UnscaledTime
                            NextTickByUse()
                        end
                    end,

                    --- `onUnuse` 関数で、スイッチがアンユーズされたときに、この関数を呼び出すこと。
                    DoUnuse = function ()
                        gripPressed = false
                    end,

                    --- `onGrab` 関数で、スイッチがグラブされたときに、この関数を呼び出すこと。
                    DoGrab = function ()
                        if not gripPressed then
                            grabbed = true
                            -- 中央値を基準位置の原点として計算する
                            grabbedDeltaTicks = (value - halfValue) / tickFrequency
                        end
                    end,

                    --- `onUngrab` 関数で、スイッチがアングラブされたときに、この関数を呼び出すこと。
                    DoUngrab = function ()
                        grabbed = false
                    end,

                    --- `updateAll` 関数で、この関数を呼び出すこと。
                    Update = function ()
                        if grabbed then
                            if colliderItem.IsMine then
                                local dp = colliderItem.GetPosition() - baseItem.GetPosition()
                                local tv = knobItem.GetRotation() * tickVector
                                local pv = Vector3.Project(dp, tv)
                                local mv = (Vector3.Dot(tv, pv) >= 0 and 1 or -1) * (pv.magnitude / tickMagnitude) + grabbedDeltaTicks
                                -- 中央値を基準位置の原点として計算する
                                local mhv = mv + halfValue / tickFrequency
                                local fv = (snapToTick and cytanb.Round(mhv) or mhv) * tickFrequency
                                local newValue = cytanb.Clamp(fv, minValue, maxValue)
                                -- cytanb.LogTrace('SlideSwitch: ', colliderItem.GetName() , ': newValue = ', newValue, ', mv = ', mv, ', fv = ', fv)
                                if newValue ~= value then
                                    propertySetter(newValue)
                                end
                            else
                                grabbed = false
                            end
                        elseif gripPressed then
                            if colliderItem.IsMine then
                                -- 長押し状態であれば、値を進める。
                                local unow = vci.me.UnscaledTime
                                if unow >= gripStartTime + gripWaitTime and unow >= gripChangeTime + gripTickPeriod then
                                    NextTickByUse()
                                end
                            else
                                gripPressed = false
                            end
                        elseif colliderItem.IsMine then
                            local unow = vci.me.UnscaledTime
                            if unow - alignPeriod >= prevAlignTime then
                                prevAlignTime = unow
                                cytanb.AlignSubItemOrigin(baseItem, colliderItem)
                            end
                        end
                    end
                }

                UpdateValue(CalcValue(propertyGetter()), false)
                return self
            end,

            -- @deprecated 非推奨。 サブアイテム間の位置と回転を相互に作用させるためのコネクターを作成する。スケールは非対応。サブアイテムのグループIDは、ゼロ以外の同じ値を設定しておく必要がある。
            CreateSubItemConnector = function ()
                local SetItemStatus = function (status, item, propagation)
                    status.item = item

                    status.position = item.GetPosition()
                    status.rotation = item.GetRotation()

                    status.initialPosition = status.position
                    status.initialRotation = status.rotation

                    status.propagation = not not propagation

                    return status
                end

                local UpdateItemStatusMap = function (statusMap)
                    for item, status in pairs(statusMap) do
                        SetItemStatus(status, item, status.propagation)
                    end
                end

                local ApplyTransform = function (position, rotation, status, targetStatusMap, targetFilter)
                    local dp = position - status.initialPosition
                    local dr = rotation * Quaternion.Inverse(status.initialRotation)

                    status.position = position
                    status.rotation = rotation

                    for item, targetStatus in pairs(targetStatusMap) do
                        -- フィルターが指定されていないか、フィルターが指定されていて true を返した場合は、適用処理をする
                        if item ~= status.item and (not targetFilter or targetFilter(targetStatus)) then
                            targetStatus.position, targetStatus.rotation = cytanb.RotateAround(targetStatus.initialPosition + dp, targetStatus.initialRotation, position, dr)

                            item.SetPosition(targetStatus.position)
                            item.SetRotation(targetStatus.rotation)
                        end
                    end
                end

                local itemStatusMap = {}
                local updateEnabled = true
                local dirty = false

                local self
                self = {
                    IsEnabled = function ()
                        return updateEnabled
                    end,

                    SetEnabled = function (enabled)
                        updateEnabled = enabled
                        if enabled then
                            UpdateItemStatusMap(itemStatusMap)
                            dirty = false
                        end
                    end,

                    Contains = function (subItem)
                        return cytanb.NillableHasValue(itemStatusMap[subItem])
                    end,

                    Add = function (subItems, noPropagation)
                        if not subItems then
                            error('SubItemConnector.Add: Invalid argument: subItems = ' .. tostring(subItems), 2)
                        end

                        local itemList = type(subItems) == 'table' and subItems or {subItems}

                        UpdateItemStatusMap(itemStatusMap)
                        dirty = false

                        for k, item in pairs(itemList) do
                            itemStatusMap[item] = SetItemStatus({}, item, not noPropagation)
                        end
                    end,

                    Remove = function (subItem)
                        local b = cytanb.NillableHasValue(itemStatusMap[subItem])
                        itemStatusMap[subItem] = nil
                        return b
                    end,

                    RemoveAll = function ()
                        itemStatusMap = {}
                        return true
                    end,

                    --- `callback(item, connector)` には、各要素に対して実行するコールバック関数を指定する。
                    Each = function (callback)
                        for item, status in pairs(itemStatusMap) do
                            if callback(item, self) == false then
                                return false
                            end
                        end
                    end,

                    -- @deprecated
                    GetItems = function ()
                        local itemList = {}
                        for item, status in pairs(itemStatusMap) do
                            table.insert(itemList, item)
                        end
                        return itemList
                    end,

                    Update = function ()
                        if not updateEnabled then
                            return
                        end

                        local transformed = false
                        for item, status in pairs(itemStatusMap) do
                            local pos = item.GetPosition()
                            local rot = item.GetRotation()
                            if not cytanb.VectorApproximatelyEquals(pos, status.position) or not cytanb.QuaternionApproximatelyEquals(rot, status.rotation) then
                                if status.propagation then
                                    if item.IsMine then
                                        ApplyTransform(pos, rot, itemStatusMap[item], itemStatusMap, function (targetStatus)
                                            if targetStatus.item.IsMine then
                                                return true
                                            else
                                                -- 操作権がないアイテムがある場合は、ダーティーフラグをセットする
                                                dirty = true
                                                return false
                                            end
                                        end)

                                        -- 複数のアイテムが変更されていても、1度に変更を適用するのは1つだけ
                                        transformed = true
                                        break
                                    else
                                        -- 操作権がないものは非サポート。SubItem が同期されるときに補間される関係で、まともに動かないため。
                                        dirty = true
                                    end
                                else
                                    -- 変更を伝搬しない場合は、ダーティーフラグをセットする
                                    dirty = true
                                end
                            end
                        end

                        if not transformed and dirty then
                            -- 全アイテムのステータスをセットし直す
                            UpdateItemStatusMap(itemStatusMap)
                            dirty = false
                        end
                    end
                }
                return self
            end,

            -- @deprecated
            UnixTime = function (optTime)
                return cytanb.PosixTime(optTime)
            end,

            -- @deprecated この関数のかわりに、`Vector3ToTable/QuaternionToTable` を使用すること。
            GetSubItemTransform = function (subItem)
                local position = subItem.GetPosition()
                local rotation = subItem.GetRotation()
                local scale = subItem.GetLocalScale()
                return {
                    positionX = position.x,
                    positionY = position.y,
                    positionZ = position.z,
                    rotationX = rotation.x,
                    rotationY = rotation.y,
                    rotationZ = rotation.z,
                    rotationW = rotation.w,
                    scaleX = scale.x,
                    scaleY = scale.y,
                    scaleZ = scale.z
                }
            end
        }

        cytanb.Extend(cytanb, {
            LogLevelOff = 0,
            LogLevelFatal = 100,
            LogLevelError = 200,
            LogLevelWarn = 300,
            LogLevelInfo = 400,
            LogLevelDebug = 500,
            LogLevelTrace = 600,
            LogLevelAll = 0x7FFFFFFF,
            ColorHueSamples = 10,
            ColorSaturationSamples = 4,
            ColorBrightnessSamples = 5,
            EscapeSequenceTag = '#__CYTANB',
            SolidusTag = '#__CYTANB_SOLIDUS',
            NegativeNumberTag = '#__CYTANB_NEGATIVE_NUMBER',
            ArrayNumberTag = '#__CYTANB_ARRAY_NUMBER',
            InstanceIDParameterName = '__CYTANB_INSTANCE_ID',
            MessageValueParameterName = '__CYTANB_MESSAGE_VALUE',
            MessageSenderOverride = '__CYTANB_MESSAGE_SENDER_OVERRIDE',
            MessageOriginalSender = '__CYTANB_MESSAGE_ORIGINAL_SENDER',
            TypeParameterName = '__CYTANB_TYPE',
            ColorTypeName = 'Color',
            Vector2TypeName = 'Vector2',
            Vector3TypeName = 'Vector3',
            Vector4TypeName = 'Vector4',
            QuaternionTypeName = 'Quaternion',
            DedicatedCommentMessageName = 'cytanb.comment.a2a6a035-6b8d-4e06-b4f9-07e6209b0639',
            DedicatedNotificationMessageName = 'cytanb.notification.698ba55f-2b69-47f2-a68d-bc303994cff3',
            InstanceIDStatePatchingMessageName = 'cytanb.instance_id_state_patching.08504824-2041-42a2-9b2a-97448b4418b0',
            LOCAL_SHARED_PROPERTY_EXPIRED_KEY = '__CYTANB_LOCAL_SHARED_PROPERTY_EXPIRED'
        }, false, true)

        cytanb.Extend(cytanb, {
            ColorMapSize = cytanb.ColorHueSamples * cytanb.ColorSaturationSamples * cytanb.ColorBrightnessSamples,
            FatalLogLevel = cytanb.LogLevelFatal,    -- @deprecated
            ErrorLogLevel = cytanb.LogLevelError,    -- @deprecated
            WarnLogLevel = cytanb.LogLevelWarn,      -- @deprecated
            InfoLogLevel = cytanb.LogLevelInfo,      -- @deprecated
            DebugLogLevel = cytanb.LogLevelDebug,    -- @deprecated
            TraceLogLevel = cytanb.LogLevelTrace     -- @deprecated
        }, false, true)

        defaultWhiteSpaceSearchPattern = cytanb.MakeSearchPattern({
            '\t', '\n', '\v', '\f', '\r', ' '
        }, 1, -1)

        tmpSpriteNodeNamePattern = cytanb.MakeSearchPattern({
            'sprite=', 'SPRITE='
        })

        tmpSpriteIndexPattern = cytanb.MakeSearchPattern({
            '0', '1', '2', '3', '4', '5', '6', '7', '8', '9'
        }, 1, 9)

        hexSearchPattern_4, hexSearchPattern_8 = (function ()
            local hexCharactes = {
                'A', 'B', 'C', 'D', 'E', 'F',
                'a', 'b', 'c', 'd', 'e', 'f',
                '0', '1', '2', '3', '4', '5', '6', '7', '8', '9'
            }
            return cytanb.MakeSearchPattern(hexCharactes, 4, 4), cytanb.MakeSearchPattern(hexCharactes, 8, 8)
        end)()

        tagComponentSearchPattern = cytanb.MakeSearchPattern({
            'A', 'B', 'C', 'D', 'E', 'F', 'G', 'H', 'I', 'J', 'K', 'L', 'M', 'N', 'O', 'P', 'Q', 'R', 'S', 'T', 'U', 'V', 'W', 'X', 'Y', 'Z',
            'a', 'b', 'c', 'd', 'e', 'f', 'g', 'h', 'i', 'j', 'k', 'l', 'm', 'n', 'o', 'p', 'q', 'r', 's', 't', 'u', 'v', 'w', 'x', 'y', 'z',
            '0', '1', '2', '3', '4', '5', '6', '7', '8', '9',
            '_', '-', '.', '(', ')', '!', '~', '*', '\'', '%'
        }, 1, -1)

        -- タグ文字列の長い順にパターンマッチする必要がある。
        escapeSequenceReplacementList = {
            {tag = cytanb.NegativeNumberTag, search = cytanb.NegativeNumberTag, replacement = ''},
            {tag = cytanb.ArrayNumberTag, search = cytanb.ArrayNumberTag, replacement = ''},
            {tag = cytanb.SolidusTag, search = cytanb.SolidusTag, replacement = '/'},
            {tag = cytanb.EscapeSequenceTag, search = cytanb.EscapeSequenceTag .. cytanb.EscapeSequenceTag, replacement = cytanb.EscapeSequenceTag}
        }

        valueConversionMap = {
            [cytanb.ColorTypeName] = {compositionFieldNames = cytanb.ListToMap({'r', 'g', 'b', 'a'}), compositionFieldLength = 4, toTableFunc = cytanb.ColorToTable, fromTableFunc = cytanb.ColorFromTable},
            [cytanb.Vector2TypeName] = {compositionFieldNames = cytanb.ListToMap({'x', 'y'}), compositionFieldLength = 2, toTableFunc = cytanb.Vector2ToTable, fromTableFunc = cytanb.Vector2FromTable},
            [cytanb.Vector3TypeName] = {compositionFieldNames = cytanb.ListToMap({'x', 'y', 'z'}), compositionFieldLength = 3, toTableFunc = cytanb.Vector3ToTable, fromTableFunc = cytanb.Vector3FromTable},
            [cytanb.Vector4TypeName] = {compositionFieldNames = cytanb.ListToMap({'x', 'y', 'z', 'w'}), compositionFieldLength = 4, toTableFunc = cytanb.Vector4ToTable, fromTableFunc = cytanb.Vector4FromTable},
            [cytanb.QuaternionTypeName] = {compositionFieldNames = cytanb.ListToMap({'x', 'y', 'z', 'w'}), compositionFieldLength = 4, toTableFunc = cytanb.QuaternionToTable, fromTableFunc = cytanb.QuaternionFromTable}
        }

        parameterValueReplacementMap = cytanb.ListToMap({cytanb.NegativeNumberTag, cytanb.ArrayNumberTag})

        logLevel = cytanb.LogLevelInfo
        logLevelStringMap = {
            [cytanb.LogLevelFatal] = 'FATAL',
            [cytanb.LogLevelError] = 'ERROR',
            [cytanb.LogLevelWarn] = 'WARN',
            [cytanb.LogLevelInfo] = 'INFO',
            [cytanb.LogLevelDebug] = 'DEBUG',
            [cytanb.LogLevelTrace] = 'TRACE'
        }

        return cytanb
    end

    if __CYTANB_EXPORT_MODULE then
        return setmetatable({}, {
            __call = function (self, main_env)
                return makeImpl(main_env)
            end
        })
    else
        return makeImpl(_ENV)
    end
end)()

if __CYTANB_EXPORT_MODULE then
    return cytanb
end
