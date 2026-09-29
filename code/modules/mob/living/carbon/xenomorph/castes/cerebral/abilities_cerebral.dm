#define MOVESPEED_ID_CEREBRAL_AURA "cerebral_aura"
#define COMSIG_XENOABILITY_REINFORCE "xenoability_reinforce"
#define COMSIG_XENOABILITY_MIND_CRUSH "xenoability_mind_crush"
#define COMSIG_XENOABILITY_CEREBRAL_COLLAPSE "xenoability_cerebral_collapse"
#define COMSIG_XENOABILITY_CEREBRAL_FEAST "xenoability_cerebral_feast"

#define REINFORCE_RADIUS 5
#define REINFORCE_LOOP_TIME 2 SECONDS
#define REINFORCE_ARMOR_BOOST 30
#define REINFORCE_SELF_ARMOR_PENALTY 35
#define REINFORCE_PLASMA_GAIN 5

// ***************************************
// *********** Reinforce (аура + барьер)
// ***************************************
/datum/action/ability/xeno_action/reinforce
	name = "Reinforce"
	desc = "Channel to create a psychic field: nearby hive members gain +30 armor and +5 plasma every 2 seconds. Our own carapace weakens by 35 while channeling. If we fall unconscious, linked sisters are knocked down."
	action_icon_state = "reinforce"
	action_icon = 'icons/Xeno/actions/cerebral.dmi'
	ability_cost = 120
	cooldown_duration = 25 SECONDS
	keybinding_signals = list(
		KEYBINDING_NORMAL = COMSIG_XENOABILITY_REINFORCE,
	)
	/// List of xenos currently in the zone and their armor boost
	var/list/armor_keys = list()
	/// Timer for plasma regen ticks
	var/plasma_timer_id = 0
	/// Used for particles
	var/obj/effect/abstract/particle_holder/particle_holder
	/// List of turfs in the zone
	var/list/affected_turfs

/datum/action/ability/xeno_action/reinforce/remove_action(mob/living/L)
	if(particle_holder)
		remove_affected_area()
	return ..()

/datum/action/ability/xeno_action/reinforce/action_activate()
	var/mob/living/carbon/xenomorph/cerebral/M = xeno_owner
	if(!istype(M))
		return fail_activate()
	if(particle_holder)
		return
	add_cooldown()
	create_affected_area()
	// Debuff self while channeling
	M.soft_armor = M.soft_armor.modifyAllRatings(-REINFORCE_SELF_ARMOR_PENALTY)
	M.add_movespeed_modifier(MOVESPEED_ID_CEREBRAL_AURA, TRUE, 0, NONE, TRUE, M.xeno_caste.aura_slowdown)
	M.aura_active = TRUE
	// Start plasma regen tick
	plasma_timer_id = addtimer(CALLBACK(src, PROC_REF(plasma_tick), M), REINFORCE_LOOP_TIME, TIMER_STOPPABLE|TIMER_LOOP)
	// Channel loop
	while(do_after(M, REINFORCE_LOOP_TIME, IGNORE_HELD_ITEM, user_display = BUSY_ICON_MEDICAL, extra_checks = CALLBACK(src, TYPE_PROC_REF(/datum/action, can_use_action), FALSE, ABILITY_IGNORE_COOLDOWN|ABILITY_USE_BUSY)))
		succeed_activate()
	stop_reinforce(M)

/datum/action/ability/xeno_action/reinforce/proc/create_affected_area()
	particle_holder = new(owner.loc, /particles/reinforce_aoe)
	particle_holder.particles.position = generator(GEN_SQUARE, 0, 16 + (REINFORCE_RADIUS - 1) * 32, LINEAR_RAND)
	affected_turfs = RANGE_TURFS(REINFORCE_RADIUS, xeno_owner)
	for(var/turf/affected_turf AS in affected_turfs)
		RegisterSignal(affected_turf, COMSIG_ATOM_EXITED, PROC_REF(remove_buff))
		RegisterSignal(affected_turf, COMSIG_ATOM_ENTERED, PROC_REF(apply_buff))
		ADD_TRAIT(affected_turf, TRAIT_BULWARKED_TURF, XENO_TRAIT)
		for(var/mob/living/carbon/xenomorph/affected_xeno in affected_turf)
			apply_buff(null, affected_xeno)

