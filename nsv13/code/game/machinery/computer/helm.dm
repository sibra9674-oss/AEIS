//Ship piloting console, most of the code is already in ship.dm
/obj/machinery/computer/ship/helm
	name = "Seegson model HLM flight control console"
	desc = "A computerized ship piloting package which allows a user to set a ship's speed, attitude, bearing and more!"
	icon_screen = "helm"
	position = OVERMAP_USER_ROLE_PILOT
	circuit = /obj/item/circuitboard/computer/ship/helm

/obj/machinery/computer/ship/helm/syndicate
	req_one_access = list(ACCESS_SYNDICATE)

/obj/machinery/computer/ship/helm/Destroy()
	if(linked && linked.helm == src)
		linked.helm = null
	return ..()

/obj/machinery/computer/ship/helm/set_position(obj/structure/overmap/OM)
	OM.helm = src
	return

/**
	Allows boarding pilots to toggle autopilot! This is locked to boarding ships for obvious reasons...
*/

/obj/machinery/computer/ship/helm/multitool_act(mob/living/user, obj/item/I)
	if(!linked)
		linked = get_overmap()
	if(linked && allowed(user) && linked.role <= NORMAL_OVERMAP && initial(linked.ai_controlled))
		linked.ai_controlled = !linked.ai_controlled
		playsound(src, 'nsv13/sound/effects/computer/startup.ogg', 75, 1)
		to_chat(user, "<span class='warning'>Autopilot [linked.ai_controlled ? "Enabled" : "Disengaged"].</span>")
	..()
	return TRUE

// Helm and tactical in one console, useful for debugging
// This console should not be made available for the player ship, looking at you mappers
/obj/machinery/computer/ship/helm/allinone
	name = "debug ship"
	desc = "You shouldn't be seeing this"
	color = "red"

/obj/machinery/computer/ship/helm/allinone/ui_interact(mob/user)
	. = ..()
	if(!linked.gunner && isliving(user))
		linked.gunner = user

/obj/machinery/computer/ship/tactical/master
    name = "Unified Command Console"
    desc = "Integrated helm and tactical control. Move with WASD/Arrows, fire with mouse."
    icon_screen = "tactical"
    // circuit не указываем — спавним через админку напрямую
    position = OVERMAP_USER_ROLE_PILOT | OVERMAP_USER_ROLE_GUNNER  // маска из ship.dm

/obj/machinery/computer/ship/tactical/master/set_position(obj/structure/overmap/OM)
    OM.helm = src
    OM.tactical = src
    return

/obj/machinery/computer/ship/tactical/master/interact(mob/user, special_state)
    if(isobserver(user))
        return
    if(!has_overmap())
        playsound(src, pick('nsv13/sound/effects/computer/error.ogg','nsv13/sound/effects/computer/error2.ogg'), 100, 1)
        to_chat(user, "<span class='warning'>No ship linked.</span>")
        return

    if((position & (OVERMAP_USER_ROLE_PILOT | OVERMAP_USER_ROLE_GUNNER)) && linked.ai_controlled)
        playsound(src, 'nsv13/sound/effects/computer/error.ogg', 100, 1)
        to_chat(user, "<span class='warning'>Autopilot active. Disable AI first.</span>")
        return TRUE

    // Освобождаем и пилота, и стрелка (в чистом tactical освобождается только стрелок)
    if(linked.pilot && linked.pilot != user)
        linked.stop_piloting(linked.pilot)
    if(linked.gunner && linked.gunner != user)
        linked.stop_piloting(linked.gunner)

    if(!linked.start_piloting(user, position))
        return TRUE

    ui_users |= user
    RegisterSignal(user, COMSIG_STOPPED_PILOTING, PROC_REF(on_user_stopped_piloting))

    to_chat(user, "<span class='notice'>MASTER CONTROL ACTIVE.</span>")
    to_chat(user, "<span class='warning'>=Hotkeys=</span>")
    to_chat(user, "<span class='notice'>WASD/Arrows: thrust. Mouse: steer. LMB: fire. Ctrl+LMB: lock target.</span>")
    to_chat(user, "<span class='notice'>Space: cycle weapon. F: special. X: dampeners. Alt: handbrake. C: mouse/keyboard toggle.</span>")
    return ..()

/obj/machinery/computer/ship/tactical/master/ui_interact(mob/user, datum/tgui/ui)
    ui = SStgui.try_update_ui(user, src, ui)
    if(!ui)
        ui = new(user, src, "MasterControlUI")
        ui.open()
        ui.set_autoupdate(TRUE)

/obj/machinery/computer/ship/tactical/master/ui_data(mob/user)
    var/list/data = ..()  // наследуем данные из tactical (оружие, цели, броня)
    if(!data)
        return list()
    // Добавляем только реальные поля из ship.dm
    data["angle"] = linked.angle
    data["desired_angle"] = linked.desired_angle
    data["speed_limit"] = linked.speed_limit
    data["inertial_dampeners"] = linked.inertial_dampeners
    data["brakes"] = linked.brakes
    data["rcs_mode"] = linked.rcs_mode
    data["move_by_mouse"] = linked.move_by_mouse
    data["mass"] = linked.mass
    data["faction"] = linked.faction
    return data

/obj/machinery/computer/ship/tactical/master/ui_act(action, params, datum/tgui/ui)
    . = ..()
    if(.) return
    if(!linked) return
    switch(action)
        if("toggle_dampeners")
            linked.toggle_dampeners(usr)
            return TRUE
        if("toggle_brakes")
            linked.brakes = !linked.brakes
            return TRUE
        if("toggle_rcs")
            linked.rcs_mode = !linked.rcs_mode
            return TRUE
        if("toggle_mouse_steering")
            linked.move_by_mouse = !linked.move_by_mouse
            return TRUE
        if("boost")
            var/direction = text2num(params["direction"])
            if(!direction) direction = NORTH
            linked.boost(direction)
            return TRUE
    return FALSE
