
local cluster = require "cluster"
local skynet = require "skynetex"
local M = skynet.module("player")

local harborname = skynet.getenv("harborname")


-- 协议进入场景
function M.scene_enter( args )
	local scene_id = args.scene_id
	local x = tonumber(args.x)
	local y = tonumber(args.y)

	M.scene_enter_base(scene_id, x, y )
end

-- 进入场景基础借口，不能暴露给前端用户直接调用
function M.scene_enter_base( scene_id, x, y )
	if self.scene_line_ then
		M.scene_exit()
	end
	-- 获取场景分线的服务地址名称
	self.scene_line_ = cluster.call("login", ".scene_blance_"..scene_id, "get_scene_line")
	-- 进入场景，返回场景内同步怪物、玩家
	local maker_list = cluster.call("login", self.scene_line_, "enter_scene", self.player_id_, self.job_, harborname, skynet.self(), x, y )
	-- 同步到客户端
	send_to_client("scene_aoi_list", {obj_list=maker_list})
end

-- 退出场景
function M.scene_exit( )
	if self.scene_line_ then 
		cluster.call("login", self.scene_line_, "exit_scene", self.player_id_ )
		self.scene_line_ = nil
	end
end