--
-- 这是一个简单活动定时开启、关闭、预告的活动管理器
-- 每当定时器到了的时候会向全局 eventserver 派发活动状态驱动消息，驱动侦听这些事件的各个活动服务开展工作
-- 按照时间划分活动（按天、周、月、年周期进行的活动）
-- 具体的活动逻辑由各个活动服务实现，此服务只负责活动开启驱动
-- 

local skynet = require "skynetex"
local cluster = require "cluster"

local command = {}

local running_activity 	= {}
local start_timer 		= {}
local end_timer 		= {}
local pre_timer 		= {}
local pre_stoptimer 	= {}

local propactivity = {
	[1] = { ID = 1, Name = "摇钱树", 		type = "day",   start = "12:30:0", 	 	 timelen = 20*60, 		pretime = {10,5,1}, prestoptime = {5,1}, },
	[2] = { ID = 2, Name = "世界boss", 	  	type = "week",  start = "4|18:0:0", 	 timelen = 30*60, 		pretime = {10,5,1}, prestoptime = {5,1}, },
	[3] = { ID = 3, Name = "体力恢复翻倍", 	type = "month", start = "15|0:0:0", 	 timelen = 24*60*60, 	pretime = {10,5,1}, prestoptime = {5,1}, },
	[4] = { ID = 4, Name = "国庆活动", 		type = "year",  start = "10.1|0:0:0", 	 timelen = 3*24*60*60, 	pretime = {10,5,1}, prestoptime = {5,1}, },
}

-- dispath the message that activity start now 
local function dispath_start_messge( activity_id )
	cluster.call("login", ".eventserver", "publish", "activity_start", activity_id)
end

-- dispath the message that activity stop now 
local function dispath_end_message( activity_id )
	cluster.call("login", ".eventserver", "publish", "activity_end", activity_id)
end 

-- dispath the message that activity start soon
local function dispath_pre_begin_message( activity_id, ti )
	cluster.call("login", ".eventserver", "publish", "activity_pre_begin", activity_id, ti)
end

-- dispath the message that activity stop soon
local function dispath_pre_stop_message( activity_id, ti )
	cluster.call("login", ".eventserver", "publish", "activity_pre_stop", activity_id, ti)
end

local function set_activity_timer( len, prop, lestlen )
	start_timer[prop.ID] = skynet.add_timer(len*100, function()
		start_timer[prop.ID] = nil
		pre_timer[prop.ID] = nil
		running_activity[prop.ID] = true 

		-- Todo dispath activity start message
		dispath_start_messge(prop.ID)

		-- begin timer activity end logic
		end_timer[prop.ID] = skynet.add_timer(lestlen*100, function( )
			end_timer[prop.ID] = nil

			-- dispath activity end message
			dispath_end_message(prop.ID)

			-- begin next time logic
			init_activity(prop.ID)	 
		end)

		-- 设置活动结束预告定时器
		if prop.prestoptime then 
			if not pre_stoptimer[prop.ID] then 
				pre_stoptimer[prop.ID] = {}
			end 

			for key, ti in ipairs(prop.prestoptime) do 
				local tmplen = lestlen - ti*60
				if tmplen > 0 then 
					local timer = skynet.add_timer(tmplen*100, function( )
						dispath_pre_stop_message(prop.ID, ti)
					end)
					table.insert(pre_stoptimer[prop.ID], timer)
				end 
			end
		end

	end)

	-- 设置预告定时器
	if prop.pretime then 
		if not pre_timer[prop.ID] then 
			pre_timer[prop.ID] = {}
		end 

		for key, ti in ipairs(prop.pretime) do 
			local tmplen = len - ti*60
			if tmplen > 0 then 
				local timer = skynet.add_timer(tmplen*100, function( )
					dispath_pre_begin_message(prop.ID, ti)
				end)
				table.insert(pre_timer[prop.ID], timer)
			end 
		end
	end
end

-- init the day type activity
local function init_day_activity(prop, is_next)
	assert(prop.type=="day")
	running_activity[prop.ID] = nil 

	local timearr = {}
	for ti in string.gmatch(prop.start, "%d+") do 
		table.insert(timearr, ti)
	end

	local now = os.time()
	local nowdate = os.date("*t", now)
	nowdate.hour  = timearr[1]
	nowdate.min   = timearr[2]
	nowdate.sec   = timearr[3]

	local tstime = os.time(nowdate)   -- the start time 
	local tetime = tstime + prop.timelen  -- the stop time  

	local next_tstime = tstime + 24*3600
	local last_tetime = tetime - 24*3600

	local lestlen = prop.timelen
	local len = 0
	if now < tstime and now > last_tetime then 
		len = tstime - now
	elseif (now + 20) > tetime and now < next_tstime then -- ＋20 是为了避免在活动刚刚结束时如果时间误差而造成重复启动活动的问题
		len = next_tstime - now
	else 
		-- activity is running
		if now < last_tetime then 
			lestlen = last_tetime - now
		end
	end

	set_activity_timer(len, prop, lestlen)
end

