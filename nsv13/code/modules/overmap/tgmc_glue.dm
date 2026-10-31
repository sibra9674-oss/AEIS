// TGMC <-> NSV13 glue. Everything that connects the ported NSV overmap core to TGMC lives here, so the NSV files stay as close to upstream as possible.

GLOBAL_VAR(nsv_main_overmap)
GLOBAL_VAR_INIT(nsv_debug, TRUE)

/// Temporary debug output for the port (set GLOB.nsv_debug to FALSE to silence).
/proc/nsv_dbg(mob/M, text)
	if(GLOB.nsv_debug && M)
		to_chat(M, span_notice("NSV DBG: [text]"))

/**
 * Creates the overmap Z-level (treadmill), spawns the player ship on it and links the TGMC ship Z-levels to it,
 * so consoles on the ship find their overmap through get_overmap(), exactly like NSV does for the "station" Zs.
 */
/proc/nsv_start_overmap(ship_path = /obj/structure/overmap/nanotrasen/frigate/starter) //Atlas-class frigate (handles far better than the Galactica / Hammerhead)
	if(GLOB.nsv_main_overmap)
		return GLOB.nsv_main_overmap
	var/obj/structure/overmap/OM = instance_overmap(ship_path)
	if(!OM)
		return null
	GLOB.nsv_main_overmap = OM
	var/datum/map_config/ship_cfg = SSmapping.configs?[SHIP_MAP]
	if(ship_cfg?.map_name)
		OM.name = ship_cfg.map_name
	if(!OM.dradis) //NSV mappers place a dradis console on the ship; we have none, so give the ship an integrated one (pilots/gunners get its UI on entering the ship view).
		var/obj/machinery/computer/ship/dradis/internal/large_ship/D = new(OM)
		D.linked = OM
		D.set_position(OM)
	for(var/z in SSmapping.levels_by_trait(ZTRAIT_MARINE_MAIN_SHIP))
		var/datum/space_level/SL = SSmapping.z_list[z]
		SL.linked_overmap = OM
		OM.occupying_levels += SL
	//NSV expects GLOB.teleportlocs (named station areas) and the ship's linked_areas for structure-crit explosions and botched repairs; TGMC has neither.
	for(var/area/A in world)
		var/turf/area_turf = locate(/turf) in A
		if(!area_turf || !SSmapping.level_trait(area_turf.z, ZTRAIT_MARINE_MAIN_SHIP))
			continue
		GLOB.teleportlocs[A.name] = A
		OM.linked_areas |= A
	message_admins("NSV overmap started: [OM] on Z[OM.z] (port build a19)")
	return OM

ADMIN_VERB(nsv_start_overmap_verb, R_DEBUG, "NSV: Start Overmap", "Creates the NSV overmap z-level and ship and links the TGMC ship z-levels to it.", ADMIN_CATEGORY_DEBUG)
	var/obj/structure/overmap/OM = nsv_start_overmap()
	if(OM)
		to_chat(user, span_notice("NSV overmap started: [OM] (Z[OM.z])."))
	else
		to_chat(user, span_warning("NSV overmap failed to start, check the runtime log."))

/// Beestation's /obj/proc/run_obj_armor, reading NSV's list-style `armor` (list("overmap_light" = 95, ...)).
/obj/structure/overmap/proc/run_obj_armor(damage_amount, damage_type, damage_flag = 0, attack_dir, armour_penetration = 0)
	if(damage_type != BRUTE && damage_type != BURN)
		return 0
	var/armor_protection = 0
	if(damage_flag && islist(armor))
		armor_protection = armor[damage_flag] || 0
	if(armor_protection)
		armor_protection = clamp(armor_protection - armour_penetration, min(armor_protection, 0), 100)
	return round(damage_amount * (100 - armor_protection) * 0.01, 0.1)

/**
 * TGMC only gives a player the default keybinds when their savefile is created/reset, so existing players have no
 * overmap keys bound. Called whenever someone starts piloting: adds any missing overmap defaults (ahead of other binds on that key).
 */
/proc/nsv_ensure_keybinds(client/C)
	if(!C?.prefs)
		return
	var/changed = FALSE
	for(var/key in GLOB.hotkey_keybinding_list_by_key)
		for(var/kb_name in GLOB.hotkey_keybinding_list_by_key[key])
			if(!findtext(kb_name, "overmap_", 1, 9))
				continue
			var/list/bound = C.prefs.key_bindings[key]
			if(kb_name in bound)
				continue
			if(!islist(bound))
				bound = list()
			C.prefs.key_bindings[key] = list(kb_name) + bound
			changed = TRUE
	if(changed)
		C.prefs.save_keybinds()
		to_chat(C, span_notice("NSV: ship control keybinds were added to your keybindings."))

