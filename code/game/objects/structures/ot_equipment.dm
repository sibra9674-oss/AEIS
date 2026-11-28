// Ordnance Technician equipment ported from CM-SS13: reagent tanks, methane reagent, OT uniform.
// Sprites are extracted from CM-SS13 (icons/obj/structures/ot_tanks.dmi and the two ot_uniform.dmi files).

//Non-flammable bulk tanks
/obj/structure/reagent_dispensers/ot_tank
	icon = 'icons/obj/structures/ot_tanks.dmi'
	icon_state = "tank_normal"
	amount_per_transfer_from_this = 10

/obj/structure/reagent_dispensers/ot_tank/ammonia
	name = "ammonia tank"
	desc = "A tank filled with ammonia gas."
	icon = 'icons/obj/structures/ot_tanks.dmi'
	icon_state = "ammoniatank"
	list_reagents = list(/datum/reagent/ammonia = 1000)

/obj/structure/reagent_dispensers/ot_tank/sacid
	name = "sulphuric acid tank"
	desc = "A tank filled with sulphuric acid."
	icon = 'icons/obj/structures/ot_tanks.dmi'
	icon_state = "sacidtank"
	list_reagents = list(/datum/reagent/toxin/acid = 1000)

/obj/structure/reagent_dispensers/ot_tank/pacid
	name = "polytrinic acid tank"
	desc = "A tank filled with polytrinic acid."
	icon = 'icons/obj/structures/ot_tanks.dmi'
	icon_state = "pacidtank"
	list_reagents = list(/datum/reagent/toxin/acid/polyacid = 1000)

/// Empty tank for storing whatever chemicals are poured into it.
/obj/structure/reagent_dispensers/ot_tank/custom
	name = "reagent tank"
	desc = "A reagent tank, typically used to store large quantities of chemicals."
	list_reagents = null

/obj/structure/reagent_dispensers/ot_tank/custom/Initialize(mapload)
	. = ..()
	create_reagents(tank_volume, AMOUNT_VISIBLE|DRAINABLE|REFILLABLE)

//Flammable tanks: subtypes of the fuel tank so they explode like one
/obj/structure/reagent_dispensers/fueltank/ot_ethanol
	name = "ethanol tank"
	desc = "A tank filled with ethanol. Command hopes you do not drink it all."
	icon = 'icons/obj/structures/ot_tanks.dmi'
	icon_state = "ethanoltank"
	list_reagents = list(/datum/reagent/consumable/ethanol = 1000)

/obj/structure/reagent_dispensers/fueltank/ot_methane
	name = "methane tank"
	desc = "A tank filled with methane gas. Does not smell like farts."
	icon = 'icons/obj/structures/ot_tanks.dmi'
	icon_state = "methanetank"
	list_reagents = list(/datum/reagent/methane = 1000)

/obj/structure/reagent_dispensers/fueltank/ot_hydrogen
	name = "hydrogen tank"
	desc = "A tank filled with hydrogen gas."
	icon = 'icons/obj/structures/ot_tanks.dmi'
	icon_state = "hydrogentank"
	list_reagents = list(/datum/reagent/hydrogen = 1000)

/obj/structure/reagent_dispensers/fueltank/ot_oxygen
	name = "oxygen tank"
	desc = "A tank filled with sweet, sweet oxygen."
	icon = 'icons/obj/structures/ot_tanks.dmi'
	icon_state = "oxygentank"
	list_reagents = list(/datum/reagent/oxygen = 1000)

//Methane did not exist as a reagent in this build
/datum/reagent/methane
	name = "Methane"
	description = "A colorless, odorless, highly flammable gas."
	reagent_state = GAS
	color = "#808080"
	custom_metabolism = REAGENTS_METABOLISM * 0.05
	taste_multi = 0

//OT uniform
/obj/item/clothing/under/marine/officer/engi/ot
	name = "ordnance engineer uniform"
	desc = "A uniform for a professional bomb maker. It has shards of light Kevlar to help protect against stabbing weapons, bullets, and shrapnel from explosions. Padded with extra plates to take the brunt force of an explosion."
	icon = 'icons/obj/clothing/uniforms/ot_uniform.dmi'
	icon_state = "ot_jumpsuit"
	worn_icon_state = "ot_jumpsuit"
	worn_icon_list = list(
		slot_w_uniform_str = 'icons/mob/clothing/uniforms/ot_uniform.dmi',
		slot_l_hand_str = 'icons/mob/inhands/items_lefthand_1.dmi',
		slot_r_hand_str = 'icons/mob/inhands/items_righthand_1.dmi',
	)
	adjustment_variants = list()

//Debug/test room vendor: no power, no access check
/obj/machinery/vending/ordnance_workshop/debug
	use_power = NO_POWER_USE
	req_access = null

//Assemblies that come ready to attach. Stock assemblies spawn "secured", and two secured devices refuse to join.
/obj/item/assembly/igniter/unsecured
	secured = FALSE

