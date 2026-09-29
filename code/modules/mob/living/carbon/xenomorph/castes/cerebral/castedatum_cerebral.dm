/datum/xeno_caste/cerebral
	caste_name = "Cerebral"
	display_name = "Cerebral"
	upgrade_name = ""
	caste_desc = "A colossal psychic anchor of the hive. It wades forward, soaking punishment while its presence empowers its kin."
	caste_type_path = /mob/living/carbon/xenomorph/cerebral
	tier = XENO_TIER_THREE
	upgrade = XENO_UPGRADE_BASETYPE

	melee_damage = 18
	speed = -0.6
	plasma_max = 500
	plasma_gain = 18
	max_health = 650
	sunder_multiplier = 0.7
	evolution_threshold = 300

	caste_flags = CASTE_EVOLUTION_ALLOWED|CASTE_IS_STRONG
	can_flags = CASTE_CAN_BE_QUEEN_HEALED|CASTE_CAN_BE_GIVEN_PLASMA|CASTE_CAN_BE_LEADER
	caste_traits = null

	soft_armor = list(MELEE = 50, BULLET = 60, LASER = 60, ENERGY = 55, BOMB = 45, BIO = 50, FIRE = 35, ACID = 55)
	minimap_icon = "cerebral"

	var/aura_plasma_drain = 8
	var/aura_slowdown = 0.2

	actions = list(
		/datum/action/ability/xeno_action/xeno_resting,
		/datum/action/ability/xeno_action/watch_xeno,
		/datum/action/ability/activable/xeno/psydrain,
		/datum/action/ability/xeno_action/reinforce,
		/datum/action/ability/activable/xeno/mind_crush,
		/datum/action/ability/xeno_action/cerebral_collapse,
	)

/datum/xeno_caste/cerebral/normal
	upgrade = XENO_UPGRADE_NORMAL

/datum/xeno_caste/cerebral/primordial
	upgrade_name = "Feast"
	caste_desc = "The hive's undying nexus. Its hunger for minds is bottomless."
	primordial_message = "We shall taste their thoughts."
	upgrade = XENO_UPGRADE_PRIMO
	aura_plasma_drain = 6

	actions = list(
		/datum/action/ability/xeno_action/xeno_resting,
		/datum/action/ability/xeno_action/watch_xeno,
		/datum/action/ability/activable/xeno/psydrain,
		/datum/action/ability/xeno_action/reinforce,
		/datum/action/ability/activable/xeno/mind_crush,
		/datum/action/ability/xeno_action/cerebral_collapse,
		/datum/action/ability/activable/xeno/cerebral_feast,
	)
