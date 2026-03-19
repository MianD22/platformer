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

func setup(start_pos: Vector2, target_pos: Vector2, speed_modifier: float = 1.0, arc_height: float = 64.0) -> void:
	global_position = start_pos
	
	var displacement = target_pos - start_pos
	
	# If the target is higher than the configured arc height, we must increase the arc so it can reach them!
	# (In Godot, negative Y is up, so displacement.y < 0 means target is above)
	var actual_arc_height = arc_height
	if displacement.y < 0 and abs(displacement.y) > actual_arc_height:
		actual_arc_height = abs(displacement.y) + 16.0 # Peak slightly above the player
		
	# To ensure we reach the requested arc height, the vertical displacement to the peak is actual_arc_height.
	# Using v^2 = u^2 + 2as, at peak v = 0, so u = sqrt(2 * g * h)
	var time_up = sqrt(2 * actual_arc_height / proj_gravity)
	
	# Fall distance from the peak down to the target
	var height_difference = actual_arc_height + displacement.y
	
	# Clamp just in case to avoid math domain errors
	if height_difference < 0:
		height_difference = 0.1 
		
	var time_down = sqrt(2 * height_difference / proj_gravity)
	
	var total_time = time_up + time_down
	
	# Calculate velocities
	velocity.y = -sqrt(2 * proj_gravity * actual_arc_height)
	
	# Apply the speed modifier directly to the horizontal travel time
	velocity.x = (displacement.x / total_time) * speed_modifier

func _on_body_entered(body):
	# Queue free if it hits a wall/floor (Assuming your floor is on a specific collision layer)
	if not body.is_in_group("player"):
		queue_free()
