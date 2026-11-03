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
	nsv_setup_map_wrap(OM.z)
	message_admins("NSV overmap started: [OM] on Z[OM.z] (port build a19)")
	return OM

#define NSV_WRAP_EDGE 2 //distance of the wrap trigger line from the map border
/// NSV overmap z-levels are SELFLOOPING: whatever reaches an edge (ships, projectiles) re-appears on the opposite side. We put trigger signals on a ring of turfs.
/proc/nsv_setup_map_wrap(z)
	var/list/ring = list()
	for(var/x in 1 to world.maxx)
		ring += locate(x, NSV_WRAP_EDGE, z)
		ring += locate(x, world.maxy - NSV_WRAP_EDGE + 1, z)
	for(var/y in 1 to world.maxy)
		ring += locate(NSV_WRAP_EDGE, y, z)
		ring += locate(world.maxx - NSV_WRAP_EDGE + 1, y, z)
	for(var/turf/T as anything in ring)
		if(T)
			T.RegisterSignal(T, COMSIG_ATOM_ENTERED, TYPE_PROC_REF(/turf, nsv_wrap_entered))

/turf/proc/nsv_wrap_entered(datum/source, atom/movable/crosser, atom/oldloc)
	SIGNAL_HANDLER
	if(!isovermap(crosser) && !isprojectile(crosser))
		return
	var/inner = NSV_WRAP_EDGE + 2
	var/nx = x
	var/ny = y
	if(x <= NSV_WRAP_EDGE)
		nx = world.maxx - inner
	else if(x >= world.maxx - NSV_WRAP_EDGE + 1)
		nx = inner
	if(y <= NSV_WRAP_EDGE)
		ny = world.maxy - inner
	else if(y >= world.maxy - NSV_WRAP_EDGE + 1)
		ny = inner
	var/turf/dest = locate(nx, ny, z)
	if(!dest || dest == src)
		return
	INVOKE_ASYNC(crosser, TYPE_PROC_REF(/atom/movable, forceMove), dest)

ADMIN_VERB(nsv_start_overmap_verb, R_DEBUG, "Start Overmap", "Creates the NSV overmap z-level and ship and links the TGMC ship z-levels to it.", "NSV")
	var/obj/structure/overmap/OM = nsv_start_overmap()
	if(OM)
		to_chat(user, span_notice("NSV overmap started: [OM] (Z[OM.z])."))
	else
		to_chat(user, span_warning("NSV overmap failed to start, check the runtime log."))

/// Beestation's /obj/proc/run_obj_armor, reading NSV's list-style `armor` (list("overmap_light" = 95, ...)).
/obj/structure/overmap/run_obj_armor(damage_amount, damage_type, damage_flag = 0, attack_dir, armour_penetration = 0)
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

ADMIN_VERB(nsv_console_info, R_DEBUG, "Console Info", "Lists every NSV ship console: type, location, power, linked ship (debug).", "NSV")
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
ADMIN_VERB(nsv_spawn_enemy, R_DEBUG, "Spawn Enemy Ship", "Spawns an AI overmap ship near the NSV ship.", "NSV")
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

ADMIN_VERB(nsv_spawn_fleet, R_DEBUG, "Spawn Enemy Fleet", "Spawns an AI fleet in the NSV ship's star system.", "NSV")
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

ADMIN_VERB(nsv_enemy_info, R_DEBUG, "Enemy Info", "Prints the state of every AI overmap ship (debug).", "NSV")
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

ADMIN_VERB(nsv_spawn_weapons, R_DEBUG, "Spawn Weapons", "Spawns ONE real NSV ship weapon machine with its ammo next to you (pick which).", "NSV")
	var/turf/start = get_turf(user.mob)
	if(!start || !SSmapping.level_trait(start.z, ZTRAIT_MARINE_MAIN_SHIP))
		to_chat(user, span_warning("Stand on the ship z-level first."))
		return
	var/list/choices = list(
		"PDC" = list(/obj/machinery/ship_weapon/pdc_mount/north, /obj/item/ammo_box/magazine/nsv/pdc),
		"Torpedo tube" = list(/obj/machinery/ship_weapon/torpedo_launcher/east, /obj/item/ship_weapon/ammunition/torpedo, /obj/item/ship_weapon/ammunition/torpedo),
		"MAC" = list(/obj/machinery/ship_weapon/mac),
		"Railgun" = list(/obj/machinery/ship_weapon/railgun, /obj/item/ship_weapon/ammunition/railgun_ammo),
		"Gauss" = list(/obj/machinery/ship_weapon/gauss_gun/north, /obj/item/ship_weapon/ammunition/gauss, /obj/item/ship_weapon/ammunition/gauss),
	)
	var/pick = tgui_input_list(user, "Which weapon?", "NSV spawn weapon", choices)
	if(!pick)
		return
	var/list/paths = choices[pick]
	var/turf/machine_turf = locate(start.x + 3, start.y + 2, start.z)
	var/turf/ammo_turf = locate(start.x + 1, start.y - 1, start.z)
	for(var/i in 1 to length(paths))
		var/path = paths[i]
		var/atom/created = new path(i == 1 ? machine_turf : ammo_turf)
		if(istype(created, /obj/machinery/ship_weapon))
			var/obj/machinery/ship_weapon/SW = created
			SW.get_ship() //do not wait for the 15 second link timer
	to_chat(user, span_notice("NSV: spawned [pick]."))

