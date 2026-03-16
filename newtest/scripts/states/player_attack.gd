extends State
class_name PlayerAttack

@export var player: CharacterBody2D
@export var animated_sprite: AnimatedSprite2D
@export var hitbox_collision: CollisionShape2D

var is_anim_finished = false

func enter():
	animated_sprite.play("attack_side")
	hitbox_collision.disabled = false
	is_anim_finished = false
	animated_sprite.animation_finished.connect(_on_animation_finished)

func exit():
	hitbox_collision.disabled = true
	animated_sprite.animation_finished.disconnect(_on_animation_finished)

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

func _on_animation_finished():
	if animated_sprite.animation == "attack_side":
		is_anim_finished = true
