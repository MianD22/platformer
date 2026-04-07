extends Area2D

@export var target_zoom: Vector2 = Vector2(1.5, 1.5) ## The zoom level when the player enters (used when lock_to_zone is off)
@export var transition_duration: float = 1.0 ## How quickly the zoom transition happens
@export var lock_to_zone: bool = false ## When enabled, the camera zooms to cover the entire zone and stays fixed at its center

var default_zoom: Vector2 = Vector2.ZERO
var default_position_smoothing: bool
var default_top_level: bool
var active_tween: Tween
var _cached_camera: Camera2D

func _ready():
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)

func _get_zone_zoom() -> Vector2:
	# Calculate the zoom needed to fit the entire collision zone in the viewport
	var collision_shape = get_node_or_null("CollisionShape2D")
	if not collision_shape or not collision_shape.shape:
		return target_zoom
	
	var shape = collision_shape.shape
	var zone_size: Vector2
	
	if shape is RectangleShape2D:
		zone_size = shape.size
	elif shape is CircleShape2D:
		zone_size = Vector2(shape.radius * 2, shape.radius * 2)
	elif shape is CapsuleShape2D:
		zone_size = Vector2(shape.radius * 2, shape.height)
	else:
		return target_zoom
	
	var viewport_size = get_viewport().get_visible_rect().size
	var zoom_x = viewport_size.x / zone_size.x
	var zoom_y = viewport_size.y / zone_size.y
	# Use the smaller zoom so the entire zone fits on screen
	var fit_zoom = min(zoom_x, zoom_y)
	return Vector2(fit_zoom, fit_zoom)

func _get_zone_center() -> Vector2:
	# Get the world-space center of the collision zone
	var collision_shape = get_node_or_null("CollisionShape2D")
	if collision_shape:
		return collision_shape.global_position
	return global_position

func _on_body_entered(body: Node2D):
	if body.is_in_group("player"):
		var camera = body.get_node_or_null("Camera2D")
		if camera:
			_cached_camera = camera
			# Store the original zoom the first time
			if default_zoom == Vector2.ZERO:
				default_zoom = camera.zoom
				default_position_smoothing = camera.position_smoothing_enabled
				default_top_level = camera.top_level
			
			if active_tween:
				active_tween.kill()
			
			if lock_to_zone:
				# Fix the camera at the zone center and zoom to cover the whole zone
				var zone_zoom = _get_zone_zoom()
				var zone_center = _get_zone_center()
				
				# Preserve global position across the top_level change to avoid snapping
				var current_global_pos = camera.global_position
				camera.top_level = true
				camera.global_position = current_global_pos
				camera.position_smoothing_enabled = false
				
				active_tween = create_tween().set_parallel(true)
				active_tween.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
				active_tween.tween_property(camera, "zoom", zone_zoom, transition_duration)
				active_tween.tween_property(camera, "global_position", zone_center, transition_duration)
			else:
				active_tween = create_tween()
				active_tween.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
				active_tween.tween_property(camera, "zoom", target_zoom, transition_duration)

func _on_body_exited(body: Node2D):
	if body.is_in_group("player"):
		var camera = body.get_node_or_null("Camera2D")
		if not camera:
			camera = _cached_camera
		if camera and default_zoom != Vector2.ZERO:
			if active_tween:
				active_tween.kill()
			
			if lock_to_zone:
				# Restore the camera to follow the player
				camera.top_level = default_top_level
				camera.position_smoothing_enabled = default_position_smoothing
				# Snap camera position back relative to the player before releasing
				camera.global_position = body.global_position
			
			active_tween = create_tween()
			active_tween.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
			active_tween.tween_property(camera, "zoom", default_zoom, transition_duration)
