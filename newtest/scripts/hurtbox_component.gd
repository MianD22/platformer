extends Area2D
class_name HurtboxComponent

@export var health_component: HealthComponent

func _ready():
	area_entered.connect(_on_area_entered)

func _on_area_entered(area: Area2D):
	if area is HitboxComponent:
		if health_component:
			health_component.take_damage(area.damage)
		else:
			print("Warning: HurtboxComponent hit, but no HealthComponent assigned!")
