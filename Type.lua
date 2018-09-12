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

setmetatable(Type, {__call = function(self, d)
	local ret = setmetatable({__t = {}, n = 0}, self)
	ret:add(d)
	return ret
end})

function Type:addObject(obj)
	local dest = self.__t['object']
	if dest then
		for k, v in pairs(dest) do
			v:add(obj[k])
			obj[k] = nil
		end
		for k, v in pairs(obj) do
			dest[k] = dest[k] or Type(nil)
			dest[k]:add(v)
		end
	else
		for k, v in pairs(obj) do
			obj[k] = Type(v)
		end
		self.__t['object'] = obj
	end
end

function Type:addArray(arr)
	local dest = self.__t['array']
	if dest then
		for _, v in ipairs(arr) do
			dest[1]:add(v)
		end
	else
		arr[1] = Type(arr[1])
		for i = 2, #arr do
			arr[1]:add(arr[i])
			arr[i] = nil
		end
		self.__t['array'] = arr
	end
end

function Type:add(d)
	self.n = self.n + 1
	local str = getTypeString(d)
	if str == 'object' then
		return self:addObject(d)
	elseif str == 'array' then
		return self:addArray(d)
	else
		self.__t[str] = true
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
		else
			f:write(s)
		end
		i = i + 1
	end
end

return Type
