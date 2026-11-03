/datum/tlv
	var/min2
	var/min1
	var/max1
	var/max2

/datum/tlv/New(min2 as num, min1 as num, max1 as num, max2 as num)
	if(min2) src.min2 = min2
	if(min1) src.min1 = min1
	if(max1) src.max1 = max1
	if(max2) src.max2 = max2

/datum/tlv/proc/get_danger_level(val as num)
	if(max2 != -1 && val >= max2)
		return 2
	if(min2 != -1 && val <= min2)
		return 2
	if(max1 != -1 && val >= max1)
		return 1
	if(min1 != -1 && val <= min1)
		return 1
	return 0

/datum/tlv/no_checks
	min2 = -1
	min1 = -1
	max1 = -1
	max2 = -1

/datum/tlv/dangerous
	min2 = -1
	min1 = -1
	max1 = 0.2
	max2 = 0.5
