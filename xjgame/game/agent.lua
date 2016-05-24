local skynet  = require "skynetex"
local cluster = require "cluster"
local netpack = require "netpack"
local socket  = require "socket"
local sproto  = require "sproto"
local conf    = require "conf"
local netpack = require "netpack"
local proto   = require "xjproto"
local sprotoloader  = require "sprotoloader"
local eventlistener = require "eventlistener"

require "player/player_base"
require "player.player_login"
require "player.player_athletic"
require "player.player_copy"
require "player.player_scene"
require "player.player_npc"
require "player.player_aoi"
require "player.player_monster"

local brokecachelen = ...   -- 连接端口之后agent保持时长，在runconfig里配置

local host  = nil
send_request = nil


skynet.register_protocol {
	name = "client",
	id = skynet.PTYPE_CLIENT,
	unpack = function (msg, sz)
		return host:dispatch(msg, sz)
	end,
}

local CMD = {}

self = {}    -- 玩家的大部分数据将存放在这个self table里
self.client_fd_ = 0
self.eventlistener_ = eventlistener

-- 确定玩家数据存在哪个 character db 里
local characterdb_num = skynet.getenv("characterdb_num") 
function get_character_dbname( player_id )
	local index = player_id%characterdb_num
	if index == 0 then 
		index = characterdb_num
	end
	return ".character_db"..index
end

-- 此接口用于发送服务端发送数据包给客户端
function send_package(pack)
	if self.client_fd_ <= 0 then 
		return
	end

	local session = 0
	pack = pack..'\1'..string.pack(">I4", session)

	local size = #pack 
	local package = string.pack(">I2", size)..pack

	socket.write(self.client_fd_, package)
end

function send_to_client( name, args )
	send_package( send_request(name, args) )
end

local function logout()
	-- 离线时保持相关数据
	player.logout_save_data()
	if self.gate_ then
		skynet.call(self.gate_, "lua", "logout", self.userid_, self.subid_)
	end

	if self.logout_timer_ then 
		skynet.del_timer(self.logout_timer_)
		self.logout_timer_ = nil
	end

	-- skynet.exit()
end

function CMD.login(source, uid, sid, secret, addr)
	skynet.error(string.format("%s is login", uid))
	player.__init__()

	self.gate_ = source
	self.userid_ = uid
	self.account_ = uid
	self.subid_ = sid
	
	self.loginip_ = addr
	self.logintime_ = os.time()

	-- 在此加载数据库，加载玩家角色列表
	player.login_load_rolelist()

	-- 但设定了一定的时限，超过时限还没回来的话即刻当作离线退出处理
	if self.logout_timer_ then 
		skynet.del_timer(self.logout_timer_)
		self.logout_timer_ = nil
	end
	self.logout_timer_ = skynet.add_timer(brokecachelen*100, logout)
end

function CMD.logout(source)
	-- NOTICE: The logout MAY be reentry
	skynet.error(string.format("%s is logout", self.userid_))
	logout()
end

function CMD.afk(source)
	-- 连接中断了，不意味着玩家马上离线，有可能稍后会马上回来
	skynet.error(string.format("AFK"))
	self.client_fd_ = 0

	-- 但设定了一定的时限，超过时限还没回来的话即刻当作离线退出处理
	if self.logout_timer_ then 
		skynet.del_timer(self.logout_timer_)
		self.logout_timer_ = nil
	end
	self.logout_timer_ = skynet.add_timer(brokecachelen*100, logout)
end

-- 连接修复之后的回调
function CMD.cbk( source, fd, addr )
	-- the connect is come back
	skynet.error(string.format("CBK"))
	self.client_fd_ = fd

	if self.logout_timer_ then 
		skynet.del_timer(self.logout_timer_)
		self.logout_timer_ = nil
	end
end

function CMD.call_player( source, cmd, ...)
	local f = assert(player[cmd])
	return f(...)
end

function request(type, name, args, response)
	local f = assert(player[name])
	local r = f(args)

	if response then
		return response(r)
	end
end

skynet.start(function()
	-- 创建协议数据
	-- host = sproto.new(proto.c2s):host "package"
	-- send_request = host:attach(sproto.new(proto.s2c))
	host = sprotoloader.load(1):host "package"
	send_request = host:attach(sprotoloader.load(2))

	-- 初始化玩家代理数据
	player.__init__()

	skynet.dispatch("lua", function(session, source, command, ...)
		local f = CMD[command]
		if f then 
			skynet.ret(skynet.pack(f(source, ...)))
		elseif eventlistener[command] then 
			eventlistener[command](...)
		else 
			error(string.format("[agent] has not find the command: %s", command))
		end
	end)

	-- c2s rpc 
	skynet.dispatch("client", function(_,_, ...)
		local result  = request(...) --pcall(request, ...)
		skynet.ret(result)
	end)

	-- 同步配置表数据
    local t = skynet.call(".luaconfig", "lua", "GET")
    resmng = conf.box(t)
    print("[agent] test conf:", resmng.ITEM_WEAPON_1, resmng.propItem[resmng.ITEM_WEAPON_2].Name)

	-- test 心跳包
	skynet.fork(function()
		while true do
			send_package(send_request "heartbeat")
			skynet.sleep(300)
		end
	end)

	-- 测试事件订阅
	local function eventtest(...)
		print("**************  test subscribe event success, ", skynet.self(), ...)
	end
	eventlistener.subscribe_event("test", eventtest)
end)
