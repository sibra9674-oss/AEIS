/**
 * Ship Researcher: the mechanoids themselves.
 * Friendly machines grown from xenomorph neural cores. Nine variants, three per tier.
 * A ghost can pilot them. Without a pilot they run on autopilot: follow their creator, pick fights with xenos,
 * use their abilities by themselves and fall back when badly hurt. A mechanoid that loses its pilot is offered to ghosts again.
 */
/mob/living/simple_animal/hostile/mechanoid
	name = "mechanoid"
	desc = "A machine grown around the brain of a xenomorph."
	icon = 'icons/mob/mechanoids.dmi'
	pixel_x = -16
	icon_state = "scrapper"
	icon_living = "scrapper"
	icon_dead = "scrapper_dead"
	faction = FACTION_TERRAGOV
	wander = FALSE
	speak_emote = list("whirrs")
	response_help = "pats"
	response_disarm = "shoves"
	response_harm = "hits"
	attacktext = "slashes"
	attack_sound = 'sound/weapons/slash.ogg'
	deathmessage = "shuts down with a long whine."
	check_friendly_fire = TRUE
	///Bandwidth this mechanoid takes on the ship
	var/bandwidth_cost = 1
	///One line shown in the gestator about what this mechanoid does
	var/variant_desc = ""
	///The researcher who grew this mechanoid
	var/datum/weakref/master_ref
	///Ability buttons this mechanoid gets
	var/list/action_types = list()
	///Ability name -> world.time when it is ready again
	var/list/ability_cooldowns = list()
	///How close the autopilot stays to its master or the nearest marine
	var/ai_follow_distance = 4
	///Below this share of health the autopilot falls back to the marines
	var/ai_retreat_health = 0.25

/mob/living/simple_animal/hostile/mechanoid/Initialize(mapload)
	. = ..()
	job = new /datum/job
	job.title = "Mechanoid"
	if(!client)
		LAZYOR(GLOB.ssd_living_mobs, src) //shows up in the ghost "Take SSD mob" list
	for(var/action_type in action_types)
		var/datum/action/new_action = new action_type(src)
		new_action.give_action(src)

///Whoever takes the mechanoid over gets its ability buttons on screen
/mob/living/simple_animal/hostile/mechanoid/Login()
	. = ..()
	for(var/datum/action/mech_action in actions)
		client.screen |= mech_action.button
	update_action_buttons()

///Called by the ability buttons
/mob/living/simple_animal/hostile/mechanoid/proc/use_ability(ability)
	return FALSE

///Glowing outline and light, shown while an ability is active
/mob/living/simple_animal/hostile/mechanoid/proc/set_glow(glow_name, color, light_range = 3)
	add_filter(glow_name, 2, outline_filter(1, color))
	set_light(light_range, 2, color)

/mob/living/simple_animal/hostile/mechanoid/proc/clear_glow(glow_name)
	remove_filter(glow_name)
	set_light(0)

/mob/living/simple_animal/hostile/mechanoid/proc/flash_glow(glow_name, color, time, light_range = 3)
	set_glow(glow_name, color, light_range)
	addtimer(CALLBACK(src, PROC_REF(clear_glow), glow_name), time)

/mob/living/simple_animal/hostile/mechanoid/proc/refresh_actions()
	for(var/datum/action/mech_action in actions)
		mech_action.update_button_icon()

/mob/living/simple_animal/hostile/mechanoid/examine(mob/user)
	. = ..()
	if(variant_desc)
		. += span_notice(variant_desc)
	if(!client && stat != DEAD)
		. += span_notice("Its pilot is missing, it runs on autopilot.")

//--------------------------------------------------------------------- intelligence

///Mechanoids only fight xenos and enemy humans, not mice, pets or anything else that wanders by
/mob/living/simple_animal/hostile/mechanoid/CanAttack(atom/the_target)
	. = ..()
	if(!.)
		return
	if(!isliving(the_target))
		return FALSE
	return isxeno(the_target) || ishuman(the_target)

///Picks the closest enemy, and prefers the ones that are already hurt
/mob/living/simple_animal/hostile/mechanoid/PickTarget(list/Targets)
	var/atom/best
	var/best_score = INFINITY
	for(var/atom/A AS in Targets)
		var/score = get_dist(src, A)
		if(isxeno(A))
			var/mob/living/carbon/xenomorph/X = A
			score -= (1 - X.health / max(X.maxHealth, 1)) * 3
		if(score < best_score)
			best_score = score
			best = A
	return best

///Never go idle, the autopilot has to keep following and fighting
/mob/living/simple_animal/hostile/mechanoid/AIShouldSleep(list/possible_targets)
	return FALSE

