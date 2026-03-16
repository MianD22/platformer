extends CharacterBody2D

enum STATE {
	FALL,
	FLOOR,
	JUMP,
	DOUBLE_JUMP,
	FLOAT,
	LEDGE_CLIMB,
	LEDGE_JUMP,
	WALL_SLIDE,
	WALL_JUMP,
	WALL_CLIMB,
	DASH,
	TURNING,
	BASH,
	BASH_LAUNCH,
	RECOIL,
}

const FALL_GRAVITY := 1500.0
const FALL_VELOCITY := 500.0
const WALK_VELOCITY := 200.0
const JUMP_VELOCITY := -600.0
const JUMP_DECELERATION := 1500.0
const DOUBLE_JUMP_VELOCITY := -450.0
const POGO_VELOCITY := -600.0
const FLOAT_GRAVITY := 200.0
const FLOAT_VELOCITY := 100.0
const FLOAT_ACCELERATION := 700.0
const LEDGE_JUMP_VELOCITY := -500.0
const WALL_SLIDE_GRAVITY := 300.0
const WALL_SLIDE_VELOCITY := 500.0
const WALL_JUMP_LENGTH := 30.0
const WALL_JUMP_VELOCITY := -500.0
const WALL_CLIMB_VELOCITY := -300.0
const WALL_CLIMB_LENGTH := 65.0
const DASH_LENGTH := 100.0
const DASH_VELOCITY := 600.0
const SPRINT_VELOCITY := 400.0
const SPRINT_ACCELERATION := 1800.0

@export_group("Bash Settings")
@export var bash_velocity: float = 1000.0
@export var bash_launch_duration: float = 0.2

@export_group("Health Settings")
@export var max_health: int = 5
@export var recoil_velocity: Vector2 = Vector2(150, -150)
@export var recoil_duration: float = 0.2
const INVULNERABILITY_DURATION = 1.0

var current_health: int
var recoil_timer: float = 0.0
var invulnerability_timer: float = 0.0

@onready var animated_sprite: AnimatedSprite2D = %AnimatedSprite
@onready var coyote_timer: Timer = %CoyoteTimer
@onready var float_cooldown: Timer = %FloatCooldown
@onready var player_collider: CollisionShape2D = %PlayerCollider
@onready var ledge_climb_ray_cast: RayCast2D = %LedgeClimbRayCast
@onready var ledge_space_ray_cast: RayCast2D = %LedgeSpaceRayCast
@onready var wall_slide_ray_cast: RayCast2D = %WallSlideRayCast
@onready var dash_cooldown: Timer = %DashCooldown
@onready var attack_area: Area2D = %AttackArea

var active_state := STATE.FALL
var can_double_jump := false
var facing_direction := 1.0
var saved_position := Vector2.ZERO
var can_dash := false
var dash_jump_buffer := false
var is_sprinting := false
var bash_launch_timer := 0.0
var is_attacking := false
var default_attack_position := Vector2.ZERO
var current_bash_target: Node2D = null
var can_bash_target: bool = false

func _ready() -> void:
	add_to_group("player")
	current_health = max_health
	default_attack_position = attack_area.position
	switch_state(active_state)
	ledge_climb_ray_cast.add_exception(self)
	attack_area.monitoring = false
	animated_sprite.sprite_frames.set_animation_loop("attack", false)
	if animated_sprite.sprite_frames.has_animation("attack_up"):
		animated_sprite.sprite_frames.set_animation_loop("attack_up", false)
	if animated_sprite.sprite_frames.has_animation("attack_down"):
		animated_sprite.sprite_frames.set_animation_loop("attack_down", false)
	animated_sprite.animation_finished.connect(_on_animation_finished)
	attack_area.body_entered.connect(_on_attack_area_body_entered)


func _physics_process(delta: float) -> void:
	handle_attack()
	handle_bash()
	process_state(delta)
	process_invulnerability(delta)
	move_and_slide()
	handle_enemy_collision()


