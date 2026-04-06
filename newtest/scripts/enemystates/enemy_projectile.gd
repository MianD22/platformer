extends Area2D

var velocity: Vector2 = Vector2.ZERO

func _ready():
	# Destroy the projectile when it hits the environment
	body_entered.connect(_on_body_entered)

func _physics_process(delta: float) -> void:
	# Move straight ahead
	position += velocity * delta
	
	# Rotates the projectile to face the direction it's moving
	rotation = velocity.angle()

func setup(start_pos: Vector2, target_pos: Vector2, speed: float = 200.0) -> void:
	global_position = start_pos
	
	# Fly in a straight line directly at the target
	var direction = (target_pos - start_pos).normalized()
	velocity = direction * speed

func _on_body_entered(body):
	# Queue free if it hits a wall/floor (Assuming your floor is on a specific collision layer)
	if not body.is_in_group("player"):
		queue_free()