/mob/living/simple_animal/hostile/mechanoid/handle_automated_action()
	. = ..()
	if(client || stat != CONSCIOUS || AIStatus == AI_OFF)
		return
	ai_think()

///One autopilot decision: use abilities, fall back when hurt, otherwise stay close to the marines
/mob/living/simple_animal/hostile/mechanoid/proc/ai_think()
	var/mob/living/enemy = get_closest_enemy(9)
	if(ai_use_abilities(enemy))
		return
	if(health < maxHealth * ai_retreat_health && enemy)
		var/atom/ally = get_follow_target()
		if(ally && get_dist(src, ally) > 2)
			target = null
			Goto(ally, move_to_delay, 1)
		return
	if(!target)
		var/atom/ally = get_follow_target()
		if(ally && get_dist(src, ally) > ai_follow_distance)
			Goto(ally, move_to_delay, max(1, ai_follow_distance - 2))

///Autopilot ability use. Returns TRUE if an ability was used. Subtypes override.
/mob/living/simple_animal/hostile/mechanoid/proc/ai_use_abilities(mob/living/enemy)
	return FALSE

///Creator first, then the closest living marine
/mob/living/simple_animal/hostile/mechanoid/proc/get_follow_target()
	var/mob/master = master_ref?.resolve()
	if(master && !QDELETED(master) && master.z == z && master.stat != DEAD)
		return master
	var/mob/living/carbon/human/best
	var/best_dist = INFINITY
	for(var/mob/living/carbon/human/H in view(14, src))
		if(H.stat == DEAD || H.faction != faction)
			continue
		var/dist = get_dist(src, H)
		if(dist < best_dist)
			best_dist = dist
			best = H
	return best

/mob/living/simple_animal/hostile/mechanoid/proc/flame_nova()
	if(stat != CONSCIOUS || !ability_ready("nova"))
		return FALSE
	start_cooldown("nova", 30 SECONDS)
	visible_message(span_userdanger("[src] vents burning fuel in every direction!"))
	flash_glow("nova", "#ff6a1a", 2 SECONDS, 5)
	playsound(src, 'sound/weapons/guns/fire/flamethrower3.ogg', 60, TRUE)
	for(var/turf/T in range(2, src))
		if(T.density)
			continue
		T.ignite(10, 20, "red")
	return TRUE

///Closest xeno or enemy human we can see
/mob/living/simple_animal/hostile/mechanoid/proc/get_closest_enemy(range = 9)
	var/mob/living/best
	var/best_dist = INFINITY
	for(var/mob/living/L in view(range, src))
		if(L == src || L.stat == DEAD || !CanAttack(L))
			continue
		var/dist = get_dist(src, L)
		if(dist < best_dist)
			best_dist = dist
			best = L
	return best

///Marines near a turf, used so the dangerous abilities don't hurt our own side
/mob/living/simple_animal/hostile/mechanoid/proc/friendlies_near(atom/center, range)
	for(var/mob/living/carbon/human/H in range(range, center))
		if(H.stat != DEAD && H.faction == faction)
			return TRUE
	return FALSE

/mob/living/simple_animal/hostile/mechanoid/proc/ability_ready(ability)
	return world.time >= ability_cooldowns[ability]

/mob/living/simple_animal/hostile/mechanoid/proc/start_cooldown(ability, time)
	ability_cooldowns[ability] = world.time + time
	refresh_actions()
	addtimer(CALLBACK(src, PROC_REF(refresh_actions)), time + 1)

///Same as the normal shot, without the casing that hostile mobs drop
/mob/living/simple_animal/hostile/mechanoid/Shoot(atom/targeted_atom)
	if(QDELETED(targeted_atom) || targeted_atom == targets_from.loc || targeted_atom == targets_from)
		return
	var/atom/movable/projectile/bolt = new(get_turf(targets_from))
	playsound(src, projectilesound, 100, TRUE)
	bolt.generate_bullet(GLOB.ammo_list[ammotype])
	bolt.fire_at(targeted_atom, src, src)

//--------------------------------------------------------------------- ghosts

///The pilot left (ghosted, disconnected, went SSD). The mechanoid goes back on autopilot and is offered to ghosts again.
/mob/living/simple_animal/hostile/mechanoid/Logout()
	. = ..()
	if(stat == DEAD || QDELETED(src))
		return
	addtimer(CALLBACK(src, PROC_REF(offer_if_empty)), 20 SECONDS)

