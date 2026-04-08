extends Camera2D

var overlapping_zones: Array = []
var active_zone: Area2D
var player_node: CharacterBody2D

var follow_player: bool = false

func _ready() -> void:
	add_to_group("RoomZoneCamera")
	make_current()
	player_node = get_tree().get_first_node_in_group("player")
	print("[Cam2DZone] Camera ready and made current")
	
func _process(_delta):
	if !player_node:
		player_node = get_tree().get_first_node_in_group("player")
		return
		
	if overlapping_zones.is_empty():
		return
	
	if active_zone == null:
		active_zone = overlapping_zones[0]
		apply_zone_settings()
		return
	
	if overlapping_zones.size() == 1 and active_zone == overlapping_zones[0]:
		return
		
	var new_zone = get_closest_zone()
	if new_zone != active_zone:
		active_zone = new_zone
		apply_zone_settings()
	
func _physics_process(_delta: float) -> void:
	if follow_player and player_node:
		global_position = player_node.global_position
	
func get_closest_zone() -> Area2D:
	var closest_zone: Area2D = null
	var closest_dist: float = INF
	var player_pos: Vector2 = player_node.global_position
	
	for zone in overlapping_zones:
		var zone_shape: CollisionShape2D = zone.collisionshape
		var col_margin: float = 0.1
		var zone_shape_pos: Vector2 = zone_shape.global_position
		var zone_shape_extents: Vector2 = zone_shape.shape.size / 2.0
		var shape_sides: Array[Vector2] = [
			Vector2(zone_shape_pos.x - zone_shape_extents.x + col_margin, player_pos.y), #left side
			Vector2(zone_shape_pos.x + zone_shape_extents.x - col_margin, player_pos.y), #right side
			Vector2(player_pos.x, zone_shape_pos.y - zone_shape_extents.y + col_margin), #top side
			Vector2(player_pos.x, zone_shape_pos.y + zone_shape_extents.y - col_margin)  #bottom side
		]
		
		var closest_dist_shapeside := INF
		for col_side in shape_sides:
			var col_dist: float = player_pos.distance_to(col_side)
			if col_dist < closest_dist_shapeside:
				closest_dist_shapeside = col_dist
				
		if closest_dist_shapeside < closest_dist:
			closest_dist = closest_dist_shapeside
			closest_zone = zone
			
	return closest_zone

func apply_zone_settings():
	print("[Cam2DZone] Applying zone: ", active_zone.name, " follow=", active_zone.follow_player, " pos=", active_zone.fixed_position)
	zoom = active_zone.zoom
	
	follow_player = active_zone.follow_player
	if !active_zone.follow_player:
		global_position = active_zone.fixed_position
		
	if active_zone.limit_camera:
		limit_enabled = true
		limit_left = active_zone.limit_left
		limit_top = active_zone.limit_top
		limit_right = active_zone.limit_right
		limit_bottom = active_zone.limit_bottom
	else:
		limit_enabled = false
