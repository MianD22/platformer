extends CharacterBody2D

# Configurable Stats (Adapted from UltimatePlatformerController)
@export_category("L/R Movement")
@export var max_speed: float = 200.0
@export var accel_time: float = 0.2
@export var decel_time: float = 0.2
@export var running_modifier: bool = false

@export_category("Jumping and Gravity")
@export var jumps: int = 1
@export var jump_height: float = 2.0
@export var gravity_scale: float = 20.0
@export var terminal_velocity: float = 500.0
@export var descending_gravity_factor: float = 1.3
@export var short_hop: bool = true
@export var coyote_time: float = 0.2
@export var jump_buffering: float = 0.2

@export_category("Wall Jumping")
@export var wall_jump: bool = false
@export var input_pause_after_wall_jump: float = 0.1
@export var wall_kick_angle: float = 60.0
@export var wall_sliding: float = 1.0
@export var wall_latching: bool = false
@export var wall_latching_modifier: bool = false

@export_category("Dashing")
@export_enum("None", "Horizontal", "Vertical", "Four Way", "Eight Way") var dash_type: int
@export var dashes: int = 1
@export var dash_cancel: bool = true
@export var dash_length: float = 2.5

@export_category("Corner Cutting/Jump Correct")
@export var corner_cutting: bool = false
@export var correction_amount: float = 1.5
@export var left_raycast: RayCast2D
@export var middle_raycast: RayCast2D
@export var right_raycast: RayCast2D

@export_category("Down Input")
@export var crouch: bool = false
@export var can_roll: bool = false
@export var roll_length: float = 2.0
@export var ground_pound: bool = false
@export var ground_pound_pause: float = 0.25
@export var up_to_cancel: bool = false

# Derived stats
var acceleration: float
var deceleration: float
var jump_magnitude: float
var dash_magnitude: float
var max_speed_lock: float

# State tracking
var max_speed_active: float
var jump_count: int
var dash_count: int
var gravity_active: bool = true

# Input Timers & States
var jump_buffer_timer: float = 0.0
var coyote_timer: float = 0.0
var movement_input_monitoring: bool = true
var movement_input_monitoring_timer: float = 0.0

var collider_scale_lock_y: float
var collider_pos_lock_y: float

@onready var sprite_2d = $Sprite2D
@onready var animation_player = $AnimationPlayer
@onready var hitbox = $HitboxComponent
@onready var hitbox_collision = hitbox.get_node("CollisionShape2D")
@onready var collision_shape_2d = $CollisionShape2D

func _ready():
	hitbox_collision.disabled = true
	update_stats()
	jump_count = jumps
	dash_count = dashes
	max_speed_lock = max_speed
	max_speed_active = max_speed
	collider_scale_lock_y = collision_shape_2d.scale.y
	collider_pos_lock_y = collision_shape_2d.position.y

func update_stats():
	acceleration = max_speed_active / max(0.001, accel_time)
	deceleration = max_speed_active / max(0.001, decel_time)
	jump_magnitude = (10.0 * jump_height) * gravity_scale
	dash_magnitude = max_speed_lock * dash_length

func _physics_process(delta):
	# running modifier logic
	if running_modifier and not Input.is_action_pressed("run"):
		max_speed_active = max_speed_lock / 2.0
	elif is_on_floor():
		max_speed_active = max_speed_lock
		
	update_stats()

	# Update timers for Coyote Time and Jump Buffering globally
	if is_on_floor():
		coyote_timer = coyote_time
		jump_count = jumps
		dash_count = dashes
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
	if not gravity_active:
		return
		
	var applied_gravity = gravity_scale
	if velocity.y > 0:
		applied_gravity = gravity_scale * descending_gravity_factor
		
	if velocity.y < terminal_velocity:
		velocity.y += applied_gravity
	elif velocity.y > terminal_velocity:
		velocity.y = terminal_velocity

func wall_kick(dir: int):
	var horizontal_kick = abs(jump_magnitude * cos(wall_kick_angle * (PI / 180)))
	var vertical_kick = abs(jump_magnitude * sin(wall_kick_angle * (PI / 180)))
	velocity.y = -vertical_kick
	velocity.x = horizontal_kick * dir
	if input_pause_after_wall_jump > 0:
		pause_input_for(input_pause_after_wall_jump)
	consume_jump()

func pause_input_for(duration: float):
	movement_input_monitoring = false
	movement_input_monitoring_timer = duration

func apply_horizontal_movement(direction, delta):
	if movement_input_monitoring_timer > 0.0:
		movement_input_monitoring_timer -= delta
		if movement_input_monitoring_timer <= 0.0:
			movement_input_monitoring = true
			
	var actual_direction = direction if movement_input_monitoring else 0.0
			
	if actual_direction != 0:
		velocity.x = move_toward(velocity.x, actual_direction * max_speed_active, acceleration * delta)
		if actual_direction > 0:
			sprite_2d.flip_h = false
			hitbox.scale.x = 1
		else:
			sprite_2d.flip_h = true
			hitbox.scale.x = -1
	else:
		velocity.x = move_toward(velocity.x, 0, deceleration * delta)
		
	# Corner Cutting
	if corner_cutting and velocity.y < 0:
		if left_raycast and middle_raycast and right_raycast:
			if left_raycast.is_colliding() and not middle_raycast.is_colliding() and not right_raycast.is_colliding():
				position.x += correction_amount
			elif not left_raycast.is_colliding() and not middle_raycast.is_colliding() and right_raycast.is_colliding():
				position.x -= correction_amount