/mob/living/simple_animal/hostile/mechanoid/proc/offer_if_empty()
	if(QDELETED(src) || stat == DEAD || client)
		return
	if(AIStatus != AI_ON)
		toggle_ai(AI_ON)
	if(src in GLOB.offered_mob_list)
		return
	offer_mob()

//=====================================================================  TIER 1  (bandwidth 1): simple, one trick

/**
 * Scrapper: fast crawler with a blade. Hits things.
 */
/mob/living/simple_animal/hostile/mechanoid/scrapper
	name = "scrapper mechanoid"
	desc = "A fast crawling machine with a blade built into its head."
	variant_desc = "Tier 1. Fast, hits hard in melee. No tricks."
	icon = 'icons/mob/mechanoids_small.dmi'
	pixel_x = 0
	icon_state = "scrapper"
	icon_living = "scrapper"
	icon_dead = "scrapper_dead"
	bandwidth_cost = 1
	maxHealth = 120
	health = 120
	speed = 0
	melee_damage = 22
	armour_penetration = 15
	obj_damage = 30

/**
 * Scorcher: mini flameblaster. Spits small flames at close range.
 */
/mob/living/simple_animal/hostile/mechanoid/scorcher
	name = "scorcher mechanoid"
	desc = "A small machine with a mini flameblaster on its head."
	variant_desc = "Tier 1. Spits small flames at close range. Fragile. Flames burn marines too."
	icon = 'icons/mob/mechanoids_small.dmi'
	pixel_x = 0
	icon_state = "scorcher"
	icon_living = "scorcher"
	icon_dead = "scorcher_dead"
	bandwidth_cost = 1
	maxHealth = 90
	health = 90
	speed = 0
	melee_damage = 8
	ranged = TRUE
	rapid = 2
	rapid_fire_delay = 4
	ranged_cooldown_time = 40
	minimum_distance = 3
	retreat_distance = 2
	ranged_message = "spits a flame"
	ammotype = /datum/ammo/flamethrower
	projectilesound = 'sound/weapons/guns/fire/flamethrower3.ogg'
	ai_follow_distance = 3

/**
 * Hauler: slow and plated. Soaks hits for the others.
 */
/mob/living/simple_animal/hostile/mechanoid/hauler
	name = "hauler mechanoid"
	desc = "A slow plated lifter that was never meant for fighting, and does it anyway."
	variant_desc = "Tier 1. Slow and tough, takes 20% less damage. Hits for a medium amount."
	icon = 'icons/mob/mechanoids_small.dmi'
	pixel_x = 0
	icon_state = "hauler"
	icon_living = "hauler"
	icon_dead = "hauler_dead"
	bandwidth_cost = 1
	maxHealth = 220
	health = 220
	speed = 1
	melee_damage = 18
	obj_damage = 40
	damage_coeff = list(BRUTE = 0.8, BURN = 0.8, TOX = 1, CLONE = 1, STAMINA = 0, OXY = 1)

//=====================================================================  TIER 2  (bandwidth 2): smarter, one real ability

/**
 * Gunner: armoured shell with a laser cannon. Can overcharge it.
 */
/mob/living/simple_animal/hostile/mechanoid/gunner
	name = "gunner mechanoid"
	desc = "An armoured shell with an energy cannon built into its back."
	variant_desc = "Tier 2. Laser bursts from range. Overcharge: fires much faster for a short time."
	icon_state = "gunner"
	icon_living = "gunner"
	icon_dead = "gunner_dead"
	bandwidth_cost = 2
	maxHealth = 220
	health = 220
	speed = 1
	melee_damage = 12
	obj_damage = 30
	ranged = TRUE
	rapid = 2
	rapid_fire_delay = 3
	ranged_cooldown_time = 25
	minimum_distance = 4
	retreat_distance = 2
	ranged_message = "fires its cannon"
	ammotype = /datum/ammo/energy/lasgun/marine/mech/burst
	projectilesound = 'sound/weapons/guns/fire/laser3.ogg'
	var/overcharged = FALSE
	action_types = list(/datum/action/innate/mechanoid_ability/overcharge)

/mob/living/simple_animal/hostile/mechanoid/gunner/use_ability(ability)
	if(ability == "overcharge")
		return overcharge()

/mob/living/simple_animal/hostile/mechanoid/gunner/proc/overcharge()
	if(stat != CONSCIOUS || overcharged || !ability_ready("overcharge"))
		return FALSE
	overcharged = TRUE
	start_cooldown("overcharge", 45 SECONDS)
	ranged_cooldown_time = 8
	rapid = 4
	visible_message(span_warning("[src]'s cannon whines as it overcharges!"))
	set_glow("overcharge", "#ff8a1f", 3)
	playsound(src, 'sound/machines/chime.ogg', 50, TRUE)
	addtimer(CALLBACK(src, PROC_REF(end_overcharge)), 8 SECONDS)
	return TRUE

