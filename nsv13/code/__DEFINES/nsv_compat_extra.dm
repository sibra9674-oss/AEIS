#define COMSIG_KB_OVERMAP_COUNTERMEASURE_DOWN "keybinding_overmap_countermeasure_down"
#define COMSIG_KB_OVERMAP_ROTATERIGHT_DOWN "keybinding_overmap_rotateright_down"
#define COMSIG_KB_OVERMAP_TOGGLEMOUSEMOVE_DOWN "keybinding_overmap_togglemousemove_down"
#define COMSIG_KB_OVERMAP_WEAPON2_DOWN "keybinding_overmap_weapon2_down"
#define COMSIG_KB_OVERMAP_WEAPON3_DOWN "keybinding_overmap_weapon3_down"
#define COMSIG_KB_OVERMAP_WEAPON1_DOWN "keybinding_overmap_weapon1_down"
#define COMSIG_KB_OVERMAP_WEAPON4_DOWN "keybinding_overmap_weapon4_down"
#define COMSIG_KB_OVERMAP_TOGGLEINERTIA_DOWN "keybinding_overmap_toggleinertia_down"
#define COMSIG_KB_OVERMAP_CYCLEFIREMODE_DOWN "keybinding_overmap_cyclefiremode_down"
#define COMSIG_KB_OVERMAP_SPECIAL_WEAPON_ACTION_DOWN "keybinding_overmap_special_weapon_action_down"
#define COMSIG_KB_OVERMAP_ROTATELEFT_DOWN "keybinding_overmap_rotateleft_down"
#define COMSIG_KB_OVERMAP_UNLOCK_DOWN "keybinding_overmap_unlock_down"
#define COMSIG_KB_OVERMAP_TOGGLEBRAKES_DOWN "keybinding_overmap_togglebrakes_down"
#define COMSIG_KB_OVERMAP_TOGGLESAFETY_DOWN "keybinding_overmap_togglesafety_down"
#define COMSIG_KB_OVERMAP_BOOST_DOWN "keybinding_overmap_boost_down"
#define CATEGORY_OVERMAP CATEGORY_MOB
#define WEIGHT_OVERMAP WEIGHT_HIGHEST
#define COMSIG_ATOM_BLOCKS_BSA_BEAM 1
#define MOBILITY_STAND			(1<<1)		//! can, and is, standing up
#define GAS_O2					"o2"
#define MOBILITY_USE			(1<<3)		//! can hold and use items
#define GAS_NUCLEIUM			"nucleium" //NSV13
#define GAS_PLASMA				"plasma"
#define SUPPRESSED_VERY 2 /// no message
#define N2STANDARD				0.79	//! percentage of nitrogen in a normal mixture of air
#define ACCESS_ARMORY 3 //! Armory, gulag teleporter, execution chamber
#define ACCESS_MINING 48
#define ABSTRACT				(1<<9) 	//! for all things that are technically items but used for various different stuff
#define PROJECTILE_PIERCE_PHASE		2
#define RICOCHET_SHINY			(1<<0)
#define COMSIG_PROJECTILE_PREHIT "com_proj_prehit"				// sent to targets during the process_hit proc of projectiles
#define RICOCHET_HARD			(1<<1)
#define PROJECTILE_HIT_THRESHHOLD_LAYER 2.75 //projectiles won't hit objects at or below this layer if possible
#define PROJECTILE_PIERCE_NONE		0
#define DELETE_UNOCCUPIED_ON_DEPARTURE 	(1<<3) // When a fighter/dropship leaves the map level for the overmap level, look for remaining occupants. If none exist, delete
#define ACCESS_SEC_DOORS 63 //! Outer brig doors, department security posts
#define GAS_TRITIUM				"tritium"
#define TRAIT_NICE_SHOT			"nice_shot" //hnnnnnnnggggg..... you're pretty good....
#define GAS_CONSTRICTED_PLASMA  "constricted_plasma" //NSV13
#define NICE_SHOT_RICOCHET_BONUS	10			//if the shooter has the NICE_SHOT trait and they fire a ricocheting projectile, add this to the ricochet chance and auto aim angle
#define O2STANDARD				0.21	//! percentage of oxygen in a normal mixture of air
#define PROJECTILE_DELETE_WITHOUT_HITTING		3
#define COMSIG_PROJECTILE_RANGE_OUT "projectile_range_out"				// sent to targets during the process_hit proc of projectiles
#define LETPASSTHROW	(1<<6)
#define COMSIG_PROJECTILE_SELF_ON_HIT "projectile_self_on_hit"			// from base of /obj/item/projectile/proc/on_hit(): (atom/movable/firer, atom/target, Angle)
#define GAS_N2					"n2"
#define STARSYSTEM_END_ON_ENTER 1<<3  //End the round after entering this system (Outpost 45)
#define GAS_PLUOXIUM			"pluox"
#define COMSIG_SHIP_RELEASE_BOARDING "ship_release_boarding"
#define COMSIG_MOB_OVERMAP_CHANGE "mob_overmap_change"
#define FIRE_PROOF (1<<21) //(1<<1) is UNACIDABLE in TGMC
#define PASSGLASS (1<<1)
#define TRAIT_SOURCE_OVERMAP_BLACKHOLE "overmap_singularity"
// Stubs for Beestation/NSV systems that are intentionally not ported (yet). Each is replaced by the real thing when its module is brought in.
/datum/gas_mixture
	var/volume = 0
	var/temperature = 293
