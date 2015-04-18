
--
-- 副本闯关玩法逻辑
--

local skynet = require "skynetex"
local M = skynet.module("player")


-- 前端出发通关请求
function M.copy_pass( args )
	-- 做是否能通关判断
	-- 如果是前端做战斗的话，需要在此验证战斗合法性， 并做战斗结算相关逻辑

end