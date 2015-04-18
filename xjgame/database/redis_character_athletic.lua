
-- 
-- 竞技场数据操作模块
--

local M = skynet.module("redis_character_handle")

local server_id = skynet.getenv("serverid")


-- 竞技场挑战成功之后交换挑战双方的排行榜位置
function M.athletic_exchange_rank( src, dst )
	-- 交换 src 和 dst 所在排行榜的位置
	local score_src = DB:ZSCORE(DBKEY_CT_ATHLETIC_RANK..server_id, src)
	local score_dst = DB:ZSCORE(DBKEY_CT_ATHLETIC_RANK..server_id, dst)

	return DB:ZADD(DBKEY_CT_ATHLETIC_RANK..server_id, score_dst, src, score_src, dst)
end

-- 或许排行榜数据
function M.athletic_get_rankdata( min, max )
	local data = DB:ZRANGE(DBKEY_CT_ATHLETIC_RANK..server_id, min-1, max-1)

	local ret = {}
	local index = 1
	for i=min, max do 
		if not data[index] then 
			return 
		end

		ret[i] = data[index]
		index = index + 1
	end

	return ret
end