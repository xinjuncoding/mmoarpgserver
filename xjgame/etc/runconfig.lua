

return {

	brokecachelen = 5,   -- 玩家链接断开之后保持agent多长时间，超过则清楚agent缓存数据, 单位为秒

	-- 数据库服务配置
	database = {
		-- 全局命名数据库服务， 这些配置最终是作为参赛传入redis驱动里进行初始化数据库服务
		namespace = {
		    host = "127.0.0.1" ,
		    port = 6379,    
		    db = 0 ,
		    --auth = "passwd",
		},

		-- 角色数据库, 有多个
		character = {
			[1] = {
		        host = "127.0.0.1" ,      
		        port = 6379,    
		        db = 1 ,
		        --auth = "passwd",
		    },
		    [2] = {
		        host = "127.0.0.1" ,      
		        port = 6379,    
		        db = 2 ,
		        --auth = "passwd",
		    },
	    },

	},
	
	-- 登陆节点启动配置，此节点也作为逻辑上的主节点
	login = {
		-- 登陆服务器网关配置
		conf = {
			name = "login_master",  -- 登陆服务名称， 全局通过cluster能访问到
			host = "0.0.0.0",     	-- 侦听地址
			port = 8001,			-- 侦听端口
			instance = 8, 			-- 登陆slave验证服务个数
		},

		-- agent池配置
		agentpool = {
			name = "agent",  -- 要启动缓存的 agent 文件名
			maxnum = 2,  	 -- 池的最大容量
			recyremove = 0,  -- 如果池的最大容易都已经用完之后，后续扩展的容量在回收时是否删除，0: 不删除； 1: 删除
		},

		-- 游戏服务器网关配置, 根据网络使用情况选配多个
		gate_list = {
			{
				servername = "gate_name1",  -- 服务器名称，玩家在登陆验证的时候会使用这个名称做握手验证
				address = "0.0.0.0",  		-- 侦听地址
				port = 9001, 				-- 侦听端口
				maxclient = 2048,  			-- 接受最大客户端连接数
			},
			{
				servername = "gate_name2",
				address = "0.0.0.0",
				port = 9002,
				maxclient = 2048,
			},
		},

		consoleport = 8801 , -- 当前节点控制台侦听端口
	},

	-- node1 节点配置
	node1 = {

		-- agent池配置, 同上
		agentpool = {
			name = "agent", 
			maxnum = 10,   
			recyremove = 0,   
		},

		-- 服务器网关配置，同上
		gate_list = {
			{
				servername = "gate_name3",
				address = "0.0.0.0",
				port = 9003,
				maxclient = 2048,
			},
			{
				servername = "gate_name4",
				address = "0.0.0.0",
				port = 9004,
				maxclient = 2048,
			},
		},

		consoleport = 8802 ,
	},
	
}