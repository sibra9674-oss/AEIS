// Glue between the Beestation/NSV pipe machinery and TGMC (which has none of tg's investigate/radio/gas bookkeeping).


GLOBAL_LIST_EMPTY(ventcrawl_machinery)

// Native (auxtools/auxmos) hooks the real auxgm/gas code calls; the DM side keeps its own tables so these have nothing to register.
/proc/_auxtools_register_gas(datum/gas/gas)
	return
/datum/auxgm/proc/finalize_gas_refs()
	return
/datum/controller/subsystem/air/proc/auxtools_update_reactions()
	return

/// tg/Beestation investigate log; TGMC has none.
/atom/proc/investigate_log(message, subject)
	return

/datum/proc/ui_update()
	SStgui.update_uis(src)

/// Moves a ratio of every gas from this mix into other (auxmos native in NSV).
/datum/gas_mixture/proc/transfer_ratio_to(datum/gas_mixture/other, ratio)
	if(!other || ratio <= 0)
		return FALSE
	other.merge(remove_ratio(ratio))
	return TRUE

/// Moves ratio of just the listed gases into other (used by scrubbers/filters).
/datum/gas_mixture/proc/scrub_into(datum/gas_mixture/into, ratio, list/gas_list)
	if(!into || ratio <= 0 || !length(gas_list))
		return FALSE
	var/datum/gas_mixture/taken = new type(volume)
	taken.temperature = temperature
	for(var/id in gas_list)
		var/moles = get_moles(id) * min(ratio, 1)
		if(moles <= 0)
			continue
		taken.set_moles(id, moles)
		set_moles(id, get_moles(id) - moles)
	into.merge(taken)
	return TRUE

/area/var/list/air_vent_names = list()
/area/var/list/air_scrub_names = list()
/area/var/list/air_vent_info = list()
/area/var/list/air_scrub_info = list()
/obj/item/tank/var/datum/gas_mixture/air_contents
/mob/living/var/last_played_vent
/obj/machinery/advanced_airlock_controller


// --- gas mixture extras ---
/datum/gas_mixture/proc/multiply(factor)
	for(var/id in gases.Copy())
		set_moles(id, gases[id] * factor)

/// Conduction between two mixtures: temperatures move towards each other proportionally to coefficient and heat capacities.
/datum/gas_mixture/proc/temperature_share(datum/gas_mixture/sharer, conduction_coefficient, sharer_temperature, sharer_heat_capacity)
	var/self_capacity = heat_capacity()
	var/other_temperature = sharer ? sharer.temperature : sharer_temperature
	var/other_capacity = sharer ? sharer.heat_capacity() : sharer_heat_capacity
	if(self_capacity <= NSV_MINIMUM_HEAT_CAPACITY || other_capacity <= NSV_MINIMUM_HEAT_CAPACITY)
		return other_temperature
	var/delta = other_temperature - temperature
	var/heat = conduction_coefficient * delta * (self_capacity * other_capacity / (self_capacity + other_capacity))
	temperature += heat / self_capacity
	if(sharer)
		sharer.temperature -= heat / other_capacity
	return temperature

/// Makes every mixture in the list the same pressure and temperature, conserving moles and energy (auxmos native in NSV).
/datum/proc/equalize_all_gases_in_list(list/datum/gas_mixture/gas_mixes)
	var/total_volume = 0
	var/datum/gas_mixture/pool = new /datum/gas_mixture(0)
	for(var/datum/gas_mixture/G as anything in gas_mixes)
		if(!G)
			continue
		total_volume += G.volume
		pool.merge(G)
	if(total_volume <= 0)
		return
	for(var/datum/gas_mixture/G as anything in gas_mixes)
		if(!G)
			continue
		var/fraction = G.volume / total_volume
		G.gases = list()
		for(var/id in pool.gases)
			G.set_moles(id, pool.gases[id] * fraction)
		G.temperature = pool.temperature

// --- tg atom-level air API (base definitions; turfs get the real ones from LINDA_turf_tile.dm) ---
/atom/proc/assume_air_moles(datum/gas_mixture/giver, moles)
	return FALSE
/atom/proc/assume_air_ratio(datum/gas_mixture/giver, ratio)
	return FALSE
/atom/proc/transfer_air(datum/gas_mixture/taker, moles)
	return FALSE
/turf/var/blocks_air = FALSE
/turf/proc/GetTemperature()
	return T20C
/turf/proc/GetHeatCapacity()
	return heat_capacity
/turf/proc/TakeTemperature(temp)
	return

// --- misc tg APIs the machinery touches ---
/atom/proc/singularity_pull(obj/anomaly/singularity/singularity, current_size)
	return
/atom/proc/transfer_fingerprints_to(atom/A)
	return
