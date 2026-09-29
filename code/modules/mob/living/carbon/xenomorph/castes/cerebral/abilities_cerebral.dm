#define MOVESPEED_ID_CEREBRAL_AURA "cerebral_aura"
#define COMSIG_XENOABILITY_PSIONIC_AURA "xenoability_psionic_aura"
#define COMSIG_XENOABILITY_PSIONIC_BARRIER "xenoability_psionic_barrier"
#define COMSIG_XENOABILITY_MIND_CRUSH "xenoability_mind_crush"
#define COMSIG_XENOABILITY_PSYCHIC_RESONANCE "xenoability_psychic_resonance"
#define COMSIG_XENOABILITY_CEREBRAL_COLLAPSE "xenoability_cerebral_collapse"
#define COMSIG_XENOABILITY_CEREBRAL_FEAST "xenoability_cerebral_feast"

// ***************************************
// *********** Psionic Aura
// ***************************************
/datum/action/ability/xeno_action/psionic_aura
	name = "Psionic Aura"
	desc = "Toggle our psychic presence: nearby hive members regenerate plasma, but we are slowed and drain plasma. If we fall unconscious while projecting, linked sisters are knocked down."
	action_icon_state = "psionic_aura"
	action_icon = 'icons/Xeno/actions/cerebral.dmi'
	ability_cost = 0
	cooldown_duration = 5 SECONDS
	action_type = ACTION_TOGGLE
	keybinding_signals = list(
		KEYBINDING_NORMAL = COMSIG_XENOABILITY_PSIONIC_AURA,
	)
	var/aura_timer_id = 0

/datum/action/ability/xeno_action/psionic_aura/action_activate()
	. = ..()
	var/mob/living/carbon/xenomorph/cerebral/M = xeno_owner
	if(!istype(M))
		return fail_activate()

	toggled = !toggled
	if(toggled)
		M.aura_active = TRUE
		M.visible_message(span_xenowarning("[M] begins radiating psychic presence!"), span_xenowarning("We project our aura, empowering our kin."))
		playsound(M, 'sound/voice/alien/roar_warlock.ogg', 40, TRUE)
		var/datum/xeno_caste/cerebral/caste = M.xeno_caste
		M.add_movespeed_modifier(MOVESPEED_ID_CEREBRAL_AURA, TRUE, 0, NONE, TRUE, caste.aura_slowdown)
		aura_timer_id = addtimer(CALLBACK(src, PROC_REF(aura_tick), M), 2 SECONDS, TIMER_STOPPABLE)
	else
		stop_aura(M)

	succeed_activate()
	add_cooldown()

/datum/action/ability/xeno_action/psionic_aura/proc/aura_tick(mob/living/carbon/xenomorph/cerebral/M)
	aura_timer_id = 0
	if(QDELETED(M) || !M.aura_active)
		return
	var/datum/xeno_caste/cerebral/caste = M.xeno_caste
	if(M.plasma_stored < caste.aura_plasma_drain)
		to_chat(M, span_xenowarning("Not enough plasma to sustain our aura."))
		stop_aura(M)
		return

	M.plasma_stored -= caste.aura_plasma_drain
	M.aura_targets.Cut()

	var/radius = M.resonating ? 6 : 4
	var/gain = M.resonating ? 8 : 5
	for(var/mob/living/carbon/xenomorph/X in view(radius, M))
		if(X == M || X.get_xeno_hivenumber() != M.get_xeno_hivenumber())
			continue
		X.gain_plasma(gain)
		M.aura_targets += X

	aura_timer_id = addtimer(CALLBACK(src, PROC_REF(aura_tick), M), 2 SECONDS, TIMER_STOPPABLE)

/datum/action/ability/xeno_action/psionic_aura/proc/stop_aura(mob/living/carbon/xenomorph/cerebral/M)
	if(!M.aura_active)
		return
	M.aura_active = FALSE
	toggled = FALSE
	if(aura_timer_id)
		deltimer(aura_timer_id)
		aura_timer_id = 0
	M.aura_targets.Cut()
	M.remove_movespeed_modifier(MOVESPEED_ID_CEREBRAL_AURA)

/// Принудительно гасит ауру (крит, смерть плазмы)
/datum/action/ability/xeno_action/psionic_aura/proc/force_off(mob/living/carbon/xenomorph/cerebral/M)
	stop_aura(M)
	update_button_icon()

// ***************************************
// *********** Psionic Barrier
// ***************************************
/datum/action/ability/xeno_action/psionic_barrier
	name = "Psionic Barrier"
	desc = "Channel to shield nearby hive members with +30 armor for 4 seconds. Our own carapace weakens by 25 for the same duration."
	action_icon_state = "psionic_barrier"
	action_icon = 'icons/Xeno/actions/cerebral.dmi'
	ability_cost = 120
	cooldown_duration = 25 SECONDS
	keybinding_signals = list(
		KEYBINDING_NORMAL = COMSIG_XENOABILITY_PSIONIC_BARRIER,
	)

