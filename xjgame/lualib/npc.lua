

-- 
-- NPC模块
--

local skynet = require "skynetex"
local cluster = require "cluster"

local npc = {}
local player_list = {} -- 视野范围内的玩家列表

function npc.new(aoi, command, id, x, y)
	local data = {}
	data.aoi   = aoi
	data.command  = command
	data.model = "wm"
	data.objid = "N_"..id  
	data.id  = math.tointeger(id)
	data.job = 1
	data.x   = math.tointeger(x)
	data.y   = math.tointeger(y)
	data.oriend 	= 1
	data.attack_id  = 0
	data.action_id  = 0
	data.dress_id   = 0
	data.dst 		= 10
	data.isnpc 		= true
	data.ismonster  = false
	data.isplayer   = false
	harborname		= ""
	address			= 0
	local mon = setmetatable( data, { __index = npc } )
	mon:init()

	return mon 
end

function npc:init( )

end

function npc:get_obj( )
	return {
		model 		= self.model,
		objid 		= self.objid,
		id 			= self.id,
		job			= self.job,
		x 			= self.x,
		y 			= self.y,
		oriend 		= self.oriend,
		attack_id 	= self.attack_id,
		action_id	= self.action_id,
		dress_id 	= self.dress_id,
		dst 		= self.dst,
		isnpc 		= self.isnpc,
		ismonster 	= self.ismonster,
		isplayer 	= self.isplayer,
		harborname	= self.harborname,
		address		= self.address,
	}
end

-- 有玩家进入视野
function npc:enter_field( player )
	assert(not player_list[player.objid])
	player_list[player.objid] = player
	cluster.call(player.harborname, player.address, "call_player", "npc_player_enter", self.objid, self.id )

	print("printdsssssss **********  enter_field")
end

-- 有玩家走出视野
function npc:exit_field( player )
	assert(player_list[player.objid])
	player_list[player.objid] = nil
	cluster.call(player.harborname, player.address, "call_player", "npc_player_exit", self.objid, self.id )
	print("printdsssssss **********  exit_field")
end








return npc
