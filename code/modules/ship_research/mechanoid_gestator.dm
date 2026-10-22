/**
 * Ship Researcher: mechanoid gestator.
 * Takes a subcore plus metal and plasteel, and after a while grows a mechanoid (marine friendly) that is offered to ghosts.
 * It can also resurrect a dead mechanoid next to it for a small amount of metal.
 */
/obj/machinery/mechanoid_machine/gestator
	name = "mechanoid gestator"
	desc = "A vat that grows a mechanoid out of a subcore, metal and plasteel. It can also resurrect a dead mechanoid next to it."
	icon = 'icons/obj/machines/mechanoid_gestator.dmi'
	icon_state = "gestator"
	width_tiles = 2
	height_tiles = 2
	///The mechanoid type that the running gestation will produce
	var/gestating_type
	///Which of the variants of the loaded core will be grown (index)
	var/selected_variant = 1
	///The subcore waiting to be grown, or being grown right now
	var/obj/item/mechanoid_core/loaded_core
	///Metal sheets stored inside
	var/stored_metal = 0
	///Plasteel sheets stored inside
	var/stored_plasteel = 0
	///Timer id of the running gestation or resurrection, null if idle
	var/timerid
	///Bandwidth reserved by the running gestation or resurrection
	var/gestating_cost = 0
	///world.time when the running process started and will end
	var/gestation_start = 0
	var/gestation_end = 0
	///The dead mechanoid that is being resurrected, if that is what we are doing
	var/mob/living/simple_animal/hostile/mechanoid/resurrect_target
	///Who started the running process. The grown mechanoid is bonded to them.
	var/datum/weakref/creator_ref

/obj/machinery/mechanoid_machine/gestator/Destroy()
	if(timerid)
		deltimer(timerid)
		timerid = null
	GLOB.active_mechanoids -= src
	if(resurrect_target)
		resurrect_target.forceMove(drop_location())
		resurrect_target = null
	if(loaded_core)
		loaded_core.forceMove(drop_location())
		loaded_core = null
	return ..()

/obj/machinery/mechanoid_machine/gestator/examine(mob/user)
	. = ..()
	. += span_notice("Metal: [stored_metal]/[MECHANOID_MAX_STORED_SHEETS], plasteel: [stored_plasteel]/[MECHANOID_MAX_STORED_SHEETS].")
	. += span_notice("Ship mechanoid bandwidth: [get_mechanoid_bandwidth_used()]/[MECHANOID_BANDWIDTH_MAX].")
	if(timerid)
		. += span_notice(resurrect_target ? "It is resurrecting a mechanoid." : "It is growing a mechanoid.")
	else if(loaded_core)
		. += span_notice("Loaded: [loaded_core.name].")
	else
		. += span_notice("It is empty. Insert a subcore.")

/obj/machinery/mechanoid_machine/gestator/update_icon_state()
	. = ..()
	icon_state = timerid ? "gestator_active" : "gestator"

/obj/machinery/mechanoid_machine/gestator/attackby(obj/item/I, mob/living/user, params)
	. = ..()
	if(.)
		return

	if(istype(I, /obj/item/mechanoid_core))
		if(timerid)
			balloon_alert(user, "Busy")
			return TRUE
		if(loaded_core)
			balloon_alert(user, "Already loaded")
			return TRUE
		if(!user.transferItemToLoc(I, src))
			return TRUE
		loaded_core = I
		selected_variant = 1
		balloon_alert(user, "Subcore loaded")
		return TRUE

	if(istype(I, /obj/item/stack/sheet/plasteel))
		insert_sheets(user, I, TRUE)
		return TRUE

	if(istype(I, /obj/item/stack/sheet/metal))
		insert_sheets(user, I, FALSE)
		return TRUE

///Moves sheets from a stack into the gestator
/obj/machinery/mechanoid_machine/gestator/proc/insert_sheets(mob/living/user, obj/item/stack/sheet/sheets, is_plasteel)
	var/stored = is_plasteel ? stored_plasteel : stored_metal
	var/amount_to_add = min(sheets.amount, MECHANOID_MAX_STORED_SHEETS - stored)
	if(amount_to_add <= 0)
		balloon_alert(user, "Storage full")
		return
	if(!sheets.use(amount_to_add))
		return
	if(is_plasteel)
		stored_plasteel += amount_to_add
	else
		stored_metal += amount_to_add
	balloon_alert(user, "Inserted [amount_to_add]")

///Dead mechanoids next to the gestator
/obj/machinery/mechanoid_machine/gestator/proc/get_dead_mechanoids()
	. = list()
	for(var/mob/living/simple_animal/hostile/mechanoid/dead_mech in range(4, src))
		if(dead_mech.stat == DEAD && is_near(dead_mech))
			. += dead_mech