ADMIN_VERB(nsv_spawn_atmos_test, R_DEBUG, "Spawn Atmos Test", "Spawns an NSV gas canister next to you (pick the gas), or the basic set (plasma, oxygen, air, tritium) in a row. Break a plasma canister to watch it flood the room; use Atmos Ignite in the NSV tab to light it.", "NSV")
	var/turf/start = get_turf(user.mob)
	if(!start)
		return
	var/list/choices = list(
		"Basic set (plasma, oxygen, air, tritium)" = null,
		"Plasma" = /obj/machinery/portable_atmospherics/canister/toxins,
		"Oxygen" = /obj/machinery/portable_atmospherics/canister/oxygen,
		"Nitrogen" = /obj/machinery/portable_atmospherics/canister/nitrogen,
		"Air" = /obj/machinery/portable_atmospherics/canister/air,
		"Tritium" = /obj/machinery/portable_atmospherics/canister/tritium,
		"Carbon dioxide" = /obj/machinery/portable_atmospherics/canister/carbon_dioxide,
		"Nitrous oxide" = /obj/machinery/portable_atmospherics/canister/nitrous_oxide,
		"Water vapor" = /obj/machinery/portable_atmospherics/canister/water_vapor,
		"BZ" = /obj/machinery/portable_atmospherics/canister/bz,
	)
	var/pick = tgui_input_list(user, "Which canister?", "NSV atmos test", choices)
	if(!pick)
		return
	var/list/types = list()
	if(isnull(choices[pick]))
		types = list(
			/obj/machinery/portable_atmospherics/canister/toxins,
			/obj/machinery/portable_atmospherics/canister/oxygen,
			/obj/machinery/portable_atmospherics/canister/air,
			/obj/machinery/portable_atmospherics/canister/tritium,
		)
	else
		types = list(choices[pick])
	var/offset = 1
	for(var/path in types)
		var/turf/T = locate(start.x + offset, start.y, start.z)
		if(T)
			var/obj/machinery/portable_atmospherics/canister/can = new path(T)
			can.release_pressure = can.can_max_release_pressure //a canister only pushes gas until the room reaches its release pressure: at the default 1 atm it releases nothing into a pressurised room
		offset++
	to_chat(user, span_notice("NSV: spawned [length(types)] canister(s) to the east of you."))

ADMIN_VERB(nsv_atmos_ignite, R_DEBUG, "Atmos Ignite", "Ignites the gas on your turf (needs oxygen and fuel gas to actually burn).", "NSV")
	var/turf/open/T = get_turf(user.mob)
	if(!istype(T) || !T.air)
		to_chat(user, span_warning("No gas mixture here."))
		return
	var/fuel = T.air.get_moles(GAS_PLASMA) + T.air.get_moles(GAS_CONSTRICTED_PLASMA) + T.air.get_moles(GAS_TRITIUM)
	var/o2 = T.air.get_moles(GAS_O2)
	T.hotspot_expose(1000, CELL_VOLUME, 1)
	var/why = ""
	if(!T.active_hotspot)
		if(o2 < 0.5)
			why = " NOT lit: less than 0.5 mol oxygen."
		else if(fuel <= 0.5)
			why = " NOT lit: no fuel gas (needs more than 0.5 mol plasma or tritium on THIS tile)."
		else
			why = " NOT lit for an unknown reason (conditions look fine)."
	to_chat(user, span_notice("NSV: hotspot [T.active_hotspot ? "CREATED" : "not created"].[why] pressure=[round(T.air.return_pressure(), 0.1)] kPa, fuel=[round(fuel, 0.1)] mol, o2=[round(o2, 0.1)] mol, temp=[round(T.air.return_temperature(), 0.1)] K."))

