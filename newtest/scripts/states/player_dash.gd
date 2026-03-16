extends State
class_name PlayerDash

@export var player: CharacterBody2D
@export var animation_player: AnimationPlayer

var dash_timer: float = 0.0

func enter():
	if player.dash_count <= 0 or player.dash_type == 0:
		Transitioned.emit(self, "Fall")
		return

	if animation_player.has_animation("Dash"):
		animation_player.play("Dash")
	elif animation_player.has_animation("Walk"):
		animation_player.play("Walk")

	player.dash_count -= 1
	var input_vector = Input.get_vector("move_left", "move_right", "up", "down")
	
	if player.dash_type == 4: # Eight Way
		if input_vector == Vector2.ZERO:
			input_vector.x = 1 if not player.sprite_2d.flip_h else -1
		player.velocity = input_vector.normalized() * player.dash_magnitude
	elif player.dash_type == 1: # Horizontal
		var dir = Input.get_axis("move_left", "move_right")
		if dir == 0:
			dir = 1 if not player.sprite_2d.flip_h else -1
		player.velocity = Vector2(dir * player.dash_magnitude, 0)
	elif player.dash_type == 2: # Vertical
		var dir = Input.get_axis("up", "down")
		if dir == 0:
			dir = -1 # Default dash up?
		player.velocity = Vector2(0, dir * player.dash_magnitude)
	elif player.dash_type == 3: # Four Way
		if abs(input_vector.x) > abs(input_vector.y):
			player.velocity = Vector2(sign(input_vector.x) * player.dash_magnitude, 0)
		else:
			var y_dir = sign(input_vector.y)
			if y_dir == 0: y_dir = -1
			player.velocity = Vector2(0, y_dir * player.dash_magnitude)
			
	var d_time = 0.0625 * player.dash_length
	dash_timer = d_time
	player.pause_input_for(d_time)
	player.gravity_active = false
	
func exit():
	player.gravity_active = true

func physics_update(delta: float):
	if dash_timer > 0:
		dash_timer -= delta
		if dash_timer <= 0:
			if player.is_on_floor():
				Transitioned.emit(self, "Idle")
			else:
				Transitioned.emit(self, "Fall")
			return
			
	if player.dash_cancel:
		var dir = Input.get_axis("move_left", "move_right")
		if dir != 0 and sign(dir) != sign(player.velocity.x) and player.velocity.x != 0:
			player.velocity.x = 0
			dash_timer = 0 # Cancel dash early
			
	player.move_and_slide()