/obj/machinery/mechanoid_machine/gestator/ui_interact(mob/user, datum/tgui/ui)
	ui = SStgui.try_update_ui(user, src, ui)
	if(!ui)
		ui = new(user, src, "MechanoidGestator", name)
		ui.open()

/obj/machinery/mechanoid_machine/gestator/ui_data(mob/user)
	. = list()
	.["metal"] = stored_metal
	.["plasteel"] = stored_plasteel
	.["max_sheets"] = MECHANOID_MAX_STORED_SHEETS
	.["bandwidth_used"] = get_mechanoid_bandwidth_used()
	.["bandwidth_max"] = MECHANOID_BANDWIDTH_MAX
	.["busy"] = !!timerid
	.["resurrecting"] = !!resurrect_target
	.["progress"] = timerid && gestation_end > gestation_start ? clamp(round((world.time - gestation_start) / (gestation_end - gestation_start) * 100), 0, 100) : 0
	.["time_left"] = timerid ? max(0, round((gestation_end - world.time) / 10)) : 0

	var/list/core_data
	if(loaded_core)
		var/mob/living/simple_animal/hostile/mechanoid/result_type = get_mechanoid_type(loaded_core.bandwidth_cost, selected_variant)
		var/cost = result_type ? initial(result_type.bandwidth_cost) : loaded_core.bandwidth_cost
		var/list/variant_data = list()
		var/variant_index = 0
		for(var/mob/living/simple_animal/hostile/mechanoid/variant_type AS in get_mechanoid_variants(loaded_core.bandwidth_cost))
			variant_index++
			variant_data += list(list(
				"index" = variant_index,
				"name" = initial(variant_type.name),
				"bandwidth" = initial(variant_type.bandwidth_cost),
				"desc" = initial(variant_type.variant_desc),
				"selected" = variant_index == selected_variant,
			))
		core_data = list(
			"name" = loaded_core.name,
			"tier" = loaded_core.get_tier_name(),
			"caste" = loaded_core.caste_name,
			"bandwidth" = cost,
			"need_metal" = cost * MECHANOID_METAL_PER_BANDWIDTH,
			"need_plasteel" = cost * MECHANOID_PLASTEEL_PER_BANDWIDTH,
			"result" = result_type ? initial(result_type.name) : "unknown",
			"variants" = variant_data,
			"time" = round(cost * MECHANOID_GESTATION_TIME_PER_BANDWIDTH / 10),
		)
	.["core"] = core_data

	var/list/dead_data = list()
	for(var/mob/living/simple_animal/hostile/mechanoid/dead_mech AS in get_dead_mechanoids())
		dead_data += list(list(
			"name" = dead_mech.name,
			"ref" = REF(dead_mech),
			"bandwidth" = dead_mech.bandwidth_cost,
			"need_metal" = dead_mech.bandwidth_cost * MECHANOID_RESURRECT_METAL_PER_BANDWIDTH,
		))
	.["dead_mechanoids"] = dead_data

/obj/machinery/mechanoid_machine/gestator/ui_act(action, list/params, datum/tgui/ui, datum/ui_state/state)
	. = ..()
	if(.)
		return
	var/mob/user = ui.user
	if(!allowed(user))
		balloon_alert(user, "Access denied")
		return TRUE
	switch(action)
		if("start")
			start_gestation(user)
		if("set_variant")
			if(timerid || !loaded_core)
				return TRUE
			selected_variant = clamp(text2num(params["index"]) || 1, 1, length(get_mechanoid_variants(loaded_core.bandwidth_cost)))
		if("eject_core")
			if(timerid || !loaded_core)
				return TRUE
			loaded_core.forceMove(drop_location())
			user.put_in_hands(loaded_core)
			loaded_core = null
		if("eject_materials")
			if(timerid)
				return TRUE
			eject_sheets()
		if("resurrect")
			var/mob/living/simple_animal/hostile/mechanoid/dead_mech = locate(params["ref"]) in get_dead_mechanoids()
			if(dead_mech)
				start_resurrection(user, dead_mech)
	update_icon()
	return TRUE

