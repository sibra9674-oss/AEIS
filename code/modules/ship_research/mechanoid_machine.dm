/**
 * Ship Researcher: base type of the big mechanoid machines (encoder and gestator).
 * They are fixed to the floor, can't be destroyed and cover several tiles. The sprite starts at the bottom left tile.
 */
/obj/machinery/mechanoid_machine
	density = TRUE
	anchored = TRUE
	use_power = NO_POWER_USE
	resistance_flags = RESIST_ALL
	interaction_flags = INTERACT_MACHINE_TGUI
	req_access = list(ACCESS_MARINE_RESEARCH)
	///Width in tiles
	var/width_tiles = 1
	///Height in tiles
	var/height_tiles = 1

/obj/machinery/mechanoid_machine/Initialize(mapload)
	. = ..()
	bound_width = width_tiles * world.icon_size
	bound_height = height_tiles * world.icon_size

///All the turfs the machine stands on
/obj/machinery/mechanoid_machine/proc/get_covered_turfs()
	var/turf/start = get_turf(src)
	var/turf/finish = locate(start.x + width_tiles - 1, start.y + height_tiles - 1, start.z)
	return block(start, finish)

///Whether the target is on the machine or next to it
/obj/machinery/mechanoid_machine/proc/is_near(atom/target)
	for(var/turf/covered AS in get_covered_turfs())
		if(get_dist(covered, target) <= 1)
			return TRUE
	return FALSE

///A free turf next to the machine, or the turf of the machine if there is none
/obj/machinery/mechanoid_machine/proc/get_exit_turf()
	var/list/covered = get_covered_turfs()
	for(var/turf/candidate AS in orange(max(width_tiles, height_tiles) + 1, src))
		if(candidate.density || (candidate in covered) || !is_near(candidate))
			continue
		return candidate
	return get_turf(src)
