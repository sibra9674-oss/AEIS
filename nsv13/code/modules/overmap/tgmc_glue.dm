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
/proc/nsv_start_overmap(ship_path = /obj/structure/overmap/nanotrasen/heavy_cruiser/starter)
	if(GLOB.nsv_main_overmap)
		return GLOB.nsv_main_overmap
	var/obj/structure/overmap/OM = instance_overmap(ship_path)
	if(!OM)
		return null
	GLOB.nsv_main_overmap = OM
	for(var/z in SSmapping.levels_by_trait(ZTRAIT_MARINE_MAIN_SHIP))
		var/datum/space_level/SL = SSmapping.z_list[z]
		SL.linked_overmap = OM
		OM.occupying_levels += SL
	message_admins("NSV overmap started: [OM] on Z[OM.z] (port build a9)")
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

// --- temporary debug: trace why a ship console does/doesn't open ---
/obj/machinery/computer/ship/attack_hand(mob/living/user)
	nsv_dbg(user, "[src] attack_hand: operational=[is_operational()] can_interact=[can_interact(user)] flags=[interaction_flags] linked=[linked] power=[machine_stat]")
	return ..()

/obj/machinery/computer/ship/interact(mob/user)
	nsv_dbg(user, "[src] interact reached")
	return ..()

ADMIN_VERB(nsv_console_info, R_DEBUG, "NSV: Console Info", "Lists every NSV ship console: type, location, power, linked ship (debug).", ADMIN_CATEGORY_DEBUG)
	to_chat(user, span_notice("NSV port build a9, debug=[GLOB.nsv_debug], overmap=[GLOB.nsv_main_overmap || "none"]"))
	var/count = 0
	for(var/obj/machinery/computer/ship/C in world)
		count++
		var/area/A = get_area(C)
		to_chat(user, span_notice("[C.type] at [C.x],[C.y],[C.z] area=[A?.name] operational=[C.is_operational()] stat=[C.machine_stat] flags=[C.interaction_flags] linked=[C.linked] has_overmap=[!!C.get_overmap()] z_linked=[!!SSmapping.z_list[C.z]?.linked_overmap]"))
	to_chat(user, span_notice("[count] ship consoles."))
