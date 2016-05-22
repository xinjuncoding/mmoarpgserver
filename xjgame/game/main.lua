local skynet = require "skynetex"
local cluster = require "cluster"
local conf    = require "conf"

local harborname = skynet.getenv("harborname")
local runconfig = require(skynet.getenv("runconfig"))
local nodeconf = runconfig[harborname]

skynet.start(function()
	-- 打开集群机制
	cluster.open(harborname)
	-- 启动控制台
	skynet.uniqueservice("debugconsole", nodeconf.consoleport)
	skynet.uniqueservice("luaconf")
	
	-- 
	skynet.uniqueservice("xjprotoloader")
	
	if harborname == "login" then 
		-- 启动全局消息派发
		skynet.uniqueservice("eventserver")
		skynet.uniqueservice("eventserver_node")

		-- 启动活动控制模块，启动于eventserver之后
		skynet.uniqueservice("activityserver")
		-- 启动各个子活动, 子活动全局唯一
		skynet.uniqueservice(true, "activity/activity_doublepower")
		skynet.uniqueservice(true, "activity/activity_moneytree")
		skynet.uniqueservice(true, "activity/activity_nationalday")
		skynet.uniqueservice(true, "activity/activity_worldboss")
		-- 启动竞技场服务
		skynet.newservice("athleticserver")

		-- 启动场景分线
		require "data/propScene"
		for k,v in pairs(propScene) do 
			skynet.newservice("scene/sceneblance", k, 20, 20)
		end
		
		-- 启动登陆服务器
		skynet.newservice("logind", nodeconf.conf.name, nodeconf.conf.host, nodeconf.conf.port, nodeconf.conf.instance)
	else 
		skynet.uniqueservice("eventserver_node")
	end

	-- 启动DB服务， 一个全局命名DB, 若干个角色数据服务
	skynet.newservice("database/redis_namespace")
	for index, _ in pairs(runconfig.database.character) do 
		skynet.newservice("database/redis_character", index)
	end
	skynet.setenv("characterdb_num", #runconfig.database.character)

	-- 启动agent池和若干个网关gate
	skynet.uniqueservice("agentpool", nodeconf.agentpool.name, nodeconf.agentpool.maxnum, nodeconf.agentpool.recyremove, runconfig.brokecachelen)
	for _, conf in pairs(nodeconf.gate_list) do 
		local gate = skynet.newservice("gated")
		skynet.call(gate, "lua", "open" , conf )
	end

	-- test eventserver
	cluster.call("login", ".eventserver", "publish", "test", "hehe", true, false)

end)