/mob/living/simple_animal/hostile/mechanoid/gunner/proc/end_overcharge()
	overcharged = FALSE
	clear_glow("overcharge")
	ranged_cooldown_time = initial(ranged_cooldown_time)
	rapid = initial(rapid)

/mob/living/simple_animal/hostile/mechanoid/gunner/ai_use_abilities(mob/living/enemy)
	if(enemy && get_dist(src, enemy) <= 7 && overcharge())
		return TRUE
	return FALSE

/**
 * Striker: fast blade machine that leaps onto its target.
 */
/mob/living/simple_animal/hostile/mechanoid/striker
	name = "striker mechanoid"
	desc = "A needle-like blade machine built to jump onto things."
	variant_desc = "Tier 2. Fast with a strong blade. Lunge: leaps at the nearest enemy, hits it and knocks it down."
	icon_state = "striker"
	icon_living = "striker"
	icon_dead = "striker_dead"
	bandwidth_cost = 2
	maxHealth = 170
	health = 170
	speed = -0.5
	melee_damage = 26
	armour_penetration = 20
	obj_damage = 30
	action_types = list(/datum/action/innate/mechanoid_ability/lunge)

/mob/living/simple_animal/hostile/mechanoid/striker/use_ability(ability)
	if(ability == "lunge")
		return lunge(get_closest_enemy(7))

/mob/living/simple_animal/hostile/mechanoid/striker/proc/lunge(mob/living/victim)
	if(stat != CONSCIOUS || !victim || !ability_ready("lunge"))
		return FALSE
	var/dist = get_dist(src, victim)
	if(dist < 2 || dist > 7)
		return FALSE
	start_cooldown("lunge", 12 SECONDS)
	visible_message(span_danger("[src] lunges at [victim]!"))
	target = victim
	flash_glow("lunge", "#7fd0ff", 1 SECONDS, 3)
	fly_at(victim, dist, 2)
	addtimer(CALLBACK(src, PROC_REF(lunge_hit), victim), 0.6 SECONDS)
	return TRUE

/mob/living/simple_animal/hostile/mechanoid/striker/proc/lunge_hit(mob/living/victim)
	if(QDELETED(src) || stat != CONSCIOUS || QDELETED(victim) || !Adjacent(victim))
		return
	victim.Knockdown(1 SECONDS)
	victim.attack_animal(src)

/mob/living/simple_animal/hostile/mechanoid/striker/ai_use_abilities(mob/living/enemy)
	return enemy ? lunge(enemy) : FALSE

/**
 * Medic: weak laser and a repair pulse that heals marines and other mechanoids around it.
 */
/mob/living/simple_animal/hostile/mechanoid/medic
	name = "medic mechanoid"
	desc = "A white machine with a repair emitter and a small defensive laser."
	variant_desc = "Tier 2. Repair Pulse heals marines and mechanoids in 5 tiles. Small laser, stays behind the line."
	icon_state = "medic"
	icon_living = "medic"
	icon_dead = "medic_dead"
	bandwidth_cost = 2
	maxHealth = 160
	health = 160
	speed = 0
	melee_damage = 8
	ranged = TRUE
	rapid = 2
	rapid_fire_delay = 3
	ranged_cooldown_time = 30
	minimum_distance = 5
	retreat_distance = 4
	ranged_message = "fires its laser"
	ammotype = /datum/ammo/energy/lasgun/marine/mech/smg
	projectilesound = 'sound/weapons/guns/fire/laser3.ogg'
	ai_follow_distance = 3
	action_types = list(/datum/action/innate/mechanoid_ability/pulse)

/mob/living/simple_animal/hostile/mechanoid/medic/use_ability(ability)
	if(ability == "pulse")
		return repair_pulse()

///Everyone hurt that is on our side and in range
/mob/living/simple_animal/hostile/mechanoid/medic/proc/get_wounded()
	. = list()
	for(var/mob/living/L in view(5, src))
		if(L.stat == DEAD)
			continue
		if(ishuman(L) && L.faction == faction && L.health < L.maxHealth)
			. += L
		else if(istype(L, /mob/living/simple_animal/hostile/mechanoid) && L.health < L.maxHealth)
			. += L

