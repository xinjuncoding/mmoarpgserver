

local skynet = require "skynetex"
local M = skynet.module("player")

-- 玩家进入怪物视野内，触发的ai逻辑由此接口完成
function M.monster_player_enter( monster_objid, monster_id )
	
end

-- 玩家离开怪物视野，触发的ai逻辑由此接口完成
function M.monster_player_exit( monster_objid, monster_id )
	
end