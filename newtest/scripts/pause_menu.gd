extends Control

@onready var double_jump_toggle = $VBoxContainer/DoubleJumpToggle
@onready var teleport_toggle = $VBoxContainer/TeleportToggle
@onready var ground_pound_toggle = $VBoxContainer/GroundPoundToggle
@onready var wall_jump_toggle = $VBoxContainer/WallJumpToggle
@onready var wall_slide_toggle = $VBoxContainer/WallSlideToggle
@onready var wall_latch_toggle = $VBoxContainer/WallLatchToggle
@onready var pdodge_tp_toggle = get_node_or_null("VBoxContainer/PDodgeTPToggle")
@onready var resume_button = $VBoxContainer/ResumeButton

# Change this value to match your desired wall slide friction
# (In player_fall.gd, a value of 1.0 means wall sliding is disabled)
var default_wall_slide_value: float = 0.5 

func _ready():
	visible = false
	process_mode = Node.PROCESS_MODE_ALWAYS
	
	if resume_button:
		resume_button.pressed.connect(_on_resume_pressed)
	if double_jump_toggle:
		double_jump_toggle.toggled.connect(_on_double_jump_toggled)
	if teleport_toggle:
		teleport_toggle.toggled.connect(_on_teleport_toggled)
	if ground_pound_toggle:
		ground_pound_toggle.toggled.connect(_on_ground_pound_toggled)
	if wall_jump_toggle:
		wall_jump_toggle.toggled.connect(_on_wall_jump_toggled)
	if wall_slide_toggle:
		wall_slide_toggle.toggled.connect(_on_wall_slide_toggled)
	if wall_latch_toggle:
		wall_latch_toggle.toggled.connect(_on_wall_latch_toggled)
	if pdodge_tp_toggle:
		pdodge_tp_toggle.toggled.connect(_on_pdodge_tp_toggled)

func _unhandled_input(event):
	if event.is_action_pressed("pause"):
		toggle_pause()
		get_viewport().set_input_as_handled()

func toggle_pause():
	var paused = not get_tree().paused
	get_tree().paused = paused
	visible = paused
	
	if paused:
		_load_current_settings()

func _on_resume_pressed():
	toggle_pause()

func _load_current_settings():
	var player = get_tree().get_first_node_in_group("player")
	if not player:
		return
	
	if double_jump_toggle:
		double_jump_toggle.set_pressed_no_signal(player.jumps > 0)
	if ground_pound_toggle:
		ground_pound_toggle.set_pressed_no_signal(player.ground_pound)
	if wall_jump_toggle:
		wall_jump_toggle.set_pressed_no_signal(player.wall_jump)
	if wall_slide_toggle:
		# In this project, wall_sliding = 1.0 means it is disabled
		wall_slide_toggle.set_pressed_no_signal(player.wall_sliding != 1.0)
	if wall_latch_toggle:
		wall_latch_toggle.set_pressed_no_signal(player.wall_latching)
	
	if teleport_toggle:
		if "teleport_enabled" in player:
			teleport_toggle.set_pressed_no_signal(player.teleport_enabled)
		else:
			teleport_toggle.set_pressed_no_signal(false)
			
	if pdodge_tp_toggle:
		if "pdodge_tp_enabled" in player:
			pdodge_tp_toggle.set_pressed_no_signal(player.pdodge_tp_enabled)
		else:
			pdodge_tp_toggle.set_pressed_no_signal(false)

func _on_double_jump_toggled(button_pressed: bool):
	var player = get_tree().get_first_node_in_group("player")
	if player:
		player.jumps = 1 if button_pressed else 0

func _on_teleport_toggled(button_pressed: bool):
	var player = get_tree().get_first_node_in_group("player")
	if player:
		if "teleport_enabled" in player:
			player.teleport_enabled = button_pressed
		else:
			push_warning("You need to add 'var teleport_enabled: bool = true' to player.gd!")

func _on_ground_pound_toggled(button_pressed: bool):
	var player = get_tree().get_first_node_in_group("player")
	if player:
		player.ground_pound = button_pressed

func _on_wall_jump_toggled(button_pressed: bool):
	var player = get_tree().get_first_node_in_group("player")
	if player:
		player.wall_jump = button_pressed

func _on_wall_slide_toggled(button_pressed: bool):
	var player = get_tree().get_first_node_in_group("player")
	if player:
		# 1.0 means disabled (regular gravity). If toggled on, we apply default_wall_slide_value.
		player.wall_sliding = default_wall_slide_value if button_pressed else 1.0

func _on_wall_latch_toggled(button_pressed: bool):
	var player = get_tree().get_first_node_in_group("player")
	if player:
		player.wall_latching = button_pressed

func _on_pdodge_tp_toggled(button_pressed: bool):
	var player = get_tree().get_first_node_in_group("player")
	if player:
		if "pdodge_tp_enabled" in player:
			player.pdodge_tp_enabled = button_pressed
