// Pure-DM gas mixture for the NSV port. NSV (Beestation) implements /datum/gas_mixture natively in the auxmos library;
// TGMC has no gas simulation at all. This reimplements the API NSV's FTL / reactor / plasma code actually calls, with the same
// formulas (ideal gas law, heat capacity weighted temperature mixing) and the specific heats from NSV's auxgm gas_types.dm.
// Gas reactions come from NSV's real reactions.dm; react(), share() and the turf simulation are DM reimplementations of what auxmos does natively.

#ifndef CELL_VOLUME
#define CELL_VOLUME 2500 //liters in a cell
#endif
#define NSV_MINIMUM_MOLE_COUNT 0.01
#define NSV_MINIMUM_HEAT_CAPACITY 0.0003
#define NSV_QUANTIZE(variable) (round(variable, 0.0000001))

/datum/gas_mixture
	var/list/gases = list()
	var/temperature = TCMB
	var/volume = CELL_VOLUME
	var/initial_volume = CELL_VOLUME
	var/list/reaction_results
	var/list/analyzer_results
	var/immutable = FALSE
	var/min_heat_capacity = 0
	var/temperature_archived = TCMB
	var/list/gases_archived = list()
	var/last_share = 0

/datum/gas_mixture/New(volume)
	..()
	if(!isnull(volume))
		src.volume = volume
		initial_volume = volume
	reaction_results = list()

/datum/gas_mixture/proc/get_moles(gas_id)
	return gases[gas_id] || 0

/datum/gas_mixture/proc/set_moles(gas_id, amt)
	if(immutable)
		return
	if(amt <= 0)
		gases -= gas_id
		return
	gases[gas_id] = amt

/datum/gas_mixture/proc/adjust_moles(gas_id, amt = 0)
	set_moles(gas_id, get_moles(gas_id) + amt)

/// Adds gas at the given temperature: the temperature of the mix moves to the heat-capacity weighted average.
/datum/gas_mixture/proc/adjust_moles_temp(gas_id, amt, temp)
	if(amt <= 0)
		adjust_moles(gas_id, amt)
		return
	var/old_energy = thermal_energy()
	var/specific_heat = GLOB.gas_data.specific_heats[gas_id] || 20
	var/added_energy = specific_heat * amt * temp
	adjust_moles(gas_id, amt)
	var/new_capacity = heat_capacity()
	if(new_capacity > NSV_MINIMUM_HEAT_CAPACITY)
		temperature = (old_energy + added_energy) / new_capacity

/datum/gas_mixture/proc/get_gases()
	return gases.Copy()

/datum/gas_mixture/proc/total_moles()
	var/moles = 0
	for(var/id in gases)
		moles += gases[id]
	return moles

/datum/gas_mixture/proc/return_temperature()
	return temperature

/datum/gas_mixture/proc/set_temperature(new_temp)
	if(immutable)
		return
	temperature = max(new_temp, TCMB)

/datum/gas_mixture/proc/return_volume()
	return max(0, volume)

/datum/gas_mixture/proc/set_volume(new_volume)
	volume = max(0, new_volume)

/datum/gas_mixture/proc/partial_heat_capacity(gas_id)
	return (GLOB.gas_data.specific_heats[gas_id] || 20) * get_moles(gas_id)

/datum/gas_mixture/proc/heat_capacity()
	var/capacity = 0
	for(var/id in gases)
		capacity += (GLOB.gas_data.specific_heats[id] || 20) * gases[id]
	return max(capacity, min_heat_capacity)

/datum/gas_mixture/proc/thermal_energy()
	return temperature * heat_capacity()

/datum/gas_mixture/proc/return_pressure()
	if(volume > 0)
		return total_moles() * R_IDEAL_GAS_EQUATION * temperature / volume
	return 0

/datum/gas_mixture/proc/clear()
	if(immutable)
		return
	gases.Cut()

/datum/gas_mixture/proc/archive()
	gases_archived = gases.Copy()
	temperature_archived = temperature
	return TRUE

/datum/gas_mixture/proc/mark_immutable()
	immutable = TRUE

/datum/gas_mixture/proc/set_min_heat_capacity(amount)
	min_heat_capacity = amount

/datum/gas_mixture/proc/garbage_collect()
	for(var/id in gases)
		if(gases[id] < NSV_MINIMUM_MOLE_COUNT)
			gases -= id

/// Adds the contents of giver into this mixture, mixing temperatures by heat capacity.
/datum/gas_mixture/proc/merge(datum/gas_mixture/giver)
	if(!giver || immutable)
		return FALSE
	var/self_capacity = heat_capacity()
	var/giver_capacity = giver.heat_capacity()
	var/combined_capacity = self_capacity + giver_capacity
	var/combined_energy = temperature * self_capacity + giver.temperature * giver_capacity
	for(var/id in giver.gases)
		set_moles(id, get_moles(id) + giver.gases[id])
	if(combined_capacity > NSV_MINIMUM_HEAT_CAPACITY)
		temperature = combined_energy / combined_capacity
	return TRUE

/// Removes the given number of moles (spread across all gases proportionally) and returns them as a new mixture.
/datum/gas_mixture/proc/remove(amount)
	var/sum = total_moles()
	amount = min(amount, sum)
	var/datum/gas_mixture/removed = new /datum/gas_mixture(volume)
	removed.temperature = temperature
	if(amount <= 0 || sum <= 0)
		return removed
	var/ratio = amount / sum
	for(var/id in gases.Copy())
		var/taken = gases[id] * ratio
		removed.set_moles(id, taken)
		set_moles(id, gases[id] - taken)
	return removed

/datum/gas_mixture/proc/remove_ratio(ratio)
	if(ratio <= 0)
		return new /datum/gas_mixture(volume)
	return remove(total_moles() * min(ratio, 1))

/datum/gas_mixture/proc/copy()
	var/datum/gas_mixture/copy = new /datum/gas_mixture(volume)
	copy.copy_from(src)
	return copy

/datum/gas_mixture/proc/copy_from(datum/gas_mixture/sample)
	if(immutable)
		return FALSE
	gases = sample.gases.Copy()
	temperature = sample.temperature
	return TRUE

/// Moves moles of gas into another mixture (used for pumps/pylons); returns the removed mix merged into target.
/datum/gas_mixture/proc/transfer_to(datum/gas_mixture/target, amount)
	var/datum/gas_mixture/removed = remove(amount)
	target.merge(removed)
	return TRUE

/datum/gas_mixture/proc/release_gas_to(datum/gas_mixture/output_air, target_pressure)
	var/output_starting_pressure = output_air.return_pressure()
	var/input_starting_pressure = return_pressure()
	if(output_starting_pressure >= min(target_pressure, input_starting_pressure - 10))
		return FALSE
	if(total_moles() > 0 && temperature > 0)
		var/pressure_delta = min(target_pressure - output_starting_pressure, (input_starting_pressure - output_starting_pressure) / 2)
		var/transfer_moles = pressure_delta * output_air.return_volume() / (temperature * R_IDEAL_GAS_EQUATION)
		output_air.merge(remove(transfer_moles))
		return TRUE
	return FALSE

/datum/gas_mixture/proc/set_analyzer_results(instability)
	if(!analyzer_results)
		analyzer_results = list()
	analyzer_results["fusion"] = instability
