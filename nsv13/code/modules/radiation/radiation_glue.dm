// NSV radiation system on TGMC. The wave / pulse / contamination code is NSV's own (radiation_wave.dm, helpers, components).
// What TGMC lacked is the per-atom plumbing and the mob side, written here the way tg/NSV does it:
//  - atoms: rad_flags / rad_insulation / rad_act()
//  - living mobs: accumulated `radiation`, decays by RAD_LOSS_PER_TICK, toxin damage above RAD_MOB_SAFE (tg handle_mutations_and_radiation),
//    driven by SSradiation once per second instead of the Life tick.
// Not ported: radiation armor (TGMC has no "rad" armor type), hair loss / mutation / vomiting thresholds, geiger counter, rad collectors.

/atom/var/rad_flags = NONE
/atom/var/rad_insulation = RAD_NO_INSULATION

/atom/proc/rad_act(strength)
	SEND_SIGNAL(src, COMSIG_ATOM_RAD_ACT, strength)

/mob/living/var/radiation = 0

/mob/living/rad_act(amount)
	. = ..()
	if(!amount || (amount < RAD_MOB_SKIN_PROTECTION))
		return
	amount -= RAD_BACKGROUND_RADIATION // always at least 1 because of how skin protection is calculated
	if(amount > RAD_BURN_THRESHOLD)
		apply_damage((amount - RAD_BURN_THRESHOLD) / RAD_BURN_THRESHOLD, BURN)
	radiation += max((amount * RAD_MOB_COEFFICIENT) / max(1, (radiation ** 2) * RAD_OVERDOSE_REDUCTION), 0)
	SSradiation.irradiated_mobs |= src

/// tg carbon life: radiation -= min(radiation, RAD_LOSS_PER_TICK); above RAD_MOB_SAFE it deals toxin damage. Called by SSradiation.
/mob/living/proc/nsv_radiation_tick()
	if(stat == DEAD)
		return
	radiation -= min(radiation, RAD_LOSS_PER_TICK)
	if(radiation > RAD_MOB_SAFE)
		apply_damage(log(radiation - RAD_MOB_SAFE) * RAD_TOX_COEFFICIENT, TOX, updating_health = TRUE)

/datum/controller/subsystem/processing/radiation
	var/list/irradiated_mobs = list()

/datum/controller/subsystem/processing/radiation/fire(resumed = FALSE)
	for(var/mob/living/L as anything in irradiated_mobs)
		if(QDELETED(L) || L.radiation <= 0)
			irradiated_mobs -= L
			continue
		L.nsv_radiation_tick()
	return ..()

// Wall insulation as in tg: normal walls medium, reinforced heavy
/turf/closed/wall/rad_insulation = RAD_MEDIUM_INSULATION
/turf/closed/wall/r_wall/rad_insulation = RAD_HEAVY_INSULATION