ADMIN_VERB(nsv_atmos_check, R_DEBUG, "Atmos Check Here", "Prints the gas mixture of your turf.", "NSV")
	var/turf/open/T = get_turf(user.mob)
	if(!istype(T) || !T.air)
		to_chat(user, span_warning("No gas mixture here."))
		return
	var/list/lines = list("pressure=[round(T.air.return_pressure(), 0.1)] kPa  temp=[round(T.air.return_temperature(), 0.1)] K  active=[T.excited] group=[T.excited_group ? length(T.excited_group.turf_list) : 0]  adjacent=[length(T.atmos_adjacent_turfs)]")
	for(var/id in T.air.get_gases())
		lines += "[GLOB.gas_data.names[id] || id]: [round(T.air.get_moles(id), 0.01)] mol"
	to_chat(user, span_notice(jointext(lines, "\n")))

ADMIN_VERB(nsv_radiation_pulse, R_DEBUG, "Radiation Pulse", "Fires NSV's real radiation_pulse() from your turf. Walls insulate; mobs accumulate radiation and take toxin damage over time.", "NSV")
	var/intensity = tgui_input_number(user, "Intensity (50 = weak, 500 = strong, 3000 = reactor leak)", "NSV radiation", 500, 100000, 1)
	if(!intensity)
		return
	radiation_pulse(user.mob, intensity, RAD_DISTANCE_COEFFICIENT, TRUE)
	to_chat(user, span_notice("NSV: radiation_pulse([intensity]) from [get_turf(user.mob)]."))

ADMIN_VERB(nsv_spawn_rpd, R_DEBUG, "Spawn RPD", "Spawns an NSV Rapid Pipe Dispenser next to you.", "NSV")
	var/turf/T = get_turf(user.mob)
	if(!T)
		return
	new /obj/item/pipe_dispenser(T)
	to_chat(user, span_notice("NSV: spawned a Rapid Pipe Dispenser."))

ADMIN_VERB(nsv_radiation_check, R_DEBUG, "Radiation Check", "Shows how much accumulated radiation you carry.", "NSV")
	var/mob/living/L = user.mob
	if(!istype(L))
		return
	to_chat(user, span_notice("NSV: radiation=[round(L.radiation, 0.1)] (safe below [RAD_MOB_SAFE], toxin damage above)."))

/obj/item/ammo_box/Initialize(mapload)
	. = ..()
	stored_ammo = list()
	if(!start_empty && ammo_type)
		for(var/i in 1 to max_ammo)
			stored_ammo += new ammo_type(src)
	update_icon()

/obj/item/ammo_box/Destroy()
	QDEL_LIST(stored_ammo)
	return ..()

/// tg clears a mob's hand reference when the held item is forceMove()'d away (NSV weapons do `A.forceMove(src)` to take ammo from your hand); TGMC does not, leaving a ghost item in the hand.
/mob/Exited(atom/movable/gone, direction)
	. = ..()
	if(istype(gone, /obj/item) && (gone == r_hand || gone == l_hand))
		temporarilyRemoveItemFromInventory(gone, TRUE)

/// NSV ships have gravity: munitions must be moved on trolleys (ammunition/can_be_pulled refuses hand-dragging while there is gravity). TGMC has no gravity system.
/atom/proc/has_gravity(turf/T)
	return TRUE

/proc/iscyborg(mob/M)
	return istype(M, /mob/living/silicon/robot)

/// tg do_mob(user, target, time): timed action that is cancelled if either of them moves.
/proc/do_mob(mob/user, mob/target, time = 30, ...)
	return do_after(user, time, target = target)

/// tg machinery tool helpers (TGMC machinery only has default_deconstruction_crowbar). Return values follow tg: 0 can't, 1 failed, 2 done.
/obj/machinery/proc/default_deconstruction_screwdriver(mob/user, icon_state_open, icon_state_closed, obj/item/I)
	if((atom_flags & NODECONSTRUCT) || I.tool_behaviour != TOOL_SCREWDRIVER)
		return FALSE
	I.play_tool_sound(src, 50)
	if(!panel_open)
		panel_open = TRUE
		icon_state = icon_state_open
		to_chat(user, span_notice("You open the maintenance hatch of [src]."))
	else
		panel_open = FALSE
		icon_state = icon_state_closed
		to_chat(user, span_notice("You close the maintenance hatch of [src]."))
	return TRUE

/obj/machinery/proc/default_unfasten_wrench(mob/user, obj/item/I, time = 20)
	if((atom_flags & NODECONSTRUCT) || I.tool_behaviour != TOOL_WRENCH)
		return 0
	to_chat(user, span_notice("You begin [anchored ? "un" : ""]securing [src]..."))
	I.play_tool_sound(src, 50)
	if(!I.use_tool(src, user, time))
		return 1
	anchored = !anchored
	to_chat(user, span_notice("You [anchored ? "" : "un"]secure [src]."))
	playsound(src, 'sound/items/deconstruct.ogg', 50, TRUE)
	return 2
