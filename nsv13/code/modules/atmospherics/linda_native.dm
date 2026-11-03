// DM replacement for what NSV's auxmos (Rust, native) does behind the real LINDA_*.dm files:
//  - gas_mixture.share / react / copy_from_turf / parse_gas_string
//  - active turf processing (classic LINDA sharing, no excited groups, no Monstermos equalisation)
//  - space = immutable vacuum mixture
// The reactions (reactions.dm), gas data (auxgm), hotspots and turf procs are NSV's own code.

/datum/gas_mixture/turf
	/// the turf this air belongs to: anything that adds/removes gas from outside (canisters, vents, spills) wakes the turf so LINDA starts spreading it
	var/turf/open/holder
	/// set while a mob breathes so a lungful doesn't wake the tile every tick
	var/quiet = FALSE

/datum/gas_mixture/turf/New(volume, turf/holder)
	..(volume)
	src.holder = holder

/datum/gas_mixture/turf/proc/wake_holder()
	if(holder && !quiet && !holder.excited && SSair.initialized)
		SSair.add_to_active(holder)

/datum/gas_mixture/turf/merge(datum/gas_mixture/giver)
	. = ..()
	wake_holder()

/datum/gas_mixture/turf/remove(amount)
	. = ..()
	wake_holder()

/datum/gas_mixture/turf/remove_ratio(ratio)
	. = ..()
	wake_holder()

/datum/gas_mixture/turf/set_moles(gas_id, amt)
	. = ..()
	wake_holder()

/datum/gas_mixture/immutable
	var/initial_temperature = 0

/datum/gas_mixture/immutable/New()
	..()
	temperature = initial_temperature
	populate()
	mark_immutable()

/datum/gas_mixture/immutable/proc/populate()
	return

/datum/gas_mixture/immutable/space
	initial_temperature = TCMB

/datum/gas_mixture/immutable/space/populate()
	set_min_heat_capacity(HEAT_CAPACITY_VACUUM)

#ifndef CALCULATE_CONDUCTION_ENERGY
#define CALCULATE_CONDUCTION_ENERGY(temperature_delta, heat_capacity_one, heat_capacity_two)\
	((temperature_delta) * ((heat_capacity_one) * ((heat_capacity_two) / ((heat_capacity_one) + (heat_capacity_two)))))
#endif

/// Heat capacity of the archived (start of tick) contents.
/datum/gas_mixture/proc/heat_capacity_archive()
	var/capacity = 0
	for(var/id in gases_archived)
		capacity += (GLOB.gas_data.specific_heats[id] || 20) * gases_archived[id]
	return max(capacity, min_heat_capacity)

