#ifndef NSV_ATLAS_SKIN_LOADED
#define NSV_ATLAS_SKIN_LOADED
// Generated: NSV-looking deck for the Atlas map. Own type paths (/turf/open/floor/nsv/...), TGMC floors are untouched.
/turf/open/floor/nsv
	vis_flags = VIS_INHERIT_PLANE
	icon = 'nsv13/icons/turf/bee_floors.dmi'
	icon_state = "plating"
	breakable_tile = TRUE

/// Decks are not dug up to bare plating, a destroyed floor is a hole (see nsv_blow_hole)
/turf/open/floor/nsv/nsv_tile_blast()
	if(istype(src, /turf/open/floor/nsv/plating))
		return FALSE
	make_plating()
	return TRUE

/turf/open/floor/nsv/make_plating()
	if(istype(src, /turf/open/floor/nsv/plating))
		return src
	var/airless = (initial_gas_mix == AIRLESS_ATMOS)
	// area-colour decals belong to the tile, not to the plating beneath it
	for(var/obj/effect/turf_decal/nsv/D in src)
		qdel(D)
	var/turf/open/floor/nsv/plating/P = ChangeTurf(airless ? /turf/open/floor/nsv/plating/airless : /turf/open/floor/nsv/plating)
	if(istype(P))
		// plating is not "intact": hidden pipes and machinery underneath become visible
		for(var/obj/machinery/atmospherics/A in P)
			A.hide(FALSE)
			A.update_icon()
	return P

/// Prying the plating off a "Breakable Floors" deck opens a hole: open space if there is a deck below, outer space otherwise.
/turf/open/floor/nsv/plating/crowbar_act(mob/living/user, obj/item/I)
	if(!SSmapping.level_trait(z, "Breakable Floors"))
		return FALSE
	user.visible_message(span_notice("[user] starts prying up the deck plating."), span_notice("You start prying up the deck plating..."))
	I.play_tool_sound(src, 80)
	if(!do_after(user, 4 SECONDS, NONE, src, BUSY_ICON_BUILD))
		return TRUE
	if(!istype(src, /turf/open/floor/nsv/plating))
		return TRUE
	var/turf/below = GET_TURF_BELOW(src)
	user.visible_message(span_warning("[user] rips up the deck plating, opening a hole!"), span_notice("You rip up the deck plating."))
	new /obj/item/stack/sheet/metal(src, 1)
	ChangeTurf(below ? /turf/open/openspace : /turf/open/space)
	return TRUE

/turf/open/floor/nsv/monotile_steel
	icon_state = "steel_monotile"
/turf/open/floor/nsv/monotile_steel/airless
	initial_gas_mix = AIRLESS_ATMOS

/turf/open/floor/nsv/monotile_dark
	icon_state = "monotile_dark"
/turf/open/floor/nsv/monotile_dark/airless
	initial_gas_mix = AIRLESS_ATMOS

/turf/open/floor/nsv/monotile_light
	icon_state = "monotile_light"
/turf/open/floor/nsv/monotile_light/airless
	initial_gas_mix = AIRLESS_ATMOS

/turf/open/floor/nsv/steel
	icon = 'nsv13/icons/turf/floors.dmi'
	icon_state = "steel"
/turf/open/floor/nsv/steel/broken_states()
	return pick("steel_dam1", "steel_dam2", "steel_dam3", "steel_dam4", "steel_dam5")
/turf/open/floor/nsv/steel/burnt_states()
	return pick("steel_scorched1", "steel_scorched2", "steel_scorched3", "steel_scorched4")
/turf/open/floor/nsv/steel/airless
	initial_gas_mix = AIRLESS_ATMOS

/turf/open/floor/nsv/lino
	icon = 'nsv13/icons/turf/floors.dmi'
	icon_state = "lino"
/turf/open/floor/nsv/lino/broken_states()
	return pick("lino_dam1", "lino_dam2")
/turf/open/floor/nsv/lino/burnt_states()
	return pick("lino_scorched1")
/turf/open/floor/nsv/lino/airless
	initial_gas_mix = AIRLESS_ATMOS

/turf/open/floor/nsv/techfloor
	icon = 'nsv13/icons/turf/floors.dmi'
	icon_state = "techfloor"
/turf/open/floor/nsv/techfloor/broken_states()
	return pick("techfloor_dam1", "techfloor_dam2")
/turf/open/floor/nsv/techfloor/burnt_states()
	return pick("techfloor_scorched1", "techfloor_scorched2")
