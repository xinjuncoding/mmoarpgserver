
--
-- 扩展skynet基础方法
--

local skynet = require "skynet"
require "skynet.manager"
-- a new timer interface for time
function skynet.add_timer(ti, func)
	local flag = true
	local function cb()
		if not flag then
			return
		end
		func()
	end
	skynet.timeout(ti, cb)

	return function() flag = false end
end

function skynet.del_timer( timer )
	assert(type(timer) == "function")
	timer()
end


local function __reload_script( script_str, ... )
    print(string.format("[skynet __reload_script] service:%s", skynet.self()))
    local param = {...}
    local ok, data = xpcall(function()  
        local func = loadstring(script_str)
        if func then 
            func(unpack(param))   
        else
            assert(false)
        end 
    end, debug.traceback)
    skynet.ret(skynet.pack(ok))
end

-- 这个接口的服务才能使用热更接口
function skynet.dispatchex(typename, func)
    local function funcex(session, source, cmd, ...)
        if typename == "lua" and cmd == "__reload_script" then
            __reload_script( ... ) 
        else
            func(session, source, cmd, ...)
        end 
    end 

    skynet.dispatch(typename, funcex)
end

function skynet.require_ex(modname)
    if package.loaded[modname] then
        package.loaded[modname] = nil
        print(string.format("require_ex %s", modname))
    end
    local ret, errstr = xpcall(function() require(modname) end, debug.traceback  )
    assert(ret, errstr)
    return ret
end

function skynet.module( name )
    local M = _G[name] or {}  
    _G[name]=M  
    package.loaded[name]=M  
    return M
end

return skynet