/mob/living/simple_animal/hostile/mechanoid/medic/proc/repair_pulse()
	if(stat != CONSCIOUS || !ability_ready("pulse"))
		return FALSE
	var/list/wounded = get_wounded()
	if(!length(wounded))
		return FALSE
	start_cooldown("pulse", 20 SECONDS)
	visible_message(span_notice("[src] emits a soft green pulse."))
	flash_glow("pulse", "#5dff9a", 1.5 SECONDS, 4)
	new /obj/effect/temp_visual/heal(get_turf(src))
	playsound(src, 'sound/machines/ping.ogg', 50, TRUE)
	for(var/mob/living/L AS in wounded)
		if(ishuman(L))
			L.heal_overall_damage(25, 25, updating_health = TRUE)
		else if(istype(L, /mob/living/simple_animal/hostile/mechanoid))
			var/mob/living/simple_animal/hostile/mechanoid/ally_mech = L
			ally_mech.adjustHealth(-50)
		new /obj/effect/temp_visual/heal(get_turf(L))
	return TRUE

/mob/living/simple_animal/hostile/mechanoid/medic/ai_use_abilities(mob/living/enemy)
	return repair_pulse()

//=====================================================================  TIER 3  (bandwidth 3): proper war machines

/**
 * Bulwark: slow tower with a shield and a self destruct charge.
 */
/mob/living/simple_animal/hostile/mechanoid/bulwark
	name = "bulwark mechanoid"
	desc = "A slow armoured tower. It can raise a shield and has a self destruct charge."
	variant_desc = "Tier 3. Tunneler chassis: huge health and power claws. Shield: takes 60% less damage but moves slower. Self Destruct: blast that also hurts marines."
	icon_state = "bulwark"
	icon_living = "bulwark"
	icon_dead = "bulwark_dead"
	bandwidth_cost = 3
	maxHealth = 450
	health = 450
	speed = 2
	melee_damage = 35
	armour_penetration = 10
	obj_damage = 60
	mob_size = MOB_SIZE_BIG
	///Whether the shield is up. Takes less damage but moves slower.
	var/shield_up = FALSE
	///Whether the self destruct charge is counting down
	var/self_destructing = FALSE
	action_types = list(/datum/action/innate/mechanoid_ability/shield, /datum/action/innate/mechanoid_ability/selfdestruct)

/mob/living/simple_animal/hostile/mechanoid/bulwark/use_ability(ability)
	switch(ability)
		if("shield")
			start_cooldown("shield", 1 SECONDS)
			set_shield(!shield_up)
			return TRUE
		if("selfdestruct")
			if(stat != CONSCIOUS || self_destructing)
				return FALSE
			if(tgui_alert(src, "Detonate yourself? The explosion hurts everyone around, marines too.", "Self destruct", list("Detonate", "Cancel")) != "Detonate")
				return FALSE
			start_self_destruct()
			return TRUE

/mob/living/simple_animal/hostile/mechanoid/bulwark/proc/set_shield(new_state)
	if(stat != CONSCIOUS || new_state == shield_up)
		return
	shield_up = new_state
	if(shield_up)
		damage_coeff = list(BRUTE = MECHANOID_SHIELD_DAMAGE_COEFF, BURN = MECHANOID_SHIELD_DAMAGE_COEFF, TOX = 1, CLONE = 1, STAMINA = 0, OXY = 1)
		speed += MECHANOID_SHIELD_SLOWDOWN
		visible_message(span_warning("[src] raises a shield!"))
		set_glow("shield", "#4fc3ff", 3)
	else
		damage_coeff = initial(damage_coeff)
		speed -= MECHANOID_SHIELD_SLOWDOWN
		visible_message(span_notice("[src] lowers its shield."))
		clear_glow("shield")
	update_simplemob_varspeed()

/mob/living/simple_animal/hostile/mechanoid/bulwark/proc/start_self_destruct()
	if(stat != CONSCIOUS || self_destructing)
		return
	self_destructing = TRUE
	set_glow("selfdestruct", "#ff2a2a", 4)
	visible_message(span_userdanger("[src] starts beeping rapidly!"))
	playsound(src, 'sound/machines/chime.ogg', 50, TRUE)
	addtimer(CALLBACK(src, PROC_REF(self_destruct)), MECHANOID_SELF_DESTRUCT_TIME)

///Blows the mechanoid up
/mob/living/simple_animal/hostile/mechanoid/bulwark/proc/self_destruct()
	if(QDELETED(src) || stat == DEAD)
		return
	cell_explosion(get_turf(src), MECHANOID_SELF_DESTRUCT_POWER, MECHANOID_SELF_DESTRUCT_FALLOFF)
	qdel(src)

