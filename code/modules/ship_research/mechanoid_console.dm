/**
 * Ship Researcher: mechanoid control console.
 * Lists the mechanoids of the ship and their bandwidth. Mechanoids without a pilot can be recalled, offered to ghosts again, or decommissioned.
 */
/obj/machinery/computer/mechanoid_console
	name = "mechanoid control console"
	desc = "Tracks every mechanoid grown on the ship and the bandwidth they take up."
	icon = 'icons/obj/machines/cryogenics.dmi'
	icon_state = "body_scannerconsole"
	screen_overlay = "body_scannerconsole_emissive"
	density = FALSE
	anchored = TRUE
	resistance_flags = RESIST_ALL
	idle_power_usage = 50
	interaction_flags = INTERACT_MACHINE_TGUI
	req_access = list(ACCESS_MARINE_RESEARCH)
	light_color = LIGHT_COLOR_EMISSIVE_GREEN

/obj/machinery/computer/mechanoid_console/ui_interact(mob/user, datum/tgui/ui)
	ui = SStgui.try_update_ui(user, src, ui)
	if(!ui)
		ui = new(user, src, "MechanoidConsole", name)
		ui.open()

/obj/machinery/computer/mechanoid_console/ui_data(mob/user)
	. = list()
	.["bandwidth_used"] = get_mechanoid_bandwidth_used() // also cleans up dead entries
	.["bandwidth_max"] = MECHANOID_BANDWIDTH_MAX
	var/list/mechanoids = list()
	for(var/atom/entry AS in GLOB.active_mechanoids)
		if(!istype(entry, /mob/living/simple_animal/hostile/mechanoid))
			continue
		var/mob/living/simple_animal/hostile/mechanoid/mechanoid = entry
		var/area/mechanoid_area = get_area(mechanoid)
		var/mob/living/master = mechanoid.master_ref?.resolve()
		mechanoids += list(list(
			"name" = mechanoid.name,
			"ref" = REF(mechanoid),
			"bandwidth" = mechanoid.bandwidth_cost,
			"health" = mechanoid.maxHealth ? clamp(round(mechanoid.health / mechanoid.maxHealth * 100), 0, 100) : 0,
			"area" = mechanoid_area ? mechanoid_area.name : "unknown",
			"piloted" = !!mechanoid.client,
			"master" = master ? master.real_name : null,
		))
	.["mechanoids"] = mechanoids

/obj/machinery/computer/mechanoid_console/ui_act(action, list/params, datum/tgui/ui, datum/ui_state/state)
	. = ..()
	if(.)
		return
	var/mob/user = ui.user
	if(!allowed(user))
		balloon_alert(user, "Access denied")
		return TRUE
	var/mob/living/simple_animal/hostile/mechanoid/target = locate(params["ref"]) in GLOB.active_mechanoids
	if(!istype(target) || QDELETED(target) || target.stat == DEAD)
		return TRUE
	if(target.client)
		to_chat(user, span_notice("[target] is controlled by someone and can't be reconfigured."))
		return TRUE
	switch(action)
		if("offer")
			target.offer_mob()
			to_chat(user, span_notice("[target] has been offered to ghosts again."))
		if("recall")
			target.Goto(user, target.move_to_delay, 1)
			to_chat(user, span_notice("[target] is coming to you."))
		if("decommission")
			target.visible_message(span_warning("[target] shuts down and collapses into inert tissue."))
			qdel(target)
	return TRUE