local function init_week_activity( prop )
	assert(prop.type=="week")
	running_activity[prop.ID] = nil 

	local timearr = {}
	for ti in string.gmatch(prop.start, "%d+") do 
		table.insert(timearr, ti)
	end

	local now = os.time()
	local nowdate = os.date("*t", now)
	local dstday  = timearr[1] - nowdate.wday

	nowdate.day  = nowdate.day + dstday
	nowdate.hour = timearr[2]
	nowdate.min  = timearr[3]
	nowdate.sec  = timearr[4]

	local tstime = os.time(nowdate)   -- the start time this week
	local tetime = tstime + prop.timelen  -- the stop time this week

	local next_tstime = tstime + 7*24*3600
	local last_tetime = tetime - 7*24*3600

	local lestlen = prop.timelen
	local len = 0
	if now < tstime and now > last_tetime then 
		len = tstime - now
	elseif (now + 20) > tetime and now < next_tstime then  -- ＋20 是为了避免在活动刚刚结束时如果时间误差而造成重复启动活动的问题
		len = next_tstime - now
	else 
		-- activity is running
		if now < last_tetime then 
			lestlen = last_tetime - now
		end
	end

	set_activity_timer(len, prop, lestlen)
end

local function init_month_activity( prop )
	assert(prop.type=="month")
	running_activity[prop.ID] = nil 

	local timearr = {}
	for ti in string.gmatch(prop.start, "%d+") do 
		table.insert(timearr, ti)
	end

	local now = os.time()
	local nowdate = os.date("*t", now)

	-- 25|10:10:10
	nowdate.day  = timearr[1]
	nowdate.hour = timearr[2]
	nowdate.min  = timearr[3]
	nowdate.sec  = timearr[4]

	local tstime = os.time(nowdate)
	local tetime = tstime + prop.timelen

	local last_tedate = os.date( "*t", tetime )
	if last_tedate.month == 1 then
		last_tedate.year = last_tedate.year - 1
		last_tedate.month = 12
	else 
		last_tedate.month = last_tedate.month - 1
	end
	local last_tetime = os.time(last_tedate)

	local lestlen = prop.timelen
	local len = 0
	if now < tstime and now > last_tetime then 
		len = tstime - now
	elseif (now + 20) > tetime then -- ＋20 是为了避免在活动刚刚结束时如果时间误差而造成重复启动活动的问题
		if nowdate.month < 12 then 
			nowdate.month = nowdate.month + 1
		else 
			nowdate.month = 1
			nowdate.year = nowdate.year + 1
		end
		local tstime = os.time(nowdate)
		len = tstime - now
	else 
		-- activity is running
		if now < last_tetime then 
			lestlen = last_tetime - now
		end
	end

	set_activity_timer(len, prop, lestlen)
end

local function init_year_activity( prop )
	assert(prop.type=="year")
	running_activity[prop.ID] = nil 

	local timearr = {}
	for ti in string.gmatch(prop.start, "%d+") do 
		table.insert(timearr, ti)
	end

	local now = os.time()
	local nowdate = os.date("*t", now)

	-- 2.14|10:10:10
	nowdate.month = timearr[1]
	nowdate.day   = timearr[2]
	nowdate.hour  = timearr[3]
	nowdate.min   = timearr[4]
	nowdate.sec   = timearr[5]

	local tstime = os.time(nowdate)
	local tetime = tstime + prop.timelen

	local last_tedate = os.date( "*t", tetime )
	last_tedate.year = last_tedate.year - 1
	local last_tetime = os.time(last_tedate) 

	local lestlen = prop.timelen
	local len = 0
	if now < tstime and now > last_tetime then 
		len = tstime - now
	elseif (now + 20) > tetime then  -- ＋20 是为了避免在活动刚刚结束时如果时间误差而造成重复启动活动的问题
		nowdate.year = nowdate.year + 1
		local next_tstime = os.time(nowdate)
		len = next_tstime - now
	else 
		-- activity is running
		if now < last_tetime then 
			lestlen = last_tetime - now
		end
	end

	set_activity_timer(len, prop, lestlen)
end

function init_activity( id )
	local prop = assert(propactivity[id]) 
	if prop.type == "day" then 
		init_day_activity(prop)
	elseif prop.type == "week" then
		init_week_activity(prop)
	elseif prop.type == "month" then 
		init_month_activity(prop)
	elseif prop.type == "year" then
		init_year_activity(prop)
	else 
		error(string.format("the acitivity type is wrong, id:%s, type:%s", prop.ID, prop.type ) )
	end
end

local function __activity_init__()
	for id, prop in pairs(propactivity) do 
		init_activity(id)
	end
end

function command.start_activity( id )
	assert(propactivity[id])
	command.stop_activity(id)
	init_activity(id)
end

function command.stop_activity( id )
	if running_activity[id] then 
		dispath_end_message( id )
		running_activity[id] = nil
	end

	if start_timer[id] then 
		skynet.del_timer(start_timer[id])
		start_timer[id] = nil
	end
	
	if end_timer[id] then 
		skynet.del_timer(end_timer[id])
		end_timer[id] = nil
	end

	if pre_timer[prop.ID] then 
		for _, timer in pairs(pre_timer[prop.ID]) do 
			skynet.del_timer(timer)
		end
		pre_timer[prop.ID] = nil
	end
end

function command.all_running_activity( )
	local ret = {}
	for id, _ in pairs(running_activity) do 
		table.insert(ret, id)
	end
	return ret
end

skynet.start(function()
	skynet.dispatch("lua", function(session, address, cmd, ...)
		local f = command[cmd]
		if f then
			skynet.ret(skynet.pack(f(...)))
		else
			error(string.format("Unknown command %s", tostring(cmd)))
		end
	end)
	skynet.register ".activityserver"

	__activity_init__()
end)