/datum/action/ability/xeno_action/reinforce/proc/remove_affected_area()
	QDEL_IN(particle_holder, 4 SECONDS)
	particle_holder.particles.spawning = 0
	particle_holder = null
	if(plasma_timer_id)
		deltimer(plasma_timer_id)
		plasma_timer_id = 0
	for(var/turf/affected_turf AS in affected_turfs)
		UnregisterSignal(affected_turf, list(COMSIG_ATOM_EXITED, COMSIG_ATOM_ENTERED))
		REMOVE_TRAIT(affected_turf, TRAIT_BULWARKED_TURF, XENO_TRAIT)
	for(var/mob/living/carbon/xenomorph/affected_xeno in armor_keys)
		remove_buff(null, affected_xeno)
	armor_keys.Cut()
	affected_turfs = null

/datum/action/ability/xeno_action/reinforce/proc/apply_buff(datum/source, mob/living/carbon/xenomorph/xeno, direction)
	SIGNAL_HANDLER
	if(!isxeno(xeno) || !owner.issamexenohive(xeno))
		return
	if(!armor_keys[xeno])
		xeno.soft_armor = xeno.soft_armor.modifyAllRatings(REINFORCE_ARMOR_BOOST)
		armor_keys[xeno] = REINFORCE_ARMOR_BOOST
		var/mob/living/carbon/xenomorph/cerebral/M = xeno_owner
		if(istype(M))
			M.aura_targets |= xeno

/datum/action/ability/xeno_action/reinforce/proc/remove_buff(datum/source, mob/living/carbon/xenomorph/xeno, direction)
	SIGNAL_HANDLER
	if(direction)
		var/turf/next = get_step(source, direction)
		if(HAS_TRAIT(next, TRAIT_BULWARKED_TURF))
			return
	if(armor_keys[xeno])
		xeno.soft_armor = xeno.soft_armor.modifyAllRatings(-armor_keys[xeno])
		armor_keys -= xeno
		var/mob/living/carbon/xenomorph/cerebral/M = xeno_owner
		if(istype(M))
			M.aura_targets -= xeno

/datum/action/ability/xeno_action/reinforce/proc/plasma_tick(mob/living/carbon/xenomorph/cerebral/M)
	if(QDELETED(M) || !M.aura_active)
		return
	var/datum/xeno_caste/cerebral/caste = M.xeno_caste
	if(M.plasma_stored < caste.aura_plasma_drain)
		to_chat(M, span_xenowarning("Not enough plasma to sustain our aura."))
		stop_reinforce(M)
		return
	M.plasma_stored -= caste.aura_plasma_drain
	for(var/mob/living/carbon/xenomorph/X in armor_keys)
		if(QDELETED(X) || X.stat == DEAD)
			continue
		X.gain_plasma(REINFORCE_PLASMA_GAIN)

/datum/action/ability/xeno_action/reinforce/proc/stop_reinforce(mob/living/carbon/xenomorph/cerebral/M)
	if(!M.aura_active)
		return
	M.aura_active = FALSE
	M.soft_armor = M.soft_armor.modifyAllRatings(REINFORCE_SELF_ARMOR_PENALTY)
	M.remove_movespeed_modifier(MOVESPEED_ID_CEREBRAL_AURA)
	remove_affected_area()

/datum/action/ability/xeno_action/reinforce/proc/force_off(mob/living/carbon/xenomorph/cerebral/M)
	stop_reinforce(M)

