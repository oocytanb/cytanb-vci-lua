----------------------------------------------------------------
--  Copyright (c) 2019 oO (https://github.com/oocytanb)
--  MIT Licensed
----------------------------------------------------------------

-- [VCI](https://github.com/virtual-cast/VCI) 環境の簡易 Fake モジュール。
-- Unit test を行うための、補助モジュールとしての利用を目的としている。
-- 実環境を忠実にエミュレートするものではなく、挙動が異なる部分が多分にあるため、その点に留意して利用する必要がある。
-- (例えば、3D オブジェクトの物理演算は行われない、ネットワーク通信は行われずローカルのインメモリーで処理される、など)
-- **EXPERIMENTAL: 実験的なモジュールであるため、多くの変更が加えられる可能性がある。**

return (function ()
	local dkjson = require('dkjson')

	local cytanb
	cytanb = {
		SetConst = function (target, name, value)
			if type(target) ~= 'table' then
				error('Cannot set const to non-table target')
			end

			local curMeta = getmetatable(target)
			local meta = curMeta or {}
			local hasMetaIndex = type(meta.__index) == 'table'
			if target[name] ~= nil and (not hasMetaIndex or meta.__index[name] == nil) then
				error('Non-const field "' .. name .. '" already exists')
			end

			if not hasMetaIndex then
				meta.__index = {}
			end
			local metaIndex = meta.__index
			metaIndex[name] = value

			if not hasMetaIndex or type(meta.__newindex) ~= 'function' then
				meta.__newindex = function (table, key, v)
					if table == target and metaIndex[key] ~= nil then
						error('Cannot assign to read only field "' .. key .. '"')
					end
					rawset(table, key, v)
				end
			end

			if not curMeta then
				setmetatable(target, meta)
			end

			return target
		end,

		SetConstEach = function (target, entries)
			for k, v in pairs(entries) do
				cytanb.SetConst(target, k, v)
			end
			return target
		end,

		Lerp = function (a, b, t)
			if t <= 0.0 then
				return a
			elseif t >= 1.0 then
				return b
			else
				return a + (b - a) * t
			end
		end,

		LerpUnclamped = function (a, b, t)
			return a + (b - a) * t
		end
	}

	local NumberHashCode = function (num, carry)
		local result = bit32.band(carry ~= 0 and carry or 31, 0xFFFFFFFF)
		if num == 0 then
			result = bit32.band(31 * result, 0xFFFFFFFF)
		else
			local integerPart = math.floor(num)
			local fractionPart = num - integerPart

			for i = 1, 4 do
				result = bit32.band(31 * result + bit32.band(integerPart, 0xFFFFFFFF), 0xFFFFFFFF)
				integerPart = math.floor(integerPart / 0x100000000)
				if integerPart == 0 then
					break
				end
			end

			if fractionPart ~= 0 then
				for i = 1, 5 do
					local mf = fractionPart * 0x1000000
					local mfInteger = math.floor(mf)
					result = bit32.band(31 * result + bit32.band(mfInteger, 0xFFFFFFFF), 0xFFFFFFFF)
					fractionPart = mf - mfInteger
					if fractionPart == 0 then
						break
					end
				end
			end
		end
		return result
	end

	local ModuleName = 'cytanb_fake_vci'
	local StringModuleName = 'string'
	local moonsharpAdditions = {_MOONSHARP = true, json = true}

	local currentVciName = ModuleName
	local stateMap = {}
	local studioSharedMap = {}
	local studioSharedCallbackMap = {}

	local messageCallbackMap = {}

	local fakeModule, Vector2, Color, vci

	local Vector2IndexMap = {'x', 'y'}

	local Vector2Metatable
	Vector2Metatable = {
		__add = function (op1, op2)
			return Vector2.__new(op1.x + op2.x, op1.y + op2.y)
		end,

		__sub = function (op1, op2)
			return Vector2.__new(op1.x - op2.x, op1.y - op2.y)
		end,

		__mul = function (op1, op2)
			local numType1 = type(op1) == 'number'
			local numType2 = type(op2) == 'number'
			if numType1 or numType2 then
				local vec, m
				if numType1 then
					vec = op2
					m = op1
				else
					vec = op1
					m = op2
				end
				return Vector2.__new(vec.x * m, vec.y * m)
			else
				return Vector2.__new(op1.x * op2.x, op1.y * op2.y)
			end
		end,

		__div = function (op1, op2)
			if type(op2) == 'number' then
				return Vector2.__new(op1.x / op2, op1.y / op2)
			else
				return Vector2.__new(op1.x / op2.x, op1.y / op2.y)
			end
		end,

		__eq = function (op1, op2)
			return op1.x == op2.x and op1.y == op2.y
		end,

		__index = function (table, key)
			if key == 'magnitude' then
				return math.sqrt(table.sqrMagnitude)
			elseif key == 'normalized' then
				local vec = Vector2.__new(table.x, table.y)
				vec.Normalize()
				return vec
			elseif key == 'sqrMagnitude' then
				return math.pow(table.x, 2) + math.pow(table.y, 2)
			else
				error('Cannot access field "' .. key .. '"')
			end
		end,

		__newindex = function (table, key, v)
			error('Cannot assign to field "' .. key .. '"')
		end,

		__tostring = function (value)
			return value.ToString()
		end
	}

	local ColorMetatable = {
		__add = function (op1, op2)
			return Color.__new(op1.r + op2.r, op1.g + op2.g, op1.b + op2.b, op1.a + op2.a)
		end,

		__sub = function (op1, op2)
			return Color.__new(op1.r - op2.r, op1.g - op2.g, op1.b - op2.b, op1.a - op2.a)
		end,

		__mul = function (op1, op2)
			local numType1 = type(op1) == 'number'
			local numType2 = type(op2) == 'number'
			if numType1 or numType2 then
				local color, m
				if numType1 then
					color = op2
					m = op1
				else
					color = op1
					m = op2
				end
				return Color.__new(color.r * m, color.g * m, color.b * m, color.a * m)
			else
				return Color.__new(op1.r * op2.r, op1.g * op2.g, op1.b * op2.b, op1.a * op2.a)
			end
		end,

		__div = function (op1, op2)
			return Color.__new(op1.r / op2, op1.g / op2, op1.b / op2, op1.a / op2)
		end,

		__eq = function (op1, op2)
			return op1.r == op2.r and op1.g == op2.g and op1.b == op2.b and op1.a == op2.a
		end,

		__index = function (table, key)
			if key == 'gamma' then
				error('!!NOT IMPLEMENTED!!')
			elseif key == 'grayscale' then
				error('!!NOT IMPLEMENTED!!')
			elseif key == 'linear' then
				error('!!NOT IMPLEMENTED!!')
			elseif key == 'maxColorComponent' then
				return math.max(table.r, table.g, table.b)
			else
				error('Cannot access field "' .. key .. '"')
			end
		end,

		__newindex = function (table, key, v)
			error('Cannot assign to field "' .. key .. '"')
		end,

		__tostring = function (value)
			return value.ToString()
		end
	}

	fakeModule = {
		-- [MoonSharp](https://www.moonsharp.org/additions.html) の拡張。
		_MOONSHARP = {
			version = '2.0.0.0',
			luacompat = string.match(_VERSION or '', '(%d+(%.%d+))') or '',
			platform = 'limited.unity.dll.mono.clr4.aot',
			is_aot = true,
			is_unity = true,
			is_mono = true,
			is_clr4 = true,
			is_pcl = false,
			banner = 'cytanb_fake_vci | Copyright (c) 2019 oO (https://github.com/oocytanb) | MIT Licensed'
		},

		-- [MoonSharp](https://www.moonsharp.org/additions.html) の拡張。
		string = {
			contains = function (str1, str2)
				return string.find(str1, str2, 1, true) ~= nil
			end,

			startsWith = function (str1, str2)
				local len1 = string.len(str1)
				local len2 = string.len(str2)
				if len1 < len2 then
					return false
				elseif len2 == 0 then
					return true
				end

				return str2 == string.sub(str1, 1, len2)
			end,

			endsWith = function (str1, str2)
				local len1 = string.len(str1)
				local len2 = string.len(str2)
				if len1 < len2 then
					return false
				elseif len2 == 0 then
					return true
				end

				local i = string.find(str1, str2, - len2, true)
				return i ~= nil
			end
		},

		-- [MoonSharp](https://www.moonsharp.org/additions.html) の拡張。
		json = {
			parse = function (jsonString)
				return dkjson.decode(jsonString, 1, dkjson.null)
			end,

			serialize = function (table)
				local t = type(table)
				if t ~= 'table' then
					error('Invalid type: ' .. t)
				end
				return dkjson.encode(table)
			end,

			isNull = function (val)
				return val == dkjson.null
			end,

			null = function ()
				return dkjson.null
			end
		},

		Vector2 = {
			__new = function (x, y)
				local self
				self = {
					x = x or 0.0,
					y = y or 0.0,

					set_Item = function (index, value)
						local key = Vector2IndexMap[index + 1]
						if key then
							self[key] = value
						else
							error('Invalid index: ' .. tostring(index))
						end
					end,

					Set = function (newX, newY)
						self.x = newX
						self.y = newY
					end,

					Normalize = function ()
						local m = self.magnitude
						if math.abs(m) <= Vector2.kEpsilon then
							self.x = 0.0
							self.y = 0.0
						else
							self.x = self.x / m
							self.y = self.y / m
						end
					end,

					ToString = function (format)
						-- format argument is not implemented
						return string.format('(%.1f, %.1f)', self.x, self.y)
					end,

					GetHashCode = function ()
						return NumberHashCode(self.x, NumberHashCode(self.y))
					end,

					-- 正しくは static 関数として実装すべきものだと考えられる。
					-- Vector3, Vector4 の SqrMagnitude は、static として実装されている。
					-- sqrMagnitude フィールドと機能が重複している。
					SqrMagnitude = function ()
						return self.sqrMagnitude
					end
				}
				setmetatable(self, Vector2Metatable)
				return self
			end,

			Lerp = function (a, b, t)
				return Vector2.__new(
					cytanb.Lerp(a.x, b.x, t),
					cytanb.Lerp(a.y, b.y, t)
				)
			end,

			LerpUnclamped = function (a, b, t)
				return Vector2.__new(
					cytanb.LerpUnclamped(a.x, b.x, t),
					cytanb.LerpUnclamped(a.y, b.y, t)
				)
			end,

			Scale = function (a, b)
				return a * b
			end,

			Dot = function (lhs, rhs)
				return lhs.x * rhs.x + lhs.y * rhs.y
			end,

			Angle = function (from, to)
				local dot = Vector2.Dot(from, to)
				local scale = from.magnitude * to.magnitude
				return math.acos(dot / scale) * 180 / math.pi
			end,

			Distance = function (a, b)
				return (a - b).magnitude
			end,

			__toVector2 = function (vec3)
				error('!!NOT IMPLEMENTED!!')
			end,

			__toVector3 = function (vec2)
				error('!!NOT IMPLEMENTED!!')
			end
		},

		Color = {
			__new = function (r, g, b, a)
				local argsSpecified = r and g and b
				local self
				self = {
					r = argsSpecified and r or 0.0,
					g = argsSpecified and g or 0.0,
					b = argsSpecified and b or 0.0,
					a = argsSpecified and (a or 1.0) or 0.0,

					ToString = function (format)
						-- format argument is not implemented
						return string.format('RGBA(%.3f, %.3f, %.3f, %.3f)', self.r, self.g, self.b, self.a)
					end,

					GetHashCode = function ()
						return NumberHashCode(self.r, NumberHashCode(self.g, NumberHashCode(self.b, NumberHashCode(self.a))))
					end,
				}
				setmetatable(self, ColorMetatable)
				return self
			end,

			HSVToRGB = function (H, S, V)
				local h = math.max(0.0, math.min(H, 1.0)) * 6.0
				local s = math.max(0.0, math.min(S, 1.0))
				local v = math.max(0.0, math.min(V, 1.0))
				local c = v * s
				local x = c * (1 - math.abs((h % 2) - 1))
				local m = v - c
				local r, g, b
				if h < 1 then
					r = c
					g = x
					b = 0.0
				elseif h < 2 then
					r = x
					g = c
					b = 0.0
				elseif h < 3 then
					r = 0.0
					g = c
					b = x
				elseif h < 4 then
					r = 0.0
					g = x
					b = c
				elseif h < 5 then
					r = x
					g = 0.0
					b = c
				else
					r = c
					g = 0.0
					b = x
				end
				return Color.__new(r + m, g + m, b + m)
			end,

			Lerp = function (a, b, t)
				return Color.__new(
					cytanb.Lerp(a.r, b.r, t),
					cytanb.Lerp(a.g, b.g, t),
					cytanb.Lerp(a.b, b.b, t),
					cytanb.Lerp(a.a, b.a, t)
				)
			end,

			LerpUnclamped = function (a, b, t)
				return Color.__new(
					cytanb.LerpUnclamped(a.r, b.r, t),
					cytanb.LerpUnclamped(a.g, b.g, t),
					cytanb.LerpUnclamped(a.b, b.b, t),
					cytanb.LerpUnclamped(a.a, b.a, t)
				)
			end,

			__toVector4 = function (color)
				error('!!NOT IMPLEMENTED!!')
			end,

			__toColor = function (vec4)
				error('!!NOT IMPLEMENTED!!')
			end
		},

		-- [VirtualCast Official Wiki](https://virtualcast.jp/wiki/)
		vci = {
			assets = {},

			state = {
				Set = function (name, value)
					local nv
					local t = type(value)
					if (t == 'number' or t == 'string' or t == 'boolean') then
						nv = value
					else
						nv = nil
					end
					stateMap[name] = nv
				end,

				Get = function (name)
					return stateMap[name]
				end,

				Add = function (name, value)
					if type(value) == 'number' then
						local curValue = stateMap[name]
						if type(curValue) == 'number' then
							stateMap[name] = curValue + value
						else
							stateMap[name] = value
						end
					end
				end
			},

			studio = {
				shared = {
					Set = function (name, value)
						local nv
						local t = type(value)
						if (t == 'number' or t == 'string' or t == 'boolean') then
							nv = value
						else
							nv = nil
						end

						local changed = studioSharedMap[name] ~= nv
						studioSharedMap[name] = nv
						if changed then
							local cbMap = studioSharedCallbackMap[name]
							if cbMap then
								for cb, v in pairs(cbMap) do
									cb(nv)
								end
							end
						end
					end,

					Get = function (name)
						return studioSharedMap[name]
					end,

					Add = function (name, value)
						if type(value) == 'number' then
							local curValue = studioSharedMap[name]
							local nv
							if type(curValue) == 'number' then
								nv = curValue + value
							else
								nv = value
							end

							local changed = studioSharedMap[name] ~= nv
							studioSharedMap[name] = nv
							if changed then
								local cbMap = studioSharedCallbackMap[name]
								if cbMap then
									for cb, v in pairs(cbMap) do
										cb(nv)
									end
								end
							end
						end
					end,

					Bind = function (name, callback)
						if not studioSharedCallbackMap[name] then
							studioSharedCallbackMap[name] = {}
						end
						studioSharedCallbackMap[name][callback] = true
					end
				}
			},

			message = {
				On = function (messageName, callback)
					if not messageCallbackMap[messageName] then
						messageCallbackMap[messageName] = {}
					end
					messageCallbackMap[messageName][callback] = true
				end,

				Emit = function (messageName, ...)
					if select('#', ...) < 1 then
						-- value 引数が指定されない場合は、処理しない。
						return
					end

					local value = ...
					local nv
					local t = type(value)
					if (t == 'number' or t == 'string' or t == 'boolean') then
						nv = value
					elseif (t == 'nil' or t == 'table' or t == 'userdata') then
						nv = nil
					else
						-- その他の型の場合は処理しない。
						return
					end

					vci.fake.EmitVciMessage(currentVciName, messageName, nv)
				end
			},

			-- fake module
			fake = {
				Setup = function (target)
					for k, v in pairs(fakeModule) do
						if moonsharpAdditions[k] then
							if target[k] == nil then
								target[k] = v
							end
						elseif k ~= StringModuleName then
							target[k] = v
						end
					end

					for k, v in pairs(fakeModule[StringModuleName]) do
						if target[StringModuleName][k] == nil then
							target[StringModuleName][k] = v
						end
					end

					package.loaded[ModuleName] = fakeModule
				end,

				Teardown = function (target)
					for k, v in pairs(fakeModule) do
						if k ~= StringModuleName and target[k] == v then
							target[k] = nil
						end
					end

					for k, v in pairs(fakeModule[StringModuleName]) do
						if target[StringModuleName][k] == v then
							target[StringModuleName][k] = nil
						end
					end

					package.loaded[ModuleName] = nil
				end,

				Round = function (num, decimalPlaces)
					if decimalPlaces then
						local m = math.pow(10, decimalPlaces)
						return math.floor(num * m + 0.5) / m
					else
						return math.floor(num + 0.5)
					end
				end,

				RoundVector2 = function (vec, decimalPlaces)
					return Vector2.__new(
						vci.fake.Round(vec.x, decimalPlaces),
						vci.fake.Round(vec.y, decimalPlaces)
					)
				end,

				RoundColor = function (color, decimalPlaces)
					return Color.__new(
						vci.fake.Round(color.r, decimalPlaces),
						vci.fake.Round(color.g, decimalPlaces),
						vci.fake.Round(color.b, decimalPlaces),
						vci.fake.Round(color.a, decimalPlaces)
					)
				end,

				SetVciName = function (name)
					currentVciName = tostring(name)
				end,

				GetVciName = function ()
					return currentVciName
				end,

				SetAssetsIsMine = function (mine)
					cytanb.SetConst(vci.assets, 'IsMine', mine and true or nil)
				end,

				ClearState = function ()
					stateMap = {}
				end,

				UnbindStudioShared = function (name, callback)
					local cbMap = studioSharedCallbackMap[name]
					if cbMap and cbMap[callback] then
						cbMap[callback] = nil
					end
				end,

				ClearStudioShared = function ()
					studioSharedMap = {}
					studioSharedCallbackMap = {}
				end,

				EmitRawMessage = function (sender, messageName, value)
					local cbMap = messageCallbackMap[messageName]
					if cbMap then
						for cb, v in pairs(cbMap) do
							cb(sender, messageName, value)
						end
					end
				end,

				EmitVciMessage = function (vciName, messageName, value)
					vci.fake.EmitRawMessage({type = 'vci', name = vciName}, messageName, value)
				end,

				EmitCommentMessage = function (userName, value)
					vci.fake.EmitRawMessage({type = 'comment', name = userName or ''}, 'comment', tostring(value))
				end,

				OffMessage = function (messageName, callback)
					local cbMap = messageCallbackMap[messageName]
					if cbMap and cbMap[callback] then
						cbMap[callback] = nil
					end
				end,

				ClearMessage = function ()
					messageCallbackMap = {}
				end
			}
		}
	}

	Vector2 = fakeModule.Vector2
	cytanb.SetConstEach(Vector2, {
		down = Vector2.__new(0, -1),
		left = Vector2.__new(-1, 0),
		one = Vector2.__new(1, 1),
		right = Vector2.__new(1, 0),
		up = Vector2.__new(0, 1),
		zero = Vector2.__new(0, 0),
		kEpsilon = 9.99999974737875E-06,
		kEpsilonNormalSqrt = 1.00000000362749E-15
	})

	Color = fakeModule.Color
	cytanb.SetConstEach(Color, {
		black = Color.__new(0, 0, 0, 1),
		blue = Color.__new(0, 0, 1, 1),
		clear = Color.__new(0, 0, 0, 0),
		cyan = Color.__new(0, 1, 1, 1),
		gray = Color.__new(0.5, 0.5, 0.5, 1),
		green = Color.__new(0, 1, 0, 1),
		grey = Color.__new(0.5, 0.5, 0.5, 1),
		magenta = Color.__new(1, 0, 1, 1),
		red = Color.__new(1, 0, 0, 1),
		white = Color.__new(1, 1, 1, 1),
		yellow = Color.__new(1, 235 / 255, 4 / 255, 1)
	})

	vci = fakeModule.vci

	vci.fake.SetAssetsIsMine(true)

	return fakeModule
end)()
