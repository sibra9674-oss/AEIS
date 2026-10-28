/// NSV13 MASS_SMALL handling
/datum/space_ship/hostile/raider
	name = "pirate raider"
	max_hull = 300
	max_armour = 30
	forward_maxthrust = 0.75
	backward_maxthrust = 0.75
	side_maxthrust = 0.75
	max_angular_acceleration = 12
	mass_friction = 0.2
	preferred_range = 9
	radius = 1
	visual_icon = 'icons/spacecombat/syn_frigate.dmi'
	visual_state = "mako"
	visual_w = 48
	visual_h = 48
	weapons = list(/datum/ship_weapon/raider_gun)

/// NSV13 MASS_MEDIUM_LARGE handling
/datum/space_ship/hostile/cruiser
	name = "hostile cruiser"
	max_hull = 900
	max_armour = 80
	forward_maxthrust = 0.65
	backward_maxthrust = 0.45
	side_maxthrust = 0.35
	max_angular_acceleration = 8
	mass_friction = 0.5
	mass_friction = 2
	preferred_range = 18
	radius = 1.8
	visual_icon = 'icons/spacecombat/syn_cruiser.dmi'
	visual_state = "barracuda"
	visual_w = 96
	visual_h = 96
	weapons = list(/datum/ship_weapon/mac, /datum/ship_weapon/raider_gun)

