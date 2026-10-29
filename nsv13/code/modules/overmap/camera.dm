// TGMC replacement for NSV's modules/overmap/camera.dm.
// NSV uses a Beestation "remote eye" mob; TGMC has no such thing, so the operator's client looks through the ship itself
// (reset_perspective(ship)), clicks arrive through an invisible screen catcher and movement keys are relayed to the ship.

/obj/structure/overmap/proc/gauss_test()
	return

/obj/structure/overmap/proc/start_piloting(mob/living/carbon/user, position)
	if(!position || user.overmap_ship == src || LAZYFIND(operators, user))
		return FALSE
	if(!user.client)
		return FALSE
	if(position & OVERMAP_USER_ROLE_PILOT)
		if(pilot)
			to_chat(pilot, "<span class='warning'>[user] has kicked you off the ship controls!</span>")
			stop_piloting(pilot)
		pilot = user
	if(position & OVERMAP_USER_ROLE_GUNNER)
		if(gunner)
			to_chat(gunner, "<span class='warning'>[user] has kicked you off the ship controls!</span>")
			stop_piloting(gunner)
		gunner = user
	nsv_ensure_keybinds(user.client)
	observe_ship(user)
	increment_selected_weapon(user)
	dradis?.attack_hand(user)
	if(position & (OVERMAP_USER_ROLE_PILOT | OVERMAP_USER_ROLE_GUNNER))
		add_verb(user, overmap_verbs)
	return TRUE

/obj/structure/overmap/proc/nsv_view_size()
	if(mass < MASS_MEDIUM)
		return 19
	return (mass <= MASS_MEDIUM) ? 27 : 35

/// Handles actually "observing" the ship.
/obj/structure/overmap/proc/observe_ship(mob/living/carbon/user)
	if(user.overmap_ship == src || LAZYFIND(operators, user))
		return FALSE
	LAZYADD(operators, user)
	user.overmap_ship = src
	CreateEye(user)

/obj/structure/overmap/proc/CreateEye(mob/user)
	if(!user.client)
		return
	var/view_w = nsv_view_size()
	var/view_h = round(view_w * 0.72) | 1
	RegisterSignal(user, COMSIG_MOVABLE_PRE_MOVE, PROC_REF(on_operator_move))
	RegisterSignal(user, COMSIG_MOB_LOGOUT, PROC_REF(on_operator_logout))
	var/atom/movable/screen/overmap_catcher/catcher = new
	catcher.ship = src
	catcher.setup(view_w, view_h)
	user.client.screen += catcher
	LAZYSET(catchers, user, catcher)
	var/datum/action/innate/camera_off/overmap/leave = new(user)
	leave.ship = src
	leave.give_action(user)
	LAZYSET(leave_actions, user, leave)
	user.reset_perspective(src)
	user.client.view_size.set_width_and_height(view_w, view_h)
	user.client.pixel_x = pixel_x
	user.client.pixel_y = pixel_y

/obj/structure/overmap/proc/on_operator_move(mob/source, new_loc, direction)
	SIGNAL_HANDLER
	if(source == pilot)
		relaymove(source, direction)
	return COMPONENT_MOVABLE_BLOCK_PRE_MOVE

/obj/structure/overmap/proc/on_operator_logout(mob/source)
	SIGNAL_HANDLER
	INVOKE_ASYNC(src, PROC_REF(stop_piloting), source)

/obj/structure/overmap/proc/stop_piloting(mob/living/M)
	SEND_SIGNAL(M, COMSIG_STOPPED_PILOTING)
	LAZYREMOVE(operators, M)
	remove_verb(M, overmap_verbs)
	if(length(controlled_weapon_datum)) //We sometimes end up in here after deleting.
		drop_weapon_selection(M)
	M.overmap_ship = null
	if(pilot && M == pilot)
		pilot = null
		keyboard_delta_angle_left = 0
		keyboard_delta_angle_right = 0
		if(helm)
			playsound(helm, 'nsv13/sound/effects/computer/hum.ogg', 100, 1)
	if(gunner && M == gunner)
		if(tactical)
			playsound(tactical, 'nsv13/sound/effects/computer/hum.ogg', 100, 1)
		gunner = null
		target_lock = null
	if(LAZYFIND(gauss_gunners, M))
		var/datum/component/overmap_gunning/C = M.GetComponent(/datum/component/overmap_gunning)
		C?.end_gunning()
	UnregisterSignal(M, list(COMSIG_MOVABLE_PRE_MOVE, COMSIG_MOB_LOGOUT))
	var/atom/movable/screen/overmap_catcher/catcher = LAZYACCESS(catchers, M)
	if(catcher)
		M.client?.screen -= catcher
		qdel(catcher)
	LAZYREMOVE(catchers, M)
	var/datum/action/innate/camera_off/overmap/leave = LAZYACCESS(leave_actions, M)
	if(leave)
		leave.remove_action(M)
		qdel(leave)
	LAZYREMOVE(leave_actions, M)
	if(M.client)
		M.client.view_size.reset_to_default()
		M.client.pixel_x = 0
		M.client.pixel_y = 0
	M.reset_perspective(null)
	return TRUE

