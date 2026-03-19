extends State
class_name PlayerAttack

@export var player: CharacterBody2D
@export var animation_player: AnimationPlayer
@export var hitbox_collision: CollisionShape2D

var is_anim_finished = false
var was_in_air = false
var hang_timer: float = 0.0

func enter():
	animation_player.play("Attack")
	hitbox_collision.disabled = false
	is_anim_finished = false
	
	# Mirror hitbox position based on facing direction
	var hitbox = hitbox_collision.get_parent()
	if player.sprite_2d.flip_h:
		hitbox.position.x = -abs(hitbox.position.x)
		hitbox.scale.x = -1
	else:
		hitbox.position.x = abs(hitbox.position.x)
		hitbox.scale.x = 1
	
	# Air attack logic
	was_in_air = not player.is_on_floor()
	if was_in_air:
		player.air_attack_count += 1
		if player.air_attack_count <= player.air_attack_hits:
			# Suspending air attack: freeze in the air
			player.gravity_active = false
			player.velocity.y = 0
			hang_timer = player.air_hang_time
	
	if not animation_player.animation_finished.is_connected(_on_animation_finished):
		animation_player.animation_finished.connect(_on_animation_finished)

func exit():
	hitbox_collision.disabled = true
	player.gravity_active = true
	if animation_player.animation_finished.is_connected(_on_animation_finished):
		animation_player.animation_finished.disconnect(_on_animation_finished)

func physics_update(delta: float):
	# Handle air hang timer
	if hang_timer > 0:
		hang_timer -= delta
		if hang_timer <= 0:
			player.gravity_active = true
	
	# Only apply gravity if on ground or past the suspending hit limit
	if not was_in_air or player.air_attack_count > player.air_attack_hits or hang_timer <= 0:
		player.apply_gravity(delta)
	
	# Slide to a stop when attacking
	player.apply_horizontal_movement(0, delta)
	player.move_and_slide()
	
	if is_anim_finished and hang_timer <= 0:
		if not player.is_on_floor():
			Transitioned.emit(self, "Fall")
		elif player.velocity.x == 0 and Input.get_axis("move_left", "move_right") == 0:
			Transitioned.emit(self, "Idle")
		else:
			Transitioned.emit(self, "Move")

func _on_animation_finished(anim_name: StringName):
	if anim_name == "Attack":
		is_anim_finished = true
