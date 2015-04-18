local skynet = require "skynetex"
local M = skynet.module("redis_namespace_handle")

-- 获取 serverid 服里账号 account 所有的角色列表
function M.np_get_role_list(account, serverid)
    assert(account)

    local key = "namespace:account:"..serverid..":"..account

    -- 返回所有的key， 这些key就是所有的角色id， 格式：{1001,1002}
    local list = DB:hkeys(key)
    local ret = {}

    for _, v in pairs(list) do 
    	ret[tonumber(v)] = tonumber(v)
    end

    return ret
end

function M.np_create_role(account, name, serverid)
    return DB:eval(REDIS_SCRIPT.NAMESPACE_CREATE_ROLE, 3, serverid, account, name)
end
