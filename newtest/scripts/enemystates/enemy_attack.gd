extends State

@onready var enemy = $"../.."
var is_attacking: bool = false

func enter():
	# Don't reset the timer here, let the main enemy script keep count
	pass

func update(_delta):
	# If player leaves range and we aren't mid-attack, go back to idle
	if enemy.target == null and not is_attacking:
		Transitioned.emit(self, "EnemyIdle")
		return
		
	if enemy.attack_timer <= 0.0 and not is_attacking:
		attack()

func attack():
	enemy.attack_timer = enemy.attack_cooldown
	is_attacking = true
	# Play the animation (which will trigger spawn_projectile() halfway through)
	enemy.animation_player.play("Attack")
	
	# Wait for the animation to finish before doing anything else
	await enemy.animation_player.animation_finished
	is_attacking = false
	
	# Loop back to idle animation while waiting for cooldown
	enemy.animation_player.play("Idle")
