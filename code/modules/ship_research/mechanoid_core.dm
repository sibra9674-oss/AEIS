/**
 * Ship Researcher: mechanoid cores.
 * A subcore (basic, standard or high) is made from the brain of a dead xenomorph in the subnuclear encoder, and is later grown into a mechanoid in the gestator.
 */

///Bandwidth cost of a mechanoid by the tier of the xeno it was made from. Tiers that are not listed here can't be made into cores.
GLOBAL_LIST_INIT(mechanoid_bandwidth_by_tier, list(
	XENO_TIER_ONE = 1,
	XENO_TIER_TWO = 2,
	XENO_TIER_THREE = 3,
))

///Every living mechanoid and every gestator that is currently growing one, with the bandwidth it takes up. Use get_mechanoid_bandwidth_used() to read it.
GLOBAL_LIST_EMPTY(active_mechanoids)

///Returns the bandwidth currently used by living mechanoids and by mechanoids that are being gestated. Also cleans up dead entries.
/proc/get_mechanoid_bandwidth_used()
	. = 0
	for(var/atom/entry AS in GLOB.active_mechanoids.Copy())
		if(QDELETED(entry))
			GLOB.active_mechanoids -= entry
			continue
		if(isliving(entry))
			var/mob/living/living_entry = entry
			if(living_entry.stat == DEAD)
				GLOB.active_mechanoids -= entry
				continue
		. += GLOB.active_mechanoids[entry]

///Returns the subcore tier name for a bandwidth cost
/proc/get_subcore_tier_name(bandwidth_cost)
	switch(bandwidth_cost)
		if(1)
			return "basic"
		if(2)
			return "standard"
		if(3)
			return "high"
	return "unknown"

///Mechanoid variants that can be grown from a core of each bandwidth cost. The first one is the default.
GLOBAL_LIST_INIT(mechanoid_variants, list(
	"1" = list(/mob/living/simple_animal/hostile/mechanoid/scrapper, /mob/living/simple_animal/hostile/mechanoid/scorcher, /mob/living/simple_animal/hostile/mechanoid/hauler),
	"2" = list(/mob/living/simple_animal/hostile/mechanoid/gunner, /mob/living/simple_animal/hostile/mechanoid/striker, /mob/living/simple_animal/hostile/mechanoid/medic),
	"3" = list(/mob/living/simple_animal/hostile/mechanoid/bulwark, /mob/living/simple_animal/hostile/mechanoid/lancer, /mob/living/simple_animal/hostile/mechanoid/incinerator, /mob/living/simple_animal/hostile/mechanoid/minigun, /mob/living/simple_animal/hostile/mechanoid/diabolus),
))

///Returns the list of mechanoid types that a core with this bandwidth cost can grow
/proc/get_mechanoid_variants(bandwidth_cost)
	return GLOB.mechanoid_variants["[bandwidth_cost]"] || list()

///Returns the mechanoid mob type that is grown from a core with this bandwidth cost, variant is the index in the list
/proc/get_mechanoid_type(bandwidth_cost, variant = 1)
	var/list/variants = get_mechanoid_variants(bandwidth_cost)
	if(!length(variants))
		return null
	return variants[clamp(variant, 1, length(variants))]

/obj/item/mechanoid_core
	name = "subcore"
	desc = "A xenomorph brain wired into a lattice of conductive filaments. It can be grown into a mechanoid in a gestator."
	icon = 'icons/obj/items/mechanoid_core.dmi'
	icon_state = "basic"
	w_class = WEIGHT_CLASS_SMALL
	///Name of the caste this core came from
	var/caste_name = "unknown"
	///How much mechanoid bandwidth the grown mechanoid will take. Decides which mechanoid is grown.
	var/bandwidth_cost = 1

/obj/item/mechanoid_core/examine(mob/user)
	. = ..()
	. += span_notice("Source: [caste_name]. Bandwidth: [bandwidth_cost].")

///Returns the name of the subcore tier: basic, standard or high
/obj/item/mechanoid_core/proc/get_tier_name()
	return get_subcore_tier_name(bandwidth_cost)

///Fills the core with the data of the xeno it was made from
/obj/item/mechanoid_core/proc/setup_from_xeno(mob/living/carbon/xenomorph/source_xeno, new_cost)
	bandwidth_cost = new_cost
	caste_name = source_xeno.xeno_caste.caste_name
	name = "[get_tier_name()] subcore"
	icon_state = get_tier_name()
