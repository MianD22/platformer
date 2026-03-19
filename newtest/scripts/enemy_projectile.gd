extends Area2D

var velocity: Vector2 = Vector2.ZERO
var proj_gravity: float = ProjectSettings.get_setting("physics/2d/default_gravity")

func _ready():
	# Destroy the projectile when it hits the environment
	body_entered.connect(_on_body_entered)

func _physics_process(delta: float) -> void:
	# Apply gravity and move
	velocity.y += proj_gravity * delta
	position += velocity * delta
	
	# Optional: Rotates the projectile to face the direction it's falling/moving
	rotation = velocity.angle()

func setup(start_pos: Vector2, target_pos: Vector2) -> void:
	global_position = start_pos
	
	var time_to_hit := 1.0 # The time (in seconds) it takes to reach the target. Lower = faster throw
	var displacement = target_pos - start_pos
	
	# Kinematic equations to perfectly hit the target in an arc
	velocity.x = displacement.x / time_to_hit
	velocity.y = (displacement.y - 0.5 * proj_gravity * time_to_hit * time_to_hit) / time_to_hit

func _on_body_entered(body):
	# Queue free if it hits a wall/floor (Assuming your floor is on a specific collision layer)
	if not body.is_in_group("player"):
		queue_free()
