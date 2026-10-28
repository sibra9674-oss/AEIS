/// Pilot key input (W/A/S/D). With inertial assistance on, A/D turn instead of strafing (NSV13 behaviour).
/datum/space_ship/proc/relay_thrust(direction)
	last_thrust_input = world.time
	if(dampeners)
		if(direction & WEST)
			movekey_delta = -15
			direction &= ~WEST
		else if(direction & EAST)
			movekey_delta = 15
			direction &= ~EAST
	user_thrust_dir = direction

/// Shift: short, strong burst with a cooldown (NSV13 afterburner).
/datum/space_ship/proc/boost(direction = NORTH)
	if(world.time < next_maneuvre)
		return FALSE
	next_maneuvre = world.time + 15 SECONDS
	boost_until = world.time + 6 SECONDS
	boost_dir = direction
	if(is_player)
		SSspacecombat.ship_sound('sound/spacecombat/afterburner.ogg', 80)
		SSspacecombat.ship_announce(span_warning("You feel the ship lurch suddenly."), shake = 3)
	return TRUE

/// One simulation step, dt in seconds. Port of the NSV13 overmap rotation + thrust model.
/datum/space_ship/proc/process_ship(dt)
	if(destroyed)
		return
	var/boosting = (world.time < boost_until)
	var/angular_limit = max_angular_acceleration
	var/forward_thrust_max = forward_maxthrust
	var/backward_thrust_max = backward_maxthrust
	var/side_thrust_max = side_maxthrust
	var/limit = speed_limit
	if(boosting)
		limit += 5
		if(boost_dir & (NORTH | SOUTH))
			angular_limit *= 0.5
			forward_thrust_max *= 5
			backward_thrust_max *= 5
		else
			angular_limit = clamp(angular_limit * 5, 0, 360)
			side_thrust_max *= 5
	// --- rotation ---
	if(is_player)
		var/keyed = (kb_left || kb_right || movekey_delta)
		if(keyed)
			helm_order = null
			desired_heading = sc_wrap_angle(heading + kb_left + kb_right + movekey_delta)
		else if(!isnull(helm_order))
			desired_heading = helm_order
		else
			desired_heading = heading
		movekey_delta = 0
	var/bounded = desired_heading
	if(bounded - heading > 180)
		bounded -= 360
	else if(bounded - heading < -180)
		bounded += 360
	var/desired_angular_velocity = 0
	if(abs(bounded - heading) < angular_limit * dt)
		desired_angular_velocity = (bounded - heading) / dt
	else if(bounded > heading)
		desired_angular_velocity = 2 * sqrt((bounded - heading) * angular_limit * 0.25)
	else
		desired_angular_velocity = -2 * sqrt((heading - bounded) * angular_limit * 0.25)
	angular_velocity += clamp(desired_angular_velocity - angular_velocity, -angular_limit * dt, angular_limit * dt)
	heading = sc_wrap_angle(heading + angular_velocity * dt)
	// --- thrust ---
	if(world.time - last_thrust_input > 3)
		user_thrust_dir = 0
	var/fx = sin(heading)
	var/fy = cos(heading)
	var/sx = fy
	var/sy = -fx
	var/thrust_x = 0
	var/thrust_y = 0
	if(brakes)
		var/forward_thrust = -((fx * vel_x) + (fy * vel_y)) / dt
		var/right_thrust = -((sx * vel_x) + (sy * vel_y)) / dt
		forward_thrust = clamp(forward_thrust, -backward_thrust_max, forward_thrust_max)
		right_thrust = clamp(right_thrust, -side_thrust_max, side_thrust_max)
		thrust_x += forward_thrust * fx + right_thrust * sx
		thrust_y += forward_thrust * fy + right_thrust * sy
	else
		if(user_thrust_dir & NORTH)
			thrust_x += fx * forward_thrust_max
			thrust_y += fy * forward_thrust_max
		if(user_thrust_dir & SOUTH)
			thrust_x -= fx * backward_thrust_max
			thrust_y -= fy * backward_thrust_max
		if(user_thrust_dir & EAST)
			thrust_x += sx * side_thrust_max
			thrust_y += sy * side_thrust_max
		if(user_thrust_dir & WEST)
			thrust_x -= sx * side_thrust_max
			thrust_y -= sy * side_thrust_max
		if(throttle > 0)
			thrust_x += fx * forward_thrust_max * (throttle / 100)
			thrust_y += fy * forward_thrust_max * (throttle / 100)
	vel_x = clamp(vel_x, -limit, limit)
	vel_y = clamp(vel_y, -limit, limit)
	vel_x += thrust_x * dt
	vel_y += thrust_y * dt
	if(dampeners)
		var/side_movement = (sx * vel_x) + (sy * vel_y)
		var/friction_impulse = (mass_friction + side_thrust_max) * dt
		var/clamped_side_movement = clamp(side_movement, -friction_impulse, friction_impulse)
		vel_x -= clamped_side_movement * sx
		vel_y -= clamped_side_movement * sy
	pos_x += vel_x * dt
	pos_y += vel_y * dt
	// stay inside the space z-level
	var/bound = SSspacecombat.map_bound_km()
	if(abs(pos_x) > bound)
		pos_x = clamp(pos_x, -bound, bound)
		vel_x = 0
	if(abs(pos_y) > bound)
		pos_y = clamp(pos_y, -bound, bound)
		vel_y = 0

