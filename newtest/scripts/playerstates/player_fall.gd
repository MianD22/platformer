extends State
class_name PlayerFall

@export var player: CharacterBody2D
@export var animation_player: AnimationPlayer

var is_anim_finished = false

func enter():
	animation_player.play("Fall")
	is_anim_finished = false
	if not animation_player.animation_finished.is_connected(_on_animation_finished):
		animation_player.animation_finished.connect(_on_animation_finished)

func exit():
	if animation_player.animation_finished.is_connected(_on_animation_finished):
		animation_player.animation_finished.disconnect(_on_animation_finished)

func physics_update(delta: float):
	player.apply_gravity(delta)
	
	# Horizontal air movement
	var direction = Input.get_axis("move_left", "move_right")
	player.apply_horizontal_movement(direction, delta)
	player.move_and_slide()
	
	if Input.is_action_just_pressed("attack"):
		Transitioned.emit(self, "Attack")
		return
	
	if Input.is_action_just_pressed("dash") and player.dash_count > 0 and player.dash_type != 0:
		Transitioned.emit(self, "Dash")
		return
		
	if player.ground_pound and Input.is_action_just_pressed("down") and not player.is_on_wall():
		Transitioned.emit(self, "GroundPound")
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
			
	if player.is_on_wall():
		if (player.wall_sliding != 1.0 or player.wall_latching) and player.velocity.y >= 0:
			Transitioned.emit(self, "WallSlide")
			return
	
	# Coyote Time allows jumping briefly after walking off a ledge
	if player.coyote_timer > 0.0 and player.jump_buffer_timer > 0.0:
		player.consume_jump()
		Transitioned.emit(self, "Jump")
		return
	elif player.jump_count > 0 and Input.is_action_just_pressed("jump"):
		player.consume_jump()
		Transitioned.emit(self, "Jump")
		return
		
	if player.is_on_floor() and is_anim_finished:
		if direction != 0:
			Transitioned.emit(self, "Move")
		else:
			Transitioned.emit(self, "Idle")

func _on_animation_finished(anim_name: StringName):
	if anim_name == "Fall":
		is_anim_finished = true
