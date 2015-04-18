
-- 
-- 场景分线逻辑, 控制分线负载分配
--

local skynet = require "skynetex"
local cluster = require "cluster"
local conf    = require "conf"

-- 场景id、有多少个分线、每个分线最大容纳多少个玩家
local scene_id, line_num, line_max = ...
local service_name = ".scene_blance_"..scene_id
line_max = tonumber(line_max)

local command = {}
local blance = {}

function command.get_scene_line( )
	local line = 1
	local warn = true
	for i=1, line_num do 
		if blance[i] < line_max then 
			line = i
			blance[line] = blance[line] + 1
			warn = false
			break
		end
	end

	-- 如果每条分线的在线人数都超过设定的界限了，那么继续提高界限，以防人数过多的时候无法登陆场景
	if warn then 
		line_max = line_max + 1
	end

	return ".sence_"..scene_id.."_"..line
end

skynet.start(function()
	skynet.dispatch("lua", function(session, address, cmd, ...)
		local f = command[cmd]
		if f then
			skynet.ret(skynet.pack(f(...)))
		else
			error(string.format("Unknown command %s", tostring(cmd)))
		end
	end)
	skynet.register(service_name)

	-- 同步配置表数据
    local t = skynet.call(".luaconfig", "lua", "GET")
    resmng = conf.box(t)

    for i=1, line_num do 
    	blance[i] = 0
    	skynet.newservice("scene/sceneserver", scene_id, i)
    end
end)
