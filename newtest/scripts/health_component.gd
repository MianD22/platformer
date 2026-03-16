extends Node2D
class_name HealthComponent

signal died
signal health_changed(current_health, max_health)

@export var max_health: int = 100
var current_health: int

func _ready():
	current_health = max_health

func take_damage(amount: int):
	current_health = max(0, current_health - amount)
	health_changed.emit(current_health, max_health)
	
	if current_health == 0:
		died.emit()