/datum/action/ability/xeno_action/psionic_barrier/action_activate()
	var/mob/living/carbon/xenomorph/cerebral/M = xeno_owner
	if(!istype(M))
		return fail_activate()
	if(!do_after(M, 1 SECONDS, NONE, M, BUSY_ICON_HOSTILE))
		return fail_activate()

	var/list/affected = list()
	for(var/mob/living/carbon/xenomorph/X in view(3, M))
		if(X.get_xeno_hivenumber() != M.get_xeno_hivenumber())
			continue
		X.soft_armor = X.soft_armor.modifyAllRatings(30)
		affected[X] = 30
	M.soft_armor = M.soft_armor.modifyAllRatings(-25)
	affected[M] = -25

	M.visible_message(span_xenowarning("[M] projects a shimmering psionic barrier!"), span_xenowarning("We shield our kin with our own mind."))
	playsound(M, 'sound/effects/bamf.ogg', 50, TRUE)

	addtimer(CALLBACK(src, PROC_REF(barrier_end), affected), 4 SECONDS)
	succeed_activate()
	add_cooldown()

/datum/action/ability/xeno_action/psionic_barrier/proc/barrier_end(list/affected)
	for(var/mob/living/carbon/xenomorph/X in affected)
		if(QDELETED(X))
			continue
		X.soft_armor = X.soft_armor.modifyAllRatings(-affected[X])

// ***************************************
// *********** Mind Crush
// ***************************************
/datum/action/ability/activable/xeno/mind_crush
	name = "Mind Crush"
	desc = "Crush a target's mind at range: 60 stamina damage, 2s knockdown and blindness."
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
// *********** Psychic Resonance
// ***************************************
/datum/action/ability/xeno_action/psychic_resonance
	name = "Psychic Resonance"
	desc = "Channel to overcharge our aura for 10 seconds: wider radius and stronger plasma gain, but our carapace weakens by 20. Requires an active aura."
	action_icon_state = "psychic_resonance"
	action_icon = 'icons/Xeno/actions/cerebral.dmi'
	ability_cost = 100
	cooldown_duration = 40 SECONDS
	keybinding_signals = list(
		KEYBINDING_NORMAL = COMSIG_XENOABILITY_PSYCHIC_RESONANCE,
	)

/datum/action/ability/xeno_action/psychic_resonance/can_use_action(silent, override_flags)
	. = ..()
	if(!.)
		return FALSE
	var/mob/living/carbon/xenomorph/cerebral/M = xeno_owner
	if(!istype(M) || M.resonating)
		return FALSE
	if(!M.aura_active)
		if(!silent)
			to_chat(owner, span_xenowarning("We must project our aura first!"))
		return FALSE

/datum/action/ability/xeno_action/psychic_resonance/action_activate()
	var/mob/living/carbon/xenomorph/cerebral/M = xeno_owner
	if(!do_after(M, 3 SECONDS, NONE, M, BUSY_ICON_HOSTILE))
		return fail_activate()

	M.resonating = TRUE
	M.soft_armor = M.soft_armor.modifyAllRatings(-20)
	M.visible_message(span_xenowarning("[M] begins to radiate overwhelming psychic presence!"), span_xenowarning("We resonate. Our kin grow stronger, our shell weaker."))
	playsound(M, 'sound/voice/alien/roar_warlock.ogg', 50, TRUE)

	addtimer(CALLBACK(src, PROC_REF(resonance_end), M), 10 SECONDS)
	succeed_activate()
	add_cooldown()

/datum/action/ability/xeno_action/psychic_resonance/proc/resonance_end(mob/living/carbon/xenomorph/cerebral/M)
	if(QDELETED(M) || !M.resonating)
		return
	M.resonating = FALSE
	M.soft_armor = M.soft_armor.modifyAllRatings(20)

// ***************************************
// *********** Cerebral Collapse
// ***************************************
/datum/action/ability/xeno_action/cerebral_collapse
	name = "Cerebral Collapse"
	desc = "Detonate our psychic core: 60 damage and 3s stagger to enemies in radius 5, 50 healing to hive members. Costs a third of our current health."
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
		H.apply_damage(60, BRUTE)
		H.adjust_stagger(3 SECONDS)
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
	desc = "Devour the mind of a broken victim (lying, staggered or unconscious): 120 damage, we heal the same and gain 150 plasma. A kill resets Psionic Barrier and Mind Crush."
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
	if(!(H.lying_angle || H.IsStaggered() || H.stat != CONSCIOUS))
		if(!silent)
			owner.balloon_alert(owner, "Target is not broken")
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
		reset_ability(/datum/action/ability/xeno_action/psionic_barrier)
		reset_ability(/datum/action/ability/activable/xeno/mind_crush)
		to_chat(xeno_owner, span_xenowarning("The feast resets our abilities!"))

	succeed_activate()
	add_cooldown()

/datum/action/ability/activable/xeno/cerebral_feast/proc/reset_ability(ability_path)
	var/datum/action/ability/target = xeno_owner.actions_by_path[ability_path]
	if(!target?.cooldown_timer)
		return
	deltimer(target.cooldown_timer)
	target.cooldown_timer = 0
	target.on_cooldown_finish()

#undef MOVESPEED_ID_CEREBRAL_AURA
