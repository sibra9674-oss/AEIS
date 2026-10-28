SUBSYSTEM_DEF(spacecombat)
	name = "Space Combat"
	priority = FIRE_PRIORITY_DEFAULT
	wait = 0.1 SECONDS
	var/list/datum/space_ship/ships = list()
	var/datum/space_ship/player_ship
	var/list/datum/ship_projectile/projectiles = list()
	/// z-level the combat is drawn on; created the first time somebody looks at it.
	var/space_z = 0
	/// Mobs whose camera is on the player ship: mob -> console they are using.
	var/list/observers = list()
	/// mob -> its "leave ship view" action button
	var/list/leave_actions = list()
	var/list/catchers = list()
	/// Camera reference: the player ship position. Everything is drawn relative to it.
	var/ref_x = 0
	var/ref_y = 0
	var/list/obj/effect/space_combat_visual/dust/dust = list()

/datum/controller/subsystem/spacecombat/Initialize()
	player_ship = new /datum/space_ship/player
	ships += player_ship
	return SS_INIT_SUCCESS

/datum/controller/subsystem/spacecombat/fire(resumed)
	// Nothing to simulate while only the idle player ship exists.
	if(length(ships) <= 1 && !length(projectiles) && !length(observers) && (!player_ship || player_ship.speed() < 0.01 && player_ship.throttle <= 0))
		return
	var/dt = wait / (1 SECONDS)
	for(var/datum/ship_projectile/projectile AS in projectiles)
		if(!projectile.process_projectile(dt))
			qdel(projectile)
	for(var/datum/space_ship/ship AS in ships)
		ship.process_ship(dt)
	refresh_visuals()
	for(var/mob/observer AS in observers)
		if(!observer.client || observer.incapacitated() || get_dist(observer, observers[observer]) > 1)
			stop_observing(observer)

/// Redraws everything relative to the player ship. Called once per tick after the simulation step.
/datum/controller/subsystem/spacecombat/proc/refresh_visuals()
	if(!space_z || !player_ship)
		return
	ref_x = player_ship.pos_x
	ref_y = player_ship.pos_y
	for(var/datum/space_ship/ship AS in ships)
		ship.update_visual()
	for(var/datum/ship_projectile/projectile AS in projectiles)
		projectile.visual?.place_at(projectile.pos_x, projectile.pos_y, projectile.angle)
	for(var/obj/effect/space_combat_visual/dust/star AS in dust)
		star.refresh()

/datum/controller/subsystem/spacecombat/proc/create_dust()
	if(length(dust))
		return
	for(var/i in 1 to 70)
		var/obj/effect/space_combat_visual/dust/star = new(null)
		star.wx = rand(-SC_DUST_HALF_X * 10, SC_DUST_HALF_X * 10) / 10
		star.wy = rand(-SC_DUST_HALF_Y * 10, SC_DUST_HALF_Y * 10) / 10
		star.depth = rand(15, 85) / 100
		star.alpha = 90 + round(star.depth * 160)
		dust += star
		star.refresh()

/// Half-size of the space z-level in km, minus a margin for the camera.
/datum/controller/subsystem/spacecombat/proc/map_bound_km()
	return (min(world.maxx, world.maxy) / 2 - 10) * 32 / SC_PX_PER_KM

/// Creates the space z-level (once) and sprites for every ship.
/datum/controller/subsystem/spacecombat/proc/ensure_space_z()
	if(space_z)
		return TRUE
	var/datum/space_level/new_level = SSmapping.add_new_zlevel("Space Combat", list())
	if(!new_level)
		return FALSE
	space_z = new_level.z_value
	ref_x = player_ship.pos_x
	ref_y = player_ship.pos_y
	create_dust()
	for(var/datum/space_ship/ship AS in ships)
		ship.create_visual()
	for(var/datum/ship_projectile/projectile AS in projectiles)
		if(!projectile.visual)
			projectile.visual = new(null)
			projectile.visual.place_at(projectile.pos_x, projectile.pos_y, projectile.angle)
	return TRUE

/datum/controller/subsystem/spacecombat/proc/spawn_flash(km_x, km_y)
	if(!space_z)
		return
	var/obj/effect/space_combat_visual/flash/flash = new(null)
	flash.place_at(km_x, km_y, 0, FALSE)
	flash.play()

/// Sends a message (and optionally a camera shake) to everyone on the main ship.
/datum/controller/subsystem/spacecombat/proc/ship_announce(message, shake = 0)
	for(var/mob/player AS in GLOB.player_list)
		if(!is_mainship_level(player.z))
			continue
		to_chat(player, message)
		if(shake)
			shake_camera(player, 1 SECONDS, shake)

/// Plays a sound to everyone on the main ship (sound may be a list of files). Like NSV13's relay().
/datum/controller/subsystem/spacecombat/proc/ship_sound(sound_file, volume = 60)
	if(islist(sound_file))
		sound_file = pick(sound_file)
	for(var/mob/player AS in GLOB.player_list)
		if(is_mainship_level(player.z))
			SEND_SOUND(player, sound(sound_file, volume = volume))

/// Spawns hostile ships around the player ship. type_list is a list of ship types, defaults to two raiders.
/datum/controller/subsystem/spacecombat/proc/start_encounter(list/type_list)
	if(!player_ship || player_ship.destroyed)
		return
	if(!length(type_list))
		type_list = list(/datum/space_ship/hostile/raider, /datum/space_ship/hostile/raider)
	for(var/ship_type in type_list)
		var/datum/space_ship/hostile/enemy = new ship_type
		var/angle = rand(0, 359)
		var/dist = rand(18, 24)
		enemy.pos_x = player_ship.pos_x + sin(angle) * dist
		enemy.pos_y = player_ship.pos_y + cos(angle) * dist
		enemy.heading = sc_wrap_angle(angle + 180)
		enemy.desired_heading = enemy.heading
		ships += enemy
		enemy.update_visual()
		player_ship.add_log("Contact detected: [enemy.name].")
	ship_announce(span_userdanger("Red alert! Hostile contacts detected on long range sensors."))

/datum/controller/subsystem/spacecombat/proc/ship_destroyed(datum/space_ship/ship, killer_name)
	ship.destroyed = TRUE
	ships -= ship
	ship_sound(ship == player_ship ? 'sound/spacecombat/ship_explode.ogg' : pick('sound/spacecombat/explosionfar_5.ogg', 'sound/spacecombat/explosionfar_3.ogg'), 80)
	spawn_flash(ship.pos_x, ship.pos_y)
	for(var/datum/space_ship/other AS in ships)
		if(other.target == ship)
			other.target = null
	if(ship == player_ship)
		ship_announce(span_userdanger("CRITICAL: hull integrity lost! The ship is breaking apart!"), shake = 5)
		for(var/mob/observer AS in observers)
			stop_observing(observer)
		player_ship_destroyed()
		return
	player_ship.add_log("[ship.name] destroyed.")
	ship_announce(span_notice("Contact destroyed: [ship.name]."))
	var/hostiles = FALSE
	for(var/datum/space_ship/hostile/enemy in ships)
		hostiles = TRUE
		break
	if(!hostiles)
		ship_announce(span_notice("All hostile contacts neutralised."))
	qdel(ship)

/// Hook: called when the player ship's hull reaches zero. Hook round end / damage here.
/datum/controller/subsystem/spacecombat/proc/player_ship_destroyed()
	return

