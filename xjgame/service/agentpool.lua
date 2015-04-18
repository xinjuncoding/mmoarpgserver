local skynet = require "skynetex"

local CMD = {}

local pool = {}	 -- the least agent
local agentlist = {} -- all of agent, include dispatched

local agentname, maxnum, recyremove, brokecachelen = ...

local function __pool_init__( )
	for i=1, maxnum do 
		local agent = skynet.newservice(agentname, brokecachelen)
		table.insert(pool, agent)
		agentlist[agent] = agent
	end
end

function CMD.get( )
	local agent = table.remove(pool)
	if not agent then 
		agent = assert(skynet.newservice(agentname, brokecachelen))
		agentlist[agent] = agent
	end
	
	return agent
end

function CMD.recycle( agent )
	assert(agent)
	
	if recyremove == 1 and #pool > maxnum then
		agentlist[agent] = nil 
		skynet.kill(agent)
	else
		table.insert(pool, 1, agent)
	end
end

skynet.start(function()
	
	skynet.dispatch("lua", function (_, address, cmd, ...)
		local f = assert(CMD[cmd])
		skynet.ret(skynet.pack(f(...)))
	end)

	skynet.register(".agentpool")

	__pool_init__()
end)
