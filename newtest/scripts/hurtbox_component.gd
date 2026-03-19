extends Area2D
class_name HurtboxComponent

@export var health_component: HealthComponent
@export var invincibility_duration: float = 1.0
@export var is_invincibility_enabled: bool = false

var is_invincible: bool = false
signal invincibility_started

func _ready():
	area_entered.connect(_on_area_entered)

func _on_area_entered(area: Area2D):
	if is_invincibility_enabled and is_invincible:
		return
		
	if area is HitboxComponent:
		if health_component:
			health_component.take_damage(area.damage)
			if is_invincibility_enabled and health_component.current_health > 0:
				start_invincibility()
		else:
			print("Warning: HurtboxComponent hit, but no HealthComponent assigned!")

func start_invincibility():
	is_invincible = true
	invincibility_started.emit()
	
	await get_tree().create_timer(invincibility_duration).timeout
	
	is_invincible = false
