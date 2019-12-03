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
	local ret = setmetatable({__t = {}}, self)
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
		for i = 1, #arr do
			dest:add(arr[i])
		end
	else
		dest = Type(arr[1])
		for i = 2, #arr do
			dest:add(arr[i])
		end
		self.__t['array'] = dest
	end
end

function Type:addNumber(num)
	local dest = self.__t['number']
	if dest then
		dest.min = math.min(dest.min, num)
		dest.max = math.max(dest.max, num)
	else
		self.__t['number'] = {
			min = num,
			max = num,
		}
	end
end

function Type:addString(str)
	local len = #str
	local dest = self.__t['string']
	if dest then
		dest.min = math.min(dest.min, len)
		dest.max = math.max(dest.max, len)
	else
		self.__t['string'] = {
			min = len,
			max = len,
		}
	end
end

function Type:add(d)
	local str = getTypeString(d)
	if str == 'object' then
		return self:addObject(d)
	elseif str == 'array' then
		return self:addArray(d)
	elseif str == 'number' then
		return self:addNumber(d)
	elseif str == 'string' then
		return self:addString(d)
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
		f:write(indent(n + 1), k, ' : ')
		obj[k]:writePretty(f, n + 1)
		f:write('\n')
	end
	f:write(indent(n), '}')
end

local function writeArray(f, arr, n)
	f:write('[\n')
	f:write(indent(n + 1))
	arr:writePretty(f, n + 1)
	f:write('\n')
	f:write(indent(n), ']')
end

local function writeNumber(f, num)
	return f:write(string.format('number [%s, %s]', num.min, num.max))
end

local function writeString(f, str)
	return f:write(string.format('string [%s, %s]', str.min, str.max))
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
		elseif s == 'number' then
			writeNumber(f, v)
		elseif s == 'string' then
			writeString(f, v)
		else
			f:write(s)
		end
		i = i + 1
	end
end

return Type