/atom/proc/has_buckled_mobs()
	return FALSE
/atom/movable/proc/dropContents()
	for(var/atom/movable/AM in src)
		AM.forceMove(drop_location())
/obj/proc/run_obj_armor(damage_amount, damage_type, damage_flag = 0, attack_dir, armour_penetration = 0)
	return damage_amount
/obj/machinery/proc/set_machine_stat(new_stat)
	machine_stat = new_stat
/obj/proc/set_greyscale(colors, config)
	return

// --- canister sprites ---
// NSV builds canister icons at runtime with its greyscale system (layer states tinted by colours). TGMC has no greyscale system, so the same layers
// from NSV's own canisters.dmi / prototype_canister.dmi are composed here with the same recipes as NSV's json configs (code/datums/greyscale/json_configs/canister_*.json).
GLOBAL_LIST_EMPTY(nsv_canister_icons)

/proc/nsv_split_colors(colors)
	var/list/out = list()
	var/pos = 1
	while(pos + 6 <= length(colors))
		out += copytext(colors, pos, pos + 7)
		pos += 7
	return out

/// One tinted greyscale layer.
/proc/nsv_tinted_layer(file, state, color)
	var/icon/layer = icon(file, state)
	if(color)
		layer.Blend(color, ICON_MULTIPLY)
	return layer

/proc/nsv_build_canister_icon(colors, config)
	var/list/c = nsv_split_colors(colors)
	var/icon/res
	if(config == /datum/greyscale_config/prototype_canister)
		var/file = 'nsv13/icons/obj/atmospherics/prototype_canister.dmi'
		res = nsv_tinted_layer(file, "can_base", c[1])
		res.Blend(icon(file, "can_shader"), ICON_MULTIPLY)
		res.Blend(icon(file, "stand"), ICON_OVERLAY)
		res.Blend(icon(file, "decals"), ICON_OVERLAY)
		var/icon/light = nsv_tinted_layer(file, "light_base", c[2])
		light.Blend(nsv_tinted_layer(file, "light", c[3]), ICON_OVERLAY)
		res.Blend(light, ICON_OVERLAY)
		return res
	var/file = 'nsv13/icons/obj/atmospherics/canisters.dmi'
	// base style: tinted base, add_shader (add), multi_shader (multiply)
	res = nsv_tinted_layer(file, "base", c[1])
	res.Blend(icon(file, "add_shader"), ICON_ADD)
	res.Blend(icon(file, "multi_shader"), ICON_MULTIPLY)
	if(config == /datum/greyscale_config/canister/stripe)
		res.Blend(nsv_tinted_layer(file, "stripe", c[2]), ICON_OVERLAY)
	else if(config == /datum/greyscale_config/canister/double_stripe)
		var/icon/stripes = nsv_tinted_layer(file, "double_stripe", c[2])
		stripes.Blend(icon(file, "double_stripe_shader"), ICON_SUBTRACT)
		res.Blend(stripes, ICON_OVERLAY)
	else if(config == /datum/greyscale_config/canister/hazard)
		res.Blend(nsv_tinted_layer(file, "hazard_stripes", c[2]), ICON_OVERLAY)
	// post effects
	res.Blend(nsv_tinted_layer(file, "outline", c[1]), ICON_OVERLAY)
	res.Blend(icon(file, "lights"), ICON_OVERLAY)
	return res

/obj/machinery/portable_atmospherics/canister/set_greyscale(colors, config)
	if(!colors || !config)
		return
	var/key = "[config]|[colors]"
	var/icon/built = GLOB.nsv_canister_icons[key]
	if(!built)
		built = nsv_build_canister_icon(colors, config)
		GLOB.nsv_canister_icons[key] = built
	greyscale_colors = colors
	greyscale_config = config
	icon = built
	icon_state = ""
/client/proc/modify_canister_gas(obj/machinery/portable_atmospherics/canister/C)
	return
/mob/proc/canUseTopic(atom/movable/target, be_close = FALSE, no_dexterity = FALSE, no_tk = FALSE, need_hands = FALSE, floor_okay = FALSE)
	if(incapacitated())
		return FALSE
	if(be_close && target && !in_range(target, src))
		return FALSE
	return TRUE
/proc/heat2colour_r(temp)
	return clamp(round(255 * (temp / 400)), 0, 255)
/proc/heat2colour_g(temp)
	return clamp(round(255 * (1 - abs(temp - 293) / 300)), 0, 255)
/proc/heat2colour_b(temp)
	return clamp(round(255 * (1 - temp / 400)), 0, 255)

/// Radio-network naming used when a vent has no id_tag; NSV's SSnetworks does the same with random names.
/datum/ss_networks_stub/proc/assign_random_name(len = 5)
	var/name = ""
	for(var/i in 1 to len)
		name += pick("A","B","C","D","E","F","G","H","J","K","L","M","N","P","R","S","T","U","V","W","X","Y","Z","2","3","4","5","6","7","8","9")
	return name
