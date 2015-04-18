      
local skynet = require "skynetex"
local M = skynet.module("player")

-- 
-- obj 格式
-- 
-- return {
-- 	model 		= self.model,
-- 	objid 		= self.objid,
-- 	id 			= self.id,
-- 	x 			= self.x,
-- 	y 			= self.y,
-- 	oriend 		= self.oriend,
-- 	attack_id 	= self.attack_id,
--  action_id   = self.action_id,
-- 	dress_id 	= self.dress_id,
-- 	dst 		= self.dst,
-- 	isnpc 		= self.isnpc,
-- 	ismonster 	= self.ismonster,
-- 	isplayer 	= self.isplayer,
-- }

-- aoi视野范围内新增玩家, call by sceneline
function M.aoi_enter( obj )
	self.aoi_obj_list_[obj.objid] = obj

	-- 通过协议同步给前端
	send_to_client("scene_aoi_list", { obj_list={obj} } )
end

-- aoi范围内玩家更新状态, call by sceneline
function M.aoi_update( obj )
	self.aoi_obj_list_[obj.objid] = obj
	
	-- 通过协议同步给前端
	send_to_client("scene_aoi_list", { obj_list={obj} } )
end

-- aoi范围内有玩家离开视野, call by sceneline
function M.aoi_exit( obj )
	self.aoi_obj_list_[obj.objid] = nil

	-- 通过协议同步给前端
	send_to_client("scene_aoi_exit", { objid=obj.objid } )
end

-- 玩家行走移动时调用, call by self
function M.aoi_move( x,y )
	if self.scene_line_ then 
		-- 移动的时候得到一个周围新增object列表，同步到前端
		local update_list = cluster.call("login", self.scene_line_, "move", self.player_id_, x, y )
		send_to_client("scene_aoi_list", { obj_list = update_list } )
	end
end