/datum/gas_mixture/proc/return_volume()
	return volume
/datum/gas_mixture/proc/return_temperature()
	return temperature
/datum/gas_mixture/proc/set_temperature(new_temp)
	temperature = new_temp
/datum/gas_mixture/proc/return_pressure()
	return 0
/datum/gas_mixture/proc/remove(amount)
	return new /datum/gas_mixture
/datum/gas_mixture/proc/merge(datum/gas_mixture/other)
	return

/datum/trader
/datum/lance
/datum/combat_dice
/datum/freight_delivery_receipt
/datum/overmap_objective
/datum/overmap_objective/cargo
/obj/structure/overmap/trader
/obj/item/supplypod_beacon
/obj/item/card/id/gulag
/datum/bank_account
/datum/verbs/menu

// ---- shims for Beestation helpers ----
/proc/get_angle(atom/A, atom/B)
	return Get_Angle(A, B)
/proc/isprojectile(O)
	return istype(O, /obj/projectile) || istype(O, /atom/movable/projectile)
/proc/station_name()
	return "Space Station"
/proc/get_turf_above(turf/T)
	return GET_TURF_ABOVE(T)
/proc/get_turf_below(turf/T)
	return GET_TURF_BELOW(T)
/client/proc/give_award(achievement_type, mob/user)
	return
/mob/var/list/mousemove_intercept_objects
/obj/item/multitool/var/atom/buffer
/obj/machinery/var/panel_open = FALSE
GLOBAL_LIST_EMPTY(critical_muni_items)
GLOBAL_LIST_EMPTY(teleportlocs)
/datum/ss_overmap_mode_stub
	var/datum/overmap_mode_stub/mode = new
	var/threat_elevation = 0
	var/override_ghost_ships = FALSE

/datum/overmap_mode_stub
	var/difficulty = 1
	var/name = "stub"
/datum/ss_overmap_mode_stub
	var/already_ended = FALSE
	var/round_extended = FALSE
/datum/ss_overmap_mode_stub/mode_obj
var/datum/ss_overmap_mode_stub/SSovermap_mode = new
/datum/component/remote_materials
/datum/component/material_container
/datum/component/two_handed
/datum/reagent/oil
/obj/item/stack/sheet/nanocarbon_glass
/datum/freight_delivery_receipt
	var/obj/structure/overmap/vessel
	var/courier
/datum/lance
	var/lance_target
	var/last_finder
/atom/movable/var/movement_type_bee = 0
/datum/gas_mixture/proc/get_moles(gas_id)
	return 0
/datum/gas_mixture/proc/adjust_moles(gas_id, amt)
	return
/datum/gas_mixture/proc/total_moles()
	return 0
/datum/controller/subsystem/mapping/proc/get_turf_below(turf/T)
	return get_turf_below(T)

#define ACID_PROOF (1<<22) //(1<<2) is ON_FIRE in TGMC
#define PASSGRILLE (1<<2)
#define PROJECTILE_PIERCE_HIT 1
#define COMSIG_PROJECTILE_BEFORE_FIRE "projectile_before_fire"
/datum/component/remote_materials/var/datum/component/material_container/mat_container
/datum/component/material_container/proc/has_enough_of_material(mat, amt)
	return FALSE
/datum/component/material_container/proc/use_amount_mat(amt, mat)
	return FALSE
/datum/component/material_container/proc/get_material_amount(mat)
	return 0
/obj/machinery/computer/ship/ftl_core
/obj/machinery/atmospherics/components/unary/plasma_loader
/turf/closed/indestructible/boarding_cordon
/obj/machinery/computer/ammo_sorter/proc/ui_update()
	return