GLOBAL_DATUM_INIT(ss_networks_stub, /datum/ss_networks_stub, new)

// --- vars used by machinery / TGMC callers ---
/obj/machinery/atmospherics/var/id_tag
/obj/machinery/atmospherics/var/list/armor
/obj/machinery/atmospherics/var/covered_by_shuttle = FALSE
/obj/machinery/meter/var/id_tag
/obj/machinery/atmospherics/pipe/var/can_buckle = FALSE
/obj/machinery/atmospherics/pipe/var/buckle_requires_restraints = FALSE
/obj/machinery/var/interaction_flags_machine = 0
/obj/machinery/var/critical_machine = FALSE
/obj/machinery/atmospherics/var/vent_movement = 0
/datum/pipeline/var/list/other_atmosmch = list()
/mob/living/var/ventcrawler = 0
/obj/machinery/power/generator/var/obj/machinery/atmospherics/components/binary/circulator/cold_circ
/obj/machinery/power/generator/var/obj/machinery/atmospherics/components/binary/circulator/hot_circ
/obj/machinery/advanced_airlock_controller/var/list/vents = list()

/obj/machinery/atmospherics/proc/build_network()
	SSair.add_to_rebuild_queue(src)
/obj/machinery/atmospherics/proc/addMember(obj/machinery/atmospherics/A)
	return
/obj/machinery/atmospherics/components/unary/cryo_cell

/obj/item/clothing/shoes/magboots/proc/negates_gravity()
	return TRUE

// --- FTL support ---
GLOBAL_VAR_INIT(crew_transfer_risa, FALSE)
GLOBAL_VAR_INIT(meteors_threatening, FALSE)
GLOBAL_LIST_EMPTY(inertia_dampeners)
/obj/machinery/inertial_dampener
/mob/living/simple_animal/hostile/swarmer
/obj/effect/anomaly
/obj/effect/anomaly/stormdrive
/obj/effect/anomaly/stormdrive/sheer
/obj/effect/anomaly/bluespace
/datum/map_template/asteroid
/obj/effect/cross_action/spacetime_dist
/datum/var/list/active_timers
/obj/machinery/var/list/req_one_access_txt
/datum/space_level/proc/set_parallax(new_parallax)
	return
/obj/structure/overmap/proc/station_time_timestamp(format = "hh:mm:ss")
	return time2text(world.time, format)
/proc/index2greek(index)
	var/static/list/greek = list("Alpha", "Beta", "Gamma", "Delta", "Epsilon", "Zeta", "Eta", "Theta", "Iota", "Kappa", "Lambda", "Mu", "Nu", "Xi", "Omicron", "Pi", "Rho", "Sigma", "Tau", "Upsilon", "Phi", "Chi", "Psi", "Omega")
	return greek[clamp(index, 1, length(greek))]
/proc/display_power(powerused)
	if(powerused < 1000)
		return "[round(powerused, 1)] W"
	if(powerused < 1000000)
		return "[round(powerused * 0.001, 0.01)] kW"
	if(powerused < 1000000000)
		return "[round(powerused * 0.000001, 0.001)] MW"
	return "[round(powerused * 0.000000001, 0.0001)] GW"

/// NSV's "advanced" looping sound (channel control, interrupt) rebuilt on top of TGMC's /datum/looping_sound.
/datum/looping_sound/advanced
	var/channel
	var/can_process = FALSE
	var/atom/parent

/datum/looping_sound/advanced/New(_parent, start_immediately = FALSE, _direct = FALSE, _channel, _process = FALSE)
	channel = _channel
	sound_channel = _channel
	can_process = _process
	parent = _parent
	return ..(list(_parent), start_immediately, _direct)

/datum/looping_sound/advanced/proc/interrupt(atom/remove_source)
	stop(remove_source)

/datum/looping_sound/advanced/proc/recalculate_volume(deviation_tolerance = 0, force = FALSE)
	return

/obj/machinery/inertial_dampener/var/on = FALSE
/obj/machinery/inertial_dampener/proc/reduceNausea(amount)
	return
/obj/effect/cross_action/spacetime_dist/var/linked_dist
/turf/proc/photograph(cap)
	return null

/proc/nsv_assign_random_name(len = 5)
	var/name = ""
	for(var/i in 1 to len)
		name += pick("A","B","C","D","E","F","G","H","J","K","L","M","N","P","R","S","T","U","V","W","X","Y","Z","2","3","4","5","6","7","8","9")
	return name

