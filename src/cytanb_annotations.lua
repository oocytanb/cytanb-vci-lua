-- SPDX-License-Identifier: MIT
-- Copyright (c) 2019 oO (https://github.com/oocytanb)

-- `cytanb.lua` モジュールのアノテーション用ファイル。

---@class cytanb_uuid_t UUID オブジェクト。`tostring` および比較演算子を使用できる。

---@class cytanb_circular_queue_t 固定容量の循環キュー。キューが満杯になった場合は、挿入方向の逆にある要素が置き換えられる。`cytanb.CreateCircularQueue` で作成する。
---@field Size fun (): number @キューの要素数を取得する。
---@field Clear fun () @キューからすべての要素を削除する。
---@field IsEmpty fun (): boolean @キューが空かを調べる。
---@field Offer fun (element: any): boolean @キューの末尾に要素を挿入し、成功したかどうかを返す。
---@field OfferFirst fun (element: any): boolean @キューの先頭に要素を挿入し、成功したかどうかを返す。
---@field Poll fun (): any @キューの先頭の要素を取り除き、それを取得する。キューが空の場合は `nil` を返す。
---@field PollLast fun (): any @キューの末尾の要素を取り除き、それを取得する。キューが空の場合は `nil` を返す。
---@field Peek fun (): any @キューの先頭の要素を取得する。キューの内容は変更されない。キューが空の場合は `nil` を返す。
---@field PeekLast fun (): any @キューの末尾の要素を取得する。キューの内容は変更されない。キューが空の場合は `nil` を返す。
---@field Get fun (index: number): any @キューの `index` の位置にある要素を取得する。`index` が `1` から `Size` の範囲外の場合は `nil` を返す。
---@field IsFull fun (): boolean @キューが満杯かを調べる。
---@field MaxSize fun (): number @キューの最大容量を取得する。

---@class cytanb UUID、ログ、数学関数、色、メッセージなど、基礎的な機能を提供するモジュール。
---@field LogLevelOff number @ログ出力を行わないことを表す定数値。
---@field LogLevelFatal number @致命的なレベルのログを表す定数値。
---@field LogLevelError number @エラーレベルのログを表す定数値。
---@field LogLevelWarn number @警告レベルのログを表す定数値。
---@field LogLevelInfo number @情報レベルのログを表す定数値。
---@field LogLevelDebug number @デバッグレベルのログを表す定数値。
---@field LogLevelTrace number @トレースレベルのログを表す定数値。
---@field LogLevelAll number @すべてのログ出力を行うことを表す定数値。
---@field ColorHueSamples number @既定の色相のサンプル数。
---@field ColorSaturationSamples number @既定の彩度のサンプル数。
---@field ColorBrightnessSamples number @既定の明度のサンプル数。
---@field ColorMapSize number @既定のカラーマップのサイズ。
---@field EscapeSequenceTag string @負の数値を示すタグ。
---@field SolidusTag string @フォワードスラッシュ '/' を示すタグ。
---@field NegativeNumberTag string @負の数値を示すタグ。
---@field ArrayNumberTag string @連想配列でなく、keyが数値であることを示すタグ。
---@field InstanceIDParameterName string @インスタンス ID のパラーメーター名。
---@field MessageValueParameterName string @メッセージ値のパラーメーター名。
---@field MessageSenderOverride string @メッセージの送信者情報置換のパラーメーター名。
---@field MessageOriginalSender string @メッセージのオリジナルの送信者情報のパラーメーター名。
---@field TypeParameterName string @タイプのパラーメーター名。
---@field Vector3TypeName string @`Vector3` のタイプ名。
---@field QuaternionTypeName string @`Quaternion` のタイプ名。
---@field InstanceID fun (): string @`vci.assets.GetInstanceId()` の値を返す。
---@field ClientID fun (): string @クライアント ID を取得する。ユーザーローカルで生成される。
---@field NillableHasValue fun (nillable: any): boolean @`nillable` が `nil` 以外の値であるかを調べる。
---@field NillableValue fun (nillable: any): any @`nillable` の値を返す。`nillable` が `nil` の場合は、エラーを発生させる。
---@field NillableValueOrDefault fun (nillable: any, defaultValue: any): any @`nillable` の値を返す。`nillable` が `nil` の場合は、`defaultValue` で指定した値を返す。`defaultValue` が `nil` の場合は、エラーを発生させる。
---@field NillableIfHasValue fun (nillable: any, callback: fun(value: any)) @`nillable` の値が `nil` ではない場合は、`callback` を実行する。`value` に `nillable` の値が渡される。
---@field NillableIfHasValueOrElse fun (nillable: any, callback: fun(value: any), emptyCallback: fun()): any @`nillable` の値が `nil` ではない場合は `callback` を実行する。`value` に `nillable` の値が渡される。`nillable` の値が `nil` の場合は `emptyCallback` を実行する。コールバック関数の実行結果を返す。
---@field StringStartsWith fun (str: string, search: string, optPosition: number): boolean @`str` の文字列が `search` に指定した文字列で始まるかを調べる。`optPosition` に、検索開始位置を指定することもできる (省略可能)。
---@field StringEndsWith fun (str: string, search: string, optLength: number): boolean @`str` の文字列が `search` に指定した文字列で終わるかを調べる。`optLength` に、検索開始位置を指定することもできる (省略可能)。
---@field StringTrimStart fun (str: string): string @`str` の文字列から、 先頭の空白を取り除いた文字列を返す。`StringTrim` も参照のこと。
---@field StringTrimEnd fun (str: string): string @`str` の文字列から、 末尾の空白を取り除いた文字列を返す。`StringTrim` も参照のこと。
---@field StringTrim fun (str: string): string @`str` の文字列から、 先頭と末尾の空白 ('\t', '\n', '\v', '\f', '\r', ' ') を取り除いた文字列を返す。
---@field StringReplace fun (str: string, target: string, replacement: string): string @`str` の文字列から `target` に一致する部分文字列を `replacement` で置換し、その結果の文字列を返す。
---@field SetConst fun (target: table, name: string, value: any): table @`target` に、定数フィールドを設定し、target 自身を返す。`name` に、定数名を指定する。`value` に、定数値を指定する。`value` に、関数を指定した場合は getter として呼び出される。
---@field SetConstEach fun (target: table, entries: table<string, any>): table @`entries` のそれぞれの要素について `SetConst` を行い、target 自身を返す。
---@field Extend fun (target: table, source: table, deep: boolean, omitMetaTable: boolean): table @`target` のテーブルフィールドを `source` のテーブルフィールドで拡張し、その結果を返す。`deep` に `true` を指定した場合は、ディープコピーを行う(省略するか `false` を指定した場合は、シャローコピーを行う)。`omitMetaTable` に 'true' を指定した場合は、メタテーブルをコピーしない。ただし、シャローコピーした場合は下位のテーブルの参照値がそのままコピーされる。(省略するか `false` を指定した場合は、コピーする)。
---@field Vars fun (v: any, padding: string): string @変数の情報を文字列で返す。`padding` は省略可能。`padding` に '__NOLF' を指定した場合は、インデントおよび改行を行わない。
---@field PosixTime fun (optTime: number): number @協定世界時 (UTC) の 1970-01-01T00:00:00Z から、指定した時刻までの経過時間を、秒単位の数値で返す。閏秒が含まれるかはシステム依存。`os.time` の戻り値の意味は実装依存であり、直接その値を計算に使うことができないため、`os.difftime` を利用することで、秒数を取得している。`optTime` には `os.time` 関数で得られる時刻を指定する。省略した場合は、引数なしの `os.time()` で得られる現在時刻となる。
---@field GetLogLevel fun (): number @現在のログレベルを取得する。既定値は `LogLevelInfo`。
---@field SetLogLevel fun (level: number) @ログレベルを設定する。
---@field IsOutputLogLevelEnabled fun (): boolean @ログレベルの文字列を出力するかを取得する。
---@field SetOutputLogLevelEnabled fun (enabled: boolean) @ログレベルの文字列を出力するかを設定する。
---@field Log fun (level: number, ...) @`level <= cytanb.GetLogLevel()` のときにログを出力する。
---@field LogFatal fun (...) @致命的なレベルのログを出力する。
---@field LogError fun (...) @エラーレベルのログを出力する。
---@field LogWarn fun (...) @警告レベルのログを出力する。
---@field LogInfo fun (...) @情報レベルのログを出力する。
---@field LogDebug fun (...) @デバッグレベルのログを出力する。
---@field LogTrace fun (...) @トレースレベルのログを出力する。
---@field ListToMap fun (list: any[], itemValue: any): table @リストをテーブルに変換する。リストの要素の値がキー値となる。`itemValue` に要素の値を指定する。`itemValue` に `nil` を指定するか省略した場合は、リストの要素の値が使われる。`itemValue` に関数を指定した場合は、引数に要素の値が渡され、戻り値の1番目のキー値、2番目が値として使われる。
---@field Round fun (num: number, decimalPlaces: number): number @`num` に最も近い整数、または `decimalPlaces` で指定した小数点以下の桁数に丸める。`decimalPlaces` は省略可能。
---@field Clamp fun (value: number, min: number, max: number): number @`min` 以上 `max` 以下の範囲に制限された `value` を返す。
---@field Lerp fun (a: number, b: number, t: number): number @`a` と `b` の間を `t` で線形補間する。`t` は 0 から 1 の範囲に制限される。
---@field LerpUnclamped fun (a: number, b: number, t: number): number @`a` と `b` の間を `t` で線形補間する。`t` の範囲に制限はない。
---@field PingPong fun (t: number, length: number): number @`t` が `0` と `length` の間を行き来する値を返す。
---@field VectorApproximatelyEquals fun (lhs: Vector2 | Vector3 | Vector4, rhs: Vector2 | Vector3 | Vector4): boolean @2 つのベクトルがおよそ一致するかを調べる。差のノルムがゼロに近いときに `true` を返す。2 つのベクトルは同じ型を指定すること。
---@field QuaternionApproximatelyEquals fun (lhs: Quaternion, rhs: Quaternion): boolean @2 つの Quaternion がおよそ一致するかを調べる。内積が `1.0` に近いときに `true` を返す。ただし、Quaternion は 720度までの回転角度をとるため、同じ回転結果にみえても、比較結果は `false` を返すことがある。
---@field QuaternionToAngleAxis fun (quat: Quaternion): number, Vector3 @`quat` を回転角度と回転軸に変換し、それぞれ1番目と2番目の戻り値として返す。
---@field RotateAround fun (targetPosition: Vector3, targetRotation: Quaternion, centerPosition: Vector3, rotation: Quaternion): Vector3, Quaternion @ターゲットを `centerPosition` で指定した位置を中心として、`rotation` で指定した回転を行う。計算結果を、1番目の戻り値にターゲットの位置、2番目の戻り値にターゲットの回転として返す。
---@field Random32 fun (): number @32 bit 整数値の範囲の疑似乱数を生成する。
---@field RandomUUID fun (): cytanb_uuid_t @乱数に基づく UUID version 4 を生成し、UUID オブジェクトを返す。
---@field UUIDFromNumbers fun (...): cytanb_uuid_t @指定した数値で、UUID オブジェクトを生成する。数値引数リストの1番目が最上位 32 bit で、4番目が最下位 32 bit となる。数値引数リストの替わりに数値配列を指定することも可能。
---@field UUIDFromString fun (str: string): cytanb_uuid_t @UUID の文字列表現から、UUID オブジェクトを生成する。無効な形式であった場合は nil を返す。
---@field CreateCircularQueue fun (capacity: number): cytanb_circular_queue_t @`capacity` で指定した容量の循環キューを作成する。`capacity` に `1` 未満を指定した場合はエラーとなる。
---@field DetectClicks fun (lastClickCount: number, lastTime: TimeSpan, clickTiming: TimeSpan): number, TimeSpan @連続したクリック数を検出する。最後のクリック時間から 'clickTiming' 以内であれば、カウントアップして 1 番目の戻り値として返す。時間が過ぎていれば `1` を返す。この関数を呼び出した時間を 2 番目の戻り値として返す。`lastClickCount` には、この関数からの1番目の戻り値を指定する。初回呼び出し時は `0` を指定する。`lastTime` には、この関数からの2番目の戻り値を指定する。初回呼び出し時は `TimeSpan.Zero` を指定する。`clickTiming` には、連続したクリックとみなす時間を指定する。省略した場合の値は 500 ミリ秒。
---@field ColorRGBToHSV fun (color: Color): number, number, number @`Color` オブジェクトの RGB 値から HSV 値へ変換する。戻り値の 1 番目に色相、2 番目に彩度、3 番目に明度を返す。
---@field ColorFromARGB32 fun (argb32: number): Color @ARGB 32 bit 値から、`Color` オブジェクトへ変換する。
---@field ColorToARGB32 fun (color: Color): number @`Color` オブジェクトから ARGB 32 bit 値へ変換する。
---@field ColorFromIndex fun (colorIndex: number, hueSamples: number, saturationSamples: number, brightnessSamples: number, omitScale: boolean): Color @カラーインデックスから対応する `Color` オブジェクトへ変換する。`hueSamples` は色相のサンプル数を指定し、省略した場合の値は　`ColorHueSamples`。`saturationSamples` は彩度のサンプル数を指定し、省略した場合の値は `ColorSaturationSamples`。`brightnessSamples` は明度のサンプル数を指定し、省略した場合の値は `ColorBrightnessSamples`。`omitScale` はグレースケールを省略するかを指定し、省略した場合の値は `false`。
---@field ColorToTable fun (value: Color): table @`Color` の各成分と型情報を含むテーブルへ変換する。
---@field ColorFromTable fun (tbl: table): Color, boolean @`ColorToTable` で得たテーブルを、`Color` へ変換して 1 番目の戻り値として返す。変換できなかった場合は `nil` を返す。テーブルに各成分以外のフィールドが含まれていたかを 2 番目の戻り値として返す。
---@field Vector2ToTable fun (value: Vector2): table @`Vector2` の各成分と型情報を含むテーブルへ変換する。
---@field Vector2FromTable fun (tbl: table): Vector2, boolean @`Vector2ToTable` で得たテーブルを、`Vector2` へ変換して 1 番目の戻り値として返す。変換できなかった場合は `nil` を返す。テーブルに各成分以外のフィールドが含まれていたかを 2 番目の戻り値として返す。
---@field Vector3ToTable fun (value: Vector3): table @`Vector3` の各成分と型情報を含むテーブルへ変換する。
---@field Vector3FromTable fun (tbl: table): Vector3, boolean @`Vector3ToTable` で得たテーブルを、`Vector3` へ変換して 1 番目の戻り値として返す。変換できなかった場合は `nil` を返す。テーブルに各成分以外のフィールドが含まれていたかを 2 番目の戻り値として返す。
---@field Vector4ToTable fun (value: Vector4): table @`Vector4` の各成分と型情報を含むテーブルへ変換する。
---@field Vector4FromTable fun (tbl: table): Vector4, boolean @`Vector4ToTable` で得たテーブルを、`Vector4` へ変換して 1 番目の戻り値として返す。変換できなかった場合は `nil` を返す。テーブルに各成分以外のフィールドが含まれていたかを 2 番目の戻り値として返す。
---@field QuaternionToTable fun (value: Quaternion): table @`Quaternion` の各成分と型情報を含むテーブルへ変換する。
---@field QuaternionFromTable fun (tbl: table): Quaternion, boolean @`QuaternionToTable` で得たテーブルを、`Quaternion` へ変換して 1 番目の戻り値として返す。変換できなかった場合は `nil` を返す。テーブルに各成分以外のフィールドが含まれていたかを 2 番目の戻り値として返す。
---@field TableToSerializable fun (data: table): table @`json.serialize/json.parse` の問題に対するワークアラウンドを行う。[負の数値の問題](https://github.com/xanathar/moonsharp/issues/163)、[数値インデックスの多次元配列の問題](https://github.com/moonsharp-devs/moonsharp/issues/219)、[フォワードスラッシュ '/' の問題](https://github.com/moonsharp-devs/moonsharp/issues/180) のワークアラウンドを行う。数値インデックスの配列である場合は、キー名に '#__CYTANB_ARRAY_NUMBER' タグを付加する。負の数値である場合は、キー名に '#__CYTANB_NEGATIVE_NUMBER' タグを付加し、負の数値を文字列に変換する。文字列にフォワードスラッシュ '/' が含まれている場合は、'#__CYTANB_SOLIDUS' に置換する。一度に多量のデータを処理しようとすると、`Too many instructions` エラーが発生することがある。
---@field TableFromSerializable fun (serData: table, noValueConversion: boolean): table @`TableToSerializable` で変換したテーブルを復元する。`ColorToTable/Vector2ToTable/Vector3ToTable/Vector4ToTable/QuaternionToTable` で変換したテーブルが含まれている場合は、テーブルから値へ自動変換を行う。`noValueConversion` に `true` を指定した場合は、値の自動変換を行わない。省略した場合の値は `false`。一度に多量のデータを処理しようとすると、`Too many instructions` エラーが発生することがある。
---@field EmitMessage fun (name: string, parameterMap: table<string, any>) @パラメーターを `TableToSerializable` および `json.serialize` でシリアライズして `vci.message.Emit` する。`name` に、メッセージ名を指定する。`parameterMap` に、送信するパラメーターのテーブルを指定する(省略可能)。また、`InstanceID` がパラメーターフィールド `__CYTANB_INSTANCE_ID` として付加されて送信される。
---@field OnMessage fun (name: string, callback: fun(sender: table, name: string, parameterMap: table)) @`EmitMessage` したメッセージを受信するコールバック関数を登録する。`name` に、メッセージ名を指定する。`callback` 関数に渡される `parameterMap` は `json.parse` および `TableFromSerializable` でデシリアライズしたテーブル。また、パラメーターフィールド `__CYTANB_INSTANCE_ID` を利用してメッセージ送信元のインスタンスを識別可能。もし `cytanb.EmitMessage` を通して送信されたデータでなければ、パラメーターフィールド `__CYTANB_MESSAGE_VALUE` に値がセットされる。**EXPERIMENTAL:実験的な機能として、受信したデータにパラメーターフィールド `__CYTANB_MESSAGE_SENDER_OVERRIDE` が指定されていた場合は、送信者情報置換処理を行い、`sender.__CYTANB_MESSAGE_ORIGINAL_SENDER` にオリジナルの送信者情報がセットされる。**
---@field OnInstanceMessage fun (name: string, callback: fun(sender: table, name: string, parameterMap: table)) @自身のインスタンスから送信されたメッセージを受信するコールバック関数を登録する。パラメーターフィールド `__CYTANB_INSTANCE_ID` を利用してインスタンスの判定を行う。その他の事項については `OnMessage` を参照。
---@field EmitCommentMessage fun (message: string, senderOverride: table) @スタジオ内に、疑似的にコメントメッセージを送信する。`message` に、送信するメッセージの内容を指定する。`senderOverride` に、送信者情報を指定する。(例: `{name = 'NicoUser', commentSource = 'Nicolive'}`) 受信側は `OnCommentMessage` を使用すること。
---@field OnCommentMessage fun (callback: fun(sender: table, name: string, message: string)) @コメントメッセージを受信するコールバック関数を登録する。通常の `comment` メッセージに加えて、`EmitCommentMessage` で送信したメッセージに対応できる。
---@field EmitNotificationMessage fun (message: string, senderOverride: table) @スタジオ内に、疑似的に通知メッセージを送信する。`message` に、送信するメッセージの内容を指定する。(`joined` | `left`)。`senderOverride` に、送信者情報を指定する。(例: `{name = 'FooUser'}`) 受信側は `OnNotificationMessage` を使用すること。
---@field OnNotificationMessage fun (callback: fun(sender: table, name: string, message: string)) @通知メッセージを受信するコールバック関数を登録する。通常の `notification` メッセージに加えて、`EmitNotificationMessage` で送信したメッセージに対応できる。
---@field GetEffekseerEmitterMap fun (name: string): table<string, ExportEffekseer> @`vci.assets.GetEffekseerEmitters` で取得したリストを、`EffectName` をキーとするマップにして返す。失敗した場合は `nil` を返す。`name` に、`Effekseer Emitter` コンポーネントを設定した「オブジェクト名」を指定する。
