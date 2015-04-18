PLAT ?= none
PLATS = linux freebsd macosx

CC ?= gcc

.PHONY : none $(PLATS) clean all cleanall

#ifneq ($(PLAT), none)

.PHONY : default

default :
	$(MAKE) $(PLAT)

#endif

none :
	@echo "Please do 'make PLATFORM' where PLATFORM is one of these:"
	@echo "   $(PLATS)"

linux : PLAT = linux
macosx : PLAT = macosx
freebsd : PLAT = freebsd

LUA_INC ?= skynet/3rd/lua
LUA_CLIB_PATH = ./xjgame/luaclib

CFLAGS = -g -O2 -Wall -I$(LUA_INC) $(MYCFLAGS) 
SHARED := -fPIC --shared
macosx : SHARED := -fPIC -dynamiclib -Wl,-undefined,dynamic_lookup

macosx : conf
	cd skynet/ && $(MAKE) CC=$(CC) $(PLAT)

linux : conf
	cd skynet/ && $(MAKE) CC=$(CC) $(PLAT)


conf : lua-conf/luaconf.c 
	mkdir -p $(LUA_CLIB_PATH)
	$(CC) $(CFLAGS) $(SHARED) $^ -o $(LUA_CLIB_PATH)/conf.so


clean :
	cd skynet/ && $(MAKE) clean
	rm -rf $(LUA_CLIB_PATH)/*
