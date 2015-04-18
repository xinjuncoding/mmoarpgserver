
local skynet 		= require "skynet"
local sprotoloader 	= require "sprotoloader"
local proto 		= require "proto"

skynet.start(function()
	sprotoloader.save(proto.c2s, 1)
	sprotoloader.save(proto.s2c, 2)
	-- don't call skynet.exit() , because sproto.core may unload and the global slot become invalid
end)
