extends State
class_name PlayerGroundPound

@export var player: CharacterBody2D
@export var animation_player: AnimationPlayer

var pause_timer: float = 0.0
var dropping: bool = false
var original_terminal_velocity: float

func enter():
	if animation_player.has_animation("Fall"):
		animation_player.play("Fall")
	
	player.velocity.x = 0
	player.velocity.y = 0
	player.gravity_active = false
	pause_timer = player.ground_pound_pause
	dropping = false
	original_terminal_velocity = player.terminal_velocity

func exit():
	player.gravity_active = true
	player.terminal_velocity = original_terminal_velocity

func physics_update(delta: float):
	if not dropping:
		player.velocity.y = 0
		player.velocity.x = 0
		pause_timer -= delta
		if pause_timer <= 0:
			dropping = true
			player.terminal_velocity = original_terminal_velocity * 10.0
			player.velocity.y = player.jump_magnitude * 2.0
	else:
		player.velocity.y = player.jump_magnitude * 2.0
		
	if player.up_to_cancel and Input.is_action_pressed("up"):
		Transitioned.emit(self, "Fall")
		return

	player.move_and_slide()
	
	if player.is_on_floor():
		Transitioned.emit(self, "Idle")