func switch_state(to_state: STATE) -> void:
	var previous_state := active_state
	active_state = to_state
	
	## State specific things that only need to run once upon entering the next state.
	match active_state:
		STATE.FALL:
			if previous_state != STATE.DOUBLE_JUMP and not is_attacking:
				animated_sprite.play("fall")
			if previous_state == STATE.FLOOR:
				coyote_timer.start()
		
		STATE.FLOOR:
			can_double_jump = true
			can_dash = true
		
		STATE.JUMP:
			if previous_state != STATE.TURNING and not is_attacking:
				animated_sprite.play("jump")
			velocity.y = JUMP_VELOCITY
			coyote_timer.stop()
		
		STATE.DOUBLE_JUMP:
			if not is_attacking:
				animated_sprite.play("double_jump")
			velocity.y = DOUBLE_JUMP_VELOCITY
			can_double_jump = false
			is_sprinting = false
		
		STATE.FLOAT:
			if float_cooldown.time_left > 0:
				active_state = previous_state
				return
			animated_sprite.play("float")
			velocity.y = 0
			is_sprinting = false
		
		STATE.LEDGE_CLIMB:
			animated_sprite.play("ledge_climb")
			velocity = Vector2.ZERO
			global_position.y = ledge_climb_ray_cast.get_collision_point().y
			can_double_jump = true
		
		STATE.LEDGE_JUMP:
			animated_sprite.play("double_jump")
			velocity.y = LEDGE_JUMP_VELOCITY
			can_dash = true
			is_sprinting = false
		
		STATE.WALL_SLIDE:
			animated_sprite.play("wall_slide")
			velocity.y = 0
			can_double_jump = true
			can_dash = true
			is_sprinting = false
		
		STATE.WALL_JUMP:
			animated_sprite.play("jump")
			velocity.y = WALL_JUMP_VELOCITY
			set_facing_direction(-facing_direction)
			saved_position = position
		
		STATE.WALL_CLIMB:
			animated_sprite.play("wall_climb")
			velocity.y = WALL_CLIMB_VELOCITY
			saved_position = position
		
		STATE.DASH:
			if dash_cooldown.time_left > 0:
				active_state = previous_state
				return
			animated_sprite.play("dash")
			velocity.y = 0
			set_facing_direction(signf(Input.get_axis("move_left", "move_right")))
			velocity.x = facing_direction * DASH_VELOCITY
			saved_position = position
			can_dash = previous_state == STATE.FLOOR or previous_state == STATE.WALL_SLIDE
			dash_jump_buffer = false
		
		STATE.TURNING:
			set_facing_direction(-facing_direction)
		
		STATE.BASH:
			velocity = Vector2.ZERO
			animated_sprite.play("jump") # Or bash animation
			Engine.time_scale = 0.05 # Slow motion
		
		STATE.RECOIL:
			animated_sprite.play("jump") # Use jump or hit animation
			# Velocity set in take_damage
			can_double_jump = false
			can_dash = false
			is_sprinting = false


