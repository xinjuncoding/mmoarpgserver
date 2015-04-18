

return [[


.package {
	type 0 : integer
	session 1 : integer
}

heartbeat 1 {}

.AOIObject {
	model 		0 : string	
	objid 		1 : string
	id 			2 : integer
	job			3 : integer
	x			4 : integer
	y			5 : integer
	oriend 		6 : integer
	attack_id 	7 : integer
	action_id	8 : integer
	dress_id    9 : integer
	dst  		10 : integer
	isnpc 		11 : boolean
	ismonster 	12 : boolean
	isplayer    13 : boolean
	harborname	14 : string
	address		15 : integer
}

# aoi 对象列表, 用于更新列表
scene_aoi_list 2 {
	request {
		obj_list 0 : *AOIObject
	}
}

scene_aoi_exit 3 {
	request {
		objid 	0 : string
	}
}

]]