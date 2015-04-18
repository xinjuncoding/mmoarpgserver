
-- 
-- 竞技场操作逻辑
--

local cluster = require "cluster"
local skynet = require "skynetex"
local M = skynet.module("player")


-- 客户端发起挑战
function M.athletic_change( args )
	local src = self.player_id_
	local dst = args.dst_id

	local win = cluster.call("login", ".athleticserver", "challenge", src, dst) 
	
	local is_win = false
	if is_win == src then 
		is_win = true
	end

	-- 派发挑战信息
	cluster.call("login", ".eventserver", "publish", "athletic_changed_"..dst, src, is_win )

	return { win_id = win }
end

-- 获取竞技场排行榜数据
function M.athletic_get_rank( args )
	local min = args.rankmin 
	local max = args.rankmax
	assert(min>0 and max>0 and max-min==5)

	local data = skynet.call(self.dbserver_, "lua","athletic_get_rankdata", min, max)

	local ret = {}
	ret.rankdata = {}
	for i=min, max do 
		if not data[i] then 
			break
		end
		local tmp = {}
		tmp.id = data[i]
		tmp.name = skynet.call(self.dbserver_, "lua", "np_get_name_by_id", tmp.id)
		tmp.rank = i
		table.insert(ret, tmp)
	end

	return ret
end