// --- things NSV's LINDA / reactions expect from the rest of tg that TGMC does not have ---
GLOBAL_LIST_INIT(cardinals_multiz, list(NORTH, SOUTH, EAST, WEST, UP, DOWN))
GLOBAL_LIST_INIT(diagonals_multiz, list(NORTHEAST, NORTHWEST, SOUTHEAST, SOUTHWEST, NORTH|UP, SOUTH|UP, EAST|UP, WEST|UP, NORTH|DOWN, SOUTH|DOWN, EAST|DOWN, WEST|DOWN))

// Radiation pulses are now NSV's real ones (modules/radiation); only the nuclear-particle projectile is missing in TGMC (known gap).
/turf/proc/fire_nuclear_particle(angle, customize = FALSE, custompower)
	return
// tg: water vapor wets floors / freon freezes them. TGMC has no wet/ice floor state yet (known gap).
/turf/open/proc/freon_gas_act()
	return FALSE
/turf/open/proc/water_vapor_gas_act()
	return FALSE

// Doors and windows decide whether gas passes (tg: ATMOS_PASS_DENSITY / ATMOS_PASS_PROC)
/obj/machinery/door/CanAtmosPass = ATMOS_PASS_DENSITY
/obj/structure/window/CanAtmosPass = ATMOS_PASS_DENSITY
/// tg firedoor reaction to a pressure spike: shut. TGMC's firedoor already has close(); only the trigger comes from LINDA.
/obj/machinery/door/firedoor/proc/emergency_pressure_stop(consider_timer = TRUE)
	if(density || operating || (machine_stat & (BROKEN|NOPOWER)))
		return
	INVOKE_ASYNC(src, PROC_REF(close))

// TGMC's /obj/machinery/attack_hand only opens a tgui when interaction_flags has INTERACT_UI_INTERACT (NSV/tg use a different flag set).
/obj/machinery/atmospherics
	interaction_flags = INTERACT_MACHINE_TGUI

/obj/machinery/portable_atmospherics
	interaction_flags = INTERACT_MACHINE_TGUI

// --- hand gas analyzer (NSV atmosanalyzer_scan, ported onto TGMC's /obj/item/tool/analyzer) ---
// Click an adjacent pipe, canister, vent, machine or floor tile with it to read its gas mix. Clicking yourself reads the tile you stand on.
/obj/item/tool/analyzer/afterattack(atom/target, mob/user, has_proximity, click_parameters)
	. = ..()
	if(!has_proximity || !user)
		return
	if(target == user)
		target = get_turf(user)
	if(nsv_atmosanalyzer_scan(user, target))
		return TRUE

/proc/nsv_atmosanalyzer_scan(mob/user, atom/target, silent = FALSE)
	if(!target)
		return FALSE
	var/mixture = target.return_analyzable_air()
	if(!mixture)
		return FALSE
	var/list/message = list()
	if(!silent)
		user.visible_message(span_notice("[user] uses the analyzer on [target]."), span_notice("You use the analyzer on [target]."))
	message += span_boldnotice("Results of analysis of [target].")
	var/list/airs = islist(mixture) ? mixture : list(mixture)
	for(var/g in airs)
		if(length(airs) > 1)
			message += span_boldnotice("Node [airs.Find(g)]")
		var/datum/gas_mixture/air_contents = g
		var/total_moles = air_contents.total_moles()
		if(total_moles > 0)
			message += span_notice("Moles: [round(total_moles, 0.01)] mol")
			message += span_notice("Volume: [air_contents.return_volume()] L")
			message += span_notice("Pressure: [round(air_contents.return_pressure(), 0.01)] kPa")
			for(var/id in air_contents.get_gases())
				var/moles = air_contents.get_moles(id)
				message += span_notice("[GLOB.gas_data.names[id] || id]: [round(moles / total_moles * 100, 0.01)] % ([round(moles, 0.01)] mol)")
			message += span_notice("Temperature: [round(air_contents.return_temperature() - T0C, 0.01)] &deg;C ([round(air_contents.return_temperature(), 0.01)] K)")
		else
			message += span_notice(length(airs) > 1 ? "This node is empty!" : "[target] is empty!")
		var/list/cached = air_contents.analyzer_results
		if(cached && cached["fusion"])
			message += span_boldnotice("Large amounts of free neutrons detected in the air indicate that a fusion reaction took place.")
			message += span_notice("Instability of the last fusion reaction: [round(cached["fusion"], 0.01)].")
	to_chat(user, jointext(message, "<br>"))
	return TRUE

/// An open welder flame ignites gas on its turf (tg: weldingtool open_flame -> hotspot_expose(700, 50, 1)).
/obj/item/tool/weldingtool/proc/nsv_weld_flame(atom/at)
	var/turf/T = get_turf(at || src)
	T?.hotspot_expose(700, 50, 1)