ADMIN_VERB(nsv_console_info, R_DEBUG, "NSV: Console Info", "Lists every NSV ship console: type, location, power, linked ship (debug).", ADMIN_CATEGORY_DEBUG)
	to_chat(user, span_notice("NSV port build a19, debug=[GLOB.nsv_debug], overmap=[GLOB.nsv_main_overmap || "none"]"))
	var/count = 0
	for(var/obj/machinery/computer/ship/C in world)
		count++
		var/area/A = get_area(C)
		to_chat(user, span_notice("[C.type] at [C.x],[C.y],[C.z] area=[A?.name] operational=[C.is_operational()] stat=[C.machine_stat] flags=[C.interaction_flags] linked=[C.linked] has_overmap=[!!C.get_overmap()] z_linked=[!!SSmapping.z_list[C.z]?.linked_overmap]"))
	to_chat(user, span_notice("[count] ship consoles."))

/// Everyone who should hear/see ship-wide relays: NSV fills mobs_in_ship from its own areas, which TGMC's ship doesn't have,
/// so we also include the people at the controls and everybody standing on the Z-levels linked to this ship.
/obj/structure/overmap/proc/nsv_ship_listeners()
	var/list/listeners = list()
	listeners |= mobs_in_ship
	listeners |= operators
	for(var/datum/space_level/SL as anything in occupying_levels)
		for(var/mob/M as anything in GLOB.player_list)
			if(M.client && M.z == SL.z_value)
				listeners |= M
	return listeners

// ---- admin helpers to test combat ----
ADMIN_VERB(nsv_spawn_enemy, R_DEBUG, "NSV: Spawn Enemy Ship", "Spawns an AI overmap ship near the NSV ship.", ADMIN_CATEGORY_DEBUG)
	var/obj/structure/overmap/OM = GLOB.nsv_main_overmap
	if(!OM)
		to_chat(user, span_warning("Start the overmap first (nsv_start_overmap)."))
		return
	var/list/choices = list()
	for(var/type in subtypesof(/obj/structure/overmap/syndicate/ai))
		choices["[type]"] = type
	var/pick = tgui_input_list(user, "Which ship?", "NSV spawn enemy", choices)
	if(!pick)
		return
	var/datum/star_system/sys = OM.current_system
	if(!sys)
		to_chat(user, span_warning("The NSV ship has no current star system."))
		return
	var/turf/T = locate(clamp(OM.x + 25, 5, world.maxx - 5), clamp(OM.y + 25, 5, world.maxy - 5), OM.z)
	var/path = choices[pick]
	var/obj/structure/overmap/enemy = new path(T)
	//NSV AI ships only work as part of a fleet (fighters and the swarm goal need one), so every lone ship gets a small fleet of its own.
	var/datum/fleet/F = new /datum/fleet()
	F.current_system = sys
	F.can_reinforce = FALSE
	sys.fleets += F
	var/role = "destroyers"
	if(enemy.ai_flags & AI_FLAG_SUPPLY)
		role = "supply"
	else if(enemy.mass <= MASS_TINY)
		role = "fighters"
	else if(enemy.mass >= MASS_LARGE)
		role = "battleships"
	F.add_ship(enemy, role)
	message_admins("[key_name_admin(user)] spawned [enemy] at [T.x],[T.y],[T.z].")

ADMIN_VERB(nsv_spawn_fleet, R_DEBUG, "NSV: Spawn Enemy Fleet", "Spawns an AI fleet in the NSV ship's star system.", ADMIN_CATEGORY_DEBUG)
	var/obj/structure/overmap/OM = GLOB.nsv_main_overmap
	if(!OM?.current_system)
		to_chat(user, span_warning("Start the overmap first, and make sure the ship has a star system."))
		return
	var/list/choices = list()
	for(var/type in subtypesof(/datum/fleet))
		choices["[type]"] = type
	var/pick = tgui_input_list(user, "Which fleet?", "NSV spawn fleet", choices)
	if(!pick)
		return
	var/datum/star_system/sys = OM.current_system
	var/path = choices[pick]
	var/datum/fleet/F = new path(sys)
	F.current_system = sys
	sys.fleets += F
	F.assemble(sys)
	message_admins("[key_name_admin(user)] spawned fleet [F] in [sys].")

