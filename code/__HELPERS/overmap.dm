// Space combat helpers (NSV13 overmap port). Units: tiles, tiles/s, degrees (0 = north, clockwise).
GLOBAL_LIST_INIT(sc_quadrant_names, list("forward starboard", "aft starboard", "aft port", "forward port"))

/// Wraps an angle into 0..360.
/proc/sc_wrap_angle(angle)
	while(angle >= 360)
		angle -= 360
	while(angle < 0)
		angle += 360
	return angle

/// Signed shortest difference from angle a to angle b, in -180..180.
/proc/sc_angle_diff(a, b)
	var/d = b - a
	while(d > 180)
		d -= 360
	while(d < -180)
		d += 360
	return d

/// Compass bearing from (x1,y1) to (x2,y2), 0 = north, clockwise.
/proc/sc_bearing(x1, y1, x2, y2)
	var/dx = x2 - x1
	var/dy = y2 - y1
	var/dist = sqrt(dx * dx + dy * dy)
	if(dist <= 0)
		return 0
	var/ang = arccos(dy / dist)
	if(dx < 0)
		ang = 360 - ang
	return sc_wrap_angle(ang)

/// Distance between two ships in km.
/proc/sc_distance(datum/space_ship/A, datum/space_ship/B)
	var/dx = B.pos_x - A.pos_x
	var/dy = B.pos_y - A.pos_y
	return sqrt(dx * dx + dy * dy)

/// Distance from point (px,py) to the segment (ax,ay)-(bx,by).
/proc/sc_point_segment_distance(px, py, ax, ay, bx, by)
	var/abx = bx - ax
	var/aby = by - ay
	var/len2 = abx * abx + aby * aby
	var/t = 0
	if(len2 > 0)
		t = clamp(((px - ax) * abx + (py - ay) * aby) / len2, 0, 1)
	var/cx = ax + abx * t
	var/cy = ay + aby * t
	return sqrt((px - cx) * (px - cx) + (py - cy) * (py - cy))

/proc/sc_dust_wrap(value, half)
	var/size = half * 2
	return value - size * round((value + half) / size, 1) 

