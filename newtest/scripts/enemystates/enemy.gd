extends CharacterBody2D

@onready var animation_player = $AnimationPlayer
@onready var state_machine = $StateMachine
@onready var shoot_point = $Marker2D
@onready var detection_zone = $PlayerDetectionZone
@onready var sprite_2d = $Sprite2D

@export var projectile_speed: float = 200.0 ## The speed of the projectile in pixels per second.
@export var attack_cooldown: float = 2.0 ## How many seconds the enemy waits between attacks.
@export var close_attack_range: float = 50.0 ## Range within which enemy will use melee hit.

@export_group("Damage Feedback")
@export var flash_duration: float = 0.3
@export var flashes_count: int = 3

var attack_timer: float = 0.0

var projectile_scene = preload("res://Scenes/enemy_projectile.tscn") # Update path if needed
var target: Node2D = null

# Get the gravity from the project settings to be synced with RigidBody nodes.
var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")

@onready var health_component = $HealthComponent

func _physics_process(delta):
	# Add the gravity.
	if not is_on_floor():
		velocity.y += gravity * delta
		
	# Tick down the attack timer regardless of state so the cooldown is preserved
	if attack_timer > 0:
		attack_timer -= delta
		
	move_and_slide()

func _ready():
	health_component.died.connect(queue_free)
	health_component.health_changed.connect(_on_health_changed)
	# Connect the detection zone signals to know when the player is in range
	detection_zone.body_entered.connect(_on_body_entered)
	detection_zone.body_exited.connect(_on_body_exited)

func _on_body_entered(body):
	if body.is_in_group("player"): 
		target = body

func _on_body_exited(body):
	if body == target:
		target = null

func _on_health_changed(_current, _max):
	var tween = create_tween()
	var flash_interval = flash_duration / (flashes_count * 2.0)
	for i in range(flashes_count):
		tween.tween_property(sprite_2d, "modulate:a", 0.0, flash_interval)
		tween.tween_property(sprite_2d, "modulate:a", 1.0, flash_interval)

# This should be called by the Call Method Track in your 'attack' animation!
func spawn_projectile():
	if target == null: return
	
	var proj = projectile_scene.instantiate()
	# Add projectile to the main scene tree so it moves independently of the enemy
	get_tree().current_scene.add_child(proj) 
	
	# Setup the projectile to shoot straight towards the target
	proj.setup(shoot_point.global_position, target.global_position, projectile_speed)
