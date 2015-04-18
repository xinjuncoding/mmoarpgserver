
-- 
-- 怪物模块
--

local skynet = require "skynetex"
local cluster = require "cluster"

local monster = {}
local player_list = {} -- 视野范围内的玩家列表

function monster.new(aoi, command, id, x, y)
	local data = {}
	data.aoi   = aoi
	data.command = command
	data.model = "wm"
	data.objid = "M_"..id
	data.id  = tonumber(id)
	data.job = 1
	data.x   = tonumber(x)
	data.y   = tonumber(y) 
	data.oriend 	= 1
	data.attack_id  = 0
	data.action_id  = 0
	data.dress_id   = 0
	data.dst 		= 10
	data.ismonster  = true
	data.isnpc 		= false
	data.isplayer 	= false
	harborname		= ""
	address			= 0

	local mon = setmetatable( data, { __index = monster } )
	mon:init()

	return mon 
end

function monster:init( )

end

function monster:get_obj( )
	return {
		model 		= self.model,
		objid 		= self.objid,
		id 			= math.tointeger(self.id),
		job			= math.tointeger(self.job),
		x 			= math.tointeger(self.x),
		y 			= math.tointeger(self.y),
		oriend 		= math.tointeger(self.oriend),
		attack_id 	= math.tointeger(self.attack_id),
		action_id	= math.tointeger(self.action_id),
		dress_id 	= math.tointeger(self.dress_id),
		dst 		= math.tointeger(self.dst),
		isnpc 		= self.isnpc,
		ismonster 	= self.ismonster,
		isplayer 	= self.isplayer,
		harborname	= self.harborname,
		address		= self.address,
	}
end

-- 有玩家进入视野
function monster:enter_field( player )
	assert(not player_list[player.objid])
	player_list[player.objid] = player
	cluster.call(player.harborname, player.address, "call_player", "monster_player_enter", self.objid, self.id )
end

-- 推出视野
function monster:exit_field( player )
	assert(player_list[player.objid])
	player_list[player.objid] = nil
	cluster.call(player.harborname, player.address, "call_player", "monster_player_exit", self.objid, self.id )
end






return monster
