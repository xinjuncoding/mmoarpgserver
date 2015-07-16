local msgserver = require "msgserverd"
local crypt = require "crypt"
local skynet = require "skynetex"
require "skynet.manager"
local cluster = require "cluster"

local harborname = skynet.getenv("harborname")
local loginservice 

local server = {}
local users = {}
local username_map = {}
local internal_id = 0

-- login server disallow multi login, so login_handler never be reentry
-- call by login server
function server.login_handler(uid, secret, addr)
	if users[uid] then
		error(string.format("%s is already login", uid))
	end

	internal_id = internal_id + 1
	local username = msgserver.username(uid, internal_id, servername)

	-- you can use a pool to alloc new agent
	local agent = skynet.call(".agentpool", "lua", "get") --skynet.newservice "msgagent"
	local u = {
		username = username,
		agent = agent,
		uid = uid,
		subid = internal_id,
	}

	-- trash subid (no used)
	skynet.call(agent, "lua", "login", uid, internal_id, secret, addr)

	users[uid] = u
	username_map[username] = u

	msgserver.login(username, secret)

	-- you should return unique subid
	return internal_id
end

-- call by agent
function server.logout_handler(uid, subid)
	local u = users[uid]
	if u then
		local username = msgserver.username(uid, subid, servername)
		assert(u.username == username)
		msgserver.logout(u.username)
		users[uid] = nil
		username_map[u.username] = nil
		skynet.call(loginservice, "lua", "logout",uid, subid)

		-- recycle agent
		skynet.call(".agentpool", "lua", "recycle", u.agent)
	end
end

-- call by login server
function server.kick_handler(uid, subid)
	local u = users[uid]
	if u then
		local username = msgserver.username(uid, subid, servername)
		assert(u.username == username)
		-- NOTICE: logout may call skynet.exit, so you should use pcall.
		pcall(skynet.call, u.agent, "lua", "logout")
	end
end

-- call by self (when socket disconnect)
function server.disconnect_handler(username)
	local u = username_map[username]
	if u then
		-- NOTICE: afk may call skynet.exit or logout, so you should use pcall.
		pcall(skynet.call, u.agent, "lua", "afk")
	end
end

-- call by self (when recv a request from client)
function server.request_handler(username, msg, sz)
	local u = username_map[username]
	return skynet.tostring(skynet.rawcall(u.agent, "client", msg, sz))
end

-- call by self (when gate open)
function server.register_handler(name)
	servername = name
	loginservice =  cluster.proxy("login", ".login_master") 
	skynet.call(loginservice, "lua", "register_gate", servername, skynet.self(), harborname)
end

-- call by self (when after auth)
function server.auth_handler(username, fd, addr)
	local u = username_map[username]
	pcall(skynet.call, u.agent, "lua", "cbk", fd, addr)
end

msgserver.start(server)

