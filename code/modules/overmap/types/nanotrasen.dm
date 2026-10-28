// ---------------------------------------------------------------
// Player ship (NSV13 MASS_LARGE handling)
// ---------------------------------------------------------------
/datum/space_ship/player
	name = "TGS Talos"
	max_hull = 2400
	max_armour = 300
	// NSV13 MASS_TITAN (the Galactica class): heavy, slow to turn, strong inertial dampening (mass 150 / 10)
	forward_maxthrust = 0.35
	backward_maxthrust = 0.10
	side_maxthrust = 0.10
	max_angular_acceleration = 2.75
	speed_limit = 3.5
	mass_friction = 15
	is_player = TRUE
	radius = 2.5
	visual_icon = 'icons/spacecombat/titan.dmi'
	visual_state = "titan"
	visual_w = 96
	visual_h = 192
	weapons = list(/datum/ship_weapon/mac, /datum/ship_weapon/torpedo, /datum/ship_weapon/railgun, /datum/ship_weapon/gauss)
	var/crit_alarm_played = FALSE

/datum/space_ship/player/on_hit(damage, quad, hull_damage)
	SSspacecombat.ship_sound(hull_damage > 0 ? pick('sound/spacecombat/shiphit.ogg', 'sound/spacecombat/shiphit2.ogg', 'sound/spacecombat/shiphit3.ogg', 'sound/spacecombat/shiphit4.ogg') : pick('sound/spacecombat/shield_hit.ogg', 'sound/spacecombat/shield_hit2.ogg'), 70)
	SSspacecombat.ship_announce(span_danger("The ship shudders as it is hit on the [GLOB.sc_quadrant_names[quad]] side!"), shake = clamp(damage / 40, 1, 4))
	if(!crit_alarm_played && hull < max_hull * 0.25)
		crit_alarm_played = TRUE
		SSspacecombat.ship_sound('sound/spacecombat/hullcrit_alarm_10.ogg', 60)

