# cytanb-color-palette

カラーパレットのアイテムです。

別の VCI から、共有変数を使用して、選択した色の取得が可能です。

## サンプルコード
```
--- ARGB 32 bit 値から、Color オブジェクトへ変換する。
function cytanbColorFromARGB32(argb32)
    local n = (type(argb32) == "number") and argb32 or 0xFF000000
    local a = bit32.band(bit32.rshift(n, 24), 0xFF) / 0xFF
    local r = bit32.band(bit32.rshift(n, 16), 0xFF) / 0xFF
    local g = bit32.band(bit32.rshift(n, 8), 0xFF) / 0xFF
    local b = bit32.band(n, 0xFF) / 0xFF
    return Color.__new(r, g, b, a);
end

-- カラーパレットの共有変数から値を取得する。
local color = cytanbColorFromARGB32(vci.studio.shared.Get("com.github.oocytanb.cytanb-tso-collab.color-palette.argb32"))
```

[共有変数に関する情報](https://gist.github.com/oocytanb/e35ab915f0ef9cf4f5948707f52da7af)


## カラーパレットを使用する VCI のサンプル
[colored-chalk](../colored-chalk/README.md)

サブアイテム名に「cytanb-color-picker」のプレフィックスをつけると、パレットに当てた場所の色が、共有変数に設定されます。
