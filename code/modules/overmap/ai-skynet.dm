// ---------------------------------------------------------------
// Hostile AI ships
// ---------------------------------------------------------------
/datum/space_ship/hostile
	name = "hostile ship"
	/// Distance the AI tries to keep from the player ship.
	var/preferred_range = 10

/datum/space_ship/hostile/process_ship(dt)
	if(destroyed)
		return
	var/datum/space_ship/victim = SSspacecombat.player_ship
	if(!victim || victim.destroyed)
		user_thrust_dir = 0
		brakes = TRUE
		return ..()
	target = victim
	var/dist = sc_distance(src, victim)
	last_thrust_input = world.time
	brakes = FALSE
	user_thrust_dir = NORTH
	dampeners = TRUE
	if(dist <= 10)
		circle_around(victim)
	else
		move_toward(victim, dist)
	ai_fire(victim, dist)
	return ..()

/// NSV13 ai_goal/seek/action -> circle_around(): orbit the target, picking the direction that wastes less time turning.
/datum/space_ship/hostile/proc/circle_around(datum/space_ship/victim)
	var/relative_angle = sc_bearing(pos_x, pos_y, victim.pos_x, victim.pos_y)
	var/option1 = sc_wrap_angle(relative_angle + 90)
	var/option2 = sc_wrap_angle(relative_angle - 90)
	var/actual_angle_positive = heading + 180
	var/option1_difference = 180 - abs(abs(actual_angle_positive - option1) - 180)
	var/option2_difference = 180 - abs(abs(actual_angle_positive - option2) - 180)
	if(option1_difference < option2_difference)
		desired_heading = sc_wrap_angle(option1 - 180)
	else
		desired_heading = sc_wrap_angle(option2 - 180)

/// NSV13 move_toward(): face the target, boost when far away and roughly lined up.
/datum/space_ship/hostile/proc/move_toward(datum/space_ship/victim, dist)
	desired_heading = sc_bearing(pos_x, pos_y, victim.pos_x, victim.pos_y)
	if(world.time >= next_maneuvre && dist > 12)
		var/angular_difference = sc_angle_diff(heading, desired_heading)
		if(abs(angular_difference) <= 15)
			boost(NORTH)
		else if(angular_difference <= -45)
			boost(WEST)
		else if(angular_difference >= 45)
			boost(EAST)

/// NSV13 ai_fire(): of the usable weapons in range pick the one whose optimal range fits best, and shoot with target leading and a miss chance.
/datum/space_ship/hostile/proc/ai_fire(datum/space_ship/victim, dist)
	var/datum/ship_weapon/chosen
	var/lowest_penalty = 999
	var/chosen_aim = 0
	for(var/datum/ship_weapon/weapon AS in weapons)
		if(dist > weapon.range)
			continue
		var/aim = weapon.aim_at(src, victim)
		if(weapon.fire_error(src, aim))
			continue
		var/penalty = max(0, dist - weapon.optimal_range)
		if(penalty < lowest_penalty)
			lowest_penalty = penalty
			chosen = weapon
			chosen_aim = aim
	if(!chosen)
		return
	if(chosen.miss_chance && prob(chosen.miss_chance))
		chosen_aim = sc_wrap_angle(chosen_aim + rand(-chosen.max_miss_distance * 10, chosen.max_miss_distance * 10) / 10 / max(dist, 1) * 57.3)
	chosen.fire(src, chosen_aim)

