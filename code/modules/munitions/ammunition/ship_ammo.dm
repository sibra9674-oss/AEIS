/// Ship munitions (sprites from NSV13 munitions.dmi). Use one on a helm/tactical console to load it into the matching weapon.
/obj/item/ship_ammo
	name = "ship munition"
	desc = "Ammunition for the ship's weapons. Slot it into a tactical or helm console to load it."
	icon = 'icons/spacecombat/munitions.dmi'
	w_class = WEIGHT_CLASS_BULKY
	/// Weapon type this loads into.
	var/weapon_type
	/// Rounds added.
	var/amount = 1

/obj/item/ship_ammo/torpedo
	name = "ship torpedo"
	desc = "A guided torpedo for the torpedo tubes."
	icon_state = "torpedo"
	weapon_type = /datum/ship_weapon/torpedo
	amount = 1

/obj/item/ship_ammo/mac_shell
	name = "naval artillery round"
	desc = "A heavy slug for the naval artillery."
	icon_state = "railgun_ammo"
	weapon_type = /datum/ship_weapon/mac
	amount = 2

/obj/item/ship_ammo/pdc_box
	name = "PDC ammunition box"
	desc = "Belts of rounds for the point defense cannons."
	icon_state = "pdc_100"
	weapon_type = /datum/ship_weapon/gauss
	amount = 150

/obj/machinery/computer/spacecombat/attackby(obj/item/I, mob/user, params)
	if(!istype(I, /obj/item/ship_ammo))
		return ..()
	var/obj/item/ship_ammo/ammo = I
	var/datum/space_ship/ship = SSspacecombat.player_ship
	if(!ship)
		return TRUE
	for(var/datum/ship_weapon/weapon AS in ship.weapons)
		if(!istype(weapon, ammo.weapon_type))
			continue
		if(weapon.max_ammo < 0 || weapon.ammo >= weapon.max_ammo)
			to_chat(user, span_warning("The [weapon.name] is already fully loaded."))
			return TRUE
		weapon.ammo = min(weapon.max_ammo, weapon.ammo + ammo.amount)
		to_chat(user, span_notice("You load [ammo] into the [weapon.name] ([weapon.ammo]/[weapon.max_ammo])."))
		playsound(src, 'sound/spacecombat/rcs.ogg', 25, TRUE)
		qdel(ammo)
		return TRUE
	to_chat(user, span_warning("Nothing on this ship can use that."))
	return TRUE
