extends RigidBody

var input_direction = Vector3.ZERO
var m_goal_vel = Vector3.ZERO
var speed_factor = Vector3(1, 0, 1)

var is_on_floor = false
var is_crouching = false

export(Resource) var settings = preload("DefaultPlayerSettings.tres")

func _integrate_forces(state: PhysicsDirectBodyState):
	var delta = state.step
		
	var collision = state.get_space_state().intersect_ray(global_transform.origin, global_transform.origin + Vector3(0, -1.675, 0), [self], collision_mask)

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
	
	# desired direction
	var m_unit_goal = input_direction
	m_unit_goal = m_unit_goal.normalized()
#    m_unit_goal = yaw.transform.basis.xform(m_unit_goal)

#    if movement_locked or fall_stunned:
#        m_unit_goal = Vector3(0, 0, 0)
	
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
#    elif Input.is_action_pressed("sprint"):
#        acceleration = settings.acceleration_sprint
#        max_speed = settings.max_speed_sprint
		
	var accel = acceleration * ((settings.acceleration_factor_from_dot as Curve).interpolate(vel_dot) + 1 / 2)
	var goal_vel = m_unit_goal * max_speed * speed_factor

	m_goal_vel = m_goal_vel.move_toward(goal_vel, accel * delta)
	
	var needed_accel = (m_goal_vel - (state.linear_velocity * Vector3(1, 0, 1))) / delta
	var max_accell = settings.max_acceleration_force * Vector3(1, 0, 1)

	needed_accel = needed_accel.normalized() * min(needed_accel.length(), max_accell.length())
	add_central_force(needed_accel * mass)