/// BeeStation LINDA share(), adapted to NSV's gas API. Works on archived values, moves gas and heat between the mixes.
/// our_coeff / sharer_coeff = 1/(open neighbours+1) of whoever gives gas. Returns a pressure-like difference (+ if the sharer received).
/datum/gas_mixture/proc/share(datum/gas_mixture/sharer, our_coeff, sharer_coeff)
	if(!sharer)
		return 0
	var/list/ours = gases_archived
	var/list/theirs = sharer.gases_archived
	var/temperature_delta = temperature_archived - sharer.temperature_archived
	var/temp_delta_threshold = abs(temperature_delta) > MINIMUM_TEMPERATURE_DELTA_TO_CONSIDER

	var/old_self_heat_capacity = 0
	var/old_sharer_heat_capacity = 0
	if(temp_delta_threshold)
		old_self_heat_capacity = heat_capacity()
		old_sharer_heat_capacity = sharer.heat_capacity()

	var/heat_capacity_self_to_sharer = 0
	var/heat_capacity_sharer_to_self = 0
	var/moved_moles = 0
	var/abs_moved_moles = 0
	var/list/specific_heats = GLOB.gas_data.specific_heats

	for(var/id in ours | theirs)
		var/delta = QUANTIZE((ours[id] || 0) - (theirs[id] || 0))
		if(!delta)
			continue
		if(delta > 0)
			delta *= our_coeff
		else
			delta *= sharer_coeff
		if(temp_delta_threshold)
			var/gas_heat_capacity = delta * (specific_heats[id] || 20)
			if(delta > 0)
				heat_capacity_self_to_sharer += gas_heat_capacity
			else
				heat_capacity_sharer_to_self -= gas_heat_capacity
		adjust_moles(id, -delta)
		sharer.adjust_moles(id, delta)
		moved_moles += delta
		abs_moved_moles += abs(delta)
	last_share = abs_moved_moles

	if(temp_delta_threshold)
		var/new_self_heat_capacity = old_self_heat_capacity + heat_capacity_sharer_to_self - heat_capacity_self_to_sharer
		var/new_sharer_heat_capacity = old_sharer_heat_capacity + heat_capacity_self_to_sharer - heat_capacity_sharer_to_self
		if(new_self_heat_capacity > MINIMUM_HEAT_CAPACITY && !immutable)
			temperature = (old_self_heat_capacity * temperature - heat_capacity_self_to_sharer * temperature_archived + heat_capacity_sharer_to_self * sharer.temperature_archived) / new_self_heat_capacity
		if(new_sharer_heat_capacity > MINIMUM_HEAT_CAPACITY)
			if(!sharer.immutable)
				sharer.temperature = (old_sharer_heat_capacity * sharer.temperature - heat_capacity_sharer_to_self * sharer.temperature_archived + heat_capacity_self_to_sharer * temperature_archived) / new_sharer_heat_capacity
			if(abs(old_sharer_heat_capacity) > MINIMUM_HEAT_CAPACITY && abs(new_sharer_heat_capacity / old_sharer_heat_capacity - 1) < 0.1)
				linda_temperature_share(sharer, OPEN_HEAT_TRANSFER_COEFFICIENT)

	garbage_collect()
	sharer.garbage_collect()

	if(temperature_delta > MINIMUM_TEMPERATURE_TO_MOVE || abs(moved_moles) > MINIMUM_MOLES_DELTA_TO_MOVE)
		var/our_moles = 0
		for(var/id in gases)
			our_moles += gases[id]
		var/their_moles = 0
		for(var/id in sharer.gases)
			their_moles += sharer.gases[id]
		return (temperature_archived * (our_moles + moved_moles) - sharer.temperature_archived * (their_moles - moved_moles)) * R_IDEAL_GAS_EQUATION / volume
	return 0

/// Conduction between two mixes (or a mix and a fixed temperature/heat capacity when sharer is null).
/datum/gas_mixture/proc/linda_temperature_share(datum/gas_mixture/sharer, conduction_coefficient, sharer_temperature, sharer_heat_capacity)
	if(sharer)
		sharer_temperature = sharer.temperature_archived
	var/temperature_delta = temperature_archived - sharer_temperature
	if(abs(temperature_delta) > MINIMUM_TEMPERATURE_DELTA_TO_CONSIDER)
		var/self_heat_capacity = heat_capacity_archive()
		sharer_heat_capacity = sharer_heat_capacity || sharer.heat_capacity_archive()
		if(sharer_heat_capacity > MINIMUM_HEAT_CAPACITY && self_heat_capacity > MINIMUM_HEAT_CAPACITY)
			var/heat = CALCULATE_CONDUCTION_ENERGY(conduction_coefficient * temperature_delta, sharer_heat_capacity, self_heat_capacity)
			if(!immutable)
				temperature = max(temperature - heat / self_heat_capacity, TCMB)
			sharer_temperature = max(sharer_temperature + heat / sharer_heat_capacity, TCMB)
			if(sharer && !sharer.immutable)
				sharer.temperature = sharer_temperature
	return sharer_temperature

/// BeeStation compare(): "" when the mixes are alike enough to not need group processing, else the reason (gas id or "temp").
/datum/gas_mixture/proc/compare(datum/gas_mixture/sample, cmp_archive = FALSE)
	var/list/mine = cmp_archive ? gases_archived : gases
	var/list/theirs = cmp_archive ? sample.gases_archived : sample.gases
	var/total = 0
	for(var/id in mine | theirs)
		var/gas_moles = mine[id] || 0
		var/sample_moles = theirs[id] || 0
		var/abs_delta = abs(gas_moles - sample_moles)
		if(abs_delta > MINIMUM_MOLES_DELTA_TO_MOVE && abs_delta > gas_moles * MINIMUM_AIR_RATIO_TO_MOVE)
			return id
	for(var/id in mine)
		total += mine[id]
	if(total > MINIMUM_MOLES_DELTA_TO_MOVE)
		if(cmp_archive)
			if(abs(temperature_archived - sample.temperature_archived) > MINIMUM_TEMPERATURE_DELTA_TO_SUSPEND)
				return "temp"
		else if(abs(temperature - sample.temperature) > MINIMUM_TEMPERATURE_DELTA_TO_SUSPEND)
			return "temp"
	return ""

