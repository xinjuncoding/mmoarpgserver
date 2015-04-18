--
-- 竞技场服务模块
-- 
-- 竞技场的排行榜放在 namespace db 上
--
-- 竞技场的计算热点在于发生挑战时的战斗计算，所以需要启动多个slave去分担这些计算量
--

local skynet  = require "skynetex"
local cluster = require "cluster"

local slave = {}
local balance = 1
local lock = {}

local command = {}

-- src vs dst
function command.challenge( src, dst )
	if lock[src] or lock[dst] then 
		return 
	end
	lock[src] = true
	lock[dst] = true

	local s = slave[balance]
	balance = balance + 1
	if balance > #slave then
		balance = 1
	end

	local win = skynet.call(s, "lua", src, dst)

	lock[src] = nil
	lock[dst] = nil

	return win
end


local function launch_slave()
	local function challenge(src, dst)
		-- 在做真正的战斗计算逻辑，判断胜负，返回获胜一方
		-- ...

		-- for test 
		local win = src 

		if win == src then 
			-- 决定胜负之后，如果挑战成功，则交换双方排行榜位置
			skynet.call(".namespace_db", "lua", "athletic_exchange_rank", src, dst)
		end
		
		return win
	end

	local function ret_pack(ok, err, ...)
		if ok then
			skynet.ret(skynet.pack(err, ...))
		else
			error(err)
		end
	end

	skynet.dispatch("lua", function(_,_,...)
		ret_pack(pcall(challenge, ...))
	end)
end

local function launch_master( )
	skynet.dispatch("lua", function(session, address, cmd, ...)
		local f = command[cmd]
		if f then
			skynet.ret(skynet.pack(f(...)))
		else
			error(string.format("Unknown command %s", tostring(cmd)))
		end
	end)
	skynet.register ".athleticserver"

	for i=1,10 do
		table.insert(slave, skynet.newservice(SERVICE_NAME))
	end
end

skynet.start(function()
	local athleticmaster = skynet.localname(".athleticserver")
	if athleticmaster then 
		launch_slave()
	else
		launch_master()
	end
end)