/mob/living/simple_animal/hostile/mechanoid/bulwark/ai_use_abilities(mob/living/enemy)
	//Shield up when a fight is close, down when it is over
	set_shield(!!enemy && get_dist(src, enemy) <= 5)
	//Last resort: nearly dead, surrounded by xenos and no marine close enough to get hurt
	if(!self_destructing && health < maxHealth * 0.15 && enemy && !friendlies_near(src, 5))
		var/xenos_close = 0
		for(var/mob/living/carbon/xenomorph/X in range(3, src))
			if(X.stat != DEAD)
				xenos_close++
		if(xenos_close >= 2)
			start_self_destruct()
			return TRUE
	return FALSE

/**
 * Incinerator: burner centipede. Spits fire, sets everything around it alight.
 */
/mob/living/simple_animal/hostile/mechanoid/incinerator
	name = "incinerator mechanoid"
	desc = "A centipede machine with an inferno cannon."
	variant_desc = "Tier 3, 4 bandwidth. Centipede burner: spits flames from range, resists burning. Flame Nova: ignites everything around it. Burns marines too."
	icon_state = "incinerator"
	icon_living = "incinerator"
	icon_dead = "incinerator_dead"
	bandwidth_cost = 4
	maxHealth = 380
	health = 380
	speed = 1
	melee_damage = 28
	obj_damage = 50
	mob_size = MOB_SIZE_BIG
	damage_coeff = list(BRUTE = 1, BURN = 0.2, TOX = 1, CLONE = 1, STAMINA = 0, OXY = 1)
	ranged = TRUE
	rapid = 3
	rapid_fire_delay = 4
	ranged_cooldown_time = 40
	minimum_distance = 3
	ranged_message = "spits fire"
	ammotype = /datum/ammo/flamethrower
	projectilesound = 'sound/weapons/guns/fire/flamethrower3.ogg'
	action_types = list(/datum/action/innate/mechanoid_ability/nova)

/mob/living/simple_animal/hostile/mechanoid/incinerator/use_ability(ability)
	if(ability == "nova")
		return flame_nova()

/mob/living/simple_animal/hostile/mechanoid/incinerator/ai_use_abilities(mob/living/enemy)
	if(enemy && get_dist(src, enemy) <= 2 && !friendlies_near(src, 3))
		return flame_nova()
	return FALSE

/**
 * Lancer: charge lance. Piercing particle lance, and a charged shot that goes through everything in line.
 */
/mob/living/simple_animal/hostile/mechanoid/lancer
	name = "lancer mechanoid"
	desc = "A tall machine with a particle lance mounted on a swivel."
	variant_desc = "Tier 3. Fires a piercing particle lance. Charge Lance: after a short charge fires a much stronger lance through everything in line, marines too."
	icon_state = "lancer"
	icon_living = "lancer"
	icon_dead = "lancer_dead"
	bandwidth_cost = 3
	maxHealth = 260
	health = 260
	speed = 1
	melee_damage = 12
	obj_damage = 30
	ranged = TRUE
	rapid = 1
	ranged_cooldown_time = 50
	minimum_distance = 4
	retreat_distance = 3
	ranged_message = "fires its lance"
	ammotype = /datum/ammo/energy/lasgun/marine/mech/lance_strike
	projectilesound = 'sound/weapons/guns/fire/laser3.ogg'
	action_types = list(/datum/action/innate/mechanoid_ability/lance)
	ai_follow_distance = 5

/mob/living/simple_animal/hostile/mechanoid/lancer/use_ability(ability)
	if(ability == "lance")
		return charge_lance(get_closest_enemy(7))

/mob/living/simple_animal/hostile/mechanoid/lancer/proc/charge_lance(mob/living/victim)
	if(stat != CONSCIOUS || !victim || !ability_ready("lance"))
		return FALSE
	if(get_dist(src, victim) < 2)
		return FALSE
	start_cooldown("lance", 25 SECONDS)
	visible_message(span_userdanger("[src] charges its lance!"))
	set_glow("lance", "#ffe45c", 4)
	addtimer(CALLBACK(src, PROC_REF(fire_lance), get_turf(victim)), 1.5 SECONDS)
	return TRUE

/mob/living/simple_animal/hostile/mechanoid/lancer/proc/fire_lance(turf/aim)
	clear_glow("lance")
	if(QDELETED(src) || stat != CONSCIOUS || !aim)
		return
	var/atom/movable/projectile/bolt = new(get_turf(src))
	playsound(src, projectilesound, 100, TRUE)
	bolt.generate_bullet(GLOB.ammo_list[/datum/ammo/energy/lasgun/marine/mech/lance_strike/super])
	bolt.fire_at(aim, src, src)

