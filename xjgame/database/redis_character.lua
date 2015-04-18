
require("database/redis_define")

skynet = require "skynetex"
DB = nil

local redis = require "redis"

local character_index = ...
local character_conf = require(skynet.getenv("runconfig")).database["character"]

require ("database/redis_script")
require ("database/redis_character_handle")
require ("database/redis_character_login")
require ("database/redis_character_athletic")

function db_message_handle(session, address, method, ...)
    assert(method)

    local func = assert(redis_character_handle[method], "reidis_character_handle param err!")
    skynet.ret(skynet.pack(func(...)))
end

skynet.start(function()
    DB = redis.connect(character_conf[tonumber(character_index)])

	skynet.dispatch("lua", db_message_handle)
	skynet.register(".character_db"..character_index)

    local function ping_callback()
        skynet.send(skynet.self(),"debug","GC")
        DB:ping()
        skynet.timeout(30*100, ping_callback)
    end
    skynet.timeout(character_index*100, ping_callback)

    print("[CHARACTER_DB] start success! DB id: ", character_index)
end)

