# cytanb-vci-lua

[![busted](https://github.com/oocytanb/cytanb-vci-lua/actions/workflows/busted.yml/badge.svg)](https://github.com/oocytanb/cytanb-vci-lua/actions/workflows/busted.yml)

VCI のスクリプトから利用できる Lua のモジュール群です。

各モジュールのソースコードを読み解いて、お使いください。

## お知らせ

**VCAS 上の VCI で互換性のない変更が行われています。互換性を保てないソフトウェア上で開発を続けることは困難なため、今後 cytanb.lua に機能追加を行うことはありません。**

VCAS 2.0.8a で、削除された関数・フィールドリスト

- _G
- collectgarbage
- rawget
- rawset
- rawequal
- rawlen
- string.dump
- package
- load
- loadsafe
- loadfile
- loadfilesafe
- dofile
- dynamic

## Softwares / Libraries

- [VCI](https://github.com/virtual-cast/VCI) 
- [Lua](https://www.lua.org/) 5.2
- [MoonSharp](https://www.moonsharp.org/) 2.0.0.0
- [LuaRocks](https://luarocks.org/)
- [hererocks](https://github.com/luarocks/hererocks)
- [dkjson](http://dkolf.de/src/dkjson-lua.fsl/)
- [busted](https://olivinelabs.com/busted/)
- [luacov](https://github.com/keplerproject/luacov)
- [luacov-multiple](https://github.com/to-kr/luacov-multiple)
- [luacheck](https://github.com/luarocks/luacheck)

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

1. リモートの `main` ブランチを `merge` し、フォーク先のリポジトリに `push` します。
    ```
    git checkout main
    git fetch upstream
    git merge upstream/main
    git push origin main
    ```

1. 作業ブランチをチェックアウトし、`merge` あるいは `rebase` して、`main` ブランチの変更を取り込みます。
    ```
    git checkout feature/sample
    ```

    - `merge` して変更を取り込む場合
        ```
        git merge main
        ```

    - `rebase` して変更を取り込む場合
        ```
        git rebase main
        ```

1. 変更したブランチを `push` します。
    ```
    git push origin feature/sample
    ```

## Testing

- リポジトリに Push すると自動テストが行われます。

- テスティングフレームワークとして、[busted](https://olivinelabs.com/busted/) を導入しています。

- ローカル環境でテストを実行するには、[LuaRocks](https://luarocks.org/) とともにインストールします。

- コードカバレッジのレポートを生成したり、`luacheck` による静的解析などを行うこともできます。

- Lua 環境を構築する方法として、[hererocks](https://github.com/luarocks/hererocks) を利用することができます。

- Windows 環境では以下の手順になります。
    1. [python](https://www.python.org/) をインストールします。
    [depot_tools](https://dev.chromium.org/developers/how-tos/depottools) をインストールしている場合は、python が含まれていますので、それを利用することができます。

    1. コンパイラーとして [Visual Studio](https://visualstudio.microsoft.com/) をインストールします。
    (もしくは [gcc](https://gcc.gnu.org/) を利用することも可能です。)

    1. Visual Studio の `Command Prompt` を開き、以下のコマンドを実行します。
    ここでは、`luaenv` ディレクトリに Lua 環境をインストールしています。

        ```
        python3 -m pip install git+https://github.com/luarocks/hererocks --user
        python3 -m hererocks "luaenv" -l 5.2 -r latest

    1. Lua が正常にインストールされたことを確認します。
       `activate` スクリプトを実行することで、環境変数が設定されます。

        ```
        luaenv\bin\activate
        lua -v
        ```

    1. 必要なパッケージをインストールします。

        ```
        luarocks install dkjson
        luarocks install busted
        luarocks install luacov
        luarocks install luacov-multiple
        luarocks install luacheck
        ```

    1. `busted` コマンドでテストを実行します。ファイル名に `_spec` が含まれている lua ファイルがテスト対象となります。

        ```
        busted src
        ```

        コードカバレッジのレポートを生成する場合は、`-c` オプションを追加します。

        ```
        busted -c src
        ```

    1. `luacheck` による静的解析を行う場合は、以下を実行します。
        ```
        luacheck src
        ```

## License

- ライセンスは、各スクリプト/ライブラリーについて、それぞれご確認ください。

- アセット等に適用するライセンスは、制作者の著作権表示とその成果物をオープンで自由に利用できることを明示する目的で、主に以下のものから選択しています。
    - [MIT License](https://opensource.org/licenses/MIT)
    - [BSD 2-Clause License](https://opensource.org/licenses/BSD-2-Clause)
    - [Apache License, Version 2.0](https://opensource.org/licenses/Apache-2.0)
    - [CC BY 4.0](https://creativecommons.org/licenses/by/4.0/)