/datum/freight_delivery_receipt/var/shipment
/datum/space_level/var/linked_overmap
/client/var/overmap_zoomout
/area/var/has_gravity
/obj/item/card/id/gulag/var/points
/datum/controller/subsystem/mapping/proc/setup_map_transitions()
	return
/obj/machinery/atmospherics/var/list/airs
/proc/isnum_safe(x)
	return isnum(x) && !isnan(x) && !isinf(x)
/proc/explosion(atom/epicenter, devastation_range, heavy_impact_range, light_impact_range, flash_range, adminlog, ignorecap, flame_range, silent, smoke)
	var/turf/epicenter_turf = get_turf(epicenter)
	if(!epicenter_turf)
		return
	if(SSmapping.level_trait(epicenter_turf.z, ZTRAIT_OVERMAP))
		//Space has no ground to crater: on the overmap level an explosion is only the Goonstation sprite and a sound for the nearby ships (like NSV).
		nsv_space_explosion(epicenter_turf, max(devastation_range, heavy_impact_range, light_impact_range))
		return
	cell_explosion(epicenter_turf, max(devastation_range * 40, 1), 20)

/proc/nsv_space_explosion(turf/T, radius = 2)
	var/obj/effect/temp_visual/impact_effect/torpedo/boom = new(T)
	boom.pixel_x = -14 //the 60x60 sprite has to be centred on the tile
	boom.pixel_y = -14
	if(radius >= 5)
		var/matrix/big = matrix()
		big.Scale(1.8, 1.8)
		boom.transform = big
	for(var/obj/structure/overmap/OM in GLOB.overmap_objects)
		if(OM.z == T.z && get_dist(OM, T) <= 30)
			OM.relay('nsv13/sound/effects/ship/torpedo_detonate.ogg')

#define PASSTABLE (1<<0)
#define FREEZE_PROOF (1<<3)
/datum/material/iron
/datum/material/titanium
/datum/material/silver
/datum/material/plasma
/datum/material/gold
/datum/material/diamond
/datum/material/uranium
/datum/material/bluespace
/datum/material/bananium
/datum/material/copper
/datum/game_mode/pvp
/datum/freight_delivery_receipt/var/completed_objectives
/datum/trader/var/station_type
/datum/trader/var/system
/obj/structure/overmap/trader/proc/set_trader(datum/trader/T)
	return
/obj/machinery/computer/ship/ftl_core/var/ftl_state
/atom/var/interaction_flags_atom = 0
/datum/gas_mixture/proc/set_moles(gas_id, amt)
	return
/datum/controller/subsystem/mapping/proc/get_turf_above(turf/T)
	return get_turf_above(T)
// star_system transitions (real code lives in FTL/ftl_jump.dm; stubbed until FTL is ported)
/datum/star_system/proc/add_ship(obj/structure/overmap/OM, turf/target_turf)
	//Simplified port of FTL/ftl_jump.dm add_ship: registers the ship in this system (FTL itself is not ported).
	if(QDELETED(OM))
		return
	if(!system_contents.Find(OM))
		system_contents += OM
	if(!occupying_z && OM.z)
		occupying_z = OM.z
	if(target_turf)
		OM.forceMove(target_turf)
	else if(!OM.z && occupying_z)
		OM.forceMove(locate(rand(40, world.maxx - 39), rand(40, world.maxy - 39), occupying_z))
	if(istype(OM))
		OM.current_system = src
		if(OM.faction != "nanotrasen" && OM.faction != "solgov")
			enemies_in_system |= OM
/datum/star_system/proc/remove_ship(obj/structure/overmap/OM, turf/new_location, is_ftl_jump = TRUE)
	return
/datum/star_system/proc/check_conflict_status()
	return

/atom/var/pass_flags_self = 0
/atom/var/flags_ricochet = 0
/atom/movable/var/movement_type = 0
/mob/living/var/has_limbs = FALSE
/datum/controller/subsystem/processing/projectiles/var/global_pixel_speed = 2
/datum/controller/subsystem/processing/projectiles/var/global_iterations_per_move = 16
/obj/machinery/computer/var/icon_keyboard
/obj/machinery/computer/var/icon_screen
/atom/proc/handle_ricochet(obj/item/projectile/P)
	return FALSE
/mob/living/proc/lowest_buckled_mob()
	return src
/proc/isalien(A)
	return FALSE
