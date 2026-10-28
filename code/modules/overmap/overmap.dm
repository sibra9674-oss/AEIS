/// An abstract space ship: position, NSV13-style thrust/rotation physics, 4-quadrant armour, hull and weapons.
/// Units: tiles (1 unit = 1 tile on the space z-level), tiles/s, degrees (0 = north, clockwise).
/datum/space_ship
	var/name = "unknown ship"
	var/pos_x = 0
	var/pos_y = 0
	var/vel_x = 0
	var/vel_y = 0
	/// Current angle, 0 = north, clockwise.
	var/heading = 0
	/// Angle the ship is trying to reach (AI sets this; for the player it follows Q/E or the helm order).
	var/desired_heading = 0
	var/angular_velocity = 0
	/// Max angular acceleration in deg/s^2.
	var/max_angular_acceleration = 6
	var/forward_maxthrust = 0.5
	var/backward_maxthrust = 0.35
	var/side_maxthrust = 0.25
	/// Per-axis velocity cap, like NSV13.
	var/speed_limit = 3.5
	/// Mass-based sideways friction used by the inertial assistance.
	var/mass_friction = 2.5
	/// Inertial assistance (IAS): kills sideways drift; A/D turn the ship instead of strafing.
	var/dampeners = TRUE
	var/brakes = FALSE
	/// Latched forward thrust set from the console, 0..100.
	var/throttle = 0
	/// Bitflags NORTH/SOUTH/EAST/WEST from the pilot keys.
	var/user_thrust_dir = 0
	var/last_thrust_input = 0
	/// Held Q / E rotation, set by keybindings (degrees added to the desired angle each step).
	var/kb_left = 0
	var/kb_right = 0
	var/movekey_delta = 0
	/// Absolute heading ordered from the console, cleared when the pilot uses the rotation keys.
	var/helm_order
	var/next_maneuvre = 0
	var/boost_until = 0
	var/boost_dir = 0
	var/max_hull = 300
	var/hull = 300
	var/max_armour = 60
	/// Armour per quadrant, see SC_QUAD_* defines.
	var/list/armour
	var/list/datum/ship_weapon/weapons
	var/datum/space_ship/target
	var/destroyed = FALSE
	var/is_player = FALSE
	/// Hit radius in tiles.
	var/radius = 1
	/// Sprite on the space z-level.
	var/visual_state = "raider"
	var/visual_icon = 'icons/spacecombat/ships.dmi'
	var/visual_w = 64
	var/visual_h = 64
	var/obj/effect/space_combat_visual/visual
	var/list/ship_log = list()

/datum/space_ship/New(new_name)
	. = ..()
	if(new_name)
		name = new_name
	hull = max_hull
	armour = list(max_armour, max_armour, max_armour, max_armour)
	var/list/new_weapons = list()
	for(var/weapon_type in weapons)
		new_weapons += new weapon_type
	weapons = new_weapons
	create_visual()

/datum/space_ship/Destroy()
	target = null
	QDEL_NULL(visual)
	QDEL_LIST(weapons)
	return ..()

/// Creates the sprite on the space z-level, if that level exists yet.
/datum/space_ship/proc/create_visual()
	if(visual || !SSspacecombat?.space_z)
		return
	visual = new(null)
	visual.icon = visual_icon
	visual.icon_state = visual_state
	visual.sprite_w = visual_w
	visual.sprite_h = visual_h
	visual.name = name
	update_visual()

/datum/space_ship/proc/update_visual()
	visual?.place_at(pos_x, pos_y, heading)

/datum/space_ship/proc/add_log(message)
	ship_log += "[worldtime2text()] [message]"
	if(length(ship_log) > 12)
		ship_log.Cut(1, 2)

/datum/space_ship/proc/speed()
	return sqrt(vel_x * vel_x + vel_y * vel_y)


/// Weapons the given station can operate, best (highest sort_priority) first.
/datum/space_ship/proc/weapons_for(control_flag)
	var/list/result = list()
	for(var/datum/ship_weapon/weapon AS in weapons)
		if(weapon.control & control_flag)
			result += weapon
	for(var/i in 1 to length(result))
		for(var/j in i + 1 to length(result))
			var/datum/ship_weapon/first = result[i]
			var/datum/ship_weapon/second = result[j]
			if(second.sort_priority > first.sort_priority)
				result[i] = second
				result[j] = first
	return result

/// Applies a hit. incoming_bearing is the compass direction the shot came from (seen from this ship).
/// Armour of the hit quadrant soaks damage first, the rest goes to the hull.
/datum/space_ship/proc/take_hit(damage, incoming_bearing, source_name, weapon_name)
	if(destroyed)
		return
	var/rel = sc_wrap_angle(incoming_bearing - heading)
	var/quad = clamp(round(rel / 90) + 1, 1, 4)
	var/absorbed = min(armour[quad], damage)
	armour[quad] -= absorbed
	var/leftover = damage - absorbed
	hull -= leftover
	add_log("[source_name]'s [weapon_name] hit our [GLOB.sc_quadrant_names[quad]] quadrant for [damage] ([absorbed] absorbed by armour).")
	on_hit(damage, quad, leftover)
	if(hull <= 0)
		hull = 0
		SSspacecombat.ship_destroyed(src, source_name)

/// Hook for subtypes, e.g. the player ship shakes the decks.
/datum/space_ship/proc/on_hit(damage, quad, hull_damage)
	return

