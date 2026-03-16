extends State
class_name PlayerAttack

@export var player: CharacterBody2D
@export var animation_player: AnimationPlayer
@export var hitbox_collision: CollisionShape2D

var is_anim_finished = false

func enter():
	animation_player.play("Attack")
	hitbox_collision.disabled = false
	is_anim_finished = false
	if not animation_player.animation_finished.is_connected(_on_animation_finished):
		animation_player.animation_finished.connect(_on_animation_finished)

func exit():
	hitbox_collision.disabled = true
	if animation_player.animation_finished.is_connected(_on_animation_finished):
		animation_player.animation_finished.disconnect(_on_animation_finished)

func physics_update(delta: float):
	player.apply_gravity(delta)
	
	# Slide to a stop when attacking
	player.apply_horizontal_movement(0, delta)
	player.move_and_slide()
	
	if is_anim_finished:
		if player.velocity.x == 0 and Input.get_axis("move_left", "move_right") == 0:
			Transitioned.emit(self, "Idle")
		else:
			Transitioned.emit(self, "Move")

func _on_animation_finished(anim_name: StringName):
	if anim_name == "Attack":
		is_anim_finished = true
