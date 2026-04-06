extends State
class_name PlayerDodge

@export var player: CharacterBody2D
@export var animation_player: AnimationPlayer

var dodge_timer: float = 0.0
## Fraction of dodge_duration at each edge that counts as a "perfect" dodge.
var perfect_dodge_margin: float = 0.2

func enter():
	# Make the player invulnerable during the dodge
	player.hurtbox_component.is_invincible = true

	# Disable gravity so the dodge is a clean horizontal slide
	player.gravity_active = false

	# Reuse the Walk animation (no new art needed)
	if animation_player.has_animation("Walk"):
		animation_player.play("Walk")

	# Determine dodge direction: use input if held, otherwise dodge backwards if standing still
	var dir = Input.get_axis("move_left", "move_right")
	if dir == 0:
		dir = 1.0 if player.sprite_2d.flip_h else -1.0

	player.velocity = Vector2(dir * player.dodge_speed, 0)
	dodge_timer = player.dodge_duration

	# Listen for projectiles passing through the hurtbox while invincible
	if not player.hurtbox_component.area_entered.is_connected(_on_dodge_area_entered):
		player.hurtbox_component.area_entered.connect(_on_dodge_area_entered)

func exit():
	player.gravity_active = true
	player.hurtbox_component.is_invincible = false

	# Stop listening once the dodge is over
	if player.hurtbox_component.area_entered.is_connected(_on_dodge_area_entered):
		player.hurtbox_component.area_entered.disconnect(_on_dodge_area_entered)

func physics_update(delta: float):
	dodge_timer -= delta

	if dodge_timer <= 0:
		if player.is_on_floor():
			Transitioned.emit(self, "Idle")
		else:
			Transitioned.emit(self, "Fall")
		return

	player.move_and_slide()

func _on_dodge_area_entered(area: Area2D) -> void:
	if not area is HitboxComponent:
		return

	# How far into the dodge we are (0 = just started, dodge_duration = about to end)
	var elapsed = player.dodge_duration - dodge_timer
	var margin = perfect_dodge_margin * player.dodge_duration

	# Perfect if the projectile arrived right at the start of the dodge
	if elapsed <= margin:
		print("Perfect Dodge!")
		
		if "pdodge_tp_enabled" in player and player.pdodge_tp_enabled:
			player.force_auto_teleport_timer = 3.0
			Transitioned.emit(self, "Teleport")
			return
			
		if Engine.time_scale == 1.0:
			Engine.time_scale = 0.2
			# Use ignore_time_scale=true so it lasts 0.3 real-world seconds
			await get_tree().create_timer(0.3, true, false, true).timeout
			Engine.time_scale = 1.0
	else:
		print("Dodge!")
