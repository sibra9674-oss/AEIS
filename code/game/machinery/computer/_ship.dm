/// Helm + tactical console. TGUI dashboard; the real flying/shooting happens through the ship camera (see SSspacecombat.start_observing).
/obj/machinery/computer/spacecombat
	name = "tactical helm console"
	desc = "Controls the ship's thrusters and weapons."
	req_access = list(ACCESS_MARINE_BRIDGE)
	interaction_flags = INTERACT_MACHINE_TGUI
	/// Radar range in km shown on the dashboard.
	var/radar_range = 30
	/// Index of the weapon fired by clicking on the ship view.
	var/selected_weapon = 1
	/// helm = flying + PDC, tactical = status + weapons, dradis = radar only. The base type acts as a helm.
	var/role = SC_ROLE_HELM
	/// Dradis zoom (px per distance unit multiplier).
	var/zoom_factor = 2.4
	var/show_friendlies = 100
	var/show_enemies = 100

/// Weapons this console can operate.
/obj/machinery/computer/spacecombat/proc/my_weapons()
	var/datum/space_ship/ship = SSspacecombat.player_ship
	if(!ship)
		return list()
	return ship.weapons_for(role == SC_ROLE_TACTICAL ? SC_CTRL_GUNNER : SC_CTRL_PILOT)

/obj/machinery/computer/spacecombat/proc/current_weapon()
	var/list/mine = my_weapons()
	if(!length(mine))
		return null
	return mine[clamp(selected_weapon, 1, length(mine))]

/// Selects a weapon slot and gives feedback.
/obj/machinery/computer/spacecombat/proc/select_weapon(mob/user, index)
	var/list/mine = my_weapons()
	if(index < 1 || index > length(mine))
		return
	selected_weapon = index
	var/datum/ship_weapon/weapon = mine[index]
	to_chat(user, span_notice("Selected weapon: [weapon.name]."))
	SEND_SOUND(user, sound('sound/spacecombat/rcs.ogg', volume = 30))

/obj/machinery/computer/spacecombat/ui_interact(mob/user, datum/tgui/ui)
	if(role != SC_ROLE_DRADIS && !(user in SSspacecombat.observers))
		SSspacecombat.start_observing(user, src)
	ui = SStgui.try_update_ui(user, src, ui)
	if(!ui)
		ui = new(user, src, role == SC_ROLE_DRADIS ? "SpaceCombatDradis" : role == SC_ROLE_TACTICAL ? "SpaceCombatTactical" : "SpaceCombatHelm", name)
		ui.open()

/obj/machinery/computer/spacecombat/ui_data(mob/user)
	. = list()
	var/datum/space_ship/ship = SSspacecombat.player_ship
	if(!ship)
		return
	.["destroyed"] = ship.destroyed
	.["name"] = ship.name
	.["hull"] = round(ship.hull)
	.["max_hull"] = ship.max_hull
	.["max_armour"] = ship.max_armour
	.["armour"] = list(
		list("name" = "Forward Port", "value" = round(ship.armour[SC_QUAD_FORE_PORT])),
		list("name" = "Forward Starboard", "value" = round(ship.armour[SC_QUAD_FORE_STARBOARD])),
		list("name" = "Aft Port", "value" = round(ship.armour[SC_QUAD_AFT_PORT])),
		list("name" = "Aft Starboard", "value" = round(ship.armour[SC_QUAD_AFT_STARBOARD])),
	)
	.["heading"] = round(ship.heading)
	.["desired_heading"] = round(ship.desired_heading)
	.["speed"] = round(ship.speed(), 0.1)
	.["max_speed"] = ship.speed_limit
	.["vel_x"] = round(ship.vel_x, 0.1)
	.["vel_y"] = round(ship.vel_y, 0.1)
	.["throttle"] = ship.throttle
	.["dampeners"] = ship.dampeners
	.["brakes"] = ship.brakes
	.["boost_ready"] = (world.time >= ship.next_maneuvre)
	.["radar_range"] = radar_range
	.["zoom_factor"] = zoom_factor
	.["zoom_factor_min"] = 0.6
	.["zoom_factor_max"] = 6
	.["showFriendlies"] = show_friendlies
	.["showEnemies"] = show_enemies
	var/list/blips = list(list("id" = REF(ship), "name" = ship.name, "x" = 0, "y" = 0, "alignment" = "nanotrasen", "colour" = "#008000", "opacity" = show_friendlies / 100))
	for(var/datum/space_ship/blip_ship AS in SSspacecombat.ships)
		if(blip_ship == ship)
			continue
		blips += list(list("id" = REF(blip_ship), "name" = blip_ship.name, "x" = round(blip_ship.pos_x - ship.pos_x, 0.1), "y" = round(blip_ship.pos_y - ship.pos_y, 0.1), "alignment" = "syndicate", "colour" = "#a30000", "opacity" = show_enemies / 100))
	.["ships"] = blips
	.["role"] = role
	.["observing"] = (user in SSspacecombat.observers) ? TRUE : FALSE
	.["is_admin"] = user.client?.holder ? TRUE : FALSE
	.["target_ref"] = ship.target ? REF(ship.target) : null
	var/list/contacts = list()
	for(var/datum/space_ship/contact AS in SSspacecombat.ships)
		if(contact == ship)
			continue
		var/brg = sc_bearing(ship.pos_x, ship.pos_y, contact.pos_x, contact.pos_y)
		contacts += list(list(
			"ref" = REF(contact),
			"name" = contact.name,
			"dx" = round(contact.pos_x - ship.pos_x, 0.1),
			"dy" = round(contact.pos_y - ship.pos_y, 0.1),
			"heading" = round(contact.heading),
			"hull" = round(contact.hull),
			"max_hull" = contact.max_hull,
			"range" = round(sc_distance(ship, contact), 0.1),
			"bearing" = round(brg),
			"rel_bearing" = round(sc_angle_diff(ship.heading, brg)),
		))
	.["contacts"] = contacts
	var/list/shots = list()
	for(var/datum/ship_projectile/projectile AS in SSspacecombat.projectiles)
		shots += list(list(
			"dx" = round(projectile.pos_x - ship.pos_x, 0.1),
			"dy" = round(projectile.pos_y - ship.pos_y, 0.1),
			"friendly" = projectile.from_player,
		))
	.["projectiles"] = shots
	var/list/weapon_data = list()
	var/index = 0
	for(var/datum/ship_weapon/weapon AS in my_weapons())
		index++
		var/aim = ship.target ? weapon.aim_at(ship, ship.target) : ship.heading
		weapon_data += list(list(
			"index" = index,
			"name" = weapon.name,
			"damage" = weapon.damage,
			"range" = weapon.range,
			"arc" = weapon.arc,
			"ammo" = weapon.ammo,
			"max_ammo" = weapon.max_ammo,
			"priority" = weapon.sort_priority,
			"controllers" = (weapon.control == SC_CTRL_GUNNER ? "Gunner" : weapon.control == SC_CTRL_PILOT ? "Pilot" : "Pilot, Gunner"),
			"cooldown_left" = weapon.cooldown_left(),
			"error" = weapon.fire_error(ship, aim),
			"selected" = (index == selected_weapon),
		))
	.["weapons"] = weapon_data
	.["log"] = ship.ship_log.Copy()

