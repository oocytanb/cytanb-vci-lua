----------------------------------------------------------------
--  Copyright (c) 2019 Kagerou (https://twitter.com/shiromacKagerou)
--  MIT Licensed
----------------------------------------------------------------

package.path=package.path..';./?.lua' 
require("kagerou_utility")

---------------------------------------
print("start kagerou_utility test")

--- KFListはキューの機能を持っているコンテナクラス

KFList = KFList:new()
KFList:push_back(1)
assert(KFList.size == 1)
assert(KFList.first.content == 1)
assert(KFList.last.content == 1)
KFList:push_back(2)
assert(KFList.size == 2)
assert(KFList.first.content == 1)
assert(KFList.last.content == 2)
KFList:push_back(3)
assert(KFList.size == 3)
assert(KFList.first.content == 1)
assert(KFList.last.content == 3)
KFList:push_back(4)
assert(KFList.size == 4)
assert(KFList.first.content == 1)
assert(KFList.last.content == 4)
--KFList:EveryDo(function(content) print(content) end)
KFList:erase(KFList.first.next)
assert(KFList.size == 3)
assert(KFList.first.content == 1)
assert(KFList.last.content == 4)
--KFList:EveryDo(function(content) print(content) end)
KFList:erase(KFList.first)
assert(KFList.size == 2)
assert(KFList.first.content == 3)
assert(KFList.last.content == 4)
--KFList:EveryDo(function(content) print(content) end)

KFList:erase(KFList.last)
assert(KFList.size == 1)
assert(KFList.first.content == 3)
assert(KFList.last.content == 3)
--KFList:EveryDo(function(content) print(content) end)

KFList:erase(KFList.first)
assert(KFList.size == 0)
assert(KFList.first == nil)
assert(KFList.last == nil)
--KFList:EveryDo(function(content) print(content) end)

-----------------------------------------
testvalue = 0
TestClass = _defineClass()
function TestClass:update()
    testvalue = testvalue + 1
end
_makeClassStatic(TestClass)
-----------------------------------------

local testObj = TestClass:new()
local testObj2 = TestClass:new()

updateSender = KFEventSender:new("update")
updateSender:register(testObj)
updateSender:register(testObj2)
updateSender:send()
assert(testvalue == 2)
updateSender:send()
assert(testvalue == 4)
updateSender:unregister(testObj2)
updateSender:send()
assert(testvalue == 5)

print("COMPLETE kagerou_utility test")