/proc/typecache_filter_list(list/atoms, list/typecache)
	. = list()
	for(var/atom/A as anything in atoms)
		if(typecache[A.type])
			. += A
/obj/item/projectile/bullet/dart
/obj/item/bodypart

/obj/item/ammo_box/magazine/var/max_ammo = 0
/obj/item/ammo_box/magazine/var/ammo_type
/obj/item/ammo_box/magazine/var/caliber
/obj/item/projectile/var/armour_penetration = 0
/obj/structure/overmap/var/armor
#define ACCESS_ENGINE 10
#define ACCESS_SYNDICATE 150
#define RADIO_CHANNEL_SECURITY "Security"
#define RADIO_CHANNEL_SUPPLY "Supply"
#define REFLECT_FAKEPROJECTILE (1<<2)
#define ATMOS_PASS_YES 1
#define LIGHT_NO_LUMCOUNT 0
#define START_PROCESSING_MANUALLY 1
#define START_PROCESSING_ON_INIT 0
#define INTERACT_MACHINE_OPEN (1<<0)
#define DEPARTMENTAL_FLAG_MUNITIONS (1<<8)

/mob/camera/ai_eye/remote/var/atom/origin
/mob/camera/ai_eye/remote/var/mob/eye_user
/mob/camera/ai_eye/remote/proc/setLoc(turf/T)
	return
/obj/item/projectile/guided_munition/var/armor
/obj/machinery/var/is_operational = TRUE
/turf/open/var/datum/gas_mixture/air
/obj/item/ammo_casing/var/caliber
#define ATMOS_GAS_MONITOR_SENSOR_NUCLEIUM "nucleium_sensor"
#define ATMOS_GAS_MONITOR_INPUT_NUCLEIUM "nucleium_in"
#define ATMOS_GAS_MONITOR_OUTPUT_NUCLEIUM "nucleium_out"
#define INTERACT_MACHINE_OFFLINE (1<<1)

/mob/var/obj/structure/overmap/last_overmap
/obj/structure/chair/fancy/gauss/var/mutable_appearance/armrest
GLOBAL_VAR_INIT(max_pixel_x, 255 * 32)
GLOBAL_VAR_INIT(max_pixel_y, 255 * 32)
GLOBAL_VAR_INIT(security_level, 0)
/datum/stub_economy/proc/get_dep_account(a)
	return new /datum/bank_account
/datum/stub_research
	var/datum/stub_research_tech/science_tech = new
/datum/stub_research_tech/proc/add_point_type(a, b)
	return
var/datum/stub_economy/SSeconomy = new
var/datum/stub_research/SSresearch = new
#define INTERACT_MACHINE_WIRES_IF_OPEN (1<<2)
/obj/item/var/lefthand_file
/obj/item/var/righthand_file
GLOBAL_LIST_EMPTY(poi_list)
GLOBAL_LIST_EMPTY(blacklisted_paperwork_itemtypes)
#define INTERACT_MACHINE_ALLOW_SILICON (1<<3)
/datum/trader/var/name
/datum/design/var/name
#define INTERACT_MACHINE_OPEN_SILICON (1<<4)
#define ACCOUNT_CAR "car"
#define ACCOUNT_MUN "mun"
#define ROLE_GHOSTSHIP "Ghost Ship"
#define POLL_IGNORE_GHOSTSHIP "ghostship"
#define WALL_DENT_SHOT 2
/mob/living/var/mobility_flags = 0
#define INTERACT_MACHINE_SET_MACHINE (1<<5)
#define TECHWEB_POINT_TYPE_DEFAULT "General Research"
/datum/fleet/proc/play_soundtrack_music(sound, volume = 100, direct = FALSE)
	return
/atom/proc/Beam(atom/BeamTarget, icon_state = "b_beam", icon = 'icons/effects/beam.dmi', time = 50, maxdistance = 10, beam_type = /obj/effect/ebeam)
	return
/atom/proc/attack_robot(mob/user)
	return
/obj/machinery/proc/default_deconstruction_screwdriver(mob/user, icon_state_open, icon_state_closed, obj/item/I)
	return FALSE
/obj/machinery/proc/default_unfasten_wrench(mob/user, obj/item/I, time = 20)
	return FALSE
/obj/item/ammo_casing/proc/fire_casing(atom/target, mob/living/user, params, distro, quiet, zone_override, spread, atom/fired_from)
	return
/obj/item/ammo_casing/var/BB

#define TESLA_MINI_POWER 12000
#define TESLA_ENERGY_MINI_BALL_FLAGS 0
#define AIMING_BEAM_ANGLE_CHANGE_THRESHOLD 0.2
/proc/play_soundtrack_music(sound, a, b)
	return
