
-- 
-- 世界boss 活动逻辑
--

local skynet = require "skynetex"
require "skynet.manager"
local cluster = require "cluster"
local activityd = require "activityd"

local activity = {
	activity_id = 2,
	activity_name = ".activity_worldboss",
}

local is_start = false

-- 活动开启逻辑
function activity.handle_start( )
	is_start = true

	-- 在此做活动开启逻辑
	-- ...
end

-- 活动结束逻辑
function activity.handle_end( )
	is_start = false

	-- 在此做活动结束逻辑
	-- ...
end

-- 活动即将开启预告
function activity.handle_pre_begin( ti )
	
end

-- 活动即将结束预告
function activity.handle_pre_stop( ti )
	
end


activityd.start(activity)