/obj/item/assembly/timer/unsecured
	secured = FALSE

/obj/item/assembly/prox_sensor/unsecured
	secured = FALSE

/obj/item/assembly/signaler/unsecured
	secured = FALSE

//Ordnance Lathe: OT fabricator for casings, containers and triggers (port of the CM-SS13 Armylathe, simplified)
/obj/machinery/ordnance_lathe
	name = "\improper Ordnance Lathe"
	desc = "A specialized lathe for printing chemical grenade casings, containers and triggers. Feed it metal and glass sheets."
	icon = 'icons/obj/machines/ot_lathe.dmi'
	icon_state = "armylathe"
	density = TRUE
	anchored = TRUE
	use_power = NO_POWER_USE
	resistance_flags = XENO_DAMAGEABLE
	/// Stored material units, one sheet is MATERIAL_PER_SHEET units
	var/metal = 0
	var/glass = 0
	var/max_material = 20000
	var/restrict_to_ot = TRUE
	var/busy = FALSE
	var/static/material_per_sheet = 100
	/// recipe name = list(path, metal cost, glass cost)
	var/static/list/recipes = list(
		"Chemical grenade casing" = list(/obj/item/explosive/grenade/chem_grenade, 150, 0),
		"Large chemical grenade casing" = list(/obj/item/explosive/grenade/chem_grenade/large, 300, 0),
		"Beaker" = list(/obj/item/reagent_containers/glass/beaker, 0, 100),
		"Large beaker" = list(/obj/item/reagent_containers/glass/beaker/large, 0, 200),
		"Igniter" = list(/obj/item/assembly/igniter/unsecured, 50, 0),
		"Timer" = list(/obj/item/assembly/timer/unsecured, 50, 0),
		"Proximity sensor" = list(/obj/item/assembly/prox_sensor/unsecured, 50, 25),
		"Signaler" = list(/obj/item/assembly/signaler/unsecured, 50, 0),
		"Cable coil" = list(/obj/item/stack/cable_coil, 25, 0),
		"Screwdriver" = list(/obj/item/tool/screwdriver, 50, 0),
	)

/obj/machinery/ordnance_lathe/examine(mob/user)
	. = ..()
	. += span_notice("It holds [metal] units of metal and [glass] units of glass. One sheet is [material_per_sheet] units.")

/obj/machinery/ordnance_lathe/attackby(obj/item/I, mob/user, params)
	if(istype(I, /obj/item/stack/sheet/metal))
		return load_sheets(I, user, TRUE)
	if(istype(I, /obj/item/stack/sheet/glass))
		return load_sheets(I, user, FALSE)
	return ..()

/obj/machinery/ordnance_lathe/proc/load_sheets(obj/item/stack/sheet/S, mob/user, is_metal)
	var/current = is_metal ? metal : glass
	var/take = min(S.amount, round((max_material - current) / material_per_sheet))
	if(take <= 0)
		to_chat(user, span_warning("[src] cannot hold any more of that material."))
		return TRUE
	if(!S.use(take))
		return TRUE
	if(is_metal)
		metal += take * material_per_sheet
	else
		glass += take * material_per_sheet
	to_chat(user, span_notice("You load [take] sheet\s into [src]."))
	return TRUE

/obj/machinery/ordnance_lathe/interact(mob/user)
	. = ..()
	if(.)
		return
	if(restrict_to_ot && user.job?.title != ORDNANCE_TECH)
		to_chat(user, span_warning("You have no idea how to operate [src]."))
		return TRUE
	if(busy)
		to_chat(user, span_warning("[src] is busy."))
		return TRUE
	var/list/display = list()
	for(var/recipe_name in recipes)
		var/list/R = recipes[recipe_name]
		display["[recipe_name] ([R[2]] metal, [R[3]] glass)"] = R
	var/choice = tgui_input_list(user, "Metal: [metal], Glass: [glass]", "Ordnance Lathe", display)
	if(!choice || busy || !user.Adjacent(src))
		return TRUE
	var/list/recipe = display[choice]
	if(metal < recipe[2] || glass < recipe[3])
		to_chat(user, span_warning("[src] does not have enough material."))
		return TRUE
	metal -= recipe[2]
	glass -= recipe[3]
	busy = TRUE
	icon_state = "armylathe_n"
	playsound(src, 'sound/machines/twobeep.ogg', 25, TRUE)
	addtimer(CALLBACK(src, PROC_REF(finish_print), recipe[1]), 2 SECONDS)
	return TRUE

/obj/machinery/ordnance_lathe/proc/finish_print(printed_type)
	busy = FALSE
	icon_state = initial(icon_state)
	new printed_type(get_turf(src))

/// Test version: no job lock and some material loaded
/obj/machinery/ordnance_lathe/debug
	restrict_to_ot = FALSE
	metal = 10000
	glass = 10000