/obj/machinery/computer/spacecombat/ui_act(action, list/params, datum/tgui/ui, datum/ui_state/state)
	. = ..()
	if(.)
		return
	var/mob/user = ui.user
	var/datum/space_ship/ship = SSspacecombat.player_ship
	if(!ship || ship.destroyed)
		return
	var/list/allowed = list()
	switch(role)
		if(SC_ROLE_HELM)
			allowed = list("throttle", "turn", "heading", "brakes", "boost", "dampeners", "select_weapon", "fire", "view", "zoom_factor", "zoomin", "zoomout", "setZoom", "showFriendlies", "showEnemies")
		if(SC_ROLE_TACTICAL)
			allowed = list("select_weapon", "fire", "view", "spawn_raiders", "spawn_cruiser")
		if(SC_ROLE_DRADIS)
			allowed = list("zoom", "zoom_factor", "zoomin", "zoomout", "setZoom", "showFriendlies", "showEnemies")
	if(!(action in allowed))
		return
	switch(action)
		if("throttle")
			ship.throttle = clamp(text2num(params["value"]), 0, 100)
			. = TRUE
		if("turn")
			ship.helm_order = sc_wrap_angle(ship.desired_heading + clamp(text2num(params["value"]), -180, 180))
			. = TRUE
		if("heading")
			ship.helm_order = sc_wrap_angle(text2num(params["value"]))
			. = TRUE
		if("brakes")
			ship.brakes = !ship.brakes
			. = TRUE
		if("boost")
			if(!ship.boost(NORTH))
				to_chat(user, span_notice("Engines on cooldown to prevent overheat."))
			. = TRUE
		if("dampeners")
			ship.dampeners = !ship.dampeners
			. = TRUE
		if("zoom")
			radar_range = clamp(text2num(params["value"]), 15, 60)
			. = TRUE
		if("target")
			var/datum/space_ship/contact = locate(params["ref"])
			if(contact in SSspacecombat.ships)
				ship.target = contact
			. = TRUE
		if("select_weapon")
			select_weapon(user, text2num(params["index"]))
			. = TRUE
		if("fire")
			var/index = text2num(params["index"])
			var/list/mine = my_weapons()
			if(index >= 1 && index <= length(mine))
				var/datum/ship_weapon/weapon = mine[index]
				var/aim = ship.target ? weapon.aim_at(ship, ship.target) : ship.heading
				var/error = weapon.fire_error(ship, aim)
				if(error)
					to_chat(user, span_warning("[weapon.name]: [error]."))
				else
					weapon.fire(ship, aim)
			. = TRUE
		if("view")
			if(user in SSspacecombat.observers)
				SSspacecombat.stop_observing(user)
			else
				SSspacecombat.start_observing(user, src)
			. = TRUE
		if("spawn_raiders")
			if(user.client?.holder)
				SSspacecombat.start_encounter()
			. = TRUE
		if("spawn_cruiser")
			if(user.client?.holder)
				SSspacecombat.start_encounter(list(/datum/space_ship/hostile/cruiser))
			. = TRUE

/obj/machinery/computer/spacecombat/tactical
	name = "tactical console"
	desc = "Shows the ship's status and controls its heavy weapons."
	role = SC_ROLE_TACTICAL

/obj/machinery/computer/spacecombat/dradis
	name = "DRADIS console"
	desc = "Long range sensor display."
	role = SC_ROLE_DRADIS
