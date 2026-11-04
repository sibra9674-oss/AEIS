// Defines that NSV13 added to the base codebase (flags.dm, traits, signals, ...). Generated.
#define ACCESS_HEADS 19 //!Bridge, EVA storage windoors, gateway shutters, AI integrity restorer, clone record deletion, comms console
#define ACCESS_MUNITIONS 69 //NSV13 - Departmental ACCESS
#define AI_FLAG_ANTI_FIGHTER 1<<3
#define AI_FLAG_BATTLESHIP 1<<1
#define AI_FLAG_BOARDER 1<<4 //Ships that like to board you.
#define AI_FLAG_DESTROYER 1<<2
#define AI_FLAG_ELITE 1<<6	 //These ships are more /fun/ than others even with the same equipment.
#define AI_FLAG_STATIONARY 1<<7 //Overrides all other flags. Object will attempt to stay in place, restoring its angle if possible (and, obviously, shooting things)
#define AI_FLAG_SUPPLY 1<<0
#define AI_FLAG_SWARMER 1<<5 //Ships that love to act in swarms. Aka, Fighters.
#define BLOCK_Z_IN_UP			(1<<12) // Should this object block z uprise from below?
#define BLOCK_Z_OUT_DOWN		(1<<9)  // Should this object block z falling from loc?
#define BULLET_ACT_FORCE_PIERCE		"PIERCE"	//! It pierces through the object regardless of the bullet being piercing by default.
#define BULLET_ACT_HIT				"HIT"		//! It's a successful hit, whatever that means in the context of the thing it's hitting.
#define CHANNEL_HEARTBEAT 1019 //sound channel for heartbeats
#define CHANNEL_IMPORTANT_SHIP_ALERT 1012 //nsv13 - sound channel for really REALLY IMPORTANT ship
#define CHANNEL_SHIP_FX 1013 //nsv13 - sound channel for general ship ambience / FX
#define CINEMATIC_NSV_SHIP_KABOOM 14 //Nsv13...duh
#define COMSIG_ADD_MOOD_EVENT "add_mood" //! Called when you send a mood event from anywhere in the code.
#define COMSIG_ATOM_BSA_BEAM "atom_bsa_beam_pass"
#define COMSIG_ATOM_DAMAGE_ACT "comsig_atom_damage_act" //Used when an atom takes damage.
#define COMSIG_ATOM_FIRE_ACT "atom_fire_act"
#define COMSIG_CARGO_DELIVERED "cargo_delivered"
#define COMSIG_FTL_STATE_CHANGE "ftl_state_change"
#define COMSIG_GLOB_CHECK_INTERDICT "check_interdict"							//from interdiction component
#define COMSIG_LOCK_LOST "lock_lost" //! from base of /obj/structure/overmap/proc/dump_lock: (target)
#define COMSIG_PARENT_EXAMINE "atom_examine"
#define COMSIG_PARENT_QDELETING "parent_qdeleting"				//! just before a datum's Destroy() is called: (force), at this point none of the other components chose to interrupt qdel and Destroy will be called
#define COMSIG_SHIP_BOARDED "ship_boarded"
#define COMSIG_SHIP_KILLED "ship_killed"
#define COMSIG_SHIP_KILLED_FLEET "ship_killed_fleet"
#define COMSIG_TARGET_LOCKED "target_locked" //! from base of /obj/structure/overmap/proc/select_target: (target)
#define COMSIG_TARGET_PAINTED "target_painted" //! from base of /obj/structure/overmap/proc/finish_lockon: (target, data_link_origin)
#define DAMAGE_DELETES_UNOCCUPIED	(1<<1) // When the overmap takes enough damage to be destroyed, if there are no occupants, delete it immediately. Modifies DAMAGE_STARTS_COUNTDOWN
#define DAMAGE_STARTS_COUNTDOWN		(1<<0) // When the overmap takes enough damage to be destroyed, begin a countdown after which it will be deleted
#define EMAGGED					(1<<0)
#define FIGHTERS_ARE_OCCUPANTS		(1<<4) // Docked overmaps count as occupants when deciding whether to delete something
#define FIRE_PRIORITY_PHYSICS		340 //NSV13 - Processes after SSprojectiles to keep hitboxes consistent for physics projectiles. Probably won't break anything
#define FLAMMABLE		(1<<2)
#define FLAVOR_TEXT_EVIL "evil"	//mob antag
#define FLYING			(1<<1)
#define INIT_ORDER_STARSYSTEM		48 //NSV13 - Needs to init before ships....
#define INTERACT_ATOM_CHECK_GRAB 					(1<<6)	//! incapacitated check checks grab
#define INTERACT_ATOM_IGNORE_INCAPACITATED		 	(1<<4)	//! ignores incapacitated check
#define INTERACT_ATOM_IGNORE_RESTRAINED 			(1<<5)	//! incapacitated check ignores restrained
#define INTERACT_ATOM_REQUIRES_DEXTERITY 			(1<<3)	//! user must be dextrous
#define LAVA_PROOF		(1<<20) //NOT (1<<0): that is INDESTRUCTIBLE in TGMC and made every ship immortal
#define MAX_CHARTER_LEN			80
#define MOBILITY_MOVE			(1<<0)		//! can move
#define NEVER_DELETE_OCCUPIED		(1<<2) // Even if the overmap takes enough damage to be destroyed, never delete it if it's occupied. I don't know when we'd use this it just seems useful
#define ONE_ATMOSPHERE			101.325	//! kPa
#define OSW_AIMING_BEAM (1<<0)					//!This weapon uses the aiming beam feature.
#define OSW_ALWAYS_FIRES_BROADSIDES (1<<1)			//!Always fires inaccurate sideways bursts (but still passes target)
#define OSW_ALWAYS_FIRES_ERRATIC_BROADSIDES (1<<2)	//!Like broadsides, but does not care about target direction (still passes target).
#define OSW_ALWAYS_FIRES_FORWARD (1<<0)				//!Always fires directly forward regardless of where you aim (but still passes target)
#define OSW_CONTROL_AI (1<<3)					//!Denotes AI being able to use this weapon if the ship it is on is AI controlled.
#define OSW_CONTROL_AI_FULL_AUTONOMY (1<<6)		//!Like Full Autonomy, except only used if the ship is controlled by AI.
#define OSW_CONTROL_AUTONOMOUS (1<<4)			//!This weapon has some form of autonomous control handling.
#define OSW_CONTROL_FULL_AUTONOMY (1<<5)		//!This weapon operates independantly when using autonomy handling. Ones with autonomy but without this are implied to be controlled by ams modes.
#define OSW_CONTROL_GUNNER (1<<1)				//!This weapon can be accessed by a gunner.
#define OSW_CONTROL_MANUAL (1<<2)				//!Denotes manual handling of the weapon.
#define OSW_CONTROL_PILOT (1<<0)				//!This weapon can be accessed by a pilot.
#define OSW_FACING_BACK (1<<3)					//!Only fires backwards(?). Uses firing arc angle.
#define OSW_FACING_FRONT (1<<1)					//!Only fires forward. Uses firing arc angle.
#define OSW_FACING_OMNI (1<<0)					//!Standard 360° aim. Mostly for ease-of-read purpose.
#define OSW_FACING_SIDES (1<<2)					//!Only fires towards the sides. Uses firing arc angle for both sides.
#define OSW_SIDE_AIMING_BEAM (1<<1)				//!Aiming beam specialized for broadsides, only points in a single angle per side.
#define OVERMAP_USER_ROLE_GUNNER (1<<1)
#define OVERMAP_USER_ROLE_OBSERVER (1<<3)
#define OVERMAP_USER_ROLE_PILOT (1<<0)
#define OVERMAP_USER_ROLE_SECONDARY_GUNNER (1<<2)
#define PASSCLOSEDTURF	(1<<5)
#define PREFTOGGLE_SOUND_AMBIENCE				(1<<2)
#define PREFTOGGLE_SOUND_ANNOUNCEMENTS			(1<<11)
#define RADIO_CHANNEL_MUNITIONS "Munitions" //NSV13 - Munitions department
#define R_IDEAL_GAS_EQUATION	8.31	//! kPa*L/(K*mol)
#define SHIP_DESTROYED 29
#define SHIP_RESUPPLYING_HEAVY (1<<1)	//!If enabled, currently busy resupplying heavy weapons (shots, torp, missiles)
#define SHIP_RESUPPLYING_LIGHT (1<<0)	//!If enabled, currently busy resupplying light weapons (light shots)
#define SLIME_EVOLUTION_THRESHOLD 10
#define STARSYSTEM_NO_ANOMALIES 1<<0	//Prevents Anomalies Spawning
#define STARSYSTEM_NO_ASTEROIDS 1<<1	//Prevents Asteroids Spawning
#define STARSYSTEM_NO_WORMHOLE 1<<2		//Prevents Incoming Wormholes
#define STRONG_INTERDICT (1<<1)													//! The "true" interdiction, disrupts drive fields to the point any shift is impossible.
#define SUCCESSFUL_UNFASTEN 2
#define TECHWEB_POINT_TYPE_WORMHOLE "Wormhole Research"
#define TRAIT_FREERUNNING		"freerunning"
#define TRAIT_GFORCE_WEAKNESS "gravity-weakness"
#define TRAIT_NODAMPENERS "nodampeners" //! Prevents a ship with this trait from using dampeners.
#define TRAIT_SEASICK			"seasick"
#define WEAK_INTERDICT (1<<0)													//! Not a "true" interdiction in that it disrupts the drive field, relies on scrambling calculations and rendering a jump too dangerous to execute.
#define ZTRAITS_BOARDABLE_SHIP list(ZTRAIT_LINKAGE = SELFLOOPING, ZTRAIT_STATION = FALSE, ZTRAIT_BOARDABLE = TRUE) //NSV13
#define ZTRAITS_OVERMAP list(ZTRAIT_LINKAGE = SELFLOOPING, ZTRAIT_OVERMAP = TRUE, ZTRAIT_BOARDABLE = FALSE, ZTRAIT_CENTCOM = TRUE) //NSV13
#define ZTRAIT_BOARDABLE "Boardable Ship" //NSV13 - System defines blah
#define ZTRAIT_OVERMAP "Overmap" //NSV13

