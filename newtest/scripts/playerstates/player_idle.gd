extends State
class_name PlayerIdle

@export var player: CharacterBody2D
@export var animation_player: AnimationPlayer

func enter():
	animation_player.play("Idle")

func physics_update(delta: float):
	player.apply_gravity(delta)
	player.apply_horizontal_movement(0, delta)
	player.move_and_slide()
	
	if Input.is_action_just_pressed("teleport"):
		Transitioned.emit(self, "Teleport")
		return
	
	if Input.is_action_just_pressed("dodge"):
		Transitioned.emit(self, "Dodge")
		return
	
	if Input.is_action_just_pressed("dash") and player.dash_count > 0 and player.dash_type != 0:
		Transitioned.emit(self, "Dash")
		return
		
	if Input.is_action_just_pressed("attack"):
		Transitioned.emit(self, "Attack")
		return
		
	# Check for buffered jump
	if player.jump_buffer_timer > 0.0 and player.is_on_floor():
		player.consume_jump()
		Transitioned.emit(self, "Jump")
		return
		
	var direction = Input.get_axis("move_left", "move_right")
	if direction != 0:
		Transitioned.emit(self, "Move")
		return
		
	if not player.is_on_floor():
		Transitioned.emit(self, "Fall")
