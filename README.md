# mmoarpgserver
  a simple mmoarpg game server base on skynet
# build
  For linux, install autoconf first for jemalloc
  ```
  cd skynet
  make 'PLATFORM'  # PLATFORM can be linux, macosx now
  ```
  Or you can :
  ```
  export PLAT=linux
  make
  ```
#Test
  Run this in console
  
  ```
  cd skynet/skynet
  ./skynet ../xjgame/etc/config.login