/mob/living/simple_animal/hostile/mechanoid/lancer/ai_use_abilities(mob/living/enemy)
	if(enemy && !friendlies_near(enemy, 2))
		return charge_lance(enemy)
	return FALSE

/**
 * Minigun: centipede gunner. Slow, sprays lasers, can spin up.
 */
/mob/living/simple_animal/hostile/mechanoid/minigun
	name = "centipede gunner mechanoid"
	desc = "A heavy centipede machine with a rotary laser on its back."
	variant_desc = "Tier 3, 4 bandwidth. Slow and tough, sprays laser bursts. Spin Up: fires far faster for a few seconds."
	icon_state = "minigun"
	icon_living = "minigun"
	icon_dead = "minigun_dead"
	bandwidth_cost = 4
	maxHealth = 420
	health = 420
	speed = 2
	melee_damage = 22
	obj_damage = 50
	mob_size = MOB_SIZE_BIG
	ranged = TRUE
	rapid = 5
	rapid_fire_delay = 2
	ranged_cooldown_time = 30
	minimum_distance = 4
	ranged_message = "sprays lasers"
	ammotype = /datum/ammo/energy/lasgun/marine/mech/smg
	projectilesound = 'sound/weapons/guns/fire/laser3.ogg'
	action_types = list(/datum/action/innate/mechanoid_ability/spinup)
	var/spun_up = FALSE

/mob/living/simple_animal/hostile/mechanoid/minigun/use_ability(ability)
	if(ability == "spinup")
		return spin_up()

/mob/living/simple_animal/hostile/mechanoid/minigun/proc/spin_up()
	if(stat != CONSCIOUS || spun_up || !ability_ready("spinup"))
		return FALSE
	spun_up = TRUE
	start_cooldown("spinup", 40 SECONDS)
	rapid = 10
	ranged_cooldown_time = 12
	set_glow("spinup", "#ffd24a", 3)
	visible_message(span_warning("[src]'s barrels spin up with a rising whine!"))
	addtimer(CALLBACK(src, PROC_REF(end_spin_up)), 6 SECONDS)
	return TRUE

/mob/living/simple_animal/hostile/mechanoid/minigun/proc/end_spin_up()
	spun_up = FALSE
	rapid = initial(rapid)
	ranged_cooldown_time = initial(ranged_cooldown_time)
	clear_glow("spinup")

/mob/living/simple_animal/hostile/mechanoid/minigun/ai_use_abilities(mob/living/enemy)
	if(enemy && get_dist(src, enemy) <= 7)
		return spin_up()
	return FALSE

/**
 * Diabolus: the mechanoid boss. Hellsphere cannon (siege shot) and a flame burst.
 */
/mob/living/simple_animal/hostile/mechanoid/diabolus
	name = "diabolus mechanoid"
	desc = "A winged command machine. Its hellsphere cannon can level a corridor."
	variant_desc = "Tier 3 boss, 5 bandwidth. Heavy laser from range. Siege Shot: hellsphere blast 3 seconds after marking. Flame Burst: ignites everything around it. Both hurt marines too."
	icon_state = "diabolus"
	icon_living = "diabolus"
	icon_dead = "diabolus_dead"
	bandwidth_cost = 5
	maxHealth = 650
	health = 650
	speed = 2
	melee_damage = 30
	obj_damage = 60
	mob_size = MOB_SIZE_BIG
	ranged = TRUE
	rapid = 1
	ranged_cooldown_time = 40
	minimum_distance = 6
	retreat_distance = 4
	ranged_message = "fires its heavy cannon"
	ammotype = /datum/ammo/energy/lasgun/marine/mech
	projectilesound = 'sound/weapons/guns/fire/laser3.ogg'
	ai_follow_distance = 5
	action_types = list(/datum/action/innate/mechanoid_ability/siege, /datum/action/innate/mechanoid_ability/nova)

/mob/living/simple_animal/hostile/mechanoid/diabolus/use_ability(ability)
	switch(ability)
		if("siege")
			return siege_shot(get_closest_enemy(9))
		if("nova")
			return flame_nova()

/mob/living/simple_animal/hostile/mechanoid/diabolus/proc/siege_shot(mob/living/victim)
	if(stat != CONSCIOUS || !victim || !ability_ready("siege"))
		return FALSE
	if(get_dist(src, victim) < 4)
		return FALSE
	start_cooldown("siege", 40 SECONDS)
	var/turf/impact = get_turf(victim)
	visible_message(span_userdanger("[src] locks onto [victim] and charges its cannon!"))
	playsound(impact, 'sound/machines/chime.ogg', 70, TRUE)
	impact.visible_message(span_userdanger("A targeting beam locks onto this spot, run!"))
	var/obj/effect/mechanoid_marker/marker = new(impact)
	flash_glow("siege", "#ff3030", 3 SECONDS, 4)
	addtimer(CALLBACK(src, PROC_REF(siege_impact), impact, marker), 3 SECONDS)
	return TRUE

