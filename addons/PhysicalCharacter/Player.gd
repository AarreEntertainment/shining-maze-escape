tool
extends RigidBody
onready var director: Director = get_node("/root/Director")
var input_direction = Vector3.ZERO
var m_goal_vel = Vector3.ZERO
var speed_factor = Vector3(1, 0, 1)

export(Resource) var settings
export(bool) var movement_locked


export(float, 0, 1) var bob_offset = 0


var is_on_floor = false
var fall_start = 0
var fall_stunned = false

var look_velocity = Vector2.ZERO

onready var fall_stun_timer = find_node("FallStun")

onready var yaw = find_node("Yaw")
onready var lean = find_node("Lean")
onready var pitch = find_node("Pitch")
onready var tilt = find_node("Tilt")
onready var camera = find_node("Camera")
onready var bob_animation_tree = find_node("AnimationTree")

onready var aim_target = find_node("Target")
onready var aim_pivot_yaw = find_node("AimPivotYaw")
onready var aim_pivot_pitch = find_node("AimPivotPitch")


var is_crouching = false
var is_right_shouldered = true


func _ready():
	if not Engine.editor_hint:
		Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
		


func _process(delta):
	if movement_locked:
		var fs = get_node_or_null("footstep")
		if fs !=null:
			if "movement" in fs:
				fs.movement = 0
		return
	if not Engine.editor_hint:
		input_direction = (
			Vector3(
				Input.get_action_strength("move_left") - Input.get_action_strength("move_right"),
				0,
				Input.get_action_strength("move_forward") - Input.get_action_strength("move_backward")
			)
			+ 
			Vector3(
				Input.get_action_strength("move_left_joystick") - Input.get_action_strength("move_right_joystick"),
				0,
				Input.get_action_strength("move_forward_joystick") - Input.get_action_strength("move_backward_joystick")
			)
		)
	if director == null:
		return
	if director.staminaBar!=null && cooldown==false:
		if director.staminaBar.value ==0:
			staminaCooldown()
		if Input.is_action_pressed("sprint"):
			director.staminaBar.value-=delta*100
		else:
			director.staminaBar.value+=delta*50
			
var cooldown = false
func staminaCooldown():
	cooldown = true
	yield(get_tree().create_timer(3.0), "timeout")
	cooldown = false
	
