extends State
class_name PlayerDodge

@export var player: CharacterBody2D
@export var animation_player: AnimationPlayer

var dodge_timer: float = 0.0

func enter():
	# Make the player invulnerable during the dodge
	player.hurtbox_component.is_invincible = true

	# Disable gravity so the dodge is a clean horizontal slide
	player.gravity_active = false

	# Reuse the Walk animation (no new art needed)
	if animation_player.has_animation("Walk"):
		animation_player.play("Walk")

	# Determine dodge direction: use input if held, otherwise face direction
	var dir = Input.get_axis("move_left", "move_right")
	if dir == 0:
		dir = -1.0 if player.sprite_2d.flip_h else 1.0

	player.velocity = Vector2(dir * player.dodge_speed, 0)
	dodge_timer = player.dodge_duration

func exit():
	player.gravity_active = true
	player.hurtbox_component.is_invincible = false

func physics_update(delta: float):
	dodge_timer -= delta

	if dodge_timer <= 0:
		if player.is_on_floor():
			Transitioned.emit(self, "Idle")
		else:
			Transitioned.emit(self, "Fall")
		return

	player.move_and_slide()
