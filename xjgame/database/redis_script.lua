

REDIS_SCRIPT = {}

-- 
-- create new role for namespace db
--
-- KEYS[1]: server_id 
-- KEYS[2]: account
-- KEYS[3]: name
--
-- namespace:max_id     
-- namespace:account:[serverid]:[account]  id   id    -- 当前账号包含的所有角色
--
-- namespace:ids:[serverid]  id id    -- 当前服包含的所有账号id
--
-- namespace:player:id:[id]         name 
-- namespace:player:name:[name]     id
--
-- 返回  1 ：创建成功
-- 返回 -1 ：创建失败，名字有重名
--
REDIS_SCRIPT.NAMESPACE_CREATE_ROLE = 
[[

if redis.call('exists', 'namespace:max_id') <= 0 then                                                      
    redis.call('set','namespace:max_id',0)                                                                  
end                                                                                                         
                                                                                                            
local max_id = redis.call('get', 'namespace:max_id') + 1                                                    
if redis.call('exists','namespace:player:id:'..max_id) <= 0 and                                      
    redis.call('exists','namespace:player:name:'..KEYS[3]) <=0                                     
then                                                                                                                                              
    redis.call('set', 'namespace:player:id:'..max_id,KEYS[3])                                      
    redis.call('set', 'namespace:player:name:'..KEYS[3],max_id)                                                                      
                                                                                                            
    redis.call('hset', 'namespace:account:'..KEYS[1]..':'..KEYS[2], max_id, max_id )                       
    redis.call('hset', 'namespace:ids:'..KEYS[1], max_id, max_id )                                                   
    redis.call('incr', 'namespace:max_id')                                                                  
                                                                                                            
    return max_id                                                                                           
else                                                                                                        
    return -1                                                                                               
end 

]]

-- 
-- create new role for character db
--
-- KEYS[1]:     id
-- KEYS[2]:     name
-- KEYS[3]:     account
-- KEYS[4]:     createtime
-- KEYS[5]:     createip
-- KEYS[6]:     channelid   -- 渠道来源
-- KEYS[7]:     job 
--
-- HASHS  player:info:[id]
--
-- player:info:[id]     id               id
-- player:info:[id]     account          account
-- player:info:[id]     name             name
-- player:info:[id]     vip              vip
-- player:info:[id]     level            level
-- player:info:[id]     scene_id         scene_id
-- player:info:[id]     createtime       createtime
-- player:info:[id]     logintime        logintime
-- player:info:[id]     logouttime       logouttime
-- player:info:[id]     createip         createip
-- player:info:[id]     channelid        channelid
-- player:info:[id]     loginip          loginip
-- player:info:[id]     job              job
--
-- 返回  player_id( > 0 )：创建成功
-- 返回 -1：创建失败，角色已经存在
--
REDIS_SCRIPT.CHARACTER_CREATE_ROLE =
[[ 

if redis.call('exists', 'player:info:'..KEYS[1]) == 1 then                                                
    return -1                                                                                              
else                                                                                                       
    redis.call('hset', 'player:info:'..KEYS[1], 'id', KEYS[1])                                             
    redis.call('hset', 'player:info:'..KEYS[1], 'name', KEYS[2])                                           
    redis.call('hset', 'player:info:'..KEYS[1], 'account', KEYS[3])                                        
    redis.call('hset', 'player:info:'..KEYS[1], 'level', 1)                                                
    redis.call('hset', 'player:info:'..KEYS[1], 'vip', 0)                                                  
    redis.call('hset', 'player:info:'..KEYS[1], 'gmlevel', 0)                                                  
    redis.call('hset', 'player:info:'..KEYS[1], 'scene_id', 1)                                                                                      
    redis.call('hset', 'player:info:'..KEYS[1], 'createtime', KEYS[4])                                     
    redis.call('hset', 'player:info:'..KEYS[1], 'logintime', KEYS[4])                                      
    redis.call('hset', 'player:info:'..KEYS[1], 'logouttime', 0)                                           
    redis.call('hset', 'player:info:'..KEYS[1], 'createip', KEYS[5])                                           
    redis.call('hset', 'player:info:'..KEYS[1], 'loginip', KEYS[5])                                           
    redis.call('hset', 'player:info:'..KEYS[1], 'channelid', KEYS[6])
    redis.call('hset', 'player:info:'..KEYS[1], 'job', KEYS[7]) 

    return KEYS[1]                                                                                               
end 

]]