/particles/reinforce_aoe
	icon = 'icons/effects/particles/generic_particles.dmi'
	icon_state = list("cross" = 1, "x" = 1, "rectangle" = 1, "up_arrow" = 1, "down_arrow" = 1, "square" = 1)
	width = 500
	height = 500
	count = 2000
	spawning = 50
	gravity = list(0, 0.1)
	color = LIGHT_COLOR_PURPLE
	lifespan = 13
	fade = 5
	fadein = 5
	scale = 0.8
	friction = generator(GEN_NUM, 0.1, 0.15)
	spin = generator(GEN_NUM, -20, 20)

// ***************************************
// *********** Mind Crush
// ***************************************
/datum/action/ability/activable/xeno/mind_crush
	name = "Mind Crush"
	desc = "Crush a target's mind at range: 60 stamina damage, 2s knockdown and 2s blindness. Cannot kill."
	action_icon_state = "mind_crush"
	action_icon = 'icons/Xeno/actions/cerebral.dmi'
	ability_cost = 150
	cooldown_duration = 20 SECONDS
	target_flags = ABILITY_MOB_TARGET
	keybinding_signals = list(
		KEYBINDING_NORMAL = COMSIG_XENOABILITY_MIND_CRUSH,
	)
	var/targetable_range = 8

/datum/action/ability/activable/xeno/mind_crush/can_use_ability(atom/A, silent = FALSE, override_flags)
	. = ..()
	if(!.)
		return FALSE
	if(!ishuman(A))
		if(!silent)
			owner.balloon_alert(owner, "Cannot crush")
		return FALSE
	var/mob/living/carbon/human/H = A
	if(H.stat == DEAD || H.issamexenohive(owner))
		return FALSE
	if(get_dist(owner, H) > targetable_range || !line_of_sight(owner, H, targetable_range))
		if(!silent)
			owner.balloon_alert(owner, "Too far")
		return FALSE

/datum/action/ability/activable/xeno/mind_crush/use_ability(atom/A)
	var/mob/living/carbon/human/H = A
	xeno_owner.face_atom(H)
	if(!do_after(xeno_owner, 1.5 SECONDS, IGNORE_TARGET_LOC_CHANGE, H, BUSY_ICON_HOSTILE))
		return fail_activate()
	H.apply_damage(60, STAMINA)
	H.Knockdown(2 SECONDS)
	H.adjust_blindness(2)
	H.apply_status_effect(STATUS_EFFECT_CONFUSED, 4 SECONDS)
	H.emote("scream")
	shake_camera(H, 2, 1)
	xeno_owner.visible_message(span_xenowarning("[xeno_owner] crushes [H]'s mind!"), span_xenowarning("We crush [H]'s mind."))
	playsound(H, 'sound/voice/alien/roar_warlock.ogg', 40, TRUE)
	succeed_activate()
	add_cooldown()

// ***************************************
// *********** Cerebral Collapse
// ***************************************
/datum/action/ability/xeno_action/cerebral_collapse
	name = "Cerebral Collapse"
	desc = "Detonate our psychic core: 40 brute and 2s stagger to enemies in radius 5, 50 healing to hive members. Costs a third of our current health."
	action_icon_state = "cerebral_collapse"
	action_icon = 'icons/Xeno/actions/cerebral.dmi'
	ability_cost = 250
	cooldown_duration = 80 SECONDS
	keybinding_signals = list(
		KEYBINDING_NORMAL = COMSIG_XENOABILITY_CEREBRAL_COLLAPSE,
	)

