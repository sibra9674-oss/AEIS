// Mobs reacting to the NSV gas simulation. TGMC has no atmos for mobs (its breathing is a pure oxyloss model, its body temperature ignores the room),
// so this adds the tg/NSV rules on top: breathing the tile's air, vacuum / pressure damage, room temperature heating or cooling the body.
// Called once per Life() tick from /mob/living/carbon/human/Life (one line added to human/life.dm).

#define NSV_BREATH_VOLUME 0.5
#define NSV_BREATH_PERCENTAGE (NSV_BREATH_VOLUME / CELL_VOLUME)
#define NSV_O2_MIN_PP 16 //kPa, below this the lungs get nothing useful
#define NSV_PLASMA_MAX_PP 0.05 //kPa
#define NSV_CO2_MAX_PP 10 //kPa
#define NSV_HAZARD_LOW_PRESSURE 20
#define NSV_WARNING_LOW_PRESSURE 50
#define NSV_WARNING_HIGH_PRESSURE 325
#define NSV_HAZARD_HIGH_PRESSURE 550
#define NSV_LOW_PRESSURE_DAMAGE 4
#define NSV_PRESSURE_DAMAGE_COEFFICIENT 4
#define NSV_MAX_HIGH_PRESSURE_DAMAGE 4
/// How much of the room temperature reaches the skin through ordinary clothing.
#define NSV_CLOTHING_HEAT_TRANSFER 0.3

/// Full space suit + helmet: sealed, supplies its own air, immune to vacuum and pressure (simplification: no tank is simulated).
/mob/living/carbon/human/proc/nsv_atmos_sealed()
	return istype(wear_suit, /obj/item/clothing/suit/space) && istype(head, /obj/item/clothing/head/helmet/space)

/mob/living/carbon/human/proc/nsv_handle_atmos()
	if(status_flags & GODMODE)
		return
	var/turf/open/T = loc
	if(!istype(T)) //inside a vehicle, crate, cryo tube...: no atmosphere here
		return
	var/datum/gas_mixture/env = T.return_air()
	if(!env)
		return
	var/sealed = nsv_atmos_sealed()
	var/pressure = env.return_pressure()

	if(sealed)
		nsv_set_alert("pressure", /atom/movable/screen/alert/lowpressure, 1, FALSE)
		nsv_set_alert("nsv_tox", /atom/movable/screen/alert/too_much_tox, null, FALSE)
		nsv_set_alert("nsv_co2", /atom/movable/screen/alert/too_much_co2, null, FALSE)
	else
		nsv_atmos_breathe(T, env, pressure)
		nsv_atmos_pressure(pressure)
	nsv_atmos_temperature(env, pressure, sealed)

/// Shows/clears one of the HUD alerts (the icons are TGMC's own screen_alert.dmi, same states NSV uses).
/mob/living/carbon/human/proc/nsv_set_alert(category, alert_type, severity, on)
	if(on)
		throw_alert(category, alert_type, severity)
	else
		clear_alert(category)

/atom/movable/screen/alert/too_much_tox
	name = "Gas poisoning"
	desc = "There is plasma in the air you breathe. Get out of here or into a sealed suit before it kills you!"
	icon_state = "too_much_tox"

/atom/movable/screen/alert/too_much_co2
	name = "Stale air"
	desc = "There is too much carbon dioxide in the air. Find fresh air before you suffocate."
	icon_state = "too_much_co2"

/mob/living/carbon/human/proc/nsv_atmos_breathe(turf/open/T, datum/gas_mixture/env, pressure)
	if(species.species_flags & NO_BREATHE)
		return
	if(HAS_TRAIT(src, TRAIT_IGNORE_SUFFOCATION))
		return
	var/total = env.total_moles()
	if(total <= 0 || pressure <= 0) //vacuum
		set_Losebreath(2)
		nsv_set_alert("nsv_tox", /atom/movable/screen/alert/too_much_tox, null, FALSE)
		nsv_set_alert("nsv_co2", /atom/movable/screen/alert/too_much_co2, null, FALSE)
		return
	var/o2_pp = env.get_moles(GAS_O2) / total * pressure
	if(o2_pp < NSV_O2_MIN_PP)
		set_Losebreath(2) //TGMC's handle_breath turns this into suffocation damage + gasp alert
	else
		// inhale a lungful, burn the oxygen into CO2, exhale back into the room
		var/datum/gas_mixture/turf/tmix = env
		if(istype(tmix))
			tmix.quiet = TRUE
		var/datum/gas_mixture/breath = env.remove(total * NSV_BREATH_PERCENTAGE)
		if(breath)
			var/used = breath.get_moles(GAS_O2) * 0.1
			breath.adjust_moles(GAS_O2, -used)
			breath.adjust_moles(GAS_CO2, used)
			env.merge(breath)
		if(istype(tmix))
			tmix.quiet = FALSE
	var/plasma_pp = env.get_moles(GAS_PLASMA) / total * pressure
	nsv_set_alert("nsv_tox", /atom/movable/screen/alert/too_much_tox, null, plasma_pp > NSV_PLASMA_MAX_PP)
	if(plasma_pp > NSV_PLASMA_MAX_PP)
		apply_damage(clamp(round(plasma_pp / NSV_PLASMA_MAX_PP), 1, 10), TOX, updating_health = TRUE)
		if(prob(10))
			to_chat(src, span_danger("You can taste plasma, your lungs burn!"))
	var/co2_pp = env.get_moles(GAS_CO2) / total * pressure
	nsv_set_alert("nsv_co2", /atom/movable/screen/alert/too_much_co2, null, co2_pp > NSV_CO2_MAX_PP)
	if(co2_pp > NSV_CO2_MAX_PP)
		adjust_oxy_loss(3, TRUE)
		if(prob(10))
			to_chat(src, span_warning("You feel short of breath, the air is stale."))

