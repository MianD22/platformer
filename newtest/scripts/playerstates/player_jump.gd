extends State
class_name PlayerJump

@export var player: CharacterBody2D
@export var animation_player: AnimationPlayer

func enter():
	animation_player.play("Jump")
	player.update_stats() # Just in case they were changed in the editor inspector
	if not player.was_wall_kicked:
		if player.jump_count > 0:
			player.jump_count -= 1
		player.velocity.y = -player.jump_magnitude
	player.was_wall_kicked = false

func physics_update(delta: float):
	# Handle variable jump height (short hop)
	if player.short_hop and Input.is_action_just_released("jump") and player.velocity.y < 0:
		player.velocity.y /= 2.0
		
	player.apply_gravity(delta)
	
	# Horizontal air movement
	var direction = Input.get_axis("move_left", "move_right")
	player.apply_horizontal_movement(direction, delta)
	player.move_and_slide()
	
	if Input.is_action_just_pressed("teleport"):
		Transitioned.emit(self, "Teleport")
		return
	
	if Input.is_action_just_pressed("attack"):
		Transitioned.emit(self, "Attack")
		return
	
	if Input.is_action_just_pressed("dash") and player.dash_count > 0 and player.dash_type != 0:
		Transitioned.emit(self, "Dash")
		return
	
	if player.wall_jump and Input.is_action_just_pressed("jump"):
		if player.is_on_wall():
			var dir = 1 if player.get_wall_normal().x > 0 else -1
			player.wall_kick(dir)
			Transitioned.emit(self, "Jump")
			return
		elif player.wall_coyote_timer > 0.0:
			var dir = 1 if player.last_wall_normal.x > 0 else -1
			player.wall_kick(dir)
			Transitioned.emit(self, "Jump")
			return
	
	if player.jump_count > 0 and Input.is_action_just_pressed("jump"):
		player.consume_jump()
		Transitioned.emit(self, "Jump")
		return
		
	if player.velocity.y >= 0:
		Transitioned.emit(self, "Fall")
