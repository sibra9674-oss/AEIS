// NSV13 RPD (Rapid Pipe Dispenser), atmos category only.
// Ported from NSV code/game/objects/items/RPD.dm; the disposals / transit tube / plumbing categories
// are dropped because the matching constructs are not part of this port.

#define ATMOS_CATEGORY 0

#define BUILD_MODE 1
#define WRENCH_MODE 2
#define DESTROY_MODE 4
#define PAINT_MODE 8

GLOBAL_LIST_INIT(pipe_paint_colors, sortList(list(
		"amethyst" = rgb(130,43,255), //supplymain
		"blue" = rgb(0,0,255),
		"brown" = rgb(178,100,56),
		"cyan" = rgb(0,255,249),
		"dark" = rgb(69,69,69),
		"green" = rgb(30,255,0),
		"grey" = rgb(255,255,255),
		"orange" = rgb(255,129,25),
		"purple" = rgb(128,0,182),
		"red" = rgb(255,0,0),
		"violet" = rgb(64,0,128),
		"yellow" = rgb(255,198,0)
)))

/// Item-side pipe state: NSV icons + paintable flag (copied from the machine by make_from_existing)
/obj/item/pipe
	icon = 'nsv13/icons/obj/atmospherics/pipes/pipe_item.dmi'
	var/paintable = FALSE

/obj/item/pipe_meter
	icon = 'nsv13/icons/obj/atmospherics/pipes/pipe_item.dmi'

/datum/asset/spritesheet/pipes
	name = "pipes"

/datum/asset/spritesheet/pipes/create_spritesheets()
	InsertAll("", 'nsv13/icons/obj/atmospherics/pipes/pipe_item.dmi', GLOB.alldirs)

/obj/item/pipe_dispenser
	name = "Rapid Pipe Dispenser (RPD)"
	desc = "A device used to rapidly pipe things."
	icon = 'nsv13/icons/obj/tools.dmi'
	icon_state = "rpd"
	force = 10
	throwforce = 10
	throw_speed = 1
	throw_range = 5
	w_class = WEIGHT_CLASS_NORMAL
	atom_flags = CONDUCT
	equip_slot_flags = ITEM_SLOT_BELT
	var/datum/effect_system/spark_spread/spark_system
	var/p_dir = NORTH
	var/p_flipped = FALSE
	var/paint_color = "grey"
	var/atmos_build_speed = 5 //deciseconds
	var/destroy_speed = 5
	var/paint_speed = 5
	var/category = ATMOS_CATEGORY
	var/piping_layer = PIPING_LAYER_DEFAULT
	var/datum/pipe_info/recipe
	var/static/datum/pipe_info/first_atmos
	var/mode = BUILD_MODE | PAINT_MODE | DESTROY_MODE | WRENCH_MODE

/obj/item/pipe_dispenser/Initialize(mapload)
	. = ..()
	spark_system = new
	spark_system.set_up(5, 0, src)
	spark_system.attach(src)
	if(!first_atmos)
		first_atmos = GLOB.atmos_pipe_recipes[GLOB.atmos_pipe_recipes[1]][1]
	recipe = first_atmos

/obj/item/pipe_dispenser/Destroy()
	QDEL_NULL(spark_system)
	return ..()

/obj/item/pipe_dispenser/attack_self(mob/user)
	ui_interact(user)

/obj/item/pipe_dispenser/ui_assets(mob/user)
	return list(
		get_asset_datum(/datum/asset/spritesheet/pipes),
	)

/obj/item/pipe_dispenser/ui_state(mob/user)
	return GLOB.default_state

/obj/item/pipe_dispenser/ui_interact(mob/user, datum/tgui/ui)
	ui = SStgui.try_update_ui(user, src, ui)
	if(!ui)
		ui = new(user, src, "RapidPipeDispenser")
		ui.open()

/obj/item/pipe_dispenser/ui_data(mob/user)
	var/list/data = list(
		"category" = category,
		"piping_layer" = piping_layer,
		"ducting_layer" = 0,
		"preview_rows" = recipe.get_preview(p_dir),
		"categories" = list(),
		"selected_color" = paint_color,
		"paint_colors" = GLOB.pipe_paint_colors,
		"mode" = mode,
		"locked" = FALSE
	)
	var/list/recipes = GLOB.atmos_pipe_recipes
	for(var/c in recipes)
		var/list/cat = recipes[c]
		var/list/r = list()
		for(var/i in 1 to cat.len)
			var/datum/pipe_info/info = cat[i]
			r += list(list("pipe_name" = info.name, "pipe_index" = i, "selected" = (info == recipe), "all_layers" = info.all_layers))
		data["categories"] += list(list("cat_name" = c, "recipes" = r))
	return data