/// tg gas_mixture.react(): runs every reaction (highest priority first) whose minimum requirements are met.
/datum/gas_mixture/proc/react(datum/holder)
	. = NO_REACTION
	if(!length(gases))
		return
	var/temp = temperature
	var/ener = thermal_energy()
	reaction_results = new
	reaction_loop:
		for(var/r in SSair.gas_reactions)
			var/datum/gas_reaction/reaction = r
			var/list/min_reqs = reaction.min_requirements.Copy()
			if((min_reqs["TEMP"] && temp < min_reqs["TEMP"]) || (min_reqs["ENER"] && ener < min_reqs["ENER"]))
				continue
			min_reqs -= "TEMP"
			min_reqs -= "ENER"
			for(var/id in min_reqs)
				if((gases[id] || 0) < min_reqs[id])
					continue reaction_loop
			. |= reaction.react(src, holder)
			if(. & STOP_REACTIONS)
				break
	if(.)
		garbage_collect()

/// Parses "o2=22;n2=82;TEMP=293.15" (NSV initial_gas_mix strings).
/datum/gas_mixture/proc/parse_gas_string(gas_string)
	var/static/list/parse_cache = list()
	var/list/parsed = parse_cache[gas_string]
	if(!parsed)
		parsed = list()
		for(var/part in splittext(gas_string, ";"))
			var/list/kv = splittext(part, "=")
			if(length(kv) != 2)
				continue
			parsed[kv[1]] = text2num(kv[2])
		parse_cache[gas_string] = parsed
	gases = list()
	for(var/id in parsed)
		if(id == "TEMP")
			temperature = parsed[id]
		else
			gases[id] = parsed[id]
	return TRUE

/datum/gas_mixture/proc/copy_from_turf(turf/model)
	parse_gas_string(model.initial_gas_mix)
	return TRUE

// ------------------------------------------------------------------ turfs ------------------------------------------------------------------

/turf/var/to_be_destroyed = FALSE
/turf/var/max_fire_temperature_sustained = 0
/turf/var/nsv_adjacency_ready = FALSE
/turf/open/var/excited = FALSE
/turf/open/var/datum/excited_group/excited_group
/turf/open/var/archived_cycle = 0
/turf/open/var/current_cycle = 0
/turf/open/var/significant_share_ticker = 0

/turf/proc/get_z_base_turf()
	return /turf/open/space

/turf/proc/zAirIn(direction, turf/source)
	return FALSE
/turf/proc/zAirOut(direction, turf/source)
	return FALSE

/turf/proc/__update_auxtools_turf_adjacency_info()
	return

/turf/proc/Melt()
	return

/turf/open/proc/update_air_ref(flag)
	return

/// Gives this turf its gas mixture. NSV does this inline in /turf/open/Initialize; split out so space can swap in the immutable vacuum.
/turf/open/proc/nsv_init_turf_air()
	air = new(2500, src)
	air.copy_from_turf(src)
	update_air_ref(planetary_atmos ? 1 : 2)

/turf/open/space/nsv_init_turf_air()
	var/static/datum/gas_mixture/immutable/space/space_gas = new
	air = space_gas
	update_air_ref(-1)

/// Waking a turf up (anything that changed its gas from outside calls this). Adjacency is computed lazily the first time a turf matters.
/turf/open/proc/nsv_activate()
	SSair.add_to_active(src)

#define NSV_LINDA_ARCHIVE(T) \
	T.air.archive(); \
	T.archived_cycle = SSair.times_fired;

#define NSV_LAST_SHARE_CHECK \
	var/last_share = our_air.last_share;\
	if(last_share > MINIMUM_AIR_TO_SUSPEND){\
		our_excited_group.reset_cooldowns();\
		cached_ticker = 0;\
		enemy_tile.significant_share_ticker = 0;\
	} else if(last_share > MINIMUM_MOLES_DELTA_TO_MOVE) {\
		our_excited_group.dismantle_cooldown = 0;\
		cached_ticker = 0;\
		enemy_tile.significant_share_ticker = 0;\
	}

#define NSV_PLANET_SHARE_CHECK \
	var/last_share = our_air.last_share;\
	if(last_share > MINIMUM_AIR_TO_SUSPEND){\
		our_excited_group.reset_cooldowns();\
		cached_ticker = 0;\
	} else if(last_share > MINIMUM_MOLES_DELTA_TO_MOVE) {\
		our_excited_group.dismantle_cooldown = 0;\
		cached_ticker = 0;\
	}