#ifndef ATMOS_GAS_MONITOR_SENSOR_NUCLEIUM
#define ATMOS_GAS_MONITOR_SENSOR_NUCLEIUM "nucleium_sensor"
#endif
#ifndef ATMOS_GAS_MONITOR_INPUT_NUCLEIUM
#define ATMOS_GAS_MONITOR_INPUT_NUCLEIUM "nucleium_in"
#endif
#ifndef ATMOS_GAS_MONITOR_OUTPUT_NUCLEIUM
#define ATMOS_GAS_MONITOR_OUTPUT_NUCLEIUM "nucleium_out"
#endif

// NSV/Beestation atmospherics defines missing from TGMC
#define TCRYO					225		//! -48.15degC
#define MOLES_CELLSTANDARD		(ONE_ATMOSPHERE*CELL_VOLUME/(T20C*R_IDEAL_GAS_EQUATION))	//! moles in a 2.5 m^3 cell at 101.325 Pa and 20 degC
#define M_CELL_WITH_RATIO		(MOLES_CELLSTANDARD * 0.005) //! compared against for superconductivity
#define MOLES_O2STANDARD		(MOLES_CELLSTANDARD*O2STANDARD)	//! O2 standard value (21%)
#define MOLES_N2STANDARD		(MOLES_CELLSTANDARD*N2STANDARD)	//! N2 standard value (79%)
#define BREATH_VOLUME			0.5		//! liters in a normal breath
#define BREATH_PERCENTAGE		(BREATH_VOLUME/CELL_VOLUME)					//! Amount of air to take a from a tile
#define EXCITED_GROUP_BREAKDOWN_CYCLES				3		//! number of FULL air controller ticks before an excited group breaks down (averages gas contents across turfs)
#define EXCITED_GROUP_DISMANTLE_CYCLES				15		//! number of FULL air controller ticks before an excited group dismantles and removes its turfs from active
#define MINIMUM_AIR_RATIO_TO_SUSPEND				0.1		//! Ratio of air that must move to/from a tile to reset group processing
#define MINIMUM_AIR_RATIO_TO_MOVE					0.05	//! Minimum ratio of air that must move to/from a tile
#define MINIMUM_AIR_TO_SUSPEND						(MOLES_CELLSTANDARD*MINIMUM_AIR_RATIO_TO_SUSPEND)	//! Minimum amount of air that has to move before a group processing can be suspended
#define MINIMUM_MOLES_DELTA_TO_MOVE					(MOLES_CELLSTANDARD*MINIMUM_AIR_RATIO_TO_MOVE) //! Either this must be active or MINIMUM_TEMPERATURE_TO_MOVE
#define MINIMUM_TEMPERATURE_TO_MOVE					(T20C+100)			//! Either this must be active or MINIMUM_MOLES_DELTA_TO_MOVE
#define MINIMUM_TEMPERATURE_DELTA_TO_SUSPEND		4		//! Minimum temperature difference before group processing is suspended
#define MINIMUM_TEMPERATURE_DELTA_TO_CONSIDER		1		//! Minimum temperature difference before the gas temperatures are just set to be equal
#define MINIMUM_TEMPERATURE_FOR_SUPERCONDUCTION		(T20C+10)
#define MINIMUM_TEMPERATURE_START_SUPERCONDUCTION	(T20C+200)
#define WALL_HEAT_TRANSFER_COEFFICIENT		0.0
#define OPEN_HEAT_TRANSFER_COEFFICIENT		0.4
#define WINDOW_HEAT_TRANSFER_COEFFICIENT	0.1		//a hack for now
#define HEAT_CAPACITY_VACUUM				7000	//a hack to help make vacuums "cold", sacrificing realism for gameplay
#define FIRE_MINIMUM_TEMPERATURE_TO_SPREAD	(150+T0C)
#define FIRE_MINIMUM_TEMPERATURE_TO_EXIST	(100+T0C)
#define FIRE_SPREAD_RADIOSITY_SCALE			0.85
#define FIRE_GROWTH_RATE					40000	//For small fires
#define PLASMA_MINIMUM_BURN_TEMPERATURE		(100+T0C)
#define PLASMA_UPPER_TEMPERATURE			(1370+T0C)
#define PLASMA_OXYGEN_FULLBURN				10
#define MIN_TOXIC_GAS_DAMAGE				1
#define MAX_TOXIC_GAS_DAMAGE				10
#define MOLES_GAS_VISIBLE					0.25 //! Moles in a standard cell after which gases are visible
#define FACTOR_GAS_VISIBLE_MAX				20 //! moles_visible * FACTOR_GAS_VISIBLE_MAX = Moles after which gas is at maximum visibility
#define MOLES_GAS_VISIBLE_STEP				0.25 //! Mole step for alpha updates. This means alpha can update at 0.25, 0.5, 0.75 and so on
#define NO_REACTION		0
#define REACTING		1
#define STOP_REACTIONS 	2
#define HAZARD_HIGH_PRESSURE				550		//! This determines at what pressure the ultra-high pressure red icon is displayed. (This one is set as a constant)
#define WARNING_HIGH_PRESSURE				325		//! This determines when the orange pressure icon is displayed (it is 0.7 * HAZARD_HIGH_PRESSURE)
#define WARNING_LOW_PRESSURE				50		//! This is when the gray low pressure icon is displayed. (it is 2.5 * HAZARD_LOW_PRESSURE)
#define HAZARD_LOW_PRESSURE					20		//! This is when the black ultra-low pressure icon is displayed. (This one is set as a constant)
#define BODYTEMP_HEAT_DAMAGE_LIMIT			(BODYTEMP_NORMAL + 50) //! The limit the human body can take before it starts taking damage from heat.
#define BODYTEMP_COLD_DAMAGE_LIMIT			(BODYTEMP_NORMAL - 50) //! The limit the human body can take before it starts taking damage from coldness.
#define SPACE_HELM_MIN_TEMP_PROTECT			2.0		//! what min_cold_protection_temperature is set to for space-helmet quality headwear. MUST NOT BE 0.
#define SPACE_HELM_MAX_TEMP_PROTECT			1500	//! Thermal insulation works both ways /Malkevin
#define SPACE_SUIT_MIN_TEMP_PROTECT			2.0		//! what min_cold_protection_temperature is set to for space-suit quality jumpsuits or suits. MUST NOT BE 0.
#define SPACE_SUIT_MAX_TEMP_PROTECT			1500
#define FIRE_SUIT_MIN_TEMP_PROTECT			60		//! Cold protection for firesuits
#define FIRE_SUIT_MAX_TEMP_PROTECT			30000	//! what max_heat_protection_temperature is set to for firesuit quality suits. MUST NOT BE 0.
#define FIRE_HELM_MIN_TEMP_PROTECT			60		//! Cold protection for fire helmets
#define FIRE_HELM_MAX_TEMP_PROTECT			30000	//! for fire helmet quality items (red and white hardhats)
#define FIRE_IMMUNITY_MAX_TEMP_PROTECT	35000		//! what max_heat_protection_temperature is set to for firesuit quality suits and helmets. MUST NOT BE 0.
#define EMERGENCY_HELM_MIN_TEMP_PROTECT		2.0		//The helmet is pressurized with air from the oxygen tank. If they don't take damage from that they won't take damage here
#define EMERGENCY_SUIT_MIN_TEMP_PROTECT		237		//This is the approximate average temperature of Mt. Everest in the winter
#define HELMET_MIN_TEMP_PROTECT				160		//For normal helmets
#define HELMET_MAX_TEMP_PROTECT				600		//For normal helmets
#define ARMOR_MIN_TEMP_PROTECT				160		//For armor
#define ARMOR_MAX_TEMP_PROTECT				600		//For armor
#define GLOVES_MIN_TEMP_PROTECT				2.0		//For some gloves (black and)
#define GLOVES_MAX_TEMP_PROTECT				1500	//For some gloves
#define SHOES_MIN_TEMP_PROTECT				2.0		//For gloves
#define SHOES_MAX_TEMP_PROTECT				1500	//For gloves
#define PRESSURE_DAMAGE_COEFFICIENT			4		//! The amount of pressure damage someone takes is equal to (pressure / HAZARD_HIGH_PRESSURE)*PRESSURE_DAMAGE_COEFFICIENT, with the maximum of MAX_PRESSURE_DAMAGE
#define MAX_HIGH_PRESSURE_DAMAGE			4
#define LOW_PRESSURE_DAMAGE					4		//! The amount of damage someone takes when in a low pressure area (The pressure threshold is so low that it doesn't make sense to do any calculations, so it just applies this flat value).
#define COLD_SLOWDOWN_FACTOR				20		//! Humans are slowed by the difference between bodytemp and BODYTEMP_COLD_DAMAGE_LIMIT divided by this
#define MAX_OUTPUT_PRESSURE					4500
#define MAX_TRANSFER_RATE 200
#define VOLUME_PUMP_LEAK_AMOUNT 0.1
#define TANK_MELT_TEMPERATURE				1000000	//! temperature in kelvins at which a tank will start to melt
#define TANK_LEAK_PRESSURE					(30.*ONE_ATMOSPHERE)	//! temperature in kelvins at which a tank starts leaking
#define TANK_RUPTURE_PRESSURE				(35.*ONE_ATMOSPHERE)	//! temperature in kelvins at which a tank spills all contents into atmosphere
#define TANK_FRAGMENT_PRESSURE				(40.*ONE_ATMOSPHERE)	//! temperature in kelvins at which a tank creates a boom 3x3 base explosion
#define TANK_FRAGMENT_SCALE	    			(6.*ONE_ATMOSPHERE)		//! +1 for each SCALE kPa aboe threshold
#define TANK_MAX_RELEASE_PRESSURE 			(ONE_ATMOSPHERE*3)
#define TANK_MIN_RELEASE_PRESSURE 			0
#define TANK_DEFAULT_RELEASE_PRESSURE 		17
#define ATMOS_PASS_NO 0
#define ATMOS_PASS_PROC -1 //ask CanAtmosPass()
#define ATMOS_PASS_DENSITY -2 //just check density
#define ATMOS_ADJACENT_ANY					(1<<0)
#define ATMOS_ADJACENT_FIRELOCK				(1<<1)
#define TURFS_CAN_SHARE(T1, T2) (LAZYACCESS(T2.atmos_adjacent_turfs, T1) || LAZYLEN(T1.atmos_adjacent_turfs & T2.atmos_adjacent_turfs))
#define TURF_SHARES(T) (LAZYLEN(T.atmos_adjacent_turfs))
#define CANATMOSPASS(A, O, V) ( A.CanAtmosPass == ATMOS_PASS_PROC ? A.CanAtmosPass(O, V) : ( A.CanAtmosPass == ATMOS_PASS_DENSITY ? !A.density : A.CanAtmosPass ) )
#define TURF_TEMPERATURE(temperature) "TEMP=[temperature]"
#define OPENTURF_DEFAULT_ATMOS		"o2=22;n2=82;TEMP=293.15" //the default air mix that open turfs spawn
#define OPENTURF_LOW_PRESSURE		"o2=14;n2=30;TEMP=293.15"
#define TCOMMS_ATMOS				"n2=100;TEMP=80" //-193,15°C telecommunications. also used for xenobiology slime killrooms
#define AIRLESS_ATMOS				"TEMP=2.7" //space
#define FROZEN_ATMOS				"o2=22;n2=82;TEMP=180" //-93.15°C snow and ice turfs
#define BURNMIX_ATMOS				"o2=100;plasma=200;TEMP=370" //used in the holodeck burn test program
#define ATMOS_TANK_N2O				"n2o=6000;TEMP=293.15"
#define ATMOS_TANK_CO2				"co2=50000;TEMP=293.15"
#define ATMOS_TANK_PLASMA			"plasma=70000;TEMP=293.15"
#define ATMOS_TANK_O2				"o2=100000;TEMP=293.15"
#define ATMOS_TANK_N2				"n2=100000;TEMP=293.15"
#define ATMOS_TANK_BZ				"bz=100000;TEMP=293.15"
#define ATMOS_TANK_PLUOXIUM			"pluox=100000;TEMP=293.15"
#define ATMOS_TANK_TRITIUM			"tritium=100000;TEMP=293.15"
#define ATMOS_TANK_AIRMIX			"o2=2644;n2=10580;TEMP=293.15"
#define MAXIMUM_LAVALAND_EQUIPMENT_EFFECT_PRESSURE 90 //! what pressure you have to be under to increase the effect of equipment meant for lavaland
#define MINIMUM_LAVALAND_EQUIPMENT_EFFECT_PRESSURE 25 //! what pressure you have to be over to increase the effect of equipment meant for lavaland
#define LAVALAND_DEFAULT_ATMOS		"o2=14;n2=5;co2=13;TEMP=300"
#define ATMOS_GAS_MONITOR_INPUT_O2 "o2_in"
#define ATMOS_GAS_MONITOR_OUTPUT_O2 "o2_out"
#define ATMOS_GAS_MONITOR_SENSOR_O2 "o2_sensor"
#define ATMOS_GAS_MONITOR_INPUT_TOX "tox_in"
#define ATMOS_GAS_MONITOR_OUTPUT_TOX "tox_out"
#define ATMOS_GAS_MONITOR_SENSOR_TOX "tox_sensor"
#define ATMOS_GAS_MONITOR_INPUT_AIR "air_in"
#define ATMOS_GAS_MONITOR_OUTPUT_AIR "air_out"
#define ATMOS_GAS_MONITOR_SENSOR_AIR "air_sensor"
#define ATMOS_GAS_MONITOR_INPUT_MIX "mix_in"
#define ATMOS_GAS_MONITOR_OUTPUT_MIX "mix_out"
#define ATMOS_GAS_MONITOR_SENSOR_MIX "mix_sensor"
#define ATMOS_GAS_MONITOR_INPUT_N2O "n2o_in"
#define ATMOS_GAS_MONITOR_OUTPUT_N2O "n2o_out"
#define ATMOS_GAS_MONITOR_SENSOR_N2O "n2o_sensor"
#define ATMOS_GAS_MONITOR_INPUT_N2 "n2_in"
#define ATMOS_GAS_MONITOR_OUTPUT_N2 "n2_out"
#define ATMOS_GAS_MONITOR_SENSOR_N2 "n2_sensor"
#define ATMOS_GAS_MONITOR_INPUT_CO2 "co2_in"
#define ATMOS_GAS_MONITOR_OUTPUT_CO2 "co2_out"
#define ATMOS_GAS_MONITOR_SENSOR_CO2 "co2_sensor"
#define ATMOS_GAS_MONITOR_INPUT_INCINERATOR "incinerator_in"
#define ATMOS_GAS_MONITOR_OUTPUT_INCINERATOR "incinerator_out"
#define ATMOS_GAS_MONITOR_SENSOR_INCINERATOR "incinerator_sensor"
#define ATMOS_GAS_MONITOR_INPUT_TOXINS_LAB "toxinslab_in"
#define ATMOS_GAS_MONITOR_OUTPUT_TOXINS_LAB "toxinslab_out"
#define ATMOS_GAS_MONITOR_SENSOR_TOXINS_LAB "toxinslab_sensor"
#define ATMOS_GAS_MONITOR_LOOP_DISTRIBUTION "distro-loop_meter"
#define ATMOS_GAS_MONITOR_LOOP_ATMOS_WASTE "atmos-waste_loop_meter"
#define ATMOS_GAS_MONITOR_WASTE_ENGINE "engine-waste_out"
#define ATMOS_GAS_MONITOR_WASTE_ATMOS "atmos-waste_out"
#define ATMOS_GAS_MONITOR_INPUT_SM "sm_in"
#define ATMOS_GAS_MONITOR_OUTPUT_SM "sm_out"
#define ATMOS_GAS_MONITOR_SENSOR_SM "sm_sense"
#define INCINERATOR_TOXMIX_IGNITER 				"toxmix_igniter"
#define INCINERATOR_TOXMIX_VENT 				"toxmix_vent"
#define INCINERATOR_TOXMIX_DP_VENTPUMP			"toxmix_airlock_pump"
#define INCINERATOR_TOXMIX_AIRLOCK_SENSOR 		"toxmix_airlock_sensor"
#define INCINERATOR_TOXMIX_AIRLOCK_CONTROLLER 	"toxmix_airlock_controller"
#define INCINERATOR_TOXMIX_AIRLOCK_INTERIOR 	"toxmix_airlock_interior"
#define INCINERATOR_TOXMIX_AIRLOCK_EXTERIOR 	"toxmix_airlock_exterior"
#define INCINERATOR_ATMOS_IGNITER 				"atmos_incinerator_igniter"
#define INCINERATOR_ATMOS_MAINVENT 				"atmos_incinerator_mainvent"
#define INCINERATOR_ATMOS_AUXVENT 				"atmos_incinerator_auxvent"
#define INCINERATOR_ATMOS_DP_VENTPUMP			"atmos_incinerator_airlock_pump"
#define INCINERATOR_ATMOS_AIRLOCK_SENSOR 		"atmos_incinerator_airlock_sensor"
#define INCINERATOR_ATMOS_AIRLOCK_CONTROLLER	"atmos_incinerator_airlock_controller"
#define INCINERATOR_ATMOS_AIRLOCK_INTERIOR 		"atmos_incinerator_airlock_interior"
#define INCINERATOR_ATMOS_AIRLOCK_EXTERIOR 		"atmos_incinerator_airlock_exterior"
#define INCINERATOR_SYNDICATELAVA_IGNITER 				"syndicatelava_igniter"
#define INCINERATOR_SYNDICATELAVA_MAINVENT 				"syndicatelava_mainvent"
#define INCINERATOR_SYNDICATELAVA_AUXVENT 				"syndicatelava_auxvent"
#define INCINERATOR_SYNDICATELAVA_DP_VENTPUMP			"syndicatelava_airlock_pump"
#define INCINERATOR_SYNDICATELAVA_AIRLOCK_SENSOR 		"syndicatelava_airlock_sensor"
#define INCINERATOR_SYNDICATELAVA_AIRLOCK_CONTROLLER 	"syndicatelava_airlock_controller"
#define INCINERATOR_SYNDICATELAVA_AIRLOCK_INTERIOR 		"syndicatelava_airlock_interior"
#define INCINERATOR_SYNDICATELAVA_AIRLOCK_EXTERIOR	 	"syndicatelava_airlock_exterior"
#define GAS_CO2					"co2"
#define GAS_H2O					"water_vapor"
#define GAS_HYPERNOB			"nob"
#define GAS_NITROUS				"n2o"
#define GAS_NITRYL				"no2"
#define GAS_BZ					"bz"
#define GAS_STIMULUM			"stim"
#define GAS_FLAG_DANGEROUS		(1<<0)
#define GAS_FLAG_BREATH_PROC	(1<<1)
#define PIPENET_UPDATE_STATUS_DORMANT 0
#define PIPENET_UPDATE_STATUS_REACT_NEEDED 1
#define PIPENET_UPDATE_STATUS_RECONCILE_NEEDED 2
#define ATMOS_ALARM_SEVERE "severe"
#define ATMOS_ALARM_MINOR "minor"
#define ATMOS_ALARM_CLEAR "clear"
#define FASTDMM_PROP(...)
#define INSTANCE_VAR_DEFAULT 0
#define SSAIR_PIPENETS 1
#define SSAIR_ATMOSMACHINERY 2
#define ABOVE_HUD_LAYER 20
#define FIXED_COLOUR_PRIORITY 1
#define FREQ_ATMOS_STORAGE 1441
#define FREQ_ATMOS_CONTROL 1439
#define FREQ_AIRLOCK_CONTROL 1449
#define FREQ_ATMOS_ALARMS 1437
#define QUANTIZE(variable) (round(variable, 0.0000001))
#define AREA_USAGE_EQUIP 1
#define AREA_USAGE_LIGHT 2
#define AREA_USAGE_ENVIRON 3
#define ON_BLUEPRINTS 0
#define BE_CLOSE TRUE
#define INVESTIGATE_ATMOS "atmos"
#define STAGE_FIVE 5
#define MINIMUM_MOLE_COUNT 0.01
#define FUSION_TEMPERATURE_THRESHOLD 10000
#define EMP_PROTECT_SELF (1<<0)
#define COMSIG_VALVE_SET_OPEN "valve_set_open"
#define VV_HK_MODIFY_CANISTER_GAS "modify_canister_gas"
#define SSnetworks GLOB.ss_networks_stub
#define INTERACT_ATOM_ATTACK_HAND (1<<0)
#define INTERACT_ATOM_UI_INTERACT (1<<1)
#define ACCESS_ENGINE_EQUIP ACCESS_MARINE_ENGINEERING
#define COMSIG_SHIP_ARRIVED "ship_arrived"
#define COMSIG_SHIP_DEPARTED "ship_departed"
#define SHIP_VICTORY 1
#define CHANNEL_SHIP_ALERT 1016
#define CHANGETURF_INHERIT_AIR 0
#define CHANNEL_FTL_MANIFOLD 1014
#define PREVENT_CONTENTS_EXPLOSION_1 0
#define COMSIG_LOOPINGSOUND_PLAYED "loopingsound_played"