///Checks everything and starts growing a mechanoid
/obj/machinery/mechanoid_machine/gestator/proc/start_gestation(mob/user)
	if(timerid || !loaded_core)
		return
	var/mob/living/simple_animal/hostile/mechanoid/chosen_type = get_mechanoid_type(loaded_core.bandwidth_cost, selected_variant)
	if(!chosen_type)
		return
	var/cost = initial(chosen_type.bandwidth_cost)
	gestating_type = chosen_type
	if(stored_metal < cost * MECHANOID_METAL_PER_BANDWIDTH || stored_plasteel < cost * MECHANOID_PLASTEEL_PER_BANDWIDTH)
		balloon_alert(user, "Not enough materials")
		return
	if(get_mechanoid_bandwidth_used() + cost > MECHANOID_BANDWIDTH_MAX)
		balloon_alert(user, "Not enough bandwidth")
		return

	stored_metal -= cost * MECHANOID_METAL_PER_BANDWIDTH
	stored_plasteel -= cost * MECHANOID_PLASTEEL_PER_BANDWIDTH
	begin_process(user, cost, cost * MECHANOID_GESTATION_TIME_PER_BANDWIDTH, PROC_REF(finish_gestation))
	visible_message(span_notice("[src] hums as it starts growing a mechanoid."))

///Checks everything and starts resurrecting a dead mechanoid
/obj/machinery/mechanoid_machine/gestator/proc/start_resurrection(mob/user, mob/living/simple_animal/hostile/mechanoid/dead_mech)
	if(timerid || QDELETED(dead_mech) || dead_mech.stat != DEAD)
		return
	var/cost = dead_mech.bandwidth_cost
	if(stored_metal < cost * MECHANOID_RESURRECT_METAL_PER_BANDWIDTH)
		balloon_alert(user, "Not enough metal")
		return
	if(get_mechanoid_bandwidth_used() + cost > MECHANOID_BANDWIDTH_MAX)
		balloon_alert(user, "Not enough bandwidth")
		return

	stored_metal -= cost * MECHANOID_RESURRECT_METAL_PER_BANDWIDTH
	resurrect_target = dead_mech
	dead_mech.forceMove(src)
	begin_process(user, cost, cost * MECHANOID_GESTATION_TIME_PER_BANDWIDTH * MECHANOID_RESURRECT_TIME_MULT, PROC_REF(finish_resurrection))
	visible_message(span_notice("[src] pulls [dead_mech] in and starts rebuilding it."))

///Reserves bandwidth and starts the timer for either process
/obj/machinery/mechanoid_machine/gestator/proc/begin_process(mob/user, cost, duration, finish_proc)
	gestating_cost = cost
	creator_ref = WEAKREF(user)
	GLOB.active_mechanoids[src] = cost
	gestation_start = world.time
	gestation_end = world.time + duration
	timerid = addtimer(CALLBACK(src, finish_proc), duration, TIMER_STOPPABLE)
	update_icon()

///Creates the mechanoid and offers it to ghosts
/obj/machinery/mechanoid_machine/gestator/proc/finish_gestation()
	var/cost = gestating_cost
	var/datum/weakref/creator = creator_ref
	var/mechanoid_type = gestating_type
	gestating_type = null
	reset_process()
	QDEL_NULL(loaded_core)
	selected_variant = 1
	if(!mechanoid_type)
		return

	var/mob/living/simple_animal/hostile/mechanoid/mechanoid = new mechanoid_type(get_exit_turf())
	mechanoid.master_ref = creator
	GLOB.active_mechanoids[mechanoid] = cost
	visible_message(span_notice("[src] opens with a hiss, and a [mechanoid.name] steps out."))
	playsound(src, 'sound/effects/alien/egg_burst.ogg', 50, TRUE)
	mechanoid.offer_mob()

///Brings the mechanoid back to life and offers it to ghosts
/obj/machinery/mechanoid_machine/gestator/proc/finish_resurrection()
	var/cost = gestating_cost
	var/mob/living/simple_animal/hostile/mechanoid/mechanoid = resurrect_target
	reset_process()
	if(QDELETED(mechanoid))
		return
	mechanoid.forceMove(get_exit_turf())
	mechanoid.revive(TRUE)
	mechanoid.icon_state = mechanoid.icon_living
	GLOB.active_mechanoids[mechanoid] = cost
	visible_message(span_notice("[src] opens with a hiss, and [mechanoid] steps out, good as new."))
	playsound(src, 'sound/effects/alien/egg_burst.ogg', 50, TRUE)
	if(!mechanoid.client)
		mechanoid.offer_mob()

///Clears the state of the running process
/obj/machinery/mechanoid_machine/gestator/proc/reset_process()
	timerid = null
	GLOB.active_mechanoids -= src
	gestating_cost = 0
	resurrect_target = null
	creator_ref = null
	update_icon()

///Drops all stored sheets on the floor
/obj/machinery/mechanoid_machine/gestator/proc/eject_sheets()
	if(stored_metal)
		new /obj/item/stack/sheet/metal(drop_location(), stored_metal)
		stored_metal = 0
	if(stored_plasteel)
		new /obj/item/stack/sheet/plasteel(drop_location(), stored_plasteel)
		stored_plasteel = 0
