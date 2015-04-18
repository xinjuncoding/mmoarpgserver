
local cluster = require "cluster"
local skynet = require "skynetex"
local M = skynet.module("player")

-- 离线时保存相关数据, 大部分数据都是实时保持的，所以在玩家连接坏掉之后缓存的数据都是早已经保存到数据库，这个接口
-- 只需要保持离线时间相关数据，以及清理定时器等工作
function M.logout_save_data( )
	-- 移除事件的侦听
	M.base_unsubscribe_events( )

	-- 退出场景
	M.scene_exit()
	
	-- 清除数据
	M.__init__()
end

-- 登陆时加载角色列表
function M.login_load_rolelist( )
	-- 获取当前账号的角色列表
	self.role_idlist_ = skynet.call(".namespace_db", "lua", "np_get_role_list", self.account_, self.server_id_)	
end

-- 前端请求获取角色列表
function M.login_get_rolelist( args )
	local ret = { rolelist = {} }
	for _, player_id in pairs(self.role_idlist_) do 
		local data = {}
		local dbserver = get_character_dbname(player_id)
		-- 加载玩家基本信息
		local info = skynet.call(dbserver, "lua", "ct_get_role_info", player_id)

		data.player_id 	 = tonumber(player_id)
		data.player_name = info.name
		data.level 		 = tonumber(info.level)
		data.job		 = tonumber(info.job)

		table.insert(ret.rolelist, data)
	end
	
	return ret
end

-- 创建角色 
function M.login_create_role( args )
	local player_name = args.player_name 
	local job 	= args.job 
	local player_id = skynet.call(".namespace_db", "lua", "np_create_role", self.account_, player_name, self.server_id_)
	local dbserver = get_character_dbname(player_id)
	local ret = skynet.call(dbserver, "lua", "ct_create_role", self.account_, player_id, player_name, job, self.loginip_, 1)

	if ret > 0 then 
		M.login_load_rolelist()
	end

	return { result = ret }
end

-- 加载角色数据
function M.login_load_playerinfo( args )
	assert(self.load_flag_==false)

	local player_id = assert(args.player_id)
	if not self.role_idlist_[player_id] then 
		return { result = -1 }
	end

	-- 默认取第一个初始化，这个在正式游戏上可以用户选择之后再初始化
	self.player_id_ = player_id
	assert(self.player_id_ > 0)
	self.load_flag_ = true

	self.dbserver_ = get_character_dbname(self.player_id_)

	-- 加载玩家基本信息
	local info = skynet.call(self.dbserver_, "lua", "ct_get_role_info", self.player_id_)
	self.player_name_ 	= info.name
	self.job_ 			= info.job
	self.vip_ 			= info.vip
	self.diamond_ 		= info.diamond or 0
	self.paydiamond_ 	= info.paydiamond or 0
	self.binddiamond_ 	= info.binddiamond or 0
	self.gold_ 			= info.gold or 0
	self.silver_ 		= info.silver or 0
	self.power_ 		= info.power or 0
	self.scene_id_ 		= info.scene_id or 1
	self.pos_y_ 		= info.pos_y or 1
	self.pos_x_ 		= info.pos_x or 1
	self.createtime_ 	= info.createtime or 0
	self.createip_ 			= info.createip or ""
	self.channel_id_ 		= info.channel_id or 1
	self.last_logintime_ 	= info.logintime or 0
	self.last_logouttime_ 	= info.logouttime or 0
	self.last_loginip_ 		= info.loginip or ""
	
	-- 加载属性
	-- ...

	-- 加载物品道具
	-- ...

	-- ...

	-- 注册要侦听的事件
	M.base_subscribe_events( )

	return { result = 0 }
end

-- 客户端获取玩家数据接口
function M.login_get_player_info( )
	return {
		player_name = self.player_name_, 
		vip 		= tonumber(self.vip_), 
		diamond 	= tonumber(self.diamond_),
		paydiamond 	= tonumber(self.paydiamond_),
		binddiamond = tonumber(self.binddiamond_),
		gold 		= tonumber(self.gold_),
		silver 		= tonumber(self.silver_),
		power		= tonumber(self.power_),
		scene_id	= tonumber(self.scene_id_),
		pos_y		= tonumber(self.pos_y_),
		pos_x 		= tonumber(self.pos_x_),
		createtime	= tonumber(self.createtime_),
	}
end


