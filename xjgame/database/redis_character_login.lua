
local M = skynet.module("redis_character_handle")


-- 创建角色
function M.ct_create_role( account, player_id, name, job, create_ip, channel_id )
    local ret = DB:eval(REDIS_SCRIPT.CHARACTER_CREATE_ROLE, 7, player_id, name, account, os.time(), create_ip, channel_id, job)
    ret = tonumber(ret)
    if ret > 0 then 
        -- 创建角色成功，初始化属性

    end
    return ret
end

-- 获取玩家基础信息
function M.ct_get_role_info( player_id )
    assert(player_id)
    local role_info = DB:hgetall(DBKEY_CT_PLAYERINFO..player_id)

    local index = 1
    local info = {}
    while index < #role_info do
        info[role_info[index]] = role_info[index+1]
        index = index + 2
    end

    return info
end
