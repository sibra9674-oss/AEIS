// ---------------------------------------------------------------
// Camera: pilot looks at the space z-level, body stays at the console
// ---------------------------------------------------------------
/datum/controller/subsystem/spacecombat/proc/start_observing(mob/user, obj/machinery/computer/spacecombat/console)
	if(!user.client || !player_ship || player_ship.destroyed || !ensure_space_z())
		return FALSE
	if(!user.client)
		return FALSE
	if(user in observers)
		return TRUE
	observers[user] = console
	inject_keybinds(user.client)
	var/datum/action/innate/space_combat_leave/leave_action = new(user)
	leave_action.give_action(user)
	leave_actions[user] = leave_action
	var/atom/movable/screen/spacecombat_catcher/catcher = new
	catcher.setup(35, 25)
	user.client.screen += catcher
	catchers[user] = catcher
	RegisterSignal(user, COMSIG_MOVABLE_PRE_MOVE, PROC_REF(on_observer_move))
	refresh_visuals()
	user.reset_perspective(player_ship.visual)
	user.client.view_size.set_width_and_height(35, 25)
	SEND_SOUND(user, sound('sound/spacecombat/hum.ogg', volume = 60))
	add_verb(user, list(/mob/proc/space_combat_leave_view, /mob/proc/space_combat_next_weapon))
	to_chat(user, span_notice(console.role == SC_ROLE_HELM ? "Helm: W/S thrust, A/D turn (strafe with IAS off), Q/E rotate, Shift boost, Alt brakes, X toggle IAS, Space cycles weapons (railgun, PDC), left click fires." : "Tactical: 1-3 or Space select weapon (artillery, torpedoes, PDC), left click fires. Use the 'Leave Ship View' verb (IC tab) to return."))
	return TRUE

/// Players with an old savefile do not have our keybindings in their prefs, so the keys would do nothing. Adds them (in front) on demand.
/datum/controller/subsystem/spacecombat/proc/inject_keybinds(client/user)
	var/datum/preferences/user_prefs = user?.prefs
	if(!user_prefs)
		return
	if(!islist(user_prefs.key_bindings))
		user_prefs.key_bindings = list()
	for(var/kb_name in GLOB.keybindings_by_name)
		var/datum/keybinding/kb = GLOB.keybindings_by_name[kb_name]
		if(!kb || copytext(kb.name, 1, 13) != "spacecombat_")
			continue
		for(var/key in kb.hotkey_keys)
			var/list/bound = user_prefs.key_bindings[key]
			if(!islist(bound))
				bound = list()
			if(kb.name in bound)
				continue
			user_prefs.key_bindings[key] = list(kb.name) + bound

/datum/controller/subsystem/spacecombat/proc/stop_observing(mob/user)
	if(!(user in observers))
		return
	observers -= user
	var/datum/action/innate/space_combat_leave/leave_action = leave_actions[user]
	if(leave_action)
		leave_action.remove_action(user)
		qdel(leave_action)
	leave_actions -= user
	UnregisterSignal(user, COMSIG_MOVABLE_PRE_MOVE)
	var/atom/movable/screen/spacecombat_catcher/catcher = catchers[user]
	if(catcher)
		user.client?.screen -= catcher
		qdel(catcher)
	catchers -= user
	user.client?.view_size.reset_to_default()
	user.reset_perspective(null)
	remove_verb(user, list(/mob/proc/space_combat_leave_view, /mob/proc/space_combat_next_weapon))

/// Left click on the ship view: fires the console's weapon towards the cursor (aim = direction from the view centre, where our ship is).
/datum/controller/subsystem/spacecombat/proc/fire_towards(mob/source, dx, dy)
	var/obj/machinery/computer/spacecombat/console = observers[source]
	var/datum/space_ship/ship = player_ship
	if(!console || !ship || ship.destroyed)
		return
	var/datum/ship_weapon/weapon = console.current_weapon()
	if(!weapon)
		return
	var/aim = sc_bearing(0, 0, dx, dy)
	var/error = weapon.fire_error(ship, aim)
	if(error)
		to_chat(source, span_warning("[weapon.name]: [error]."))
		SEND_SOUND(source, sound('sound/spacecombat/error.ogg', volume = 40))
	else
		weapon.fire(ship, aim)

