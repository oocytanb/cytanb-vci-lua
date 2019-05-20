# [cytanb-tso-collab](https://github.com/oocytanb/cytanb-tso-collab)

このプロジェクトは、[THE SEED ONLINE](https://seed.online/) の 3D オブジェクトを、協同して制作するための試みです。

Unity のプロジェクトファイルをオープンソースで公開していますので、すぐにアイテム作成やアイディアの追加を行えるようになっています。

**ひとりの力ですべてをなすには、人生はあまりにも短い。されど、多様性を認めるとき、世界はまわりだす。**

# Softwares

- [Unity](https://unity3d.com/) 2018.2

- [UniVRM](https://github.com/vrm-c/UniVRM)

- [UniVCI](https://github.com/virtual-cast/VCI)

- [Blender](https://www.blender.org/) 2.79

- [GIMP](https://www.gimp.org/) 2.10

- [Krita](https://krita.org/)

# Git

- [Git 公式サイト](https://git-scm.com/)

- [GitHub Desktop](https://desktop.github.com/) : GitHub 公式のGUIクライアント

- [GitHub for Unity](https://unity.github.com/) を導入しています。
    - `Unity Editor Menu > Window > GitHub` からアクセス出来ます。

- [Git Large File Storage (LFS)](https://git-lfs.github.com/) を導入しています。
    - **このため、Git LFS に対応した Git クライアントを使って、プロジェクトを clone する必要があります。**

- [Smart Merge (UnityYAMLMerge)](https://docs.unity3d.com/ja/2018.2/Manual/SmartMerge.html)

- Git に関する詳しい情報は、Web で調べてください。

## Pull request の作成手順
1. GitHub の [cytanb-tso-collab](https://github.com/oocytanb/cytanb-tso-collab.git) リポジトリを `Fork` します。(プロジェクトサイト右上 `Fork` ボタン)

1. フォークしたリポジトリをローカルへ `clone` します。

1. 機能開発用のブランチを作成します。

    `feature/sample` ブランチとして作成する例
    ```
    git checkout -b feature/sample
    ```

1. ローカルで変更を行い `commit` します。

1. 変更したブランチを `push` します。
    ```
    git push origin feature/sample
    ```

1. GitHub のサイト上でフォークしたリポジトリから `Pull request` を作成します。


## フォーク元のリポジトリに追従する手順

1. リモートリポジトリを追加します。

    現在の状態を確認します。
    ```
    git remote -v
    ```

    既に `upstream` としてフォーク元のリポジトリが追加されている場合は、この手順をスキップして次へ進みます。

    `upstream` としてリモートジポジトリを追加します。
    ```
    git remote add upstream https://github.com/oocytanb/cytanb-tso-collab.git
    ```

1. リモートの `develop` ブランチを `merge` し、フォーク先のリポジトリに `push` します。
    ```
    git checkout develop
    git fetch upstream
    git merge upstream/develop
    git push origin develop
    ```

1. 作業ブランチをチェックアウトし、`merge` あるいは `rebase` して、`develop` ブランチの変更を取り込みます。
    ```
    git checkout feature/sample
    ```

    - `merge` して変更を取り込む場合
        ```
        git merge develop
        ```

    - `rebase` して変更を取り込む場合
        ```
        git rebase develop
        ```

1. 変更したブランチを `push` します。
    ```
    git push origin feature/sample
    ```

# License
- Assets 以下に、適切な制作単位でサブディレクトリを作成し、制作単位ごとに LICENSE ファイルを用意します。

- ライセンスの種類は、オープンソースライセンスのうち、現在のところ以下のいずれかから選択しています。
    - [MIT License](https://opensource.org/licenses/MIT)
    - [ISC License](https://opensource.org/licenses/ISC)
    - [BSD 2-Clause License](https://opensource.org/licenses/BSD-2-Clause)
    - [Apache License, Version 2.0](https://opensource.org/licenses/Apache-2.0)
    - [CC BY 4.0](https://creativecommons.org/licenses/by/4.0/)

- これらのライセンスを採用する目的は、制作者の著作権表示とその成果物をオープンで自由に利用できることを、明示することです。

- その他のライセンスを適用する必要がある場合には、選択肢の追加を検討します。

- 外部のアセットを使用する場合は、ライセンスが適合するかをよく確認する必要があります。

# Utility scripts
See [cytanb-utility-scripts](cytanb-utility-scripts/README.md) directory.


# Community channel
[Discord](https://discord.gg/FwFjw5n)
