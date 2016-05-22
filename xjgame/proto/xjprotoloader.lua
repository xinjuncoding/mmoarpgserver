
local skynet = require "skynet"
local sprotoparser = require "sprotoparser"
local sprotoloader = require "sprotoloader"
local proto = require "xjproto"

skynet.start(function()
	sprotoloader.save(proto.c2s, 1)
	sprotoloader.save(proto.s2c, 2)
	-- don't call skynet.exit() , because sproto.core may unload and the global slot become invalid
end)
