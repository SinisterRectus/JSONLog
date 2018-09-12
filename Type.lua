local json = require('json')

local Type = {}
Type.__index = Type

local function getTypeString(d)
	if d == json.null then
		return 'null' -- null
	end
	if d == nil then
		return 'undefined' -- undefined
	end
	local s = type(d)
	if s == 'table' then
		local m = getmetatable(d)
		return m and m.__jsontype or s -- object, array, table
	end
	return s -- string, boolean, number
end

local function parseObject(obj)
	for k, v in pairs(obj) do
		obj[k] = Type(v)
	end
end

local function mergeObject(dest, obj)
	for k, v in pairs(dest) do
		v:add(obj[k])
		obj[k] = nil
	end
	for k, v in pairs(obj) do
		dest[k] = dest[k] or Type(nil)
		dest[k]:add(v)
	end
end

local function parseArray(arr)
	arr[1] = Type(arr[1])
	for i = 2, #arr do
		arr[1]:add(arr[i])
		arr[i] = nil
	end
end

local function mergeArray(dest, arr)
	for _, v in ipairs(arr) do
		dest[1]:add(v)
	end
end

local function new(s, d, meta)
	return setmetatable({__t = {[s] = d}, n = 1}, meta)
end

setmetatable(Type, {__call = function(self, d)
	local s = getTypeString(d)
	if s == 'object' then
		parseObject(d)
		return new(s, d, self)
	elseif s == 'array' then
		parseArray(d)
		return new(s, d, self)
	else
		return new(s, true, self)
	end
end})

function Type:has(value)
	return not not self.__t[value]
end

function Type:getObject()
	return self.__t['object']
end

function Type:getArray()
	return self.__t['array']
end

function Type:add(d)
	self.n = self.n + 1
	local str = getTypeString(d)
	if str == 'object' then
		local dest = self:getObject()
		if dest then
			mergeObject(dest, d)
		else
			parseObject(d)
			self.__t['object'] = d
		end
	elseif str == 'array' then
		local dest = self:getArray()
		if dest then
			mergeArray(dest, d)
		else
			parseArray(d)
			self.__t['array'] = d
		end
	else
		if not self:has(str) then
			self.__t[str] = true
		end
	end
end

local function indent(n)
	return string.rep(' ', n * 4)
end

local function writeObject(f, obj, n)
	f:write('{\n')
	local keys = {}
	for k in pairs(obj) do
		table.insert(keys, k)
	end
	table.sort(keys)
	for _, k in ipairs(keys) do
		local v = obj[k]
		f:write(indent(n + 1), k, ' : ')
		v:writePretty(f, n + 1)
		f:write('\n')
	end
	f:write(indent(n), '}')
end

local function writeArray(f, arr, n)
	f:write('[\n')
	for _, v in ipairs(arr) do
		f:write(indent(n + 1))
		v:writePretty(f, n + 1)
		f:write('\n')
	end
	f:write(indent(n), ']')
end

function Type:writePretty(f, n)
	n = n or 0
	local i = 1
	for s, v in pairs(self.__t) do
		if i > 1 then
			f:write(' or ')
		end
		if s == 'object' then
			writeObject(f, v, n)
		elseif s == 'array' then
			writeArray(f, v, n)
		elseif v == true then
			f:write(s)
		end
		i = i + 1
	end
end

return Type
