extends CharacterBody2D

# Configurable Stats (Adapted from UltimatePlatformerController)
@export_category("L/R Movement")
@export var max_speed: float = 200.0
@export var accel_time: float = 0.2
@export var decel_time: float = 0.2

@export_category("Jumping and Gravity")
@export var jump_height: float = 2.0
@export var gravity_scale: float = 20.0
@export var terminal_velocity: float = 500.0
@export var descending_gravity_factor: float = 1.3
@export var short_hop: bool = true
@export var coyote_time: float = 0.2
@export var jump_buffering: float = 0.2

# Derived stats
var acceleration: float
var deceleration: float
var jump_magnitude: float

# Input Timers
var jump_buffer_timer: float = 0.0
var coyote_timer: float = 0.0

@onready var animated_sprite = $AnimatedSprite2D
@onready var hitbox = $HitboxComponent
@onready var hitbox_collision = hitbox.get_node("CollisionShape2D")

func _ready():
	hitbox_collision.disabled = true
	update_stats()

func update_stats():
	acceleration = max_speed / max(0.001, accel_time)
	deceleration = max_speed / max(0.001, decel_time)
	jump_magnitude = (10.0 * jump_height) * gravity_scale

func _physics_process(delta):
	# Update timers for Coyote Time and Jump Buffering globally
	if is_on_floor():
		coyote_timer = coyote_time
	else:
		coyote_timer -= delta
		
	if Input.is_action_just_pressed("jump"):
		jump_buffer_timer = jump_buffering
	else:
		jump_buffer_timer -= delta

func consume_jump():
	coyote_timer = 0.0
	jump_buffer_timer = 0.0

func apply_gravity(delta):
	var applied_gravity = gravity_scale
	if velocity.y > 0:
		applied_gravity = gravity_scale * descending_gravity_factor
		
	if velocity.y < terminal_velocity:
		velocity.y += applied_gravity
	elif velocity.y > terminal_velocity:
		velocity.y = terminal_velocity

func apply_horizontal_movement(direction, delta):
	if direction != 0:
		velocity.x = move_toward(velocity.x, direction * max_speed, acceleration * delta)
		if direction > 0:
			animated_sprite.flip_h = false
			hitbox.scale.x = 1
		else:
			animated_sprite.flip_h = true
			hitbox.scale.x = -1
	else:
		velocity.x = move_toward(velocity.x, 0, deceleration * delta)
