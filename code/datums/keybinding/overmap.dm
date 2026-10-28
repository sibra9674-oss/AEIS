// NSV13 pilot key layout, only active while looking through the ship (see SSspacecombat.start_observing).
// W/S thrust, A/D turn (IAS on) or strafe (IAS off) come from the movement relay in subsystem.dm.

/datum/keybinding/spacecombat
	category = CATEGORY_MOB
	weight = WEIGHT_HIGHEST

/datum/keybinding/spacecombat/rotate_left
	hotkey_keys = list("Q")
	name = "spacecombat_rotate_left"
	full_name = "Ship: Rotate Left"
	description = "Hold to rotate the ship counter-clockwise"
	keybind_signal = "spacecombat_kb_rotate_left"

/datum/keybinding/spacecombat/rotate_left/down(client/user)
	. = ..()
	var/datum/space_ship/ship = SSspacecombat.pilot_ship(user.mob)
	if(!ship)
		return FALSE
	ship.kb_left = -15
	return TRUE

/datum/keybinding/spacecombat/rotate_left/up(client/user)
	var/datum/space_ship/ship = SSspacecombat.pilot_ship(user.mob)
	if(!ship)
		return FALSE
	ship.kb_left = 0
	return TRUE

/datum/keybinding/spacecombat/rotate_right
	hotkey_keys = list("E")
	name = "spacecombat_rotate_right"
	full_name = "Ship: Rotate Right"
	description = "Hold to rotate the ship clockwise"
	keybind_signal = "spacecombat_kb_rotate_right"

/datum/keybinding/spacecombat/rotate_right/down(client/user)
	. = ..()
	var/datum/space_ship/ship = SSspacecombat.pilot_ship(user.mob)
	if(!ship)
		return FALSE
	ship.kb_right = 15
	return TRUE

/datum/keybinding/spacecombat/rotate_right/up(client/user)
	var/datum/space_ship/ship = SSspacecombat.pilot_ship(user.mob)
	if(!ship)
		return FALSE
	ship.kb_right = 0
	return TRUE

/datum/keybinding/spacecombat/boost
	hotkey_keys = list("Shift")
	name = "spacecombat_boost"
	full_name = "Ship: Boost"
	description = "Afterburner burst (15 second cooldown)"
	keybind_signal = "spacecombat_kb_boost"

/datum/keybinding/spacecombat/boost/down(client/user)
	. = ..()
	var/datum/space_ship/ship = SSspacecombat.pilot_ship(user.mob)
	if(!ship)
		return FALSE
	if(!ship.boost(ship.user_thrust_dir & (NORTH | SOUTH | EAST | WEST) ? ship.user_thrust_dir : NORTH))
		to_chat(user, span_notice("Engines on cooldown to prevent overheat."))
	return TRUE

/datum/keybinding/spacecombat/toggle_brakes
	hotkey_keys = list("Alt")
	name = "spacecombat_brakes"
	full_name = "Ship: Toggle Brakes"
	description = "Use the thrusters to bring the ship to a stop"
	keybind_signal = "spacecombat_kb_brakes"

/datum/keybinding/spacecombat/toggle_brakes/down(client/user)
	. = ..()
	var/datum/space_ship/ship = SSspacecombat.pilot_ship(user.mob)
	if(!ship)
		return FALSE
	ship.brakes = !ship.brakes
	to_chat(user, span_notice("Brakes [ship.brakes ? "engaged" : "released"]."))
	return TRUE

/datum/keybinding/spacecombat/toggle_ias
	hotkey_keys = list("X")
	name = "spacecombat_ias"
	full_name = "Ship: Toggle Inertial Assistance"
	description = "With IAS on, A/D turn the ship; with it off they strafe"
	keybind_signal = "spacecombat_kb_ias"

/datum/keybinding/spacecombat/toggle_ias/down(client/user)
	. = ..()
	var/datum/space_ship/ship = SSspacecombat.pilot_ship(user.mob)
	if(!ship)
		return FALSE
	ship.dampeners = !ship.dampeners
	to_chat(user, span_notice("Inertial assistance [ship.dampeners ? "enabled" : "disabled"]."))
	return TRUE

/datum/keybinding/spacecombat/cycle_weapon
	hotkey_keys = list("Space")
	name = "spacecombat_cycle_weapon"
	full_name = "Ship: Cycle Weapon"
	description = "Select the next weapon"
	keybind_signal = "spacecombat_kb_cycle_weapon"

/datum/keybinding/spacecombat/cycle_weapon/down(client/user)
	. = ..()
	var/obj/machinery/computer/spacecombat/console = SSspacecombat.observers[user.mob]
	if(!console || !SSspacecombat.gunner_ship(user.mob))
		return FALSE
	console.select_weapon(user.mob, (console.selected_weapon % max(1, length(console.my_weapons()))) + 1)
	return TRUE

/datum/keybinding/spacecombat/weapon_1
	hotkey_keys = list("1")
	name = "spacecombat_weapon_1"
	full_name = "Ship: Weapon 1"
	description = "Select weapon 1"
	keybind_signal = "spacecombat_kb_weapon_1"
	var/slot = 1

/datum/keybinding/spacecombat/weapon_1/down(client/user)
	. = ..()
	var/obj/machinery/computer/spacecombat/console = SSspacecombat.observers[user.mob]
	if(!console || !SSspacecombat.gunner_ship(user.mob))
		return FALSE
	console.select_weapon(user.mob, slot)
	return TRUE

/datum/keybinding/spacecombat/weapon_1/weapon_2
	hotkey_keys = list("2")
	name = "spacecombat_weapon_2"
	full_name = "Ship: Weapon 2"
	description = "Select weapon 2"
	keybind_signal = "spacecombat_kb_weapon_2"
	slot = 2

/datum/keybinding/spacecombat/weapon_1/weapon_3
	hotkey_keys = list("3")
	name = "spacecombat_weapon_3"
	full_name = "Ship: Weapon 3"
	description = "Select weapon 3"
	keybind_signal = "spacecombat_kb_weapon_3"
	slot = 3

/datum/keybinding/spacecombat/weapon_1/weapon_4
	hotkey_keys = list("4")
	name = "spacecombat_weapon_4"
	full_name = "Ship: Weapon 4"
	description = "Select weapon 4"
	keybind_signal = "spacecombat_kb_weapon_4"
	slot = 4