ADMIN_VERB(nsv_enemy_info, R_DEBUG, "NSV: Enemy Info", "Prints the state of every AI overmap ship (debug).", ADMIN_CATEGORY_DEBUG)
	var/obj/structure/overmap/OM = GLOB.nsv_main_overmap
	if(!OM)
		to_chat(user, span_warning("No NSV ship."))
		return
	to_chat(user, span_notice("PLAYER SHIP: [OM] at [OM.x],[OM.y],[OM.z] sys=[OM.current_system] angle=[OM.angle] vel=[OM.velocity?.a],[OM.velocity?.e] mass=[OM.mass] processing=[!!(OM.datum_flags & DF_ISPROCESSING)] sensor_range=[OM.dradis?.sensor_range] painted=[length(OM.target_painted)] lock=[OM.target_lock]"))
	var/n = 0
	for(var/obj/structure/overmap/E in GLOB.overmap_objects)
		if(E == OM)
			continue
		n++
		to_chat(user, span_notice("[E] ([E.type]) at [E.x],[E.y],[E.z] faction=[E.faction] ai=[E.ai_controlled] sys=[E.current_system] dist=[get_dist(E, OM)] processing=[!!(E.datum_flags & DF_ISPROCESSING)] pilot=[E.pilot] target=[E.last_target] move_mode=[E.move_mode] vel=[E.velocity?.a],[E.velocity?.e] visible_to_us=[OM.is_sensor_visible(E)] icon=[E.icon]:[E.icon_state] weapons=[length(E.overmap_weapon_datums)]"))
	to_chat(user, span_notice("[n] other overmaps."))

/// Debug: tells the main pilot why an overmap ship could not step into the next tile (throttled to once per second).
/proc/nsv_move_failed(obj/structure/overmap/OM, direction)
	var/static/last_report = 0
	if(world.time < last_report + 10)
		return
	last_report = world.time
	var/turf/T = get_step(OM, direction)
	var/list/blockers = list()
	if(T?.density)
		blockers += "turf [T.type]"
	for(var/atom/movable/AM in T)
		if(AM.density)
			blockers += "[AM] ([AM.type])"
	var/obj/structure/overmap/main = GLOB.nsv_main_overmap
	nsv_dbg(main?.pilot, "MOVE FAILED: [OM] dir=[direction] at [OM.x],[OM.y] vel=[OM.velocity?.a],[OM.velocity?.e] blocked_by=[english_list(blockers, "nothing dense found")]")

// ---- console sprites (NSV draws consoles from its own computer.dmi: base "computer" + a screen state + a keyboard state) ----
/obj/machinery/computer/ship
	icon = 'nsv13/icons/obj/computer.dmi'
	icon_state = "computer"

/obj/machinery/computer/ship/Initialize(mapload)
	screen_overlay = icon_screen //TGMC draws the screen from screen_overlay, NSV names it icon_screen
	. = ..()

/obj/machinery/computer/ship/update_overlays()
	. = ..()
	if(!icon_keyboard)
		return
	if(machine_stat & (BROKEN|DISABLED))
		return
	if(machine_stat & NOPOWER)
		. += mutable_appearance(icon, "[icon_keyboard]_off")
		return
	. += mutable_appearance(icon, icon_keyboard)

/// Debug for the red "ERROR" sprite: lists what is lying on / overlaying a damaged ship (throttled).
/proc/nsv_report_turf(obj/structure/overmap/OM)
	var/static/last_report = 0
	if(world.time < last_report + 20)
		return
	last_report = world.time
	var/obj/structure/overmap/main = GLOB.nsv_main_overmap
	var/list/found = list()
	for(var/atom/movable/AM in get_turf(OM))
		if(AM != OM)
			found += "[AM.type]"
	var/list/ovl = list()
	for(var/i in OM.overlays)
		ovl += "[i]"
	nsv_dbg(main?.pilot, "HIT: [OM] icon_state=[OM.icon_state] icon=[OM.icon] on_turf=[english_list(found, "nothing")] overlays=[english_list(ovl, "none")]")

/// nsv_dbg to the pilot of the main (player) ship, for debug lines raised by AI ships and projectiles.
/proc/nsv_dbg_main(text)
	var/static/last_line = 0
	if(world.time < last_line + 5) //PDC fire would flood the chat
		return
	last_line = world.time
	var/obj/structure/overmap/main = GLOB.nsv_main_overmap
	nsv_dbg(main?.pilot, text)

/// Debug: TGMC's "something broke" placeholder prop. Tells us when/where it gets created so the red ERROR sprite can be traced.
/obj/structure/prop/mainship/errorprop/Initialize(mapload)
	. = ..()
	var/list/near = list()
	for(var/obj/structure/overmap/OM in range(8, src))
		near += "[OM]"
	nsv_dbg_main("ERRORPROP created at [x],[y],[z] loc=[loc] mapload=[mapload] ships_near=[english_list(near, "none")] type=[type]")
	stack_trace("NSV debug: errorprop created at [x],[y],[z]")
