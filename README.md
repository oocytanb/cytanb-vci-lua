# cytanb-vci-lua

VCI のスクリプトから利用できる Lua のモジュールです。

[cytanb-tso-collab](https://github.com/oocytanb/cytanb-tso-collab) は関連するプロジェクトです。

## Softwares / Libraries

- [VCI](https://github.com/virtual-cast/VCI) 
- [Lua](https://www.lua.org/) 5.2
- [MoonSharp](https://www.moonsharp.org/) 2.0.0.0

## Git

- [Git 公式サイト](https://git-scm.com/)

- Git に関する詳しい情報は、Web の資料に当たってください。

### Pull request の作成手順
1. GitHub の [cytanb-vci-lua](https://github.com/oocytanb/cytanb-vci-lua.git) リポジトリを `Fork` します。(プロジェクトサイト右上 `Fork` ボタン)

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


### フォーク元のリポジトリに追従する手順

1. リモートリポジトリを追加します。

    現在の状態を確認します。
    ```
    git remote -v
    ```

    既に `upstream` としてフォーク元のリポジトリが追加されている場合は、この手順をスキップして次へ進みます。

    `upstream` としてリモートジポジトリを追加します。
    ```
    git remote add upstream https://github.com/oocytanb/cytanb-vci-lua.git
    ```

1. リモートの `master` ブランチを `merge` し、フォーク先のリポジトリに `push` します。
    ```
    git checkout master
    git fetch upstream
    git merge upstream/master
    git push origin master
    ```

1. 作業ブランチをチェックアウトし、`merge` あるいは `rebase` して、`master` ブランチの変更を取り込みます。
    ```
    git checkout feature/sample
    ```

    - `merge` して変更を取り込む場合
        ```
        git merge master
        ```

    - `rebase` して変更を取り込む場合
        ```
        git rebase master
        ```

1. 変更したブランチを `push` します。
    ```
    git push origin feature/sample
    ```

## License

- ライセンスは、各スクリプト/ライブラリーについて、それぞれご確認ください。

- アセット等に適用するライセンスは、制作者の著作権表示とその成果物をオープンで自由に利用できることを明示する目的で、主に以下のものから選択しています。
    - [MIT License](https://opensource.org/licenses/MIT)
    - [ISC License](https://opensource.org/licenses/ISC)
    - [BSD 2-Clause License](https://opensource.org/licenses/BSD-2-Clause)
    - [Apache License, Version 2.0](https://opensource.org/licenses/Apache-2.0)
    - [CC BY 4.0](https://creativecommons.org/licenses/by/4.0/)

## Community
[Discord](https://discord.gg/FwFjw5n)