/turf/open/proc/eg_reset_cooldowns()
	excited_group?.reset_cooldowns()

/turf/open/proc/eg_garbage_collect()
	excited_group?.garbage_collect()

/turf/proc/process_cell(fire_count)
	return

/// BeeStation LINDA process_cell (modern BeeStation, pure DM), adapted to NSV's gas_mixture API (gases / gases_archived).
/turf/open/process_cell(fire_count)
	if(archived_cycle < fire_count) //archive self if not already done
		NSV_LINDA_ARCHIVE(src)

	current_cycle = fire_count
	var/cached_ticker = significant_share_ticker
	cached_ticker += 1

	var/list/adjacent_turfs = atmos_adjacent_turfs
	var/datum/excited_group/our_excited_group = excited_group
	var/our_share_coeff = 1 / (LAZYLEN(adjacent_turfs) + 1)
	var/datum/gas_mixture/our_air = air
	var/list/share_end

	for(var/turf/open/enemy_tile as anything in adjacent_turfs)
		if(!istype(enemy_tile) || !enemy_tile.air)
			continue
		// turfs can ask to share at the very end (space does)
		if(enemy_tile.run_later)
			LAZYADD(share_end, enemy_tile)

		if(fire_count <= enemy_tile.current_cycle)
			continue
		NSV_LINDA_ARCHIVE(enemy_tile)

		var/should_share_air = FALSE
		var/datum/gas_mixture/enemy_air = enemy_tile.air
		var/datum/excited_group/enemy_excited_group = enemy_tile.excited_group
		// both in a group and different: merge. both excited: share. otherwise compare to decide whether to wake them
		if(our_excited_group && enemy_excited_group)
			if(our_excited_group != enemy_excited_group)
				our_excited_group.merge_groups(enemy_excited_group)
				our_excited_group = excited_group
		if(our_excited_group && enemy_excited_group && enemy_tile.excited)
			should_share_air = TRUE
		else if(our_air.compare(enemy_air, cmp_archive = TRUE))
			SSair.add_to_active(enemy_tile)
			var/datum/excited_group/existing_group = our_excited_group || enemy_excited_group || new
			if(!our_excited_group)
				existing_group.add_turf(src)
			if(!enemy_excited_group)
				existing_group.add_turf(enemy_tile)
			our_excited_group = excited_group
			should_share_air = TRUE

		if(should_share_air)
			var/difference = our_air.share(enemy_air, our_share_coeff, 1 / (LAZYLEN(enemy_tile.atmos_adjacent_turfs) + 1))
			if(difference)
				if(difference > 0)
					consider_pressure_difference(enemy_tile, difference)
				else
					enemy_tile.consider_pressure_difference(src, -difference)
			NSV_LAST_SHARE_CHECK

	if(planetary_atmos) //share our air with the "atmosphere" above the turf
		var/datum/gas_mixture/planetary_mix = SSair.get_planetary_mix(initial_gas_mix)
		if(planetary_mix)
			NSV_LINDA_ARCHIVE(src)
			if(our_air.compare(planetary_mix, cmp_archive = TRUE))
				if(!our_excited_group)
					var/datum/excited_group/new_group = new
					new_group.add_turf(src)
					our_excited_group = excited_group
				our_air.share(planetary_mix, 0.8, 0.8)
				our_air.linda_temperature_share(planetary_mix, OPEN_HEAT_TRANSFER_COEFFICIENT, planetary_mix.temperature_archived, planetary_mix.heat_capacity() * 5)
				planetary_mix.garbage_collect()
				NSV_PLANET_SHARE_CHECK

	for(var/turf/open/enemy_tile as anything in share_end)
		var/datum/gas_mixture/enemy_mix = enemy_tile.air
		NSV_LINDA_ARCHIVE(src)
		var/difference = our_air.share(enemy_mix, 1, 1)
		if(!our_excited_group)
			continue
		NSV_LAST_SHARE_CHECK
		if(!difference)
			continue
		if(difference > 0)
			consider_pressure_difference(enemy_tile, difference)
		else
			enemy_tile.consider_pressure_difference(src, difference)

	var/reacting = our_air.react(src)
	if(our_excited_group)
		our_excited_group.turf_reactions |= reacting

	update_visuals()
	if(!active_hotspot && !(reacting & (REACTING | STOP_REACTIONS)))
		if(!our_excited_group) //nothing of interest happens here: stop processing this turf
			SSair.remove_from_active(src)
		if(cached_ticker > EXCITED_GROUP_DISMANTLE_CYCLES) //stalling out: take a rest
			SSair.sleep_active_turf(src)

	significant_share_ticker = cached_ticker
	temperature_expose(our_air, our_air.temperature)

