----------------------------------------------------------------
--  Copyright (c) 2019 oO (https://github.com/oocytanb)
--  MIT Licensed
----------------------------------------------------------------

-- `cytanb.lua` モジュールのアノテーション用ファイル。

---@alias cytanb_uuid_t number[]

---@class cytanb UUID、ログ、色、メッセージなど、基礎的な機能を提供するモジュール。
---@field FatalLogLevel number @致命的なレベルのログを表す定数値。
---@field ErrorLogLevel number @エラーレベルのログを表す定数値。
---@field WarnLogLevel number @警告レベルのログを表す定数値。
---@field InfoLogLevel number @情報レベルのログを表す定数値。
---@field DebugLogLevel number @デバッグレベルのログを表す定数値。
---@field TraceLogLevel number @トレースレベルのログを表す定数値。
---@field ColorHueSamples number @デフォルトの色相のサンプル数。
---@field ColorSaturationSamples number @デフォルトの彩度のサンプル数。
---@field ColorBrightnessSamples number @デフォルトの明度のサンプル数。
---@field ColorMapSize number @デフォルトのカラーマップのサイズ。
---@field NegativeNumberTag string @負の数値を示すタグ。
---@field ArrayNumberTag string @連想配列でなく、keyが数値であることを示すタグ。
---@field InstanceIDParameterName string @インスタンス ID のパラーメーター名。
---@field MessageValueParameterName string @メッセージ値のパラーメーター名。
---@field InstanceID fun (): string @インスタンス ID を取得する。VCI を設置したユーザー以外では、同期完了前は空文字列を返す。
---@field SetConst fun (target: table, name: string, value: any): table @`target` に定数フィールドを設定し、target 自身を返す。`name` に定数名を指定する。`value` に定数値を指定する。
---@field Extend fun (target: table, source: table, deep: boolean, omitMetaTable: boolean): table @`target` のテーブルフィールドを `source` のテーブルフィールドで拡張し、その結果を返す。`deep` に `true` を指定した場合は、ディープコピーを行う(省略するか `false` を指定した場合は、シャローコピーを行う)。`omitMetaTable` に 'true' を指定した場合は、メタテーブルをコピーしない。ただし、シャローコピーした場合は下位のテーブルの参照値がそのままコピーされる。(省略するか `false` を指定した場合は、コピーする)。
---@field Vars fun (v: any, padding: string): string @変数の情報を文字列で返す。`padding` は省略可能。`padding` に '__NOLF' を指定した場合は、インデントおよび改行を行わない。
---@field GetLogLevel fun (): number @現在のログレベルを取得する。
---@field SetLogLevel fun (level: number) @ログレベルを設定する。
---@field Log fun (level: number, ...) @`level <= cytanb.GetLogLevel()` のときにログを出力する。
---@field FatalLog fun (...) @致命的なレベルのログを出力する。
---@field ErrorLog fun (...) @エラーレベルのログを出力する。
---@field WarnLog fun (...) @警告レベルのログを出力する。
---@field InfoLog fun (...) @情報レベルのログを出力する。
---@field DebugLog fun (...) @デバッグレベルのログを出力する。
---@field TraceLog fun (...) @トレースレベルのログを出力する。
---@field ListToMap fun (list: any[], itemValue: any): table @リストをテーブルに変換する。リストの要素の値がキー値となる。`itemValue` に要素の値を指定する。`itemValue` に `nil` を指定するか省略した場合は、リストの要素の値が使われる。
---@field Random32 fun (): number @32 bit 整数値の範囲の疑似乱数を生成する。
---@field RandomUUID fun (): cytanb_uuid_t @乱数に基づく UUID version 4 を生成し、32 bit の数値データ4個分の配列を返す。
---@field UUIDString fun (uuid: cytanb_uuid_t): string @RandomUUID 関数で生成した UUID を文字列へ変換する。
---@field ParseUUID fun (string: str): cytanb_uuid_t @UUID 文字列をパースし、32 bit の数値データ4個分の配列を返す。パースに失敗した場合は nil を返す。
---@field ColorFromARGB32 fun (argb32: number): Color @ARGB 32 bit 値から、Color オブジェクトへ変換する。
---@field ColorToARGB32 fun (color: Color): number @Color オブジェクトから ARGB 32 bit 値へ変換する。
---@field ColorFromIndex fun (colorIndex: number, hueSamples: number, saturationSamples: number, brightnessSamples: number, omitScale: boolean): Color @カラーインデックスから対応する Color オブジェクトへ変換する。`hueSamples` は色相のサンプル数を指定し、省略した場合の値は　`ColorHueSamples`。`saturationSamples` は彩度のサンプル数を指定し、省略した場合の値は `ColorSaturationSamples`。`brightnessSamples` は明度のサンプル数を指定し、省略した場合の値は `ColorBrightnessSamples`。`omitScale` はグレースケールを省略するかを指定し、省略した場合の値は `false`。
---@field GetSubItemTransform fun (subItem: ExportTransform): table<string, number> @SubItem の Transform を取得する。
---@field TableToSerializable fun (data: table): table @[json.parse が負の数値を扱えない問題](https://github.com/xanathar/moonsharp/issues/163) と数値インデックスの多次元配列のワークアラウンドを行う。数値インデックスの配列である場合は、キー名に '#__CYTANB_ARRAY_NUMBER' タグを付加する。負の数値である場合は、キー名に '#__CYTANB_NEGATIVE_NUMBER' タグを付加し、負の数値を文字列に変換する。
---@field TableFromSerializable fun (serData: table): table @TableToSerializable で変換したテーブルを復元する。
---@field EmitMessage fun (name: string, parameterMap: table<string, any>) @パラメーターを JSON シリアライズして `vci.message.Emit` する。`name` はメッセージ名を指定する。`parameterMap` は送信するパラメーターのテーブルを指定する(省略可能)。また、`InstanceID` がパラメーターフィールド `__CYTANB_INSTANCE_ID` として付加されて送信される。
---@field OnMessage fun (name: string, callback: fun(sender: table, name: string, parameterMap: table)) @`EmitMessage` したメッセージを受信するコールバック関数を登録する。`name` はメッセージ名を指定する。`callback` 関数に渡される `parameterMap` は JSON データをデシリアライズしたテーブル。また、パラメーターフィールド `__CYTANB_INSTANCE_ID` を利用してメッセージ送信元のインスタンスを識別可能。もしデシリアライズできないデータであった場合は、パラメーターフィールド `__CYTANB_MESSAGE_VALUE` に値がセットされる。
