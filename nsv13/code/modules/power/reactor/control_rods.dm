/obj/item/control_rod
	name = "\improper Nanocarbon Reactor Control Rod"
	desc = "A standard nanocarbon reactor control rod."
	icon = 'nsv13/icons/obj/control_rod.dmi'
	icon_state = "normal"
	w_class = WEIGHT_CLASS_BULKY
	var/rod_integrity = 100
	var/rod_effectiveness = 1

/obj/item/control_rod/Initialize(mapload)
	.=..()
	AddComponent(/datum/component/two_handed, require_twohands=TRUE)

/obj/item/control_rod/inferior
	name = "\improper Techfab Manufactured Reactor Control Rod"
	desc = "A Reactor Control Rod manufactured onboard, techfabs lack the resolution to completely solidify the core."
	icon_state = "inferior"
	rod_integrity = 80
	rod_effectiveness = 0.8

/obj/item/control_rod/superior
	name = "\improper Crystaline Nanocarbon Reactor Control Rod"
	desc = "A superior nanocarbon reactor control rod, a yielding a longer life time."
	icon_state = "superior"
	rod_integrity = 200

/obj/item/control_rod/plasma
	name = "\improper Nanocarbon Sheathed Plasma Reactor Control Rod"
	desc = "A nanocarbon sheet surrounds the plasma core of this reactor control rod."
	icon_state = "plasma"
	rod_effectiveness = -0.5

/obj/item/control_rod/irradiated
	name = "\improper Depleted Reactor Control Rod"
	desc = "A reactor control rod saturated with radioactive particles, it is no longer effective."
	icon_state = "irradiated"
	rod_integrity = 0
	rod_effectiveness = 0

/obj/item/control_rod/irradiated/Initialize(mapload)
	.=..()
	AddComponent(/datum/component/radioactive, 500, src)

