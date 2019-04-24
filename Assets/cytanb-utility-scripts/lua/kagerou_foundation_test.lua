----------------------------------------------------------------
--  Copyright (c) 2019 Kagerou (https://twitter.com/shiromacKagerou)
--  MIT Licensed
----------------------------------------------------------------

package.path=package.path..';./?.lua' 
require("kagerou_foundation")

---------------------------------------
print("start kagerou_foundation test")

--- ### kagerou_foundationの機能一覧 ###
--- クラスの定義
--- インスタンスの生成
--- コンストラクタとデストラクタ
--- 継承、多重継承
--- クラスメンバ変数の動的型チェック
    --- 未定義変数参照防止
    --- 未定義変数代入防止
    --- constメンバ変数
    --- 型互換性チェック
    --- (privateメンバの機能はありません)
--- Releaseヴァージョンでの高速化

--- ### クラスの定義 ###
--- クラスは以下のように宣言する
TutorialClass = _defineClass() -- _defineClass() でクラス作成開始
TutorialClass.value = "" -- メンバ変数を（constで）定義
TutorialClass.mutableValue = _mutable("") -- メンバ変数を（mutableで）定義
--- コンストラクタ定義
function TutorialClass:new(valueText, mutableValueText)
    local ins = self:_rawnew() -- 定型文
    ins._.value = valueText -- constメンバ変数は"._"を挟むと強制代入できる
    ins.mutableValue = mutableValueText -- mutableメンバ変数は普通に代入できる
    return ins -- 定型文
end
--- デストラクタ定義
function TutorialClass:delete()
    print("delete") -- デストラクタは複数回呼ばれてもよいようにしておく
end
--- メンバ関数定義
function TutorialClass:test(text) -- ！メンバ関数定義と呼び出しには必ず :(セミコロン)を使うこと！エラーが発生します！
    print(text)
end
_makeClassStatic(TutorialClass) -- _makeClassStatic() でクラス作成終了

--- ### 予約語一覧 ###
--- グローバルスペース
    --- _defineClass
    --- _makeClassStatic
    --- _mutable
    --- _weak
    --- _tableCopy
    --- _addmetatable
    --- DEBUG
--- クラス内
    --- _rawnew
    --- new　（コンストラクタ）
    --- delete　（デストラクタ）
--- クラスメタテーブル内
    --- _super
    --- _mutableList
    --- _readableList

TutorialsugoiProtocol = _defineClass() -- _defineClass() でクラス作成開始
function TutorialsugoiProtocol:sugoiInterface(text)
    print(text)
end
_makeClassStatic(TutorialsugoiProtocol) -- _makeClassStatic() でクラス作成終了

TutorialfutuuProtocol = _defineClass() -- _defineClass() でクラス作成開始
function TutorialfutuuProtocol:futuuInterface(text)
    print(text)
end
_makeClassStatic(TutorialfutuuProtocol) -- _makeClassStatic() でクラス作成終了

--- ### 継承、多重継承 ###
MultipleInheritance = _defineClass(TutorialsugoiProtocol, TutorialfutuuProtocol) -- _makeClassStatic() の引数に継承するクラスを並べると継承する
_makeClassStatic(MultipleInheritance)

MyClass = _defineClass()
MyClass.interface = _mutable({xxx = 1})
MyClass.interfacesugoi = _mutable(TutorialsugoiProtocol:new())
MyClass.interfacefutuu = _mutable(TutorialfutuuProtocol:new())
MyClass.interfaceNil = _mutable(nil)
MyClass_deletedFlag_for_test = false
function MyClass:delete()
    MyClass_deletedFlag_for_test = true
end
_makeClassStatic(MyClass)

--- ### インスタンスの生成 ###
local instanceMyclass = MyClass:new() -- new で生成する
--- ！メンバ関数定義と呼び出しには必ず :(セミコロン)を使うこと！エラーが発生します！
assert(instanceMyclass.interface.xxx == 1) -- 未定義のインスタンスメンバはクラスのメンバ変数の定義が参照される

instanceMyclass.interface = {xxx = 2}
instanceMyclass.interface = {yyy = 2} -- これはインターフェイスに互換性がないのでエラーになる。 xxxが必要
instanceMyclass.interface = {yyy = 2, xxx = 3} -- これはインターフェイスが互換性があるのでOK!


local testInterface = MultipleInheritance:new()
instanceMyclass.interfacesugoi = testInterface -- これはインターフェイスが互換性があるのでOK!
instanceMyclass.interfacefutuu = testInterface -- これはインターフェイスが互換性があるのでOK!

--- ！メンバ関数定義と呼び出しには必ず :(セミコロン)を使うこと！エラーが発生します！
-- instanceMyclass.new() -- これはエラーになる

--- 未定義変数参照防止
-- local naiyo = instanceMyclass.naiyo -- これはエラーになる
local naiyo = instanceMyclass.interfaceNil -- これは宣言しているのでエラーにならない

--- 未定義変数代入防止
-- instanceMyclass.naiyo = "text" -- これはエラーになる
instanceMyclass.interfaceNil = "text" -- これは宣言しているのでエラーにならない


--- ### デストラクタの動作チェック ###
--- 任意のタイミングでデストラクタを動作させたい場合は直接deleteを呼ぶ
instanceMyclass = nil
collectgarbage()
assert(MyClass_deletedFlag_for_test == true)


--- ### Releaseヴァージョンでの高速化 ###
--- DEBUGテーブルとその中の定義をすべて消去するとすべての型チェックがなくなり、高速化します

print("COMPLETE kagerou_foundation test")