/turf/open/floor/nsv/techfloor/airless
	initial_gas_mix = AIRLESS_ATMOS

/turf/open/floor/nsv/techfloor_grid
	icon = 'nsv13/icons/turf/floors.dmi'
	icon_state = "techfloor_grid"
/turf/open/floor/nsv/techfloor_grid/broken_states()
	return pick("techfloor_grid_dam1")
/turf/open/floor/nsv/techfloor_grid/burnt_states()
	return pick("techfloor_grid_scorched1", "techfloor_grid_scorched2")
/turf/open/floor/nsv/techfloor_grid/airless
	initial_gas_mix = AIRLESS_ATMOS

/turf/open/floor/nsv/riveted
	icon = 'nsv13/icons/turf/floors.dmi'
	icon_state = "riveted"
/turf/open/floor/nsv/riveted/broken_states()
	return pick("riveted_dam1", "riveted_dam2", "riveted_dam3", "riveted_dam4", "riveted_dam5")
/turf/open/floor/nsv/riveted/burnt_states()
	return pick("riveted_scorched1", "riveted_scorched2", "riveted_scorched3")
/turf/open/floor/nsv/riveted/airless
	initial_gas_mix = AIRLESS_ATMOS

/turf/open/floor/nsv/durasteel
	icon = 'nsv13/icons/turf/floors.dmi'
	icon_state = "durasteel"
/turf/open/floor/nsv/durasteel/broken_states()
	return pick("durasteel_dam1", "durasteel_dam2", "durasteel_dam3", "durasteel_dam4", "durasteel_dam5")
/turf/open/floor/nsv/durasteel/burnt_states()
	return pick("floorscorched1", "floorscorched2", "floorscorched3", "floorscorched4")
/turf/open/floor/nsv/durasteel/airless
	initial_gas_mix = AIRLESS_ATMOS

/turf/open/floor/nsv/techmaint
	icon_state = "techmaint"
/turf/open/floor/nsv/techmaint/airless
	initial_gas_mix = AIRLESS_ATMOS

/turf/open/floor/nsv/plating
	icon_state = "plating"
	floor_tile = null
	intact_tile = FALSE
/turf/open/floor/nsv/plating/airless
	initial_gas_mix = AIRLESS_ATMOS

/turf/open/floor/nsv/engine
	icon_state = "engine"
/turf/open/floor/nsv/engine/airless
	initial_gas_mix = AIRLESS_ATMOS

/turf/open/floor/nsv/wood
	icon_state = "wood"
/turf/open/floor/nsv/wood/airless
	initial_gas_mix = AIRLESS_ATMOS

/turf/open/floor/nsv/solarpanel
	icon_state = "solarpanel"
/turf/open/floor/nsv/solarpanel/airless
	initial_gas_mix = AIRLESS_ATMOS

/turf/open/floor/nsv/freezer
	icon_state = "freezerfloor"
/turf/open/floor/nsv/freezer/airless
	initial_gas_mix = AIRLESS_ATMOS

/turf/open/floor/nsv/showroom
	icon_state = "showroomfloor"
/turf/open/floor/nsv/showroom/airless
	initial_gas_mix = AIRLESS_ATMOS

/turf/open/floor/nsv/steel_grid
	icon_state = "steel_grid"
/turf/open/floor/nsv/steel_grid/airless
	initial_gas_mix = AIRLESS_ATMOS

/turf/open/floor/nsv/steel_ridged
	icon_state = "steel_ridged"
/turf/open/floor/nsv/steel_ridged/airless
	initial_gas_mix = AIRLESS_ATMOS

/turf/open/floor/nsv/circuit
	icon_state = "bcircuit"
/turf/open/floor/nsv/circuit/airless
	initial_gas_mix = AIRLESS_ATMOS

/turf/open/floor/nsv/circuit_green
	icon_state = "gcircuit"
/turf/open/floor/nsv/circuit_green/airless
	initial_gas_mix = AIRLESS_ATMOS

/turf/open/floor/nsv/stairs
	icon_state = "stairs"
/turf/open/floor/nsv/stairs/airless
	initial_gas_mix = AIRLESS_ATMOS


