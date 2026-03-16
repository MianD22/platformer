extends State
class_name PlayerCrouch

@export var player: CharacterBody2D
@export var animation_player: AnimationPlayer

func enter():
	player.max_speed_active = player.max_speed_lock / 2.0
	player.collision_shape_2d.scale.y = player.collider_scale_lock_y / 2.0
	player.collision_shape_2d.position.y = player.collider_pos_lock_y + (8 * player.collider_scale_lock_y)
	
	if animation_player.has_animation("crouch_idle") and player.velocity.x == 0:
		animation_player.play("crouch_idle")
	elif animation_player.has_animation("crouch_walk") and player.velocity.x != 0:
		animation_player.play("crouch_walk")
	else:
		if animation_player.has_animation("Walk"):
			animation_player.play("Walk")

func exit():
	player.collision_shape_2d.scale.y = player.collider_scale_lock_y
	player.collision_shape_2d.position.y = player.collider_pos_lock_y

func physics_update(delta: float):
	player.apply_gravity(delta)
	
	var direction = Input.get_axis("move_left", "move_right")
	player.apply_horizontal_movement(direction, delta)
	player.move_and_slide()
	
	if Input.is_action_just_pressed("roll") and player.can_roll:
		Transitioned.emit(self, "Roll")
		return
		
	if not Input.is_action_pressed("down"):
		if direction != 0:
			Transitioned.emit(self, "Move")
		else:
			Transitioned.emit(self, "Idle")
		return
		
	if not player.is_on_floor():
		Transitioned.emit(self, "Fall")
		return
