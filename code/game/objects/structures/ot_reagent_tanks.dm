// Reagent tanks for the Ordnance Technician workshop (port of the CM-SS13 OT tanks).
// Sprites are placeholders: existing tank icon states recoloured with the "color" var.

//Non-flammable bulk tanks
/obj/structure/reagent_dispensers/ot_tank
	icon_state = "watertank"
	amount_per_transfer_from_this = 10

/obj/structure/reagent_dispensers/ot_tank/ammonia
	name = "ammonia tank"
	desc = "A tank filled with ammonia gas."
	color = "#b8a86a"
	list_reagents = list(/datum/reagent/ammonia = 1000)

/obj/structure/reagent_dispensers/ot_tank/sacid
	name = "sulphuric acid tank"
	desc = "A tank filled with sulphuric acid."
	color = "#c8d030"
	list_reagents = list(/datum/reagent/toxin/acid = 1000)

/obj/structure/reagent_dispensers/ot_tank/pacid
	name = "polytrinic acid tank"
	desc = "A tank filled with polytrinic acid."
	color = "#40c060"
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
	color = "#d8d8e8"
	list_reagents = list(/datum/reagent/consumable/ethanol = 1000)

/obj/structure/reagent_dispensers/fueltank/ot_methane
	name = "methane tank"
	desc = "A tank filled with methane gas. Does not smell like farts."
	color = "#9ab0ff"
	list_reagents = list(/datum/reagent/methane = 1000)

/obj/structure/reagent_dispensers/fueltank/ot_hydrogen
	name = "hydrogen tank"
	desc = "A tank filled with hydrogen gas."
	color = "#ffffff"
	list_reagents = list(/datum/reagent/hydrogen = 1000)

/obj/structure/reagent_dispensers/fueltank/ot_oxygen
	name = "oxygen tank"
	desc = "A tank filled with sweet, sweet oxygen."
	color = "#80c0ff"
	list_reagents = list(/datum/reagent/oxygen = 1000)

//Methane did not exist as a reagent in this build
/datum/reagent/methane
	name = "Methane"
	description = "A colorless, odorless, highly flammable gas."
	reagent_state = GAS
	color = "#808080"
	custom_metabolism = REAGENTS_METABOLISM * 0.05
	taste_multi = 0