func _integrate_forces(state: PhysicsDirectBodyState):

	
	var delta = state.step
	
	if Input.is_action_just_pressed("crouch"):
		is_crouching = !is_crouching
	
	var collision = state.get_space_state().intersect_ray(global_transform.origin, global_transform.origin + Vector3(0, -1.5, 0), [self], collision_mask)

	var was_on_floor = is_on_floor
	is_on_floor = not collision.empty()
	if is_on_floor:
		var velocity = linear_velocity
		var ray_dir = Vector3.DOWN

		var other_velocity = Vector3.ZERO
		
		var ray_dir_velocity = ray_dir.dot(velocity)
		var other_dir_velcoity = ray_dir.dot(other_velocity)
		
		var rel_velocity = ray_dir_velocity - other_dir_velcoity

		var ride_height = settings.ride_height if not is_crouching else settings.crouch_ride_height
		var ride_hit_distance = global_transform.origin.distance_to(collision.position) - ride_height
		var x = ride_hit_distance
		var spring_force = (x * settings.ride_spring_strength) - (rel_velocity * settings.ride_spring_damper)
		add_central_force(Vector3.DOWN * spring_force)

	
	if not is_on_floor and was_on_floor:
		fall_start = global_transform.origin.y    
	
	
	# desired direction
	var m_unit_goal = input_direction
	m_unit_goal = m_unit_goal.normalized()
	m_unit_goal = yaw.transform.basis.xform(m_unit_goal)
		
	if movement_locked or fall_stunned:
		m_unit_goal = Vector3(0, 0, 0)
	
	# current direction
	var unit_vel = m_goal_vel.normalized()
	# difference between desired direction and current direction
	var vel_dot = m_unit_goal.dot(unit_vel)

	var acceleration = settings.acceleration
	
	# Air acceleration
	if not is_on_floor:
		acceleration = settings.acceleration_air
	
	var max_speed = settings.max_speed
	
	if is_crouching:
		max_speed = settings.max_speed_crouch
	elif Input.is_action_pressed("sprint") && cooldown == false:
		acceleration = settings.acceleration_sprint
		max_speed = settings.max_speed_sprint
		$footstep.movement = 2
	elif m_goal_vel!= Vector3.ZERO:
		$footstep.movement = 1
		
	var accel = acceleration * ((settings.acceleration_factor_from_dot as Curve).interpolate(vel_dot) + 1 / 2)
	var goal_vel = m_unit_goal * max_speed * speed_factor

	m_goal_vel = m_goal_vel.move_toward(goal_vel, accel * delta)

	var needed_accel = (m_goal_vel - (state.linear_velocity * Vector3(1, 0, 1))) / delta
	var max_accell = settings.max_acceleration_force * Vector3(1, 0, 1)

	needed_accel = needed_accel.normalized() * min(needed_accel.length(), max_accell.length())
	add_central_force(needed_accel * mass)
	
	var h_linear_velocity = (linear_velocity.abs() * Vector3(1, 0, 1)).length()
	if h_linear_velocity and is_on_floor and m_unit_goal.abs().length():
		var base_timescale = 1.6
		bob_animation_tree["parameters/TimeScale/scale"] = range_lerp(
			h_linear_velocity, 
			settings.max_speed, 
			settings.max_speed_sprint, 
			base_timescale, 
			base_timescale * (settings.max_speed_sprint/settings.max_speed)
		)

		bob_animation_tree.advance(delta)
		if settings.head_bob_enabled:
			yaw.transform.origin.y = 0.147 + (settings.bob_curve.interpolate(bob_offset) * settings.max_bob_height)
		
	# View tilt
	if settings.head_tilt_enabled:
		var velocity_relative_to_look_direction = yaw.transform.basis.xform_inv(linear_velocity)
		var tilt_vector = Vector3(velocity_relative_to_look_direction.z * .5, 0, velocity_relative_to_look_direction.x * -.75)
		if not is_on_floor:
			tilt_vector.x += velocity_relative_to_look_direction.y * -4
		tilt.rotation_degrees = tilt.rotation_degrees.move_toward(tilt_vector, delta * 40)
	
	# Splash
	if not was_on_floor and is_on_floor:
		var fall_delta = fall_start - global_transform.origin.y
		if fall_delta > settings.fall_stun_height:
			if settings.fall_stun_length:
				fall_stunned = true
				fall_stun_timer.start(settings.fall_stun_length)
				var _signal_connection = fall_stun_timer.connect("timeout", self, "set", ["fall_stunned", false], CONNECT_ONESHOT)
			$AudioStreamPlayer.play()
		
	# Non mouse look
	if not movement_locked and (Input.is_action_pressed("look_left") or Input.is_action_pressed("look_right")):      
		yaw.rotation_degrees.y += (Input.get_action_strength("look_left") - Input.get_action_strength("look_right")) * settings.stick_sensitivity * delta

	if not movement_locked and (Input.is_action_pressed("look_up") or Input.is_action_pressed("look_down")):
		var x_delta = (Input.get_action_strength("look_up") - Input.get_action_strength("look_down")) * settings.stick_sensitivity * delta * -1
		if not settings.invert_mouse:
			x_delta *= -1
		pitch.rotation_degrees.x -= x_delta
		pitch.rotation_degrees.x = clamp(pitch.rotation_degrees.x, -90, 90)

	# Delay look
	if settings.mouse_look_mode == settings.MOUSE_LOOK_MODE.DELAYED:
		if abs(look_velocity.x) > settings.view_box_dead_zone.x * settings.view_box.x:
			var a = range_lerp(abs(look_velocity.x) - settings.view_box_dead_zone.x * settings.view_box.x, 0, (1 - settings.view_box_dead_zone.x) * settings.view_box.x, 0, 1)
			yaw.rotation_degrees.y -= sign(look_velocity.x) * settings.stick_sensitivity * settings.view_box_curve.interpolate(a) * delta
		if abs(look_velocity.y) > settings.view_box_dead_zone.y * settings.view_box.y:
			var a = range_lerp(abs(look_velocity.y) - settings.view_box_dead_zone.y * settings.view_box.y, 0, (1 - settings.view_box_dead_zone.y) * settings.view_box.y, 0, 1)
			pitch.rotation_degrees.x += sign(look_velocity.y) * settings.stick_sensitivity * settings.view_box_curve.interpolate(a) * delta
			pitch.rotation_degrees.x = clamp(pitch.rotation_degrees.x, -90, 90)
			
		$Control/MarginContainer/AspectRatioContainer/TextureRect.material.set_shader_param("view_box_dead_zone", settings.view_box_dead_zone)
		$Control/MarginContainer/AspectRatioContainer/TextureRect.material.set_shader_param(
			"Reticle", 
			Vector2(
				range_lerp(look_velocity.x, settings.view_box.x * -1, settings.view_box.x, 0, 1), 
				range_lerp(look_velocity.y, settings.view_box.y * -1, settings.view_box.y, 0, 1)
			)
		)
		
		var max_x_pivot = 20
		aim_pivot_yaw.rotation_degrees.y = range_lerp(look_velocity.x, settings.view_box.x * -1, settings.view_box.x, max_x_pivot, -max_x_pivot)
		
		var max_y_pivot = 15
		aim_pivot_pitch.rotation_degrees.x = range_lerp(look_velocity.y, settings.view_box.y * -1, settings.view_box.y, max_y_pivot, -max_y_pivot)
		
		# Decay Velocity