/obj/item/pipe_dispenser/ui_act(action, list/params, datum/tgui/ui, datum/ui_state/state)
	. = ..()
	if(.)
		return
	var/playeffect = TRUE
	switch(action)
		if("color")
			if(params["paint_color"] in GLOB.pipe_paint_colors)
				paint_color = params["paint_color"]
			. = TRUE
		if("category")
			recipe = first_atmos
			p_dir = NORTH
			playeffect = FALSE
			. = TRUE
		if("piping_layer")
			piping_layer = clamp(text2num(params["piping_layer"]), PIPING_LAYER_MIN, PIPING_LAYER_MAX)
			playeffect = FALSE
			. = TRUE
		if("pipe_type")
			var/list/cat = GLOB.atmos_pipe_recipes[params["category"]]
			var/idx = text2num(params["pipe_type"])
			if(cat && idx >= 1 && idx <= cat.len)
				recipe = cat[idx]
				p_dir = NORTH
				. = TRUE
		if("setdir")
			p_dir = text2dir(params["dir"])
			p_flipped = text2num(params["flipped"])
			playeffect = FALSE
			. = TRUE
		if("mode")
			var/n = text2num(params["mode"])
			if(n in list(BUILD_MODE, WRENCH_MODE, DESTROY_MODE, PAINT_MODE))
				if(mode & n)
					mode &= ~n
				else
					mode |= n
				. = TRUE
	if(playeffect && .)
		spark_system.start()
		playsound(get_turf(src), 'sound/effects/pop.ogg', 50, FALSE)

/obj/item/pipe_dispenser/preattack(atom/A, mob/user, params)
	if(!ishuman(user))
		return FALSE

	//So that changing the menu settings doesn't affect the pipes already being built.
	var/queued_p_type = recipe.id
	var/queued_p_dir = p_dir
	var/queued_p_flipped = p_flipped

	//make sure what we're clicking is valid
	var/static/list/make_pipe_whitelist
	if(!make_pipe_whitelist)
		make_pipe_whitelist = typecacheof(list(/obj/structure/girder, /obj/item/pipe, /obj/structure/window, /obj/structure/grille))
	var/can_make_pipe = (isturf(A) || is_type_in_typecache(A, make_pipe_whitelist))

	if((mode & DESTROY_MODE) && (istype(A, /obj/item/pipe) || istype(A, /obj/item/pipe_meter)))
		to_chat(user, span_notice("You start destroying a pipe..."))
		playsound(get_turf(src), 'sound/machines/click.ogg', 50, 1)
		if(do_after(user, destroy_speed, NONE, A))
			activate()
			qdel(A)
		return TRUE

	if(mode & PAINT_MODE)
		var/obj/machinery/atmospherics/pipe/M = A
		if(istype(M) && M.paintable)
			to_chat(user, span_notice("You start painting \the [M] [paint_color]..."))
			playsound(get_turf(src), 'sound/machines/click.ogg', 50, 1)
			if(do_after(user, paint_speed, NONE, M))
				M.paint(GLOB.pipe_paint_colors[paint_color]) //paint the pipe
				user.visible_message(span_notice("[user] paints \the [M] [paint_color]."), span_notice("You paint \the [M] [paint_color]."))
			return TRUE
		var/obj/item/pipe/P = A
		if(istype(P) && P.paintable)
			to_chat(user, span_notice("You start painting \the [P] [paint_color]..."))
			playsound(get_turf(src), 'sound/machines/click.ogg', 50, 1)
			if(do_after(user, paint_speed, NONE, P))
				P.add_atom_colour(GLOB.pipe_paint_colors[paint_color], FIXED_COLOUR_PRIORITY) //paint the pipe
				user.visible_message(span_notice("[user] paints \the [P] [paint_color]."), span_notice("You paint \the [P] [paint_color]."))
			return TRUE

	if(!(mode & BUILD_MODE) || !can_make_pipe)
		return FALSE

	playsound(get_turf(src), 'sound/machines/click.ogg', 50, 1)
	if(recipe.type == /datum/pipe_info/meter)
		to_chat(user, span_notice("You start building a meter..."))
		if(do_after(user, atmos_build_speed, NONE, A))
			activate()
			var/obj/item/pipe_meter/PM = new /obj/item/pipe_meter(get_turf(A))
			PM.setAttachLayer(piping_layer)
			if(mode & WRENCH_MODE)
				PM.wrench_act(user, src)
		return TRUE

	if(recipe.all_layers == FALSE && (piping_layer == PIPING_LAYER_MIN || piping_layer == PIPING_LAYER_MAX))
		to_chat(user, span_notice("You can't build this object on the layer..."))
		return TRUE
	to_chat(user, span_notice("You start building a pipe..."))
	if(do_after(user, atmos_build_speed, NONE, A))
		activate()
		var/obj/machinery/atmospherics/path = queued_p_type
		var/pipe_item_type = initial(path.construction_type) || /obj/item/pipe
		var/obj/item/pipe/P = new pipe_item_type(get_turf(A), queued_p_type, queued_p_dir)

		if(queued_p_flipped && istype(P, /obj/item/pipe/trinary/flippable))
			var/obj/item/pipe/trinary/flippable/F = P
			F.flipped = queued_p_flipped

		P.update()
		P.add_fingerprint(user, "rpd")
		P.set_piping_layer(piping_layer)
		if(findtext("[queued_p_type]", "/obj/machinery/atmospherics/pipe") && !findtext("[queued_p_type]", "layer_manifold"))
			P.add_atom_colour(GLOB.pipe_paint_colors[paint_color], FIXED_COLOUR_PRIORITY)
		if(mode & WRENCH_MODE)
			P.wrench_act(user, src)
	return TRUE

/obj/item/pipe_dispenser/proc/activate()
	playsound(get_turf(src), 'sound/items/deconstruct.ogg', 50, 1)

#undef ATMOS_CATEGORY
#undef BUILD_MODE
#undef DESTROY_MODE
#undef PAINT_MODE
#undef WRENCH_MODE
