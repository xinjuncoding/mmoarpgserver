
--
-- 场景基础服务单元
--

local skynet  = require "skynetex"
local cluster = require "cluster"
local conf    = require "conf"
local aoi 	  = require "aoidriver"
local monster = require "monster"
local npc 	  = require "npc"

local scene_id, line_id = ...
local service_name = ".sence_"..scene_id.."_"..line_id

local command = {}

local propdata
local obj_list = {}

local online_num = 0


local function enterfunc( sobj, tobj )
	if tobj.isplayer then 
		-- 让agent同步前端数据 
		local tmpobj = sobj 
		if not sobj.isplayer then
			tmpobj = sobj:get_obj()
		end
		cluster.call(tobj.harborname, tobj.address, "call_player", "aoi_enter", tmpobj )
	elseif tobj.isnpc and sobj.isplayer then
		-- 触发NPC的AI
		tobj:enter_field( sobj )
	elseif tobj.ismonster and sobj.isplayer then 
		-- 触发怪物的AI
		tobj:enter_field( sobj )
	end
end

local function exitfunc( sobj, tobj )
	if tobj.isplayer then 
		-- 让agent同步前端数据 
		if not sobj.isplayer then
			tmpobj = sobj:get_obj()
		end
		cluster.call(tobj.harborname, tobj.address, "call_player", "aoi_exit", tmpobj )
	elseif tobj.isnpc and sobj.isplayer then
		-- 触发NPC的AI
		tobj:exit_field( sobj )
	elseif tobj.ismonster and sobj.isplayer then 
		-- 触发怪物的AI
		tobj:exit_field( sobj )
	end
end

local function movefunc( sobj, tobj )
	if tobj.isplayer then 
		-- 让agent同步前端数据 
		if not sobj.isplayer then
			tmpobj = sobj:get_obj()
		end
		cluster.call(tobj.harborname, tobj.address, "call_player", "aoi_update", tmpobj )
	elseif tobj.isnpc and sobj.isplayer then
		-- 触发NPC的AI

	elseif tobj.ismonster and sobj.isplayer then 
		-- 触发怪物的AI

	end
end 

local function attackfunc( sobj, tobj )
	if tobj.isplayer and sobj.ismonster then 
		-- 玩家被怪物攻击
		cluster.call(tobj.harborname, tobj.address, "call_player", "aoi_update", sobj:get_obj() )
	elseif tobj.isnpc and sobj.isplayer then
		-- 触发NPC的AI

	elseif tobj.ismonster and sobj.isplayer then 
		-- 怪物被玩家攻击

	end
end 

-- 进入场景 
function command.enter_scene( player_id, job, harborname, addr, x, y, oriend )
	local pobj = {
		objid 		= tostring(player_id), 
		id 			= math.tointeger(player_id),
		job			= math.tointeger(job),
		model 		= "wm", 
		x  			= math.tointeger(x),
		y  			= math.tointeger(y),
		oriend		= math.tointeger(oriend),
		dst 		= 30, -- 观察半径
		attack_id 	= 0,
		dress_id  	= 0,
		action_id   = 0,
		isplayer 	= true,
		ismonster 	= false,
		isnpc 		= false,
		harborname 	= harborname,
		address 	= addr,
	} 
	obj_list[pobj.objid] = pobj
	online_num = online_num + 1

	return aoi.enter(pobj, enterfunc)
end

-- 退出场景
function command.exit_scene( player_id )
	local pobj = assert(obj_list[tostring(player_id)])
	obj_list[player_id] = nil
	aoi.remove(pobj, exitfunc)

	online_num = online_num - 1
	assert(online_num >= 0, string.format("online_num:%d", online_num))
end

-- 行走
function command.move( player_id, x, y )
	local pobj = assert(obj_list[player_id])
	pobj.x = x
	pobj.y = y

	-- 更新的时候有可能产生新增玩家进入视野, 同步到前端
	return aoi.update(pobj, movefunc, enterfunc, exitfunc)

end

-- 攻击
-- attack_id: 攻击的对象, action_id: 所做的攻击动作
function command.attack( obj_id, attack_id, action_id )
	local pobj = assert(obj_list[obj_id])
	pobj.attack_id = attack_id
	pobj.action_id = action_id
	-- 更新的时候有可能产生新增玩家进入视野, 需要同步到前端
	return aoi.update(pobj, attackfunc, enterfunc, exitfunc)
end

-- 初始化场景地图数据、怪物、npc等
local function __init__( )
	-- 获取场景配置表
	propdata = resmng.propScene[tonumber(scene_id)]
	aoi.init(propdata.width, propdata.height)

	-- 加载npc
	for _, v in pairs(propdata.npcs) do 
		local n = npc.new(aoi, command, v[1],v[2],v[3])
		obj_list[n.objid] = n

		aoi.enter(n, enterfunc)
	end

	-- 加载monster
	for _, v in pairs(propdata.monsters) do 
		local m = monster.new(aoi, command, v[1], v[2], v[3])
		obj_list[m.objid] = m

		aoi.enter(m, enterfunc)
	end

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

	__init__()
end)