#        look_velocity = look_velocity.move_toward(Vector2.ZERO, delta * 100)
		


	#if Input.is_action_just_pressed("ui_accept"):
	#	if Input.get_mouse_mode() != Input.MOUSE_MODE_CAPTURED:
	#		Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	#	else:
	#		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
			
		
		
	if Input.is_action_pressed("lean_left"):
		lean.rotation_degrees.z = lerp(lean.rotation_degrees.z, -16, delta * 5)
	elif Input.is_action_pressed("lean_right"):
		lean.rotation_degrees.z = lerp(lean.rotation_degrees.z, 16, delta * 5)
	else:
		lean.rotation_degrees.z = lerp(lean.rotation_degrees.z, 0, delta * 5)
var canc_pressed = false
func _unhandled_input(event: InputEvent) -> void:
	pass
	#if event.is_action_pressed("ui_cancel") && !canc_pressed:
		#if Input.MOUSE_MODE_CAPTURED:
		#	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
		#	canc_pressed = true
		#else:
		#	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
		#	canc_pressed = true
	#if event.is_action_released("ui_cancel"):
		#canc_pressed = false

func _input(event: InputEvent):
	if not movement_locked and event is InputEventMouseMotion and Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
		if settings.mouse_look_mode == settings.MOUSE_LOOK_MODE.FIXED and not event.is_echo():
			yaw.rotation_degrees.y -= settings.mouse_sensitivity * event.relative.x
			
			var x_delta = settings.mouse_sensitivity * event.relative.y
			if not settings.invert_mouse:
				x_delta *= -1
			
			pitch.rotation_degrees.x -= x_delta
			pitch.rotation_degrees.x = clamp(pitch.rotation_degrees.x, -90, 90)
		
			
		if settings.mouse_look_mode == settings.MOUSE_LOOK_MODE.DELAYED:
			look_velocity.x += event.relative.x * settings.view_box_sensitivity
			look_velocity.x = clamp(look_velocity.x, settings.view_box.x * -1, settings.view_box.x)
			look_velocity.y += event.relative.y * settings.view_box_sensitivity
			look_velocity.y = clamp(look_velocity.y, settings.view_box.y * -1, settings.view_box.y)
		
