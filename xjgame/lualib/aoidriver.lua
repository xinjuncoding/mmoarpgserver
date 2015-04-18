
--
-- aoi模块，采用十字链算法
--

local assert = assert


local aoi = {}

local w = 200
local h = 100

local obj_list = {}
local obj_list_x = {}
local obj_list_y = {}

local dst_max = 50  -- 最大观察半径

--[[  object 格式

	obj = {
		objid 		= object, 
		id 			= playerid,
		x  			= x,
		y  			= y,
		oriend 	 	= oriend,
		attack_id 	= 0,
		action_id	= 0,
		dress_id  	= 0,
		model 		= "w", -- "w"、"m"、“wm"、"mw" 
		dst 		= 10, -- 观察半径
		isplayer 	= false,
		ismonster	= false,
		isnpc		= false,
	}
	
--]]

local function is_watcher(obj)
	if obj.model == "w" or obj.model == "wm" or obj.model == "mw" then 
		return true
	else
		return false
	end
end

local function is_maker(obj)
	if obj.model == "m" or obj.model == "wm" or obj.model == "mw" then 
		return true
	else 
		return false
	end
end

local function dispatch_message( obj, func )
	assert(func)
	if is_maker(obj) then 
		-- 按照设置的最大视野范围遍历x轴
		local tmps = obj.x - dst_max
		if tmps <= 0 then 
			tmps = 1
		end

		local tmpe = obj.x + dst_max
		if tmpe > w then 
			tmpe = w
		end

		for i=tmps, tmpe do
			if i <= 0 then
				break
			end

			if obj_list_x[i] then 
				for k,v in pairs(obj_list_x[i]) do 
					-- 是观察者，并且在他的视野范围内
					if is_watcher(v) and math.abs(v.x - obj.x) <= v.dst and math.abs(v.y - obj.y) <= v.dst and v ~= obj then
						-- 执行更新回调
						func(obj, v)
					end
				end
			end
		end

	end
end

-- 获取obj附近的watcher
local function get_watcher( obj )
	local list = {}
	-- 按照设置的最大视野范围遍历x轴
	local tmps = obj.x - dst_max
	if tmps <= 0 then 
		tmps = 1
	end

	local tmpe = obj.x + dst_max
	if tmpe > w then 
		tmpe = w
	end

	for i=tmps, tmpe do
		if i <= 0 then
			break
		end

		if obj_list_x[i] then 
			for k,v in pairs(obj_list_x[i]) do 
				-- 是观察者，并且在他的视野范围内
				if is_watcher(v) and math.abs(v.y - obj.y) <= v.dst and math.abs(v.x - obj.x) <= v.dst and v ~= obj then
					-- 执行更新回调
					list[v.id] = v
				end
			end
		end
	end

	return list
end

-- 获取obj附近的maker
local function get_maker( obj, isproto ) 
	local list = {}
	-- 按照设置的最大视野范围遍历x轴
	local tmps = obj.x - dst_max
	if tmps <= 0 then 
		tmps = 1
	end

	local tmpe = obj.x + dst_max
	if tmpe > w then 
		tmpe = w
	end

	for i=tmps, tmpe do
		if i <= 0 then
			break
		end

		if obj_list_x[i] then 
			for k,v in pairs(obj_list_x[i]) do 
				-- 是观察者，并且在他的视野范围内
				if is_maker(v) and math.abs(v.y - obj.y) <= obj.dst and math.abs(v.x - obj.x) <= obj.dst and v ~= obj then
					-- 执行更新回调
					local ret 
					if v.isplayer then 
						ret = v
					else
						ret = v:get_obj()
					end

					if isproto then 
						table.insert(list,ret)
					else
						list[k] = ret
					end
				end
			end
		end
	end

	return list
end

function aoi.enter( obj, func )
	obj_list[obj.objid] = obj

	if not obj_list_x[obj.x] then 
		obj_list_x[obj.x] = {}
	end

	if not obj_list_y[obj.y] then 
		obj_list_y[obj.y] = {}
	end

	obj_list_x[obj.x][obj.objid] = obj
	obj_list_y[obj.y][obj.objid] = obj

	-- 如果是maker模式，广播给所有视野范围的带w模式的obj
	dispatch_message(obj, func)

	-- 如果是watcher模式，在进入之后返回视野上所有带m模式的obj
	if is_watcher(obj) then 
		return get_maker(obj, true)
	end
end

function aoi.remove( obj, func )
	obj_list[obj.objid] = nil
	obj_list_x[obj.x][obj.objid] = nil
	obj_list_y[obj.y][obj.objid] = nil

	-- 如果是m活着mw模式，需要广播给其他所有视野范围的w 
	dispatch_message(obj, func)
end

-- 需要计算更新之前和更新之后的交集作为广播集合
function aoi.update( obj, updatefunc, enterfunc, exitfunc )
	local bef_w_list = get_watcher(obj_list[obj.objid])
	local bef_m_list = get_maker(obj_list[obj.objid])

	obj_list[obj.objid] = obj
	obj_list_x[obj.x][obj.objid] = obj
	obj_list_y[obj.y][obj.objid] = obj

	local aft_w_list = get_watcher(obj)
	local aft_m_list = get_maker(obj)

	if is_maker(obj) then 
		for k,v in pairs(aft_w_list) do 
			if bef_w_list[k] then 
				updatefunc(obj, v) -- 更新交集
			else
				enterfunc(obj, v)  -- 新增进入视野
			end
		end
		
		-- 走出对方的视野了也通知对方做退出视野的相关操作
		for k,v in pairs(bef_w_list) do 
			if not aft_w_list[k] then 
				exitfunc(obj, v)
			end
		end
	end

	local list = {}
	-- 如果是watcher
	if is_watcher(obj) then 
		-- 找出新增的部分，需要更新到前端
		for k,v in pairs(aft_m_list) do 
			if not bef_m_list[k] then 
				if v.isplayer then 
					-- list[k] = v
					table.insert(list, v)
				else
					-- list[k] = v:get_obj()
					table.insert(list, v:get_obj())
				end
			end
		end
	end

	return list
end

function aoi.init(width, height, maxdst)
	w 		= width  or w 
	h 		= height or h 
	dst_max = maxdst or dst_max
end

return aoi

