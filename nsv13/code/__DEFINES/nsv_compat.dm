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
#define LAVA_PROOF		(1<<0)
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
