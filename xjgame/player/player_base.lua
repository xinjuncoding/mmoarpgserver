
local cluster = require "cluster"
local skynet = require "skynetex"
local M = skynet.module("player")


-- 初始化
function M.__init__( )
	self.server_id_ = skynet.getenv("serverid")
	self.role_idlist_ 		= {}
	self.player_id_ 		= 0
	self.player_name_ 		= ""
	self.job_ 				= 0
	self.vip_ 				= 0
	self.diamond_ 			= 0
	self.paydiamond_ 		= 0
	self.binddiamond_ 		= 0
	self.gold_ 				= 0
	self.silver_ 			= 0
	self.power_ 			= 0
	self.scene_id_ 			= 0
	self.pos_y_ 			= 0
	self.pos_x_ 			= 0
	self.createtime_ 		= 0
	self.createip_ 			= ""
	self.channel_id_ 		= 0
	self.last_logintime_ 	= 0
	self.last_logouttime_ 	= 0
	self.last_loginip_ 		= ""

	self.load_flag_  		= false  -- 是否已经加载角色数据

	self.aoi_obj_list_ = {}
end

-- 离线的时候移除侦听
function M.base_unsubscribe_events( )
	if self.event_athlect_changed_ then 
		self.eventlistener_.unsubscribe_event("athletic_changed_"..self.player_id_, self.event_athlect_changed_)
		self.event_athlect_changed_ = nil
	end

	-- 其他事件移除在此继续添加
	-- ...
end

-- 玩家登陆之后执行
function M.base_subscribe_events( )
	-- 贞听竞技场上谁挑战我
	-- 事件源是 player_athletic 的 athletic_change 协议接口
	local function changed_cb( changer, is_win )
		print(string.format("[event dispatch ], %s change %s   is_win: %s", changer, self.player_id_, is_win) )
	end
	self.event_athlect_changed_ = self.eventlistener_.subscribe_event("athletic_changed_"..self.player_id_, changed_cb )

	-- 其他侦听事件在此继续添加
	-- ...
end