

local skynet = require "skynetex"
require "skynet.manager"
local cluster = require "cluster"
local eventlistener = require "eventlistener"

local activity = {}


function activity.start( handle )
	local function activity_start( activity_id, ... )
		if handle.activity_id == activity_id then 
			handle.handle_start( ... )
		end
	end

	local function activity_end( activity_id, ... )
		if handle.activity_id == activity_id then 
			handle.handle_end( ... )
		end
	end

	local function pre_begin( activity_id, ... )
		if handle.activity_id == activity_id then 
			handle.handle_pre_begin( ... )
		end
	end

	local function pre_stop( ... )
		if handle.activity_id == activity_id then 
			handle.handle_pre_stop( ... )
		end
	end

	skynet.start(function()
		skynet.dispatch("lua", function(session, address, cmd, ...)
			local f = handle[cmd]
			if f then
				skynet.ret(skynet.pack(f(...)))
			elseif eventlistener[cmd] then 
				eventlistener[cmd](...)
			else
				error(string.format("Unknown command %s", tostring(cmd)))
			end
		end)
		skynet.register(handle.activity_name)

		eventlistener.subscribe_event("activity_start", 	activity_start)
		eventlistener.subscribe_event("activity_end", 		activity_end)
		eventlistener.subscribe_event("activity_pre_begin", pre_begin)
		eventlistener.subscribe_event("activity_pre_stop", 	pre_stop)
	end)

end


return activity



