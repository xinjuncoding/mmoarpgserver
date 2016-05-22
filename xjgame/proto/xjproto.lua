local sprotoparser = require "sprotoparser"

local proto = {}

proto.c2s = sprotoparser.parse(require "c2s")

proto.s2c = sprotoparser.parse(require "s2c")

return proto
