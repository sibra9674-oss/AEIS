/// A weapon mounted on a space ship. Fires real projectiles that travel across the space z-level.
/// Distances are in tiles, speeds in tiles/s.
/datum/ship_weapon
	var/name = "weapon"
	/// Damage per hit.
	var/damage = 20
	/// Max distance the projectile travels.
	var/range = 14
	/// Time between shots.
	var/cooldown = 3 SECONDS
	/// Half-angle of the firing arc relative to ship heading. 180 = full turret.
	var/arc = 180
	/// Random spread in degrees (+/-).
	var/spread = 3
	/// Projectile speed in tiles/s.
	var/proj_speed = 20
	/// Icon state of the projectile sprite.
	var/proj_state = "50cal"
	/// Remaining ammo, -1 = unlimited.
	var/ammo = -1
	var/max_ammo = -1
	/// Magazine capacity if different from the starting ammo.
	var/ammo_cap = 0
	var/next_fire = 0
	/// Shots per trigger pull.
	var/burst = 1
	/// Fires along the ship heading whatever the cursor says (NSV13 OSW_ALWAYS_FIRES_FORWARD).
	var/forward_only = FALSE
	/// Who can operate it: SC_CTRL_* bitflags.
	var/control = SC_CTRL_PILOT | SC_CTRL_GUNNER
	/// Higher = listed first (NSV13 sort_priority).
	var/sort_priority = 0
	/// AI prefers the weapon whose optimal range is closest (NSV13 optimal_range).
	var/optimal_range = 0
	var/miss_chance = 0
	var/max_miss_distance = 0
	var/fire_sound
	var/fire_volume = 60

/// Seconds until the weapon is ready again.
/datum/ship_weapon/New()
	. = ..()
	max_ammo = ammo
	if(max_ammo > 0 && ammo_cap)
		max_ammo = ammo_cap

/datum/ship_weapon/proc/cooldown_left()
	return max(0, round((next_fire - world.time) / (1 SECONDS), 0.1))

/// Aim angle (with target leading) from owner towards target.
/datum/ship_weapon/proc/aim_at(datum/space_ship/owner, datum/space_ship/target)
	var/dx = target.pos_x - owner.pos_x
	var/dy = target.pos_y - owner.pos_y
	var/flight_time = sqrt(dx * dx + dy * dy) / proj_speed
	var/lead_x = target.pos_x + target.vel_x * flight_time
	var/lead_y = target.pos_y + target.vel_y * flight_time
	return sc_bearing(owner.pos_x, owner.pos_y, lead_x, lead_y)

/// Returns null when the weapon can fire in the given direction, otherwise the reason it cannot.
/datum/ship_weapon/proc/fire_error(datum/space_ship/owner, aim_angle)
	if(world.time < next_fire)
		return "reloading"
	if(ammo == 0)
		return "out of ammo"
	if(!forward_only && abs(sc_angle_diff(owner.heading, aim_angle)) > arc)
		return "outside firing arc"
	return null

/// Fires in the given direction. Caller should have checked fire_error().
/datum/ship_weapon/proc/fire(datum/space_ship/owner, aim_angle)
	next_fire = world.time + cooldown
	if(ammo > 0)
		ammo = max(0, ammo - burst)
	if(forward_only)
		aim_angle = owner.heading
	for(var/i in 1 to burst)
		var/angle = sc_wrap_angle(aim_angle + (spread ? rand(-spread * 10, spread * 10) / 10 : 0))
		new /datum/ship_projectile(owner, src, angle)
	owner.add_log("[name] fired.")
	if(fire_sound)
		SSspacecombat.ship_sound(fire_sound, owner.is_player ? fire_volume : fire_volume * 0.5)
	return TRUE

// Numbers taken from NSV13 (overmap/weapons): damage, fire_delay, control flags, sort_priority.
/// "Naval Artillery" - the big MAC, fired by the gunner at the cursor.
/datum/ship_weapon/mac
	name = "Naval Artillery"
	ammo = 20
	ammo_cap = 40
	proj_state = "railgun"
	damage = 400
	range = 50
	cooldown = 3.5 SECONDS
	arc = 180
	spread = 0
	proj_speed = 40
	control = SC_CTRL_GUNNER
	sort_priority = 12
	optimal_range = 50
	fire_sound = 'sound/spacecombat/battleship_gun2.ogg'
	fire_volume = 80

/// "Torpedo tubes" - fired forward, homing on the locked target.
/datum/ship_weapon/torpedo
	name = "Torpedo tubes"
	damage = 250
	range = 45
	cooldown = 2 SECONDS
	arc = 180
	spread = 0
	proj_speed = 9
	proj_state = "torpedo"
	ammo = 8
	ammo_cap = 16
	forward_only = TRUE
	control = SC_CTRL_GUNNER
	sort_priority = 10
	fire_sound = 'sound/spacecombat/torpedo.ogg'
	fire_volume = 80

/// "Coaxial railguns" - pilot weapon, fixed forward.
/datum/ship_weapon/railgun
	name = "Coaxial railguns"
	proj_state = "railgun_ap"
	damage = 150
	range = 32
	cooldown = 1.5 SECONDS
	arc = 45
	spread = 0.5
	proj_speed = 35
	forward_only = TRUE
	control = SC_CTRL_PILOT
	sort_priority = 8
	optimal_range = 20
	fire_sound = 'sound/spacecombat/railgun_fire.ogg'
	fire_volume = 80

/// "PDC" - short range 3-round bursts, both stations.
/datum/ship_weapon/gauss
	name = "PDC"
	ammo = 600
	ammo_cap = 900
	proj_state = "pdc"
	damage = 10
	range = 12
	cooldown = 0.25 SECONDS
	burst = 3
	arc = 180
	spread = 4
	proj_speed = 30
	control = SC_CTRL_PILOT | SC_CTRL_GUNNER
	sort_priority = 4
	optimal_range = 10
	miss_chance = 33
	max_miss_distance = 6
	fire_sound = list('sound/spacecombat/pdc.ogg', 'sound/spacecombat/pdc2.ogg', 'sound/spacecombat/pdc3.ogg')
	fire_volume = 50

/// Hostile cannon.
/datum/ship_weapon/raider_gun
	name = "raider cannon"
	damage = 40
	range = 15
	cooldown = 2.5 SECONDS
	arc = 40
	spread = 5
	proj_speed = 16
	optimal_range = 15
	fire_sound = 'sound/spacecombat/battleship_gun2.ogg'
	fire_volume = 60