/mob/living/simple_animal/hostile/mechanoid/diabolus/proc/siege_impact(turf/impact, obj/effect/mechanoid_marker/marker)
	qdel(marker)
	if(QDELETED(src) || stat == DEAD || !impact)
		return
	cell_explosion(impact, 60, 30)

/mob/living/simple_animal/hostile/mechanoid/diabolus/ai_use_abilities(mob/living/enemy)
	if(enemy && get_dist(src, enemy) <= 2 && !friendlies_near(src, 3) && flame_nova())
		return TRUE
	if(!enemy || get_dist(src, enemy) < 4 || friendlies_near(enemy, 4))
		return FALSE
	return siege_shot(enemy)

//--------------------------------------------------------------------- ability buttons and effects

///Red target ring that shows where a siege shot is about to land
/obj/effect/mechanoid_marker
	name = "targeting beam"
	desc = "Something heavy is about to land here."
	icon = 'icons/effects/mechanoid_fx.dmi'
	icon_state = "target"
	anchored = TRUE
	layer = FLY_LAYER
	mouse_opacity = MOUSE_OPACITY_TRANSPARENT

/obj/effect/mechanoid_marker/Initialize(mapload)
	. = ..()
	set_light(2, 2, "#ff3030")
	QDEL_IN(src, 5 SECONDS)

///Base of the buttons that trigger mechanoid abilities
/datum/action/innate/mechanoid_ability
	name = "Mechanoid ability"
	action_icon = 'icons/mob/mechanoid_actions.dmi'
	///Which ability this button triggers
	var/ability_key

/datum/action/innate/mechanoid_ability/can_use_action()
	. = ..()
	if(!.)
		return FALSE
	var/mob/living/simple_animal/hostile/mechanoid/mech = owner
	return istype(mech) && mech.stat == CONSCIOUS && mech.ability_ready(ability_key)

/datum/action/innate/mechanoid_ability/Activate()
	var/mob/living/simple_animal/hostile/mechanoid/mech = owner
	if(istype(mech))
		mech.use_ability(ability_key)
	update_button_icon()

/datum/action/innate/mechanoid_ability/overcharge
	name = "Overcharge"
	desc = "Fire much faster for a few seconds."
	action_icon_state = "overcharge"
	ability_key = "overcharge"

/datum/action/innate/mechanoid_ability/lunge
	name = "Lunge"
	desc = "Leap at the nearest enemy, hit it and knock it down."
	action_icon_state = "lunge"
	ability_key = "lunge"

/datum/action/innate/mechanoid_ability/pulse
	name = "Repair Pulse"
	desc = "Heal marines and mechanoids around you."
	action_icon_state = "pulse"
	ability_key = "pulse"

/datum/action/innate/mechanoid_ability/shield
	name = "Toggle Shield"
	desc = "Take much less damage, but move slower."
	action_icon_state = "shield"
	ability_key = "shield"

/datum/action/innate/mechanoid_ability/selfdestruct
	name = "Self Destruct"
	desc = "Blow yourself up. Hurts marines too."
	action_icon_state = "selfdestruct"
	ability_key = "selfdestruct"

/datum/action/innate/mechanoid_ability/selfdestruct/can_use_action()
	var/mob/living/simple_animal/hostile/mechanoid/bulwark/mech = owner
	return istype(mech) && mech.stat == CONSCIOUS && !mech.self_destructing

/datum/action/innate/mechanoid_ability/nova
	name = "Flame Burst"
	desc = "Set everything around you on fire. Burns marines too."
	action_icon_state = "nova"
	ability_key = "nova"

/datum/action/innate/mechanoid_ability/lance
	name = "Charge Lance"
	desc = "Charge, then fire a strong lance through everything in line."
	action_icon_state = "lance"
	ability_key = "lance"

/datum/action/innate/mechanoid_ability/spinup
	name = "Spin Up"
	desc = "Fire far faster for a few seconds."
	action_icon_state = "spinup"
	ability_key = "spinup"

/datum/action/innate/mechanoid_ability/siege
	name = "Siege Shot"
	desc = "Mark the nearest enemy. A blast lands there after 3 seconds, on anyone standing in it."
	action_icon_state = "siege"
	ability_key = "siege"