/obj/structure/overmap/proc/remove_eye_control()
	return TRUE

/obj/structure/overmap/var/list/catchers
/obj/structure/overmap/var/list/leave_actions

/// Keeps the operator's view smooth: the ship moves by pixel offsets inside its tile, the client follows them.
/client/proc/AdjustView()
	if(mob?.overmap_ship)
		pixel_x = mob.overmap_ship.pixel_x
		pixel_y = mob.overmap_ship.pixel_y
	else
		pixel_x = 0
		pixel_y = 0

/datum/action/innate/camera_off/overmap
	name = "Stop observing"
	desc = "Return to your body."
	var/obj/structure/overmap/ship

/datum/action/innate/camera_off/overmap/Activate()
	if(!ship || !ismob(owner))
		return
	ship.stop_piloting(owner)

/// Invisible full-view button that receives clicks while looking through a ship (works independent of turfs and lighting).
/atom/movable/screen/overmap_catcher
	icon = 'icons/mob/screen/generic.dmi'
	icon_state = "catcher"
	plane = HUD_PLANE
	layer = 1
	mouse_opacity = MOUSE_OPACITY_OPAQUE
	screen_loc = "CENTER"
	var/obj/structure/overmap/ship
	var/view_w = 35
	var/view_h = 25

/atom/movable/screen/overmap_catcher/proc/setup(width, height)
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

/atom/movable/screen/overmap_catcher/Click(location, control, params)
	var/list/modifiers = params2list(params)
	var/mob/clicker = usr
	nsv_dbg(clicker, "catcher click params=[params] ship=[ship] overmap_ship=[clicker?.overmap_ship]")
	if(!istype(clicker) || !ship || clicker.overmap_ship != ship)
		return
	var/list/halves = splittext(modifiers["screen-loc"], ",")
	if(length(halves) < 2)
		return
	var/list/xs = splittext(halves[1], ":")
	var/list/ys = splittext(halves[2], ":")
	var/click_x = (text2num(xs[1]) - 1) * 32 + (length(xs) > 1 ? text2num(xs[2]) : 0)
	var/click_y = (text2num(ys[1]) - 1) * 32 + (length(ys) > 1 ? text2num(ys[2]) : 0)
	// Offset (in tiles) from the view centre, where our ship sits.
	var/dx = (click_x - view_w * 16) / 32
	var/dy = (click_y - view_h * 16) / 32
	var/turf/target = locate(clamp(round(ship.x + dx + 0.5), 1, world.maxx), clamp(round(ship.y + dy + 0.5), 1, world.maxy), ship.z)
	nsv_dbg(clicker, "click dx=[dx] dy=[dy] target=[target] ([target?.x],[target?.y]) ship=([ship.x],[ship.y]) angle=[ship.angle]")
	if(!target)
		return
	ship.InterceptClickOn(clicker, params, target)


/obj/structure/overmap/var/obj/structure/overmap/gunner_cam_target

/// Gunner target tracking: the gunner's view follows the locked target instead of our own ship (toggle by calling again with the same target).
/obj/structure/overmap/proc/update_gunner_cam(atom/target)
	if(!gunner?.client)
		return
	if(target == gunner_cam_target)
		target = null
	gunner_cam_target = isovermap(target) ? target : null
	var/obj/structure/overmap/focus = gunner_cam_target || src
	gunner.reset_perspective(focus)
	gunner.client.pixel_x = focus.pixel_x
	gunner.client.pixel_y = focus.pixel_y