func process_state(delta: float) -> void:
	match active_state:
		STATE.FALL:
			velocity.y = move_toward(velocity.y, FALL_VELOCITY, FALL_GRAVITY * delta)
			handle_movement()
			
			if is_on_floor():
				switch_state(STATE.FLOOR)
			elif Input.is_action_just_pressed("jump"):
				if coyote_timer.time_left > 0:
					switch_state(STATE.JUMP)
				elif can_double_jump:
					switch_state(STATE.DOUBLE_JUMP)
				else:
					switch_state(STATE.FLOAT)
			elif is_input_toward_facing() and is_ledge() and is_space():
				switch_state(STATE.LEDGE_CLIMB)
			elif is_input_toward_facing() and can_wall_slide():
				switch_state(STATE.WALL_SLIDE)
			elif Input.is_action_just_pressed("sprint") and can_dash and not is_attacking:
				switch_state(STATE.DASH)
		
		STATE.FLOOR:
			if is_sprinting:
				if not is_attacking:
					animated_sprite.play("sprint")
				handle_sprint(delta)
			else:
				if not is_attacking:
					if Input.get_axis("move_left", "move_right"):
						animated_sprite.play("walk")
					else:
						animated_sprite.play("idle")
				handle_movement()
			
			if not is_on_floor():
				switch_state(STATE.FALL)
			elif Input.is_action_just_pressed("jump"):
				switch_state(STATE.JUMP)
			elif Input.is_action_just_pressed("sprint") and not is_attacking:
				switch_state(STATE.DASH)
			elif is_sprinting and is_input_against_facing():
				switch_state(STATE.TURNING)
		
		STATE.JUMP, STATE.DOUBLE_JUMP, STATE.LEDGE_JUMP, STATE.WALL_JUMP:
			velocity.y = move_toward(velocity.y, 0, JUMP_DECELERATION * delta)
			if active_state == STATE.WALL_JUMP:
				var distance := absf(position.x - saved_position.x)
				if distance >= WALL_JUMP_LENGTH or can_wall_slide():
					active_state = STATE.JUMP
				else:
					handle_movement(facing_direction)
			
			elif active_state != STATE.WALL_JUMP:
				handle_movement()
			
			if Input.is_action_just_released("jump") or velocity.y >= 0:
				velocity.y = 0
				switch_state(STATE.FALL)
			elif Input.is_action_just_pressed("jump"):
				switch_state(STATE.DOUBLE_JUMP)
			elif Input.is_action_just_pressed("sprint") and can_dash and not is_attacking:
				switch_state(STATE.DASH)
		
		STATE.FLOAT:
			velocity.y = move_toward(velocity.y, FLOAT_VELOCITY, FLOAT_GRAVITY * delta)
			handle_movement(0, WALK_VELOCITY, FLOAT_ACCELERATION * delta)
			
			if is_on_floor():
				switch_state(STATE.FLOOR)
			elif Input.is_action_just_released("jump"):
				float_cooldown.start()
				switch_state(STATE.FALL)
			elif is_input_toward_facing() and is_ledge() and is_space():
				switch_state(STATE.LEDGE_CLIMB)
			elif is_input_toward_facing() and can_wall_slide():
				switch_state(STATE.WALL_SLIDE)
			elif Input.is_action_just_pressed("sprint") and can_dash and not is_attacking:
				switch_state(STATE.DASH)
		
		STATE.LEDGE_CLIMB:
			is_sprinting = Input.is_action_pressed("sprint")
			if not animated_sprite.is_playing():
				animated_sprite.play("idle")
				var offset := ledge_climb_offset()
				offset.x *= facing_direction
				position += offset
				switch_state(STATE.FLOOR)
			elif Input.is_action_just_pressed("jump"):
				var progress := inverse_lerp(0, animated_sprite.sprite_frames.get_frame_count("ledge_climb"), animated_sprite.frame)
				var offset := ledge_climb_offset()
				offset.x *= facing_direction * progress
				position += offset
				switch_state(STATE.LEDGE_JUMP)
		
		STATE.WALL_SLIDE:
			velocity.y = move_toward(velocity.y, WALL_SLIDE_VELOCITY, WALL_SLIDE_GRAVITY * delta)
			handle_movement()
			
			if is_on_floor():
				switch_state(STATE.FLOOR)
			elif is_ledge() and is_space():
				switch_state(STATE.LEDGE_CLIMB)
			elif not can_wall_slide():
				switch_state(STATE.FALL)
			elif Input.is_action_just_pressed("jump"):
				switch_state(STATE.WALL_JUMP)
			elif Input.is_action_just_pressed("sprint"):
				if is_input_toward_facing():
					switch_state(STATE.WALL_CLIMB)
				else:
					set_facing_direction(-facing_direction)
					switch_state(STATE.DASH)
		
		STATE.WALL_CLIMB:
			var distance := absf(position.y - saved_position.y)
			if distance >= WALL_CLIMB_LENGTH or is_on_ceiling():
				velocity.y = 0
				switch_state(STATE.WALL_SLIDE)
			elif is_ledge():
				switch_state(STATE.LEDGE_JUMP)
		
		STATE.DASH:
			velocity.y = move_toward(velocity.y, FALL_VELOCITY, FALL_GRAVITY * delta)
			is_sprinting = Input.is_action_pressed("sprint")
			dash_cooldown.start()
			if is_on_floor():
				coyote_timer.start()
			if Input.is_action_just_pressed("jump"):
				dash_jump_buffer = true
			var distance := absf(position.x - saved_position.x)
			if distance >= DASH_LENGTH or signf(get_last_motion().x) != facing_direction:
				if dash_jump_buffer and coyote_timer.time_left > 0:
					
					switch_state(STATE.JUMP)
				elif is_on_floor():
					switch_state(STATE.FLOOR)
				else:
					switch_state(STATE.FALL)
			elif is_ledge() and is_space():
				switch_state(STATE.LEDGE_CLIMB)
			elif can_wall_slide():
				switch_state(STATE.WALL_SLIDE)
		
		STATE.TURNING:
			if signf(velocity.x) == facing_direction and is_input_against_facing():
				set_facing_direction(-facing_direction)
			handle_sprint(delta)
			
			if not is_on_floor():
				switch_state(STATE.FALL)
			elif not is_sprinting or velocity.x * facing_direction >= SPRINT_VELOCITY:
				switch_state(STATE.FLOOR)
			elif Input.is_action_just_pressed("jump"):
				animated_sprite.play("double_jump")
				is_sprinting = false
				switch_state(STATE.JUMP)
		
		STATE.BASH_LAUNCH:
			process_bash_launch(delta)
			
		STATE.RECOIL:
			process_recoil(delta)
		
		STATE.BASH:
			var input_vector := Input.get_vector("move_left", "move_right", "move_up", "move_down")
			# Here you could rotate an arrow based on input_vector
			
			if Input.is_action_just_released("bash"):
				Engine.time_scale = 1.0
				if input_vector != Vector2.ZERO:
					velocity = input_vector.normalized() * bash_velocity
					switch_state(STATE.BASH_LAUNCH) # Use launch state to ignore input briefly
					bash_launch_timer = bash_launch_duration # Duration of "no control"
					can_double_jump = true
					can_dash = true
				else:
					active_state = STATE.FALL # Just fall if no direction


