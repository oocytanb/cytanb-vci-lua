# cytanb-color-palette

カラーパレットのアイテムです。
別の VCI から、パレットで選択した色情報を取得可能です。

[![cytanb-color-palette 紹介動画](https://img.youtube.com/vi/e3qvpL7QpMM/0.jpg)](https://www.youtube.com/watch?v=e3qvpL7QpMM)

## パレットの色選択

- アバターの手、または名前にハッシュタグ `#cytanb-color-picker` が含まれるアイテムが、パレットに当たると、その場所の色が設定されます。

- パレットの左側にある `Advanced` スイッチをつかんでグリップ(使用)すると、`Brightness`, `Opacity`, `Picker` スイッチの有効/無効を切り換えます。

- `Brightness` スイッチに触れると、パレットの明度を切り替えます。

- `Opacity` スイッチに触れると、パレットの不透明度を切り替えます。

- `Picker` スイッチをつかんでグリップ(使用)すると、当たり判定をするコライダーを `制限する[LIMIT]/しない[ANY]` を切り換えます。

## 共有変数 `vci.studio.shared` から色情報を取得する方法

サンプルコード

```
--- ARGB 32 bit 値から、Color オブジェクトへ変換する。
--- @param argb32 number
--- @return Color
local ColorFromARGB32 = function (argb32)
    local n = (type(argb32) == 'number') and argb32 or 0xFF000000
    return Color.__new(
        bit32.band(bit32.rshift(n, 16), 0xFF) / 0xFF,
        bit32.band(bit32.rshift(n, 8), 0xFF) / 0xFF,
        bit32.band(n, 0xFF) / 0xFF,
        bit32.band(bit32.rshift(n, 24), 0xFF) / 0xFF
    )
end

-- カラーパレットが存在しない場合のデフォルト色 (ここでは緑色)。
local DefaultARGB32 = 0xFF00A95F

-- カラーパレットの共有変数から値を取得する。
local color = ColorFromARGB32(vci.studio.shared.Get('com.github.oocytanb.cytanb-tso-collab.color-palette.argb32') or DefaultARGB32)
```

[共有変数に関する情報](https://gist.github.com/oocytanb/e35ab915f0ef9cf4f5948707f52da7af)

## カラーパレットのメッセージ `vci.message` の詳細 (**実験的機能 - 仕様変更される可能性があります**)

### メッセージの一般形式
- メッセージ内容: パラメーターマップ (テーブル) を JSON エンコードした文字列です。

- ただし、MoonSharpの `json.parse` は、負の数値が含まれているとエラーとなるため (https://github.com/xanathar/moonsharp/issues/163)、その場合はパラメーター名に '#__CYTANB_NEGATIVE_NUMBER' タグを付加し、負の数値を文字列に変換します。

- パラメーターのシリアライズ / デシリアライズは、`cytanb.EmitMessage` / `cytanb.OnMessage` によって透過的に行われます。

### カラーパレットが送出するメッセージ
- 概要: カラーパレットの状態 (インスタンス ID、オブジェクトのトランスフォーム、選択色) を通知します。
    パレットで新しい色が選択されたとき、および、問い合わせメッセージ 'cytanb.color-palette.query-status' を受けたときに、このメッセージを送出します。

- メッセージ名: 'cytanb.color-palette.item-status'

- パラメーター:
    - __CYTANB_INSTANCE_ID: カラーパレットのインスタンス ID 文字列。
    - version: メッセージのバージョン数値。
    - positionX, positionY, positionZ: オブジェクトの座標値。
    - rotationX, rotationY, rotationZ, rotationW: オブジェクトの回転値。
    - scaleX, scaleY, scaleZ: オブジェクトのスケール値。
    - argb32: パレットで選択した色の ARGB 32 bit 値。

- サンプルコード:
    ```
    cytanb.OnMessage('cytanb.color-palette.item-status', function (sender, name, parameterMap)
        -- vci.message から色情報を取得する。
        -- 複数のパレットを区別しない場合は、色情報だけを処理するとよい。
        local color = cytanb.ColorFromARGB32(parameterMap['argb32'])

        -- カラーパレットのインスタンス ID や、位置によって、複数のパレットを区別する事も出来る。
        local instanceID = parameterMap['__CYTANB_INSTANCE_ID']
        local position = Vector3.__new(parameterMap['positionX'], parameterMap['positionY'], parameterMap['positionZ'])
    end)
    ```

### カラーパレットが受け付けるメッセージ

- 概要: カラーパレットの状態を問い合わせます。

- メッセージ名: 'cytanb.color-palette.query-status'

- パラメーター:
    - version: メッセージのバージョン。

- サンプルコード:
    ```
    cytanb.EmitMessage('cytanb.color-palette.query-status', {version = 0x10000})
    ```

## カラーパレットを使用する VCI のサンプル

- [colored-chalk-and-panels](../colored-chalk-and-panels/README.md)

- [oO-bariumkuchen](../oO-bariumkuchen/README.md)
