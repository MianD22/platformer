extends State

@onready var enemy = $"../.." # Adjust this if your path to the CharacterBody2D is different

func enter():
	enemy.animation_player.play("Idle")

func update(_delta):
	# Transition to attack state the moment the player walks into the DetectionZone
	if enemy.target != null:
		Transitioned.emit(self, "EnemyAttack")
