/// A projectile in flight. Simulated by SSspacecombat, drawn as an effect on the space z-level.
/datum/ship_projectile
	var/pos_x = 0
	var/pos_y = 0
	var/vel_x = 0
	var/vel_y = 0
	/// Direction of travel, 0 = north, clockwise.
	var/angle = 0
	var/damage = 0
	var/speed = 1
	var/distance_left = 0
	var/weapon_name = "weapon"
	var/owner_name = "unknown"
	/// TRUE if fired by the player ship; player shots only hit hostiles and vice versa.
	var/from_player = FALSE
	var/is_torpedo = FALSE
	var/obj/effect/space_combat_visual/visual
	var/datum/space_ship/homing_target

/datum/ship_projectile/New(datum/space_ship/owner, datum/ship_weapon/weapon, new_angle)
	. = ..()
	angle = new_angle
	speed = weapon.proj_speed
	damage = weapon.damage
	distance_left = weapon.range
	weapon_name = weapon.name
	is_torpedo = (weapon.proj_state == "torpedo")
	owner_name = owner.name
	if(is_torpedo)
		homing_target = owner.target
	from_player = owner.is_player
	// start a little ahead of the muzzle so we never clip the shooter
	pos_x = owner.pos_x + sin(angle) * owner.radius
	pos_y = owner.pos_y + cos(angle) * owner.radius
	vel_x = sin(angle) * speed
	vel_y = cos(angle) * speed
	SSspacecombat.projectiles += src
	if(SSspacecombat.space_z)
		visual = new(null)
		visual.icon = 'icons/spacecombat/projectiles.dmi'
		visual.sprite_w = 32
		visual.sprite_h = 32
		visual.icon_state = weapon.proj_state
		visual.name = weapon.name
		visual.place_at(pos_x, pos_y, angle)

/datum/ship_projectile/Destroy()
	SSspacecombat.projectiles -= src
	QDEL_NULL(visual)
	return ..()

/// Advances the projectile by dt seconds. Returns FALSE when it should be removed.
/datum/ship_projectile/proc/process_projectile(dt)
	// torpedoes home in on the shooter's locked target (NSV13 guided munitions)
	if(is_torpedo && homing_target && !homing_target.destroyed)
		var/want = sc_bearing(pos_x, pos_y, homing_target.pos_x, homing_target.pos_y)
		var/turn = clamp(sc_angle_diff(angle, want), -60 * dt, 60 * dt)
		angle = sc_wrap_angle(angle + turn)
		vel_x = sin(angle) * speed
		vel_y = cos(angle) * speed
	var/new_x = pos_x + vel_x * dt
	var/new_y = pos_y + vel_y * dt
	for(var/datum/space_ship/victim AS in SSspacecombat.ships)
		if(victim.destroyed || victim.is_player == from_player)
			continue
		if(sc_point_segment_distance(victim.pos_x, victim.pos_y, pos_x, pos_y, new_x, new_y) <= victim.radius)
			SSspacecombat.spawn_flash(new_x, new_y)
			if(is_torpedo)
				SSspacecombat.ship_sound('sound/spacecombat/torpedo_hit.ogg', 70)
			victim.take_hit(damage, sc_wrap_angle(angle + 180), owner_name, weapon_name)
			return FALSE
	pos_x = new_x
	pos_y = new_y
	distance_left -= speed * dt
	if(distance_left <= 0)
		return FALSE
	return TRUE
