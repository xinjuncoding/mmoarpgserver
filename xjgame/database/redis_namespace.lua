
require("database/redis_define")

local skynet = require "skynetex"

local redis = require "redis"
local namespace_conf = require(skynet.getenv("runconfig")).database["namespace"]

DB = nil 

require ("database/redis_script")
require ("database/redis_namespace_handle")
require ("database/redis_namespace_login")

function db_message_handle(session, address, method, ...)
    assert(method)

    local func = assert(redis_namespace_handle[method], "reidis_character_handle param err!")
    skynet.ret(skynet.pack(func(...)))
end

skynet.start(function()
    DB = redis.connect(namespace_conf)

    skynet.dispatch("lua", db_message_handle)
    skynet.register ".namespace_db"

    local function ping_callback()
        skynet.send(skynet.self(),"debug","GC")
        DB:ping()
        skynet.timeout(30*100, ping_callback)
    end
    skynet.timeout(100*100, ping_callback)

    print("[NAMESPACE_DB] start success!")
end)