#define SSAIR_ACTIVETURFS 3
#define SSAIR_EXCITEDGROUPS 4
#define SSAIR_HOTSPOTS 5
#define VOLATILE_REACTION (1<<2)
#ifndef GASFIRE_LAYER
#define GASFIRE_LAYER (FLY_LAYER + 0.1)
#endif

#ifndef CELL_VOLUME
#define CELL_VOLUME 2500
#endif

#define RAD_PROTECT_CONTENTS (1<<0)
#define RAD_NO_CONTAMINATE (1<<1)
#define COMSIG_ATOM_RAD_ACT "atom_rad_act"
#define COMSIG_ATOM_RAD_PROBE "atom_rad_probe"
#define COMSIG_ATOM_RAD_CONTAMINATING "atom_rad_contaminating"
#define COMSIG_ATOM_RAD_WAVE_PASSING "atom_rad_wave_pass"
#define COMPONENT_BLOCK_RADIATION (1<<0)
#define COMPONENT_BLOCK_CONTAMINATION (1<<0)
#define COMPONENT_RAD_WAVE_HANDLED (1<<0)
#ifndef DT_PROB
#define DT_PROB(prob_per_second_percent, delta_time) (prob(100*(1-((1-(prob_per_second_percent/100))**delta_time))))
#endif
#define INVESTIGATE_RADIATION "radiation"


