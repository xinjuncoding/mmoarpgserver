local skynet = require "skynetex"
require "skynet.manager"

local command = {}
local event_listener = {}
-- 接受全局事件的中转派发
function command.publish_event( event, ... )
	assert(event_listener[event])
	for _, func in pairs(event_listener[event]) do 
		func(...)
	end
end

-- 订阅事件
function command.subscribe_event( event, func, is_local )
	if event_listener[event] == nil then 
		event_listener[event] = {}

		-- 如果是本地事件的话，不需要注册到全局事件服务里
		if not is_local then 
			skynet.call( ".eventserver_node", "lua", "subscribe", event, skynet.self(), "publish_event")
		end
	end 

	event_listener[event][func] = func
	return func, is_local
end

-- 取消订阅
function command.unsubscribe_event( event, func, is_local)
	assert(event_listener[event] and event_listener[event][func]) 
	event_listener[event][func] = nil

	local flag = true 
	for _,_ in pairs(event_listener[event]) do 
		flag = false
		break
	end

	if flag and not is_local then 
		skynet.call( ".eventserver_node", "lua", "unsubscribe", event, skynet.self() )
	end
end

return command