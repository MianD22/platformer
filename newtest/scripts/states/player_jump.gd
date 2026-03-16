extends State
class_name PlayerJump

@export var player: CharacterBody2D
@export var animated_sprite: AnimatedSprite2D

func enter():
	animated_sprite.play("jump")
	player.update_stats() # Just in case they were changed in the editor inspector
	player.velocity.y = -player.jump_magnitude

func physics_update(delta: float):
	# Handle variable jump height (short hop)
	if player.short_hop and Input.is_action_just_released("jump") and player.velocity.y < 0:
		player.velocity.y /= 2.0
		
	player.apply_gravity(delta)
	
	# Horizontal air movement
	var direction = Input.get_axis("move_left", "move_right")
	player.apply_horizontal_movement(direction, delta)
	player.move_and_slide()
		
	if player.velocity.y >= 0:
		Transitioned.emit(self, "Fall")
