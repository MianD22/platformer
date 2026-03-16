extends State
class_name PlayerRoll

@export var player: CharacterBody2D
@export var animation_player: AnimationPlayer

var roll_timer: float = 0.0

func enter():
	if animation_player.has_animation("Roll"):
		animation_player.play("Roll")
	
	player.collision_shape_2d.scale.y = player.collider_scale_lock_y / 2.0
	player.collision_shape_2d.position.y = player.collider_pos_lock_y + (8 * player.collider_scale_lock_y)
	
	roll_timer = 0.75
	var time_frozen = player.roll_length * 0.0625
	player.pause_input_for(time_frozen)
	
	var dir = 1 if not player.sprite_2d.flip_h else -1
	if Input.is_action_pressed("move_left"): dir = -1
	elif Input.is_action_pressed("move_right"): dir = 1
		
	player.velocity.x = player.max_speed_lock * player.roll_length * dir
	player.velocity.y = 0

func exit():
	player.collision_shape_2d.scale.y = player.collider_scale_lock_y
	player.collision_shape_2d.position.y = player.collider_pos_lock_y

func physics_update(delta: float):
	player.apply_gravity(delta)
	player.move_and_slide()
	
	if roll_timer > 0:
		roll_timer -= delta
		if roll_timer <= 0:
			if Input.is_action_pressed("down") and player.crouch:
				Transitioned.emit(self, "Crouch")
			elif player.is_on_floor():
				var dir = Input.get_axis("move_left", "move_right")
				if dir != 0:
					Transitioned.emit(self, "Move")
				else:
					Transitioned.emit(self, "Idle")
			else:
				Transitioned.emit(self, "Fall")
