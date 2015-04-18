
-- 玩家基础信息
DBKEY_CT_PLAYERINFO     = "player:info:"  -- player:info:[player_id]
INFO_ID             = "id"
INFO_ACCOUNT        = "account"
INFO_NAME           = "name"
INFO_JOB			= "job"
INFO_VIP            = "vip"
INFO_GMLEVEL        = "gmlevel"
INFO_DIAMOND        = "diamond"
INFO_PAYDIAMOND     = "paydiamond"
INFO_BINDDIAMOND	= "binddiamond"
INFO_GOLD           = "gold"
INFO_SILVER         = "silver"
INFO_LEVEL          = "level"
INFO_POWER          = "power"
INFO_SCENE_ID       = "scene_id"
INFO_POSX 			= "pos_x"
INFO_POSY 			= "pos_y"
INFO_CREATETIME     = "createtime"
INFO_LOGINTIME      = "logintime"
INFO_LOGOUTTIME     = "logouttime"
INFO_CREATEIP       = "createip"
INFO_LOGINIP        = "loginip"
INFO_CHANNEL 		= "channel_id"   -- 渠道来源


-- 竞技场数据
-- 排行榜存在 character db 里
DBKEY_CT_ATHLETIC_RANK = "character:athletic:rank:" -- namespace:athletic:rank:[server_id] 

-- 具体玩家的玩法数据存在 character db 里
DBKEY_CT_ATHLETIC = "player:athletic:"  -- player:athletic:[player_id],  hash set

