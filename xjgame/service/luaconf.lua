
local skynet = require "skynetex"
local conf = require "conf"

function require_data()
    local require = skynet.require_ex
    require("data/defineItem")
    require("data/defineNpc")
    require("data/defineMonster")
    
    require("data/propItem")
    require("data/propMonster")
    require("data/propNpc")
    require("data/propScene")
    -- 继续添加其他配置表的加载
    -- ...

    -- 从_G表里过滤配置表信息，只有prop和大写字母开头才是配置表相关配置数据
    local tmpconf = {}
    for k,v in pairs(_G) do 
        local ktype = type(k)
        local vtype = type(v)

        local fchar = string.sub(k,1,1)

        if fchar ~= "_" and ktype == "string" and vtype ~= "function" and ( string.sub(k,1,4) == "prop" or
            (fchar >="A" and fchar <="Z")) then
            tmpconf[k] = v
        end
    end

    return conf.host.new(tmpconf)
end

local tconf_prop = require_data()

local address_list = {}
local command = {}

function command.GET(address)
    if address then 
        table.insert(address_list, address)
    end
    return tconf_prop
end

-- 热更配置表接口
function reload_resmng()
    skynet.cache.clear()
    tconf_prop = require_data()
    assert(tconf_prop)
    for _,address in ipairs(address_list) do
        if not skynet.call(address, "lua", "__reload_script", [[
            local t = ...
            assert(t)
            local conf = require "conf"
            resmng = conf.box(t) 
            ]], tconf_prop) then
            assert(false)
        end
    end
end

skynet.start(function()
    skynet.dispatch("lua", function(session, address, cmd, ...)
        local f = command[cmd]
        if f then 
            skynet.ret(skynet.pack(f(address, ...)))
        else
            error(string.format("[luaconfig] has not find the command: %s", cmd))
        end
    end)
    skynet.register ".luaconfig"
end)

