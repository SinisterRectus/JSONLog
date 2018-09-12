# JSONLog

JSON metadata logger and analyzer written in Lua for the Luvit framework.

Initially written for logging Discord WebSocket payloads, but can be used for any [dkjson](http://dkolf.de/src/dkjson-lua.fsl/home)-compatible data.

Work-in-progress.

### Instructions

- Initialize a `JSONLog` object with a log name as its only argument.
- Add a key, value pair to the log with `JSONLog:add(k, v)`
- To cache the log's state for future use, call `JSONLog:dumpState()`. The filename `<name>_state.json` is used.
- To output a human-readable analysis of the logged JSON, call `JSONLog:dumpPretty()`. The filename `<name>_pretty.txt` is used.
- Optionally call `JSONLog:startLoop(ms)` to initilize a loop that periodically calls `JSONLog:dumpState()` and `JSONLog:dumpPretty()`
- Optionally call `JSONLog:stopLoop()` to stop the dump loop.

### Discordia Example

```lua
local discordia = require('../discordia') -- adjust path as necessary
local JSONLog = require('./JSONLog') -- adjust path as necessary
local json = require('json')

local client = discordia.Client()

local log = JSONLog('events')

local ms = discordia.Time.fromSeconds(30):toMilliseconds()
log:startLoop(ms)

client:on('ready', function() return print('ready') end)

client:on('raw', function(str)
	local payload = json.decode(str, 1, json.null)
	if payload.op == 0 then
		log:add(payload.t, payload.d)
	end
end)

client:run('<TOKEN>')
```