// ---------------------------------------------------------------- walls (NSV legacy smoothing, Baystation style)
/turf/closed/wall/nsv
	vis_flags = VIS_INHERIT_PLANE
	name = "wall"
	icon = 'nsv13/icons/turf/wall_masks.dmi'
	icon_state = "solid"
	base_icon_state = "solid"
	color = "#787878"
	smoothing_flags = NONE
	smoothing_groups = null
	canSmoothWith = null
	var/list/wall_connections = list("0", "0", "0", "0")
	var/list/other_connections = list("0", "0", "0", "0")
	/// Overlay drawn over the wall (multiplied), e.g. the reinforcement pattern
	var/texture_state = null

/turf/closed/wall/nsv/steel

/turf/closed/wall/nsv/reinforced
	name = "reinforced wall"
	desc = "A huge chunk of reinforced metal used to separate rooms."
	texture_state = "reinf_over"
	max_integrity = 3000
	max_temperature = 6000
	explosion_block = 4

/turf/closed/wall/nsv/Initialize(mapload, ...)
	. = ..()
	nsv_update_connections()
	update_icon()

/turf/closed/wall/nsv/proc/nsv_join_type(atom/W)
	if(ismob(W) || istype(W, /obj/machinery/door/window))
		return 0
	if(istype(W, /turf/closed/wall/nsv))
		return 1 //joins fully
	if(istype(W, /obj/machinery/door) || istype(W, /obj/structure/window) || istype(W, /obj/structure/window_frame) || istype(W, /obj/structure/girder))
		return 2 //joins with a connector sprite
	return 0

/turf/closed/wall/nsv/proc/nsv_update_connections()
	var/list/wall_dirs = list()
	var/list/other_dirs = list()
	for(var/atom/W in orange(src, 1))
		switch(nsv_join_type(W))
			if(1)
				wall_dirs += get_dir(src, W)
			if(2)
				wall_dirs += get_dir(src, W)
				other_dirs += get_dir(src, W)
	wall_connections = nsv_dirs_to_corner_states(wall_dirs)
	other_connections = nsv_dirs_to_corner_states(other_dirs)

/// Re-evaluates this wall and its wall neighbours (call after something next to them changed).
/turf/closed/wall/nsv/proc/nsv_refresh_neighbours()
	for(var/turf/closed/wall/nsv/W in orange(src, 1))
		W.nsv_update_connections()
		W.update_icon()

/turf/closed/wall/nsv/ChangeTurf(path, list/new_baseturfs, flags)
	var/list/neighbours = list()
	for(var/turf/closed/wall/nsv/W in orange(src, 1))
		neighbours += W
	. = ..()
	for(var/turf/closed/wall/nsv/W as anything in neighbours)
		if(!QDELETED(W))
			W.nsv_update_connections()
			W.update_icon()

/turf/closed/wall/nsv/update_overlays()
	. = ..()
	for(var/i in 1 to 4)
		. += image(icon, "[base_icon_state][wall_connections[i]]", dir = 1 << (i - 1))
		if(other_connections[i] != "0")
			. += image(icon, "[base_icon_state]_other[wall_connections[i]]", dir = 1 << (i - 1))
	if(texture_state)
		. += image(icon, texture_state)

/// Baystation's corner encoding: 4 corner states from the directions a thing connects in.
/proc/nsv_dirs_to_corner_states(list/dirs)
	var/list/ret = list(NORTHWEST, SOUTHEAST, NORTHEAST, SOUTHWEST)
	for(var/i in 1 to length(ret))
		var/dir = ret[i]
		var/state = 0
		if(dir in dirs)
			state |= 2 //diagonal
		if(turn(dir, 45) in dirs)
			state |= 1 //counterclockwise
		if(turn(dir, -45) in dirs)
			state |= 4 //clockwise
		ret[i] = "[state]"
	return ret

// ---------------------------------------------------------------- turf decals (NSV tile colouring, stripes, markings)
/// One decal type for every NSV/Bee decal used on Atlas: the map sets sheet/icon_state/color/alpha. (TGMC's own decal types are untouched.)
/obj/effect/turf_decal/nsv
	name = "decal"
	icon = 'nsv13/icons/turf/decals.dmi'
	icon_state = "bordercorner"
	/// 1 = NSV's decals.dmi, 2 = Bee's decals.dmi
	var/sheet = 1

/obj/effect/turf_decal/nsv/Initialize(mapload)
	. = ..()
	if(sheet == 2)
		icon = 'nsv13/icons/turf/bee_decals.dmi'


// ---- stage 2: NSV doors (same icon state names as the TGMC firedoor, so only the icon is swapped) ----
/obj/machinery/door/firedoor/border_only/nsv
	icon = 'nsv13/icons/obj/doors/edge_Doorfire.dmi'

#endif
