/// Anything drawn on the space z-level: ships, projectiles, flashes.
/obj/effect/space_combat_visual
	name = "contact"
	icon = 'icons/spacecombat/ships.dmi'
	anchored = TRUE
	layer = ABOVE_MOB_LAYER
	animate_movement = NO_STEPS
	mouse_opacity = MOUSE_OPACITY_TRANSPARENT
	/// Last angle applied, to avoid resetting the transform every tick.
	var/last_angle = -1
	var/sprite_w = 64
	var/sprite_h = 64

/// Moves the visual to the given position (units, relative to the centre of the space z-level) and rotates it.
/// Movement is animated over one simulation step so the client interpolates instead of stepping.
/// Camera-relative: the player ship always sits on the same tile (so the client camera never jitters), everything else moves around it.
/obj/effect/space_combat_visual/proc/place_at(km_x, km_y, angle, smooth = TRUE)
	place_rel(km_x - SSspacecombat.ref_x, km_y - SSspacecombat.ref_y, angle, smooth)

/obj/effect/space_combat_visual/proc/place_rel(km_x, km_y, angle, smooth = TRUE)
	var/space_z = SSspacecombat.space_z
	if(!space_z)
		return
	var/center_x = round(world.maxx / 2)
	var/center_y = round(world.maxy / 2)
	var/px = km_x * SC_PX_PER_KM
	var/py = km_y * SC_PX_PER_KM
	var/tile_dx = round(px / 32)
	var/tile_dy = round(py / 32)
	var/turf/new_turf = locate(center_x + tile_dx, center_y + tile_dy, space_z)
	if(!new_turf)
		return
	var/first_placement = !loc
	if(loc != new_turf)
		if(loc)
			// keep the on-screen position identical across the tile change, so the animation continues smoothly
			pixel_x += (loc.x - new_turf.x) * 32
			pixel_y += (loc.y - new_turf.y) * 32
		forceMove(new_turf)
	// centre the sprite (any size) on the tile centre
	var/target_x = px - tile_dx * 32 - (sprite_w / 2 - 16)
	var/target_y = py - tile_dy * 32 - (sprite_h / 2 - 16)
	var/matrix/target_transform = matrix().Turn(angle)
	last_angle = angle
	if(first_placement || !smooth)
		pixel_x = target_x
		pixel_y = target_y
		transform = target_transform
		return
	animate(src, pixel_x = target_x, pixel_y = target_y, transform = target_transform, time = SC_STEP, easing = LINEAR_EASING)

/obj/effect/space_combat_visual/flash
	name = "explosion"
	icon_state = "flash"

/obj/effect/space_combat_visual/flash/proc/play()
	animate(src, alpha = 0, time = 6)
	QDEL_IN(src, 7)

/// Drifting star dust: gives the feeling of speed. Positions wrap around the view.
/obj/effect/space_combat_visual/dust
	name = "stardust"
	icon_state = "dust"
	layer = BELOW_MOB_LAYER
	var/wx = 0
	var/wy = 0
	/// Parallax factor (how much of the ship movement it follows).
	var/depth = 0.5
	var/last_rx = 0
	var/last_ry = 0


/obj/effect/space_combat_visual/dust/proc/refresh()
	var/rx = sc_dust_wrap(wx - SSspacecombat.ref_x * depth, SC_DUST_HALF_X)
	var/ry = sc_dust_wrap(wy - SSspacecombat.ref_y * depth, SC_DUST_HALF_Y)
	var/jumped = (abs(rx - last_rx) > SC_DUST_HALF_X || abs(ry - last_ry) > SC_DUST_HALF_Y)
	last_rx = rx
	last_ry = ry
	place_rel(rx, ry, 0, !jumped)

