local DB = DB
local skynet = require "skynetex"

local M = skynet.module("redis_namespace_handle")

function M.np_get_name_by_id( id )
    return DB:get("namespace:player:id:"..id)
end