#undef NSV_LAST_SHARE_CHECK
#undef NSV_PLANET_SHARE_CHECK

// ------------------------------------------------------------------ excited groups (BeeStation LINDA_turf_tile.dm) ------------------------------------------------------------------

/datum/excited_group
	var/list/turf_list = list()
	var/breakdown_cooldown = 0
	var/dismantle_cooldown = 0
	var/turf_reactions = NONE

/datum/excited_group/New()
	SSair.excited_groups += src

/datum/excited_group/proc/add_turf(turf/open/target_turf)
	turf_list += target_turf
	target_turf.excited_group = src
	dismantle_cooldown = 0

/datum/excited_group/proc/merge_groups(datum/excited_group/target_group)
	if(turf_list.len > target_group.turf_list.len)
		SSair.excited_groups -= target_group
		for(var/turf/open/group_member as anything in target_group.turf_list)
			group_member.excited_group = src
			turf_list += group_member
		breakdown_cooldown = min(breakdown_cooldown, target_group.breakdown_cooldown)
		dismantle_cooldown = 0
	else
		SSair.excited_groups -= src
		for(var/turf/open/group_member as anything in turf_list)
			group_member.excited_group = target_group
			target_group.turf_list += group_member
		target_group.breakdown_cooldown = min(breakdown_cooldown, target_group.breakdown_cooldown)
		target_group.dismantle_cooldown = 0

/datum/excited_group/proc/reset_cooldowns()
	breakdown_cooldown = 0
	dismantle_cooldown = 0

/// Averages the gas of every turf in the group (conserving moles and energy) and writes that mix back to all of them.
/datum/excited_group/proc/self_breakdown(roundstart = FALSE, poke_turfs = FALSE)
	var/datum/gas_mixture/shared_mix = new
	var/list/shared_cached_moles = shared_mix.gases
	var/list/group_turfs = turf_list
	var/turflen = group_turfs.len
	var/immutable_in_group = FALSE
	var/energy = 0
	var/heat_cap = 0

	for(var/turf/open/group_member as anything in group_turfs)
		var/datum/gas_mixture/mix = group_member.air
		if(roundstart)
			if(mix.immutable)
				immutable_in_group = TRUE
				shared_mix.copy_from(mix)
				shared_cached_moles = shared_mix.gases
				break
			if(group_member.planetary_atmos)
				immutable_in_group = TRUE
				var/datum/gas_mixture/planetary_mix = SSair.get_planetary_mix(group_member.initial_gas_mix)
				if(planetary_mix)
					shared_mix.copy_from(planetary_mix)
					shared_cached_moles = shared_mix.gases
					break
		var/capacity = mix.heat_capacity()
		energy += mix.temperature * capacity
		heat_cap += capacity
		for(var/gas_id in mix.gases)
			shared_cached_moles[gas_id] = (shared_cached_moles[gas_id] || 0) + mix.gases[gas_id]

	if(!immutable_in_group && heat_cap > 0)
		shared_mix.temperature = energy / heat_cap
		for(var/gas_id in shared_cached_moles)
			shared_cached_moles[gas_id] /= turflen
		shared_mix.garbage_collect()

	for(var/turf/open/group_member as anything in group_turfs)
		if(group_member.air.immutable)
			continue
		if(group_member.planetary_atmos)
			group_member.air.copy_from(SSair.get_planetary_mix(group_member.initial_gas_mix))
		else
			group_member.air.copy_from(shared_mix)
		group_member.update_visuals()
		if(poke_turfs)
			SSair.add_to_active(group_member)
			group_member.significant_share_ticker = EXCITED_GROUP_DISMANTLE_CYCLES

	breakdown_cooldown = 0

/// Dismantles the group and puts all its turfs to sleep.
/datum/excited_group/proc/dismantle()
	for(var/turf/open/current_turf as anything in turf_list)
		current_turf.excited = FALSE
		current_turf.significant_share_ticker = 0
		SSair.active_turfs -= current_turf
	garbage_collect()

/// Breaks the group apart without sleeping its turfs.
/datum/excited_group/proc/garbage_collect()
	for(var/turf/open/current_turf as anything in turf_list)
		current_turf.excited_group = null
	turf_list.Cut()
	SSair.excited_groups -= src
	if(SSair.currentpart == SSAIR_EXCITEDGROUPS)
		SSair.currentrun -= src

