/**
 * Ship Researcher: subnuclear encoder.
 * Turns a dead xenomorph standing next to it into a subcore: tier 1 gives a basic subcore, tier 2 a standard one and tier 3 a high one.
 */
/obj/machinery/mechanoid_machine/encoder
	name = "subnuclear encoder"
	desc = "Burns a dead xenomorph down to its brain and encodes it into a subcore. Put a corpse next to it and use the machine."
	icon = 'icons/obj/machines/mechanoid_encoder.dmi'
	icon_state = "encoder"
	width_tiles = 3
	height_tiles = 2
	///Corpse that is being processed right now
	var/mob/living/carbon/xenomorph/processing_corpse
	///Timer id of the running process
	var/timerid
	///world.time when the process started and will end
	var/process_start = 0
	var/process_end = 0

/obj/machinery/mechanoid_machine/encoder/Destroy()
	if(timerid)
		deltimer(timerid)
		timerid = null
	processing_corpse = null
	return ..()

/obj/machinery/mechanoid_machine/encoder/update_icon_state()
	. = ..()
	icon_state = timerid ? "encoder_active" : "encoder"

///Dead xenomorphs next to the encoder that can be made into subcores
/obj/machinery/mechanoid_machine/encoder/proc/get_candidates()
	. = list()
	for(var/mob/living/carbon/xenomorph/candidate in range(4, src))
		if(candidate.stat == DEAD && GLOB.mechanoid_bandwidth_by_tier[candidate.tier] && !isxenohivemind(candidate) && is_near(candidate))
			. += candidate

/obj/machinery/mechanoid_machine/encoder/ui_interact(mob/user, datum/tgui/ui)
	ui = SStgui.try_update_ui(user, src, ui)
	if(!ui)
		ui = new(user, src, "MechanoidEncoder", name)
		ui.open()

/obj/machinery/mechanoid_machine/encoder/ui_data(mob/user)
	. = list()
	.["processing"] = !!timerid
	.["progress"] = timerid && process_end > process_start ? clamp(round((world.time - process_start) / (process_end - process_start) * 100), 0, 100) : 0
	.["time_left"] = timerid ? max(0, round((process_end - world.time) / 10, 0.1)) : 0
	.["processing_name"] = processing_corpse ? processing_corpse.name : null
	var/list/corpses = list()
	for(var/mob/living/carbon/xenomorph/candidate AS in get_candidates())
		var/cost = GLOB.mechanoid_bandwidth_by_tier[candidate.tier]
		corpses += list(list(
			"name" = candidate.name,
			"caste" = candidate.xeno_caste.caste_name,
			"ref" = REF(candidate),
			"subcore" = get_subcore_tier_name(cost),
			"bandwidth" = cost,
		))
	.["corpses"] = corpses

/obj/machinery/mechanoid_machine/encoder/ui_act(action, list/params, datum/tgui/ui, datum/ui_state/state)
	. = ..()
	if(.)
		return
	var/mob/user = ui.user
	if(!allowed(user))
		balloon_alert(user, "Access denied")
		return TRUE
	if(action != "encode")
		return TRUE
	if(timerid)
		balloon_alert(user, "Busy")
		return TRUE
	if(user.skills.getRating(SKILL_MEDICAL) < SKILL_MEDICAL_EXPERT)
		balloon_alert(user, "Not skilled enough")
		return TRUE
	var/mob/living/carbon/xenomorph/corpse = locate(params["ref"]) in get_candidates()
	if(!corpse)
		balloon_alert(user, "Corpse lost")
		return TRUE
	processing_corpse = corpse
	process_start = world.time
	process_end = world.time + MECHANOID_ENCODE_TIME
	timerid = addtimer(CALLBACK(src, PROC_REF(finish_encoding)), MECHANOID_ENCODE_TIME, TIMER_STOPPABLE)
	visible_message(span_notice("[src] hums as it starts to process [corpse]."))
	update_icon()
	return TRUE

///Finishes the process and spits out the subcore
/obj/machinery/mechanoid_machine/encoder/proc/finish_encoding()
	timerid = null
	var/mob/living/carbon/xenomorph/corpse = processing_corpse
	processing_corpse = null
	update_icon()
	if(QDELETED(corpse) || corpse.stat != DEAD || !is_near(corpse))
		visible_message(span_warning("[src] beeps: the corpse was lost."))
		return
	var/obj/item/mechanoid_core/core = new(drop_location())
	core.setup_from_xeno(corpse, GLOB.mechanoid_bandwidth_by_tier[corpse.tier])
	visible_message(span_notice("[src] dings and spits out a [core.name], leaving nothing of [corpse]."))
	qdel(corpse)