/datum/overmap_mode_stub_dummy
/datum/ss_overmap_mode_stub/proc/update_reminder(objective)
	return
/mob/living/dummy_pilot/proc/destroy_dummy_pilot(datum/source)
	return
/obj/structure/overmap/proc/force_parallax_update()
	return
/obj/structure/frame/var/circuit
GLOBAL_LIST_EMPTY(busy_states)
GLOBAL_LIST_EMPTY(bombers)
GLOBAL_VAR_INIT(MAX_EX_DEVESTATION_RANGE, 3)
GLOBAL_VAR_INIT(MAX_EX_HEAVY_RANGE, 7)
GLOBAL_VAR_INIT(MAX_EX_LIGHT_RANGE, 14)
GLOBAL_VAR_INIT(MAX_EX_FLASH_RANGE, 20)
/obj/item/disk/design_disk/var/list/blueprints = list()
/obj/item/disk/design_disk/var/max_blueprints = 0

// ---- compiler-driven fixes (round 2) ----
#define HARDPOINT_SLOT_COUNTERMEASURE "Countermeasure"
#define HARDPOINT_SLOT_ARMOUR "Armour"
/atom/movable/proc/experience_pressure_difference(pressure_difference, direction, pressure_resistance_prob_delta = 0)
	return
/datum/proc/onMouseDrag(src_object, over_object, src_location, over_location, params, mob/M)
	return
/datum/proc/onMouseMove(object, location, control, params)
	return
/atom/proc/return_air()
	return
/atom/proc/remove_air(amount)
	return
/atom/proc/remove_air_ratio(ratio)
	return
/atom/proc/return_analyzable_air()
	return
/atom/proc/assume_air(datum/gas_mixture/giver)
	return
/atom/proc/return_temperature()
	return
/atom/proc/emag_act(mob/user)
	return
/atom/proc/rcd_vals(mob/user, obj/item/construction/rcd/the_rcd)
	return FALSE
/atom/proc/rcd_act(mob/user, obj/item/construction/rcd/the_rcd, passed_mode)
	return FALSE
/obj/structure/overmap/proc/on_interdict()
	return
/obj/item/firing_pin/proc/pin_auth(mob/living/user)
	return TRUE
/datum/component/overmap_shields/var/active = FALSE
/datum/component/overmap_shields/proc/absorb_hit(obj/item/projectile/P)
	return FALSE
/datum/component/fighter_loadout/proc/get_slot(slot)
	return null
/obj/structure/overmap/small_craft/var/datum/component/fighter_loadout/loadout
/obj/structure/chair/fancy/proc/update_armrest()
	return
/obj/structure/chair/fancy/proc/GetArmrest()
	return
/datum/stub_map_config
	var/return_system = "Staging"
	var/starmap_path = "config/starmap/starmap.json"
GLOBAL_DATUM_INIT(nsv_map_config, /datum/stub_map_config, new)
/obj/structure/overmap/var/datum/component/overmap_shields/shields

// ---- real NSV helpers that the autostub used to replace with empty stubs ----
///Whether the angle is on the port or starboard side of the ship (facing north or south on the map)
/proc/angle2dir_ship(angle)
	var/modulated_angle = (((angle % 360) + 360) % 360)
	if(modulated_angle <= 180)
		return SOUTH
	else
		return NORTH

/proc/shake_with_inertia(mob/M, duration=0, strength=1, dampenerData=null)
	set waitfor = FALSE
	if(M?.client)
		shake_camera(M, duration, strength)

/atom/proc/shake_animation(intensity = 8) //Makes the object visibly shake
	var/initial_transform = new/matrix(transform)
	var/init_px = pixel_x
	var/shake_dir = pick(-1, 1)
	var/rotation = 2 + min(intensity, 12) * 0.3
	var/offset = 1 + min(intensity, 12) * 0.2
	var/time = 2 + min(intensity, 12) * 0.2
	animate(src, transform = turn(transform, rotation * shake_dir), pixel_x = init_px + offset * shake_dir, time = 1)
	animate(transform = initial_transform, pixel_x = init_px, time = time, easing = ELASTIC_EASING)

/atom/movable/proc/physics_collide(atom/movable/A)
	return TRUE

/mob/proc/can_hear()
	return TRUE
/mob/proc/can_hear_ambience()
	return TRUE

/obj/structure/overmap/var/nsv_next_bounce = 0
