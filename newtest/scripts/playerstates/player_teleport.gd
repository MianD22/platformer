extends State
class_name PlayerTeleport

@export var player: CharacterBody2D
@export var animation_player: AnimationPlayer
@export var hologram_speed: float = 250.0 ## How fast the hologram moves

var hologram: Sprite2D
var camera: Camera2D
var original_process_mode: Node.ProcessMode

func enter():
	# Save original process mode so we can restore it later
	original_process_mode = player.process_mode

	# Pause the entire scene tree (freezes all nodes that inherit pause)
	player.get_tree().paused = true

	# Let the player (and its children: state machine, states) keep processing
	player.process_mode = Node.PROCESS_MODE_ALWAYS

	# Zero out player velocity so they don't slide when we resume
	player.velocity = Vector2.ZERO

	# Create the hologram sprite
	hologram = Sprite2D.new()
	hologram.texture = player.sprite_2d.texture
	hologram.hframes = player.sprite_2d.hframes
	hologram.vframes = player.sprite_2d.vframes
	hologram.frame = player.sprite_2d.frame
	hologram.flip_h = player.sprite_2d.flip_h
	hologram.modulate = Color(0.3, 0.5, 1.0, 0.5) # Blue and transparent
	hologram.process_mode = Node.PROCESS_MODE_ALWAYS

	# Add hologram to the scene root, THEN set position (must be in tree first)
	player.get_tree().current_scene.add_child(hologram)
	hologram.global_position = player.global_position

	# Move camera to follow the hologram
	camera = player.get_node("Camera2D")
	if camera:
		camera.reparent(hologram)

	# Hide the real player sprite
	player.sprite_2d.visible = false

func exit():
	# Safety cleanup in case something exits the state unexpectedly
	_cleanup()

func physics_update(_delta: float):
	if not is_instance_valid(hologram):
		return

	# Check for teleport key to finish
	if Input.is_action_just_pressed("teleport"):
		_finish_teleport()
		return

	# Move the hologram with the standard movement inputs
	var dir_x = Input.get_axis("move_left", "move_right")
	var dir_y = Input.get_axis("up", "down")
	var move_dir = Vector2(dir_x, dir_y)
	if move_dir.length() > 1.0:
		move_dir = move_dir.normalized()

	hologram.global_position += move_dir * hologram_speed * _delta

	# Flip hologram sprite to face movement direction
	if dir_x > 0:
		hologram.flip_h = false
	elif dir_x < 0:
		hologram.flip_h = true

func _finish_teleport():
	if is_instance_valid(hologram):
		# Teleport the player to the hologram's position
		player.global_position = hologram.global_position

	_cleanup()

	# Transition to the appropriate state
	if player.is_on_floor():
		Transitioned.emit(self, "Idle")
	else:
		Transitioned.emit(self, "Fall")

func _cleanup():
	# Remove hologram
	if is_instance_valid(hologram):
		hologram.queue_free()
		hologram = null

	# Move camera back to the player
	if is_instance_valid(camera):
		camera.reparent(player)
		camera = null

	# Unpause the scene tree and restore process mode
	player.get_tree().paused = false
	player.process_mode = original_process_mode

	# Show the real player sprite
	player.sprite_2d.visible = true