// ------------------------------------------------------------------ SSair turf stages (BeeStation air.dm) ------------------------------------------------------------------

/datum/controller/subsystem/air
	var/list/active_turfs = list()
	var/list/excited_groups = list()
	var/list/hotspots = list()
	var/list/turf/open/high_pressure_delta = list()
	var/list/hotspot_run = list()
	/// cached static mixes planetary turfs relax towards (keyed by initial_gas_mix)
	var/list/planetary = list()

/datum/controller/subsystem/air/proc/get_planetary_mix(gas_string)
	var/datum/gas_mixture/immutable/planetary/mix = planetary[gas_string]
	if(!mix)
		mix = new
		mix.parse_gas_string(gas_string)
		mix.archive()
		planetary[gas_string] = mix
	return mix

/datum/gas_mixture/immutable/planetary
	initial_temperature = T20C

/datum/controller/subsystem/air/proc/process_active_turfs(resumed = FALSE)
	var/fire_count = times_fired
	if(!resumed)
		currentrun = active_turfs.Copy()
	var/list/current = currentrun
	while(length(current))
		var/turf/open/T = current[length(current)]
		current.len--
		if(T)
			T.process_cell(fire_count)
		if(MC_TICK_CHECK)
			return

/datum/controller/subsystem/air/proc/process_excited_groups(resumed = FALSE)
	if(!resumed)
		currentrun = excited_groups.Copy()
	var/list/current = currentrun
	while(length(current))
		var/datum/excited_group/EG = current[length(current)]
		current.len--
		var/volatile_reaction = EG.turf_reactions & VOLATILE_REACTION
		EG.breakdown_cooldown++
		if(!volatile_reaction)
			EG.dismantle_cooldown++
		if(EG.breakdown_cooldown >= EXCITED_GROUP_BREAKDOWN_CYCLES && !volatile_reaction)
			EG.self_breakdown(poke_turfs = TRUE)
		else if(EG.dismantle_cooldown >= EXCITED_GROUP_DISMANTLE_CYCLES && !(EG.turf_reactions & (REACTING | STOP_REACTIONS)))
			EG.dismantle()
		EG.turf_reactions = NONE
		if(MC_TICK_CHECK)
			return

/datum/controller/subsystem/air/proc/process_hotspots(resumed = FALSE)
	if(!resumed)
		hotspot_run = hotspots.Copy()
	while(length(hotspot_run))
		var/obj/effect/hotspot/H = hotspot_run[length(hotspot_run)]
		hotspot_run.len--
		if(H)
			H.process()
		else
			hotspots -= H
		if(MC_TICK_CHECK)
			return

/datum/controller/subsystem/air/proc/process_high_pressure_delta(resumed = FALSE)
	while(length(high_pressure_delta))
		var/turf/open/T = high_pressure_delta[length(high_pressure_delta)]
		high_pressure_delta.len--
		T.high_pressure_movements()
		T.pressure_difference = 0
		T.pressure_direction = 0
		T.pressure_specific_target = null
		if(MC_TICK_CHECK)
			return

/// Removes a turf from processing and breaks up its excited group so things adapt to the change.
/datum/controller/subsystem/air/proc/remove_from_active(turf/open/T)
	active_turfs -= T
	if(currentpart == SSAIR_ACTIVETURFS)
		currentrun -= T
	if(istype(T))
		T.excited = FALSE
		if(T.excited_group)
			T.excited_group.garbage_collect()

/// Puts a turf to sleep without touching its excited group.
/datum/controller/subsystem/air/proc/sleep_active_turf(turf/open/T)
	active_turfs -= T
	if(currentpart == SSAIR_ACTIVETURFS)
		currentrun -= T
	if(istype(T))
		T.excited = FALSE

/// Adds a turf to active processing, handles duplicates. blockchanges nukes the excited group the turf was part of.
/datum/controller/subsystem/air/proc/add_to_active(turf/open/activate, blockchanges = FALSE)
	if(!istype(activate) || !activate.air || activate.air.immutable)
		return
	if(!activate.nsv_adjacency_ready)
		activate.ImmediateCalculateAdjacentTurfs()
	activate.significant_share_ticker = 0
	if(blockchanges && activate.excited_group)
		activate.excited_group.garbage_collect()
	if(activate.excited)
		return
	activate.excited = TRUE
	active_turfs += activate
