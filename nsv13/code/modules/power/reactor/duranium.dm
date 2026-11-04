// NSV duranium sheet (from nsv13 custom_materials.dm), adapted to TGMC's stack framework.
GLOBAL_LIST_INIT(duranium_recipes, list ( \
	new/datum/stack_recipe("railgun rail", /obj/item/ship_weapon/parts/railgun_rail, 1, time = 2 SECONDS, crafting_flags = NONE), \
	new/datum/stack_recipe("mac barrel", /obj/item/ship_weapon/parts/mac_barrel, 1, time = 2 SECONDS, crafting_flags = NONE), \
	))

/obj/item/stack/sheet/duranium
	name = "duranium"
	singular_name = "duranium sheet"
	desc = "This sheet is an extra durable alloy of durasteel and plasteel."
	icon = 'nsv13/icons/obj/custom_stack_objects.dmi'
	icon_state = "sheet-duranium"
	worn_icon_state = "sheet-duranium"
	throwforce = 10
	atom_flags = CONDUCT
	merge_type = /obj/item/stack/sheet/duranium

/obj/item/stack/sheet/duranium/get_main_recipes()
	. = ..()
	. += GLOB.duranium_recipes

/obj/item/stack/sheet/duranium/twenty
	amount = 20

/obj/item/stack/sheet/duranium/fifty
	amount = 50
