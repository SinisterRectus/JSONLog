local fs = require('fs')
local json = require('json')
local timer = require('timer')
local Type = require('./Type')

local JSONLog = {}
JSONLog.__index = JSONLog

local stateExt = '_state.json'
local prettyExt = '_pretty.txt'

local function applyTypeMeta(tbl)
	for _, v in pairs(tbl) do
		if type(v) == 'table' then
			if v.__t then -- assuming that all Type objects and only Type objects have __t property
				setmetatable(v, Type)
			end
			applyTypeMeta(v, Type)
		end
	end
end

setmetatable(JSONLog, {__call = function(self, name)
	local f = fs.readFileSync(name .. stateExt)
	local data = f and json.decode(f, 1, json.null) or {}
	applyTypeMeta(data)
	return setmetatable({name = name, data = data}, self)
end})

function JSONLog:add(k, v)
	self.new = true
	if self.data[k] then
		self.data[k]:add(v)
	else
		self.data[k] = Type(v)
	end
end

function JSONLog:dumpState()
	return fs.writeFileSync(self.name .. stateExt, json.encode(self.data))
end

function JSONLog:dumpPretty()
	local f = assert(io.open(self.name .. prettyExt, 'w'))
	local keys = {}
	for k in pairs(self.data) do
		table.insert(keys, k)
	end
	table.sort(keys)
	for _, k in ipairs(keys) do
		local v = self.data[k]
		f:write(k, '\n')
		v:writePretty(f)
		f:write('\n\n')
	end
	f:close()
end

function JSONLog:startLoop(ms)
	self:stopLoop()
	self.loop = timer.setInterval(ms, function()
		if self.new then
			self:dumpState()
			self:dumpPretty()
		end
		self.new = nil
	end)
end

function JSONLog:stopLoop()
	if self.loop then
		timer.clearInterval(self.loop)
		self.loop = nil
	end
end

return JSONLog
