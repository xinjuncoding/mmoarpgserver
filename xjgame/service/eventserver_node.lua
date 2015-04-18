

local skynet = require "skynetex"
local cluster = require "cluster"

local harborname = skynet.getenv("harborname")

local command = {}
local event_list = {}

function command.publish( event, ... )
	if not event_list[event] then 
		return
	end

	for address, cmd in pairs(event_list[event]) do 
		skynet.send(address, "lua", cmd, event, ... )
	end
end

function command.subscribe( event, address, cmd )
	if not event_list[event] then 
		event_list[event] = {}
		cluster.call( "login", ".eventserver", "subscribe", event, harborname, skynet.self(), "publish")
	end
	
	event_list[event][address] = cmd
end

function command.unsubscribe( event, address )
	if not event_list[event] then 
		error(string.format("[.agentevent] find not this event %s, %s, %s", event, address))
	end

	event_list[event][address] = nil
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
	skynet.register ".eventserver_node"

end)