func set_bash_target(target: Node2D) -> void:
	print("Set Bash Target: ", target)
	current_bash_target = target
	can_bash_target = target != null


func handle_bash() -> void:
	if Input.is_action_just_pressed("bash") and can_bash_target and active_state != STATE.BASH:
		switch_state(STATE.BASH)
		
		
func process_bash_launch(delta: float) -> void:
	# Apply gravity but ignore horizontal input
	velocity.y = move_toward(velocity.y, FALL_VELOCITY, FALL_GRAVITY * delta)
	bash_launch_timer -= delta
	
	if bash_launch_timer <= 0:
		switch_state(STATE.FALL)
	
	# Still allow switching to other states if needed (like Dash or Jump cancel?)
	# Usually better to lock out until done, or maybe allow Dash cancel
	if Input.is_action_just_pressed("sprint") and can_dash:
		switch_state(STATE.DASH)



func handle_movement(input_direction: float = 0, horizontal_velocity: float = WALK_VELOCITY, step: float = WALK_VELOCITY) -> void:
	if input_direction == 0:
		input_direction = signf(Input.get_axis("move_left", "move_right"))
	set_facing_direction(input_direction)
	velocity.x = move_toward(velocity.x, input_direction * horizontal_velocity, step)


func handle_sprint(delta: float) -> void:
	if is_attacking:
		handle_movement()
		is_sprinting = false
		return
	handle_movement(facing_direction, SPRINT_VELOCITY, SPRINT_ACCELERATION * delta)
	is_sprinting = Input.is_action_pressed("sprint") and not is_on_wall()


func set_facing_direction(direction: float) -> void:
	if direction:
		animated_sprite.flip_h = direction < 0
		facing_direction = direction
		ledge_climb_ray_cast.position.x = direction * absf(ledge_climb_ray_cast.position.x)
		ledge_climb_ray_cast.target_position.x = direction * absf(ledge_climb_ray_cast.target_position.x)
		ledge_climb_ray_cast.force_raycast_update()
		wall_slide_ray_cast.position.x = direction * absf(wall_slide_ray_cast.position.x)
		wall_slide_ray_cast.target_position.x = direction * absf(wall_slide_ray_cast.target_position.x)
		wall_slide_ray_cast.force_raycast_update()
		attack_area.position.x = direction * absf(attack_area.position.x)
		if is_equal_approx(attack_area.rotation, 0) or is_equal_approx(attack_area.rotation, PI):
			attack_area.rotation = 0
			attack_area.scale.x = direction


func is_input_toward_facing() -> bool:
	return signf(Input.get_axis("move_left", "move_right")) == facing_direction


func is_input_against_facing() -> bool:
	return signf(Input.get_axis("move_left", "move_right")) == -facing_direction


func is_ledge() -> bool:
	return is_on_wall_only() and \
	ledge_climb_ray_cast.is_colliding() and \
	ledge_climb_ray_cast.get_collision_normal().is_equal_approx(Vector2.UP)


func is_space() -> bool:
	ledge_space_ray_cast.global_position = ledge_climb_ray_cast.get_collision_point()
	ledge_space_ray_cast.force_raycast_update()
	return not ledge_space_ray_cast.is_colliding()


func ledge_climb_offset() -> Vector2:
	var shape := player_collider.shape
	if shape is CapsuleShape2D:
		return Vector2(shape.radius * 2.0, -shape.height * 0.5)
	if shape is RectangleShape2D:
		return Vector2(shape.size.x, -shape.size.y * 0.5)
	return Vector2.ZERO


func can_wall_slide() -> bool:
	return is_on_wall_only() and wall_slide_ray_cast.is_colliding()


func handle_enemy_collision() -> void:
	# Check for collision with enemies
	for i in get_slide_collision_count():
		var collision := get_slide_collision(i)
		var collider := collision.get_collider()
		
		if collider.is_in_group("enemy"):
			take_damage(1, collider.global_position)
			break # Only take damage once per frame