/datum/action/ability/xeno_action/cerebral_collapse/action_activate()
	var/mob/living/carbon/xenomorph/cerebral/M = xeno_owner
	if(!istype(M))
		return fail_activate()
	if(!do_after(M, 2 SECONDS, NONE, M, BUSY_ICON_HOSTILE))
		return fail_activate()
	playsound(M, 'sound/effects/bamf.ogg', 75, TRUE)
	playsound(M, 'sound/voice/alien/roar_warlock.ogg', 50, TRUE)
	shake_camera(M, 2, 2)
	M.visible_message(span_xenowarning("[M]'s brain detonates in a psychic nova!"), span_xenowarning("We collapse our cortex outward!"))
	for(var/turf/T in RANGE_TURFS(5, M))
		T.Shake(duration = 0.5 SECONDS)
	for(var/mob/living/carbon/human/H in view(5, M))
		if(H.stat == DEAD || H.issamexenohive(M))
			continue
		H.apply_damage(40, BRUTE)
		H.adjust_stagger(2 SECONDS)
		H.adjust_blindness(2)
		shake_camera(H, 2, 1)
	for(var/mob/living/carbon/xenomorph/X in view(5, M))
		if(X == M || X.get_xeno_hivenumber() != M.get_xeno_hivenumber())
			continue
		HEAL_XENO_DAMAGE(X, 50, FALSE)
	M.apply_damage(round(M.health * 0.3), BRUTE)
	succeed_activate()
	add_cooldown()

// ***************************************
// *********** Cerebral Feast (Primordial)
// ***************************************
/datum/action/ability/activable/xeno/cerebral_feast
	name = "Cerebral Feast"
	desc = "Devour the mind of a CRITICAL victim (unconscious): 120 brute damage, we heal the same and gain 150 plasma. A kill resets Mind Crush cooldown."
	action_icon_state = "cerebral_feast"
	action_icon = 'icons/Xeno/actions/cerebral.dmi'
	ability_cost = 50
	cooldown_duration = 30 SECONDS
	target_flags = ABILITY_MOB_TARGET
	keybinding_signals = list(
		KEYBINDING_NORMAL = COMSIG_XENOABILITY_CEREBRAL_FEAST,
	)

/datum/action/ability/activable/xeno/cerebral_feast/can_use_ability(atom/A, silent = FALSE, override_flags)
	. = ..()
	if(!.)
		return FALSE
	if(!ishuman(A))
		if(!silent)
			owner.balloon_alert(owner, "Cannot devour")
		return FALSE
	var/mob/living/carbon/human/H = A
	if(H.stat == DEAD || H.issamexenohive(owner))
		return FALSE
	if(!owner.Adjacent(H))
		if(!silent)
			owner.balloon_alert(owner, "Too far")
		return FALSE
	if(H.stat != UNCONSCIOUS)
		if(!silent)
			owner.balloon_alert(owner, "Target must be in critical condition")
		return FALSE

/datum/action/ability/activable/xeno/cerebral_feast/use_ability(atom/A)
	var/mob/living/carbon/human/H = A
	xeno_owner.face_atom(H)
	if(!do_after(xeno_owner, 1 SECONDS, IGNORE_TARGET_LOC_CHANGE, H, BUSY_ICON_HOSTILE))
		return fail_activate()
	H.apply_damage(120, BRUTE)
	HEAL_XENO_DAMAGE(xeno_owner, 120, FALSE)
	xeno_owner.gain_plasma(150)
	xeno_owner.visible_message(span_xenowarning("[xeno_owner] devours [H]'s mind!"), span_xenowarning("We feast on [H]'s thoughts."))
	playsound(H, 'sound/voice/alien/drool2.ogg', 40, TRUE)
	if(H.stat == DEAD)
		reset_ability_cooldown(/datum/action/ability/activable/xeno/mind_crush)
		to_chat(xeno_owner, span_xenowarning("The feast resets our abilities!"))
	succeed_activate()
	add_cooldown()

/datum/action/ability/activable/xeno/cerebral_feast/proc/reset_ability_cooldown(ability_path)
	var/datum/action/ability/target = xeno_owner.actions_by_path[ability_path]
	if(!target || !target.cooldown_timer)
		return
	deltimer(target.cooldown_timer)
	target.cooldown_timer = 0
	target.on_cooldown_finish()

#undef MOVESPEED_ID_CEREBRAL_AURA
