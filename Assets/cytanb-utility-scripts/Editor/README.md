# CytanbBindVrmComponentsMenu

「外部のモデリングツールで修正 -> VRM へエクスポート」にかかる手順を、簡略化するためのスクリプトです。

**このスクリプトは、公式で案内されている手順とは、異なる方法で VRM を出力しますので、正しい結果を得られない可能性があります。よく理解されている方のみお使いください。**

使い方:

1. 公式の手順に沿い、メタ情報や BlendShape の設定などをすべて行い、VRM をエクスポートします。

1. 完成した VRM ファイルを、`[ルートオブジェクト名]-normalized.vrm` としてインポートします。

1. シーンに外部のモデリングツールで作成したオブジェクトを配置し、`Cytanb > Bind VRM Components` を実行します。

1. すると、prefab の情報を利用して、VRM 用のコンポーネントが追加されます。
(VRM Meta, VRM Blend Shape Proxy, secondary オブジェクト & VRM Spring Bone
**もし、元に戻す場合は、これらの追加されたコンポーネントを手動で削除してください。**)

1. 以降は、「シーンのオブジェクトを VRM にエクスポート <-> 外部のモデリングツールで修正」を繰り返します。

# CytanbGenerateColorPaletteMenu

cytanb-color-palette のオブジェクトを生成するスクリプトです。