#define CHANNEL_REACTOR_ALERT 1011 // NSV: reactor alarm sound channel

// NSV (tg) temperature / pressure conversion helpers used by the RBMK
#define KELVIN_TO_CELSIUS(K) ((K) - T0C)
#define CELSIUS_TO_KELVIN(C) ((C) + T0C)
#define KPA_TO_PSI(KPA) ((KPA) * 0.14503773773)

// NSV particle accelerator: tg projectile pass flags that TGMC does not have (custom bits, only used by pass_flags_self / projectile_piercing)
#define PASSMOB (1<<19)
#define PASSMACHINE (1<<20)
#define PASSANOMALY (1<<21)
#define PASSBLOB (1<<22)
#define INVESTIGATE_ENGINES "engines"

#define MINIMUM_HEAT_CAPACITY 0.0003
#define OXYGEN_BURN_RATE_BASE				1.4
#define PLASMA_BURN_RATE_DELTA				9
#define PLASMA_MINIMUM_OXYGEN_NEEDED		2
#define PLASMA_MINIMUM_OXYGEN_PLASMA_RATIO	30
#define FIRE_CARBON_ENERGY_RELEASED			100000	//! Amount of heat released per mole of burnt carbon into the tile
#define FIRE_HYDROGEN_ENERGY_RELEASED		280000  //! Amount of heat released per mole of burnt hydrogen and/or tritium(hydrogen isotope)
#define FIRE_PLASMA_ENERGY_RELEASED			3000000	//! Amount of heat released per mole of burnt plasma into the tile
#define WATER_VAPOR_FREEZE					200
#define N2O_DECOMPOSITION_MIN_ENERGY		1400
#define N2O_DECOMPOSITION_ENERGY_RELEASED	200000
#define NITRYL_FORMATION_ENERGY				100000
#define TRITIUM_BURN_OXY_FACTOR				100
#define TRITIUM_BURN_TRIT_FACTOR			10
#define TRITIUM_BURN_RADIOACTIVITY_FACTOR	50000 	//! The neutrons gotta go somewhere. Completely arbitrary number.
#define TRITIUM_MINIMUM_RADIATION_ENERGY	0.1  	//! minimum 0.01 moles trit or 10 moles oxygen to start producing rads
#define MINIMUM_TRIT_OXYBURN_ENERGY 		2000000	//! This is calculated to help prevent singlecap bombs(Overpowered tritium/oxygen single tank bombs)
#define SUPER_SATURATION_THRESHOLD			96
#define STIMULUM_HEAT_SCALE					100000
#define STIMULUM_FIRST_RISE					0.65
#define STIMULUM_FIRST_DROP					0.065
#define STIMULUM_SECOND_RISE				0.0009
#define STIMULUM_ABSOLUTE_DROP				0.00000335
#define REACTION_OPPRESSION_THRESHOLD		5
#define NOBLIUM_FORMATION_ENERGY			2e9 	//! 1 Mole of Noblium takes the planck energy to condense.
#define STIM_BALL_GAS_AMOUNT				5
#define NOBLIUM_RESEARCH_AMOUNT				1000
#define BZ_RESEARCH_SCALE					4
#define BZ_RESEARCH_MAX_AMOUNT				400
#define STIMULUM_RESEARCH_AMOUNT			50
#define FUSION_ENERGY_THRESHOLD				3e9 	//! Amount of energy it takes to start a fusion reaction
#define FUSION_MOLE_THRESHOLD				250 	//! Mole count required (tritium/plasma) to start a fusion reaction
#define FUSION_TRITIUM_CONVERSION_COEFFICIENT 0.002
#define INSTABILITY_GAS_POWER_FACTOR 		3
#define FUSION_TRITIUM_MOLES_USED  			1
#define PLASMA_BINDING_ENERGY  				20000000
#define TOROID_CALCULATED_THRESHOLD			5.96	//! changing it by 0.1 generally doubles or halves fusion temps
#define PARTICLE_CHANCE_CONSTANT 			(-20000000)
#define FUSION_INSTABILITY_ENDOTHERMALITY   2
#define FUSION_SCALE_DIVISOR				10		//! Used to be Pi
#define FUSION_MINIMAL_SCALE				50
#define FUSION_SLOPE_DIVISOR				1250	//! This number is probably the safest number to change
#define FUSION_ENERGY_TRANSLATION_EXPONENT	1.25	//! This number is probably the most dangerous number to change
#define FUSION_BASE_TEMPSCALE				6       //! This number is responsible for orchestrating fusion temperatures
#define FUSION_RAD_MIDPOINT					15		//! If you decrease this by one, the fusion rads will *triple* and vice versa
#define FUSION_MIDDLE_ENERGY_REFERENCE		1e6		//! This number is deceptively dangerous; sort of tied to TOROID_CALCULATED_THRESHOLD
#define FUSION_BUFFER_DIVISOR				1		//! Increase this to cull unrobust fusions faster
#define RAD_BACKGROUND_RADIATION 9 					// How much radiation is harmless to a mob
#define RAD_MOB_COEFFICIENT 0.20					// Radiation applied is multiplied by this
#define RAD_MOB_SKIN_PROTECTION ((1/RAD_MOB_COEFFICIENT)+RAD_BACKGROUND_RADIATION)
#define RAD_LOSS_PER_TICK 0.5
#define RAD_TOX_COEFFICIENT 0.08					// Toxin damage per tick coefficient
#define RAD_OVERDOSE_REDUCTION 0.000001				// Coefficient to the reduction in applied rads once the thing, usualy mob, has too much radiation
#define RAD_BURN_THRESHOLD 1000						// Applied radiation must be over this to burn
#define RAD_MOB_SAFE 500							// How much stored radiation in a mob with no ill effects
#define RAD_MOB_HAIRLOSS 800						// How much stored radiation to check for hair loss
#define RAD_MOB_MUTATE 1250							// How much stored radiation to check for mutation
#define RAD_MOB_VOMIT 2000							// The amount of radiation to check for vomitting
#define RAD_MOB_VOMIT_PROB 1						// Chance per tick of vomitting
#define RAD_MOB_KNOCKDOWN 2000						// How much stored radiation to check for stunning
#define RAD_MOB_KNOCKDOWN_PROB 1					// Chance of knockdown per tick when over threshold
#define RAD_MOB_KNOCKDOWN_AMOUNT 3					// Amount of knockdown when it occurs
#define RAD_NO_INSULATION 1.0						// For things that shouldn't become irradiated for whatever reason
#define RAD_VERY_LIGHT_INSULATION 0.9				// What girders have
#define RAD_LIGHT_INSULATION 0.8
#define RAD_MEDIUM_INSULATION  0.7					// What common walls have
#define RAD_HEAVY_INSULATION 0.6					// What reinforced walls have
#define RAD_EXTREME_INSULATION 0.5					// What rad collectors have
#define RAD_FULL_INSULATION 0						// What depleted uranium windows have
#define RAD_CONTAMINATION_BUDGET_SIZE 0.2			// Mob and non-mob budgets each gets a share from the radiation as large as this;
#define RAD_DISTANCE_COEFFICIENT 1					// Lower means further rad spread
#define RAD_DISTANCE_COEFFICIENT_COMPONENT_MULTIPLIER 2	// Radiation components have additional penalty at distance coefficient
#define RAD_HALF_LIFE 90							// The half-life of contaminated objects
#define RAD_WAVE_MINIMUM 10							// Radiation waves with less than this amount of power stop spreading
#define RAD_COMPONENT_MINIMUM 1						// To ensure slow contamination
#define RAD_CONTAMINATION_STR_COEFFICIENT (1 / RAD_HALF_LIFE / 8 * RAD_DISTANCE_COEFFICIENT_COMPONENT_MULTIPLIER ** 2)
#define RAD_GEIGER_RC 4								// RC-constant for the LP filter for geiger counters. See #define LPFILTER for more info.
#define RAD_GEIGER_GRACE_PERIOD 4					// How many seconds after we last detect a radiation pulse until we stop blipping