/mob/living/carbon/human/proc/nsv_atmos_pressure(pressure)
	if(pressure < NSV_WARNING_LOW_PRESSURE)
		nsv_set_alert("pressure", /atom/movable/screen/alert/lowpressure, pressure < NSV_HAZARD_LOW_PRESSURE ? 2 : 1, TRUE)
	else if(pressure > NSV_WARNING_HIGH_PRESSURE)
		nsv_set_alert("pressure", /atom/movable/screen/alert/highpressure, pressure > NSV_HAZARD_HIGH_PRESSURE ? 2 : 1, TRUE)
	else
		nsv_set_alert("pressure", /atom/movable/screen/alert/lowpressure, 1, FALSE)
	if(pressure < NSV_HAZARD_LOW_PRESSURE)
		take_overall_damage(NSV_LOW_PRESSURE_DAMAGE, BRUTE, updating_health = TRUE)
		if(prob(20))
			to_chat(src, span_danger("The vacuum tears at your body!"))
	else if(pressure > NSV_HAZARD_HIGH_PRESSURE)
		take_overall_damage(min(((pressure / NSV_HAZARD_HIGH_PRESSURE) - 1) * NSV_PRESSURE_DAMAGE_COEFFICIENT, NSV_MAX_HIGH_PRESSURE_DAMAGE), BRUTE, updating_health = TRUE)
		if(prob(20))
			to_chat(src, span_danger("The crushing pressure hurts!"))

/mob/living/carbon/human/proc/nsv_atmos_temperature(datum/gas_mixture/env, pressure, sealed)
	var/diff = env.return_temperature() - bodytemperature
	if(abs(diff) < 5)
		return
	// thin air (and vacuum) carries almost no heat; a sealed suit insulates strongly
	var/transfer = clamp(pressure / ONE_ATMOSPHERE, 0, 1) * (sealed ? 0.05 : NSV_CLOTHING_HEAT_TRANSFER)
	if(transfer <= 0)
		return
	var/rate = diff > 0 ? (1 / BODYTEMP_HEAT_DIVISOR) : (1 / BODYTEMP_COLD_DIVISOR)
	adjust_bodytemperature(clamp(diff * rate * transfer, BODYTEMP_COOLING_MAX, BODYTEMP_HEATING_MAX))

/// tg passes the flame temperature to fire_act(); TGMC's fire_act() takes a burn level and does rand(10, burn_level) damage.
/proc/nsv_burn_level(temperature)
	return clamp(round(temperature / 50), 10, 25)

// ---------------------------------------------------------------- space wind ----------------------------------------------------------------
// NSV's experience_pressure_difference() is tuned for tg's move_resist/pressure_resistance numbers and rarely moves TGMC mobs. Living mobs use this instead:
// a decompression pulls them one tile per air tick, and a strong one (a big breach into vacuum) throws them toward it.
#define NSV_WIND_MIN_DIFFERENCE 25
#define NSV_WIND_THROW_DIFFERENCE 80

/atom/movable/proc/nsv_living_wind(pressure_difference, direction, throw_target)
	last_high_pressure_movement_air_cycle = SSair.times_fired
	if(direction == UP || direction == DOWN || !direction)
		return
	var/mob/living/L = src
	if(pressure_difference < NSV_WIND_MIN_DIFFERENCE || L.buckled || L.anchored || L.status_flags & GODMODE)
		return
	if(ishuman(L))
		var/mob/living/carbon/human/H = L
		if(H.nsv_atmos_sealed() && H.stat == CONSCIOUS) //suited crew can brace
			pressure_difference *= 0.5
			if(pressure_difference < NSV_WIND_MIN_DIFFERENCE)
				return
	if(pressure_difference >= NSV_WIND_THROW_DIFFERENCE)
		var/turf/throw_turf = get_ranged_target_turf(get_turf(L), direction, clamp(round(pressure_difference / 40), 2, 7))
		if(throw_target && (get_dir(L, throw_target) & direction))
			throw_turf = get_turf(throw_target)
		if(throw_turf)
			L.throw_at(throw_turf, clamp(round(pressure_difference / 40), 2, 7), clamp(round(pressure_difference / 60), 1, 4))
	else
		step(L, direction)
	if(prob(25))
		to_chat(L, span_warning("The wind drags you toward the breach!"))
