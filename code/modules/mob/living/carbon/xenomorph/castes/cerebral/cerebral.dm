/mob/living/carbon/xenomorph/cerebral
	caste_base_type = /datum/xeno_caste/cerebral
	name = "Cerebral"
	desc = "A walking brain of the hive, wreathed in psychic dread."
	icon = 'icons/Xeno/castes/cerebral/basic.dmi'
	icon_state = "Cerebral Walking"
	effects_icon = 'icons/Xeno/castes/cerebral/effects.dmi'
	bubble_icon = "alienroyal"
	health = 250
	maxHealth = 250
	plasma_stored = 100
	pixel_x = -16
	tier = XENO_TIER_THREE
	upgrade = XENO_UPGRADE_NORMAL

	/// Активна ли аура
	var/aura_active = FALSE
	/// Ксены, получавшие бафф на последнем тике ауры
	var/list/aura_targets = list()
	/// Были ли мы в критe на прошлом update_health
	var/was_crit = FALSE

/mob/living/carbon/xenomorph/cerebral/Destroy()
	aura_targets = null
	return ..()

// Хук входа в крит: update_health вызывается apply_damage и лечилками
/mob/living/carbon/xenomorph/cerebral/update_health()
	. = ..()
	var/crit_now = (stat == UNCONSCIOUS)
	if(crit_now && !was_crit && aura_active)
		shatter_link()
	was_crit = crit_now

// Крит с активной аурой: все слинкованные падают, аура гаснет
/mob/living/carbon/xenomorph/cerebral/proc/shatter_link()
	for(var/mob/living/carbon/xenomorph/X in aura_targets)
		if(QDELETED(X) || X.stat == DEAD)
			continue
		X.Knockdown(2 SECONDS)
		to_chat(X, span_xenodanger("Our link to [src] shatters our mind!"))
	aura_targets.Cut()
	var/datum/action/ability/xeno_action/psionic_aura/aura = actions_by_path[/datum/action/ability/xeno_action/psionic_aura]
	aura?.force_off(src)

/mob/living/carbon/xenomorph/cerebral/primordial
	upgrade = XENO_UPGRADE_PRIMO

/mob/living/carbon/xenomorph/cerebral/Corrupted
	hivenumber = XENO_HIVE_CORRUPTED

/mob/living/carbon/xenomorph/cerebral/Alpha
	hivenumber = XENO_HIVE_ALPHA

/mob/living/carbon/xenomorph/cerebral/Beta
	hivenumber = XENO_HIVE_BETA

/mob/living/carbon/xenomorph/cerebral/Zeta
	hivenumber = XENO_HIVE_ZETA

/mob/living/carbon/xenomorph/cerebral/admeme
	hivenumber = XENO_HIVE_ADMEME

/mob/living/carbon/xenomorph/cerebral/Corrupted/fallen
	hivenumber = XENO_HIVE_FALLEN
