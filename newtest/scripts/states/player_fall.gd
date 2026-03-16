extends State
class_name PlayerFall

@export var player: CharacterBody2D
@export var animated_sprite: AnimatedSprite2D

func enter():
	animated_sprite.play("fall")

func physics_update(delta: float):
	player.apply_gravity(delta)
	
	# Horizontal air movement
	var direction = Input.get_axis("move_left", "move_right")
	player.apply_horizontal_movement(direction, delta)
	player.move_and_slide()
	
	# Coyote Time allows jumping briefly after walking off a ledge
	if player.coyote_timer > 0.0 and player.jump_buffer_timer > 0.0:
		player.consume_jump()
		Transitioned.emit(self, "Jump")
		return
		
	if player.is_on_floor():
		if direction != 0:
			Transitioned.emit(self, "Move")
		else:
			Transitioned.emit(self, "Idle")