/// Invisible full-view button that receives clicks on the ship view, independent of turfs and lighting.
/atom/movable/screen/spacecombat_catcher
	icon = 'icons/mob/screen/generic.dmi'
	icon_state = "catcher"
	plane = HUD_PLANE
	layer = 1
	mouse_opacity = MOUSE_OPACITY_OPAQUE
	screen_loc = "CENTER"
	var/view_w = 35
	var/view_h = 25

/atom/movable/screen/spacecombat_catcher/proc/setup(width, height)
	view_w = width
	view_h = height
	var/max_tiles = 33
	var/ox = min(max_tiles, width)
	var/oy = min(max_tiles, height)
	var/px = width * 32
	var/py = height * 32
	var/sx = min(max_tiles * 32, px)
	var/sy = min(max_tiles * 32, py)
	var/icon/newicon = icon('icons/mob/screen/generic.dmi', "catcher")
	newicon.Scale(sx, sy)
	icon = newicon
	screen_loc = "CENTER-[(ox - 1) * 0.5],CENTER-[(oy - 1) * 0.5]"
	var/matrix/scaled = new
	scaled.Scale(px / sx, py / sy)
	transform = scaled

/atom/movable/screen/spacecombat_catcher/Click(location, control, params)
	var/list/modifiers = params2list(params)
	if(!modifiers["left"] || modifiers["shift"] || modifiers["ctrl"] || modifiers["alt"])
		return
	var/mob/clicker = usr
	if(!istype(clicker) || !(clicker in SSspacecombat.observers))
		return
	var/list/halves = splittext(modifiers["screen-loc"], ",")
	if(length(halves) < 2)
		return
	var/list/xs = splittext(halves[1], ":")
	var/list/ys = splittext(halves[2], ":")
	var/click_x = (text2num(xs[1]) - 1) * 32 + (length(xs) > 1 ? text2num(xs[2]) : 0)
	var/click_y = (text2num(ys[1]) - 1) * 32 + (length(ys) > 1 ? text2num(ys[2]) : 0)
	SSspacecombat.fire_towards(clicker, click_x - view_w * 16, click_y - view_h * 16)

/// WASD while looking through the ship: W/S thrust, A/D turn (IAS on) or strafe (IAS off), like NSV13.
/datum/controller/subsystem/spacecombat/proc/on_observer_move(mob/source, new_loc, direction)
	SIGNAL_HANDLER
	var/datum/space_ship/ship = pilot_ship(source)
	if(ship)
		ship.relay_thrust(direction)
	return COMPONENT_MOVABLE_BLOCK_PRE_MOVE

/// Ship the mob is piloting, or null.
/datum/controller/subsystem/spacecombat/proc/pilot_ship(mob/user)
	var/obj/machinery/computer/spacecombat/console = observers[user]
	if(!console || console.role != SC_ROLE_HELM || !player_ship || player_ship.destroyed)
		return null
	return player_ship

/// Ship the mob is operating weapons of (helm or tactical), or null.
/datum/controller/subsystem/spacecombat/proc/gunner_ship(mob/user)
	var/obj/machinery/computer/spacecombat/console = observers[user]
	if(!console || console.role == SC_ROLE_DRADIS || !player_ship || player_ship.destroyed)
		return null
	return player_ship

/mob/proc/space_combat_leave_view()
	set category = "IC"
	set name = "Leave Ship View"
	SSspacecombat.stop_observing(src)

/mob/proc/space_combat_next_weapon()
	set category = "IC"
	set name = "Next Ship Weapon"
	var/obj/machinery/computer/spacecombat/console = SSspacecombat.observers[src]
	if(!console || !SSspacecombat.player_ship)
		return
	console.select_weapon(src, (console.selected_weapon % max(1, length(console.my_weapons()))) + 1)

/datum/action/innate/space_combat_leave
	name = "Leave ship view"
	desc = "Return to your body."

/datum/action/innate/space_combat_leave/Activate()
	if(!ismob(owner))
		return
	SSspacecombat.stop_observing(owner)

