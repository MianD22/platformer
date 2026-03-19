extends CharacterBody2D

@onready var animation_player = $AnimationPlayer
@onready var state_machine = $StateMachine
@onready var shoot_point = $Marker2D
@onready var detection_zone = $PlayerDetectionZone

var projectile_scene = preload("res://Scenes/enemy_projectile.tscn") # Update path if needed
var target: Node2D = null

# Get the gravity from the project settings to be synced with RigidBody nodes.
var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")

func _physics_process(delta):
	# Add the gravity.
	if not is_on_floor():
		velocity.y += gravity * delta
		
	move_and_slide()

func _ready():
	# Connect the detection zone signals to know when the player is in range
	detection_zone.body_entered.connect(_on_body_entered)
	detection_zone.body_exited.connect(_on_body_exited)

func _on_body_entered(body):
	if body.is_in_group("player"): 
		target = body

func _on_body_exited(body):
	if body == target:
		target = null

# This should be called by the Call Method Track in your 'attack' animation!
func spawn_projectile():
	if target == null: return
	
	var proj = projectile_scene.instantiate()
	# Add projectile to the main scene tree so it moves independently of the enemy
	get_tree().current_scene.add_child(proj) 
	
	# Setup the projectile to calculate the arc math towards the target
	proj.setup(shoot_point.global_position, target.global_position)