func take_damage(amount: int, source_position: Vector2) -> void:
	if active_state == STATE.RECOIL or invulnerability_timer > 0: # Invulnerability during recoil
		return
		
	current_health -= amount
	print("Player took damage! Health: ", current_health)
	
	if current_health <= 0:
		print("Player Died!")
		get_tree().reload_current_scene() # Restart for now
		return
	
	# Calculate recoil direction
	var direction_to_source := global_position.direction_to(source_position)
	var recoil_dir := -signf(direction_to_source.x)
	if recoil_dir == 0: recoil_dir = -facing_direction # Fallback
	
	velocity = Vector2(recoil_dir * recoil_velocity.x, recoil_velocity.y)
	recoil_timer = recoil_duration
	
	# Interrupt any attack in progress
	cancel_attack()
	
	switch_state(STATE.RECOIL)
	
	# Start invulnerability
	invulnerability_timer = recoil_duration + INVULNERABILITY_DURATION
	# Disable collision with enemies (Layer 3 is usually enemies)
	set_collision_mask_value(3, false)
	
	# Also explicitly ignore collisions with all active enemies to prevent pushing
	var enemies = get_tree().get_nodes_in_group("enemy")
	for enemy in enemies:
		if enemy is PhysicsBody2D:
			add_collision_exception_with(enemy)
			# potentially double-sided, but player exception is usually enough if they are both moving
			# enemy.add_collision_exception_with(self) 

func process_invulnerability(delta: float) -> void:
	if invulnerability_timer > 0:
		invulnerability_timer -= delta
		
		# Flash effect (toggle opacity)
		if invulnerability_timer <= 0:
			invulnerability_timer = 0
			# Restore collision
			set_collision_mask_value(3, true)
			animated_sprite.modulate.a = 1.0
			
			# Remove exceptions
			var enemies = get_tree().get_nodes_in_group("enemy")
			for enemy in enemies:
				if enemy is PhysicsBody2D:
					remove_collision_exception_with(enemy)
		else:
			# Flash fast
			if Engine.get_frames_drawn() % 4 == 0:
				animated_sprite.modulate.a = 0.5 if animated_sprite.modulate.a == 1.0 else 1.0



func process_recoil(delta: float) -> void:
	velocity.y = move_toward(velocity.y, FALL_VELOCITY, FALL_GRAVITY * delta)
	recoil_timer -= delta
	
	if recoil_timer <= 0:
		switch_state(STATE.FALL)


func handle_attack() -> void:
	if Input.is_action_just_pressed("attack") and not is_attacking:
		is_attacking = true
		attack_area.monitoring = true
		
		if Input.is_action_pressed("move_up"):
			if animated_sprite.sprite_frames.has_animation("attack_up"):
				animated_sprite.play("attack_up")
			else:
				animated_sprite.play("attack")
			
			attack_area.rotation = -PI / 2
			attack_area.scale.x = 1
			attack_area.position = Vector2(0, -absf(default_attack_position.x))
			
		elif Input.is_action_pressed("move_down") and not is_on_floor():
			if animated_sprite.sprite_frames.has_animation("attack_down"):
				animated_sprite.play("attack_down")
			else:
				animated_sprite.play("attack")
				
			attack_area.rotation = PI / 2
			attack_area.scale.x = 1
			attack_area.position = Vector2(0, absf(default_attack_position.x))
			
		else:
			animated_sprite.play("attack")
			attack_area.rotation = 0
			attack_area.scale.x = facing_direction
			attack_area.position.y = default_attack_position.y
			attack_area.position.x = facing_direction * absf(default_attack_position.x)


func _on_animation_finished() -> void:
	if animated_sprite.animation == &"attack" or animated_sprite.animation == &"attack_up" or animated_sprite.animation == &"attack_down":
		cancel_attack()
		
		match active_state:
			STATE.FALL:
				animated_sprite.play("fall")
			STATE.JUMP, STATE.WALL_JUMP:
				animated_sprite.play("jump")
			STATE.DOUBLE_JUMP, STATE.LEDGE_JUMP:
				animated_sprite.play("double_jump")
			STATE.WALL_SLIDE:
				animated_sprite.play("wall_slide")
			STATE.FLOAT:
				animated_sprite.play("float")


func cancel_attack() -> void:
	is_attacking = false
	attack_area.monitoring = false
	attack_area.rotation = 0
	attack_area.scale.x = facing_direction
	attack_area.position.y = default_attack_position.y
	attack_area.position.x = facing_direction * absf(default_attack_position.x)


func _on_attack_area_body_entered(body: Node2D) -> void:
	if body.has_method("take_damage"):
		body.take_damage()
		if animated_sprite.animation == &"attack_down":
			velocity.y = POGO_VELOCITY
			can_double_jump = true
			can_dash = true
