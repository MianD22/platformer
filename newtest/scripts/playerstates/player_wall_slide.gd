extends State
class_name PlayerWallSlide

@export var player: CharacterBody2D
@export var animation_player: AnimationPlayer

func enter():
	if player.wall_latching and ((player.wall_latching_modifier and Input.is_action_pressed("latch")) or not player.wall_latching_modifier):
		if animation_player.has_animation("Latch"):
			animation_player.play("Latch")
		elif animation_player.has_animation("Fall"):
			animation_player.play("Fall")
	else:
		if animation_player.has_animation("Slide"):
			animation_player.play("Slide")
		elif animation_player.has_animation("Fall"):
			animation_player.play("Fall")

func physics_update(delta: float):
	if player.wall_latching and ((player.wall_latching_modifier and Input.is_action_pressed("latch")) or not player.wall_latching_modifier):
		player.velocity.y = 0
	else:
		var applied_gravity = player.gravity_scale / max(0.001, player.wall_sliding)
		var t_vel = player.terminal_velocity / max(0.001, player.wall_sliding)
		if player.velocity.y < t_vel:
			player.velocity.y += applied_gravity
		elif player.velocity.y > t_vel:
			player.velocity.y = t_vel

	var direction = Input.get_axis("move_left", "move_right")
	
	if player.wall_latching_modifier and Input.is_action_pressed("latch"):
		player.apply_horizontal_movement(0, delta)
	else:
		player.apply_horizontal_movement(direction, delta)
		
	player.move_and_slide()
	
	if Input.is_action_just_pressed("dash") and player.dash_count > 0 and player.dash_type != 0:
		Transitioned.emit(self, "Dash")
		return
	
	if player.wall_jump and Input.is_action_just_pressed("jump"):
		var dir = 1
		# If wall is on our right side (which means we were moving right originally) -> jump left
		# By default, CharacterBody2D has get_wall_normal() which is more reliable
		if player.get_wall_normal().x > 0:
			dir = 1
		else:
			dir = -1
			
		player.wall_kick(dir)
		Transitioned.emit(self, "Jump")
		return
		
	if player.is_on_floor():
		Transitioned.emit(self, "Idle")
		return
		
	if not player.is_on_wall():
		Transitioned.emit(self, "Fall")
		return
