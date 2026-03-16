extends State
class_name PlayerIdle

@export var player: CharacterBody2D
@export var animated_sprite: AnimatedSprite2D

func enter():
	animated_sprite.play("idle")

func physics_update(delta: float):
	player.apply_gravity(delta)
	player.apply_horizontal_movement(0, delta)
	player.move_and_slide()
	
	if Input.is_action_just_pressed("attack") and player.is_on_floor():
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
