
local skynet = require "skynetex"
local M = skynet.module("player")

-- 玩家进入npc视野内，触发的ai逻辑由此接口完成
function M.npc_player_enter( npc_objid, npc_id )
	self.talk_npc_ = {npc_objid, npc_id}
	-- 触发与npc的对话逻辑
	-- ...
end

-- 玩家离开npc视野，触发的ai逻辑由此接口完成
function M.npc_player_exit( npc_objid, npc_id )
	-- 清除与npc对话的条件
	self.talk_npc_ = nil
end



