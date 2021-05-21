local function main(args)
   package.path = package.path .. ';../src/?.lua'

   require('cytanb_fake_vci').vci.fake.Setup(_G)
   _G.__CYTANB_EXPORT_MODULE = true
   local cytanb = require('cytanb')(_ENV)

   for k, v in pairs(cytanb) do
      if type(k) == 'string' and type(v) == 'function' then
         print(k)
      end
   end
end

main({...})
