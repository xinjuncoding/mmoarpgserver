--
-- a simple global event server, you can listen and dispathch a event
--
-- provide global broadcast 
--

local skynet = require "skynetex"
local cluster = require "cluster"

local command = {}

local event_list = {}

function command.publish( event, ... )
	if not event_list[event] then 
		return
	end
	
	for node, addr_list in pairs(event_list[event]) do
		for address, cmd in pairs(addr_list) do 
			--addr_list[addr_list] = nil
			cluster.call(node, address, cmd, event, ... )
		end
	end

end

function command.subscribe( event, node, address, cmd )
	if not event_list[event] then 
		event_list[event] = {}
	end

	if not event_list[event][node] then 
		event_list[event][node] = {}
	end

	event_list[event][node][address] = cmd
end

function command.unsubscribe( event, node, address )
	if not event_list[event] or not event_list[event][node] then 
		error(string.format("[.agentevent] find not this event %s, %s, %s", event, node, address))
	end

	event_list[event][node][address] = nil
end

skynet.start(function()
	skynet.dispatch("lua", function(session, address, cmd, ...)
		local f = command[cmd]
		if f then
			skynet.ret(skynet.pack(f(...)))
		else
			error(string.format("[.agentevent] can not find command %s", cmd))
		end
	end)
	skynet.register ".eventserver"
end)



