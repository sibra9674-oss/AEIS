// NSV/Beestation SSair, reduced to what the ported pipe machinery needs: pipenet rebuilds, pipenet processing and atmos machinery processing.
// TGMC's SSair only builds the networks once at round start (SS_NO_FIRE). Turf gas simulation (active turfs, excited groups, hotspots,
// equalisation) is auxmos-native in NSV and is NOT part of this port.

#define SSAIR_REBUILD_PIPELINE 1
#define SSAIR_REBUILD_QUEUE 2

/datum/controller/subsystem/air
	flags = 0
	wait = 0.5 SECONDS
	var/list/rebuild_queue = list()
	var/list/expansion_queue = list()
	var/list/currentrun = list()
	var/currentpart = SSAIR_PIPENETS
	/// every gas reaction datum, highest priority first (NSV builds this at SSair init)
	var/list/gas_reactions = list()

/// Objects whose open/closed state decides whether gas passes (doors, shutters, windows...). TGMC doors set density directly in many different procs,
/// so instead of hooking each of them the air system remembers what it saw and re-evaluates the turf when something changed or was deleted.
/// obj -> list(density, turf)
/datum/controller/subsystem/air/var/list/atmos_watched = list()

/datum/controller/subsystem/air/proc/nsv_watch(obj/O)
	if(O in atmos_watched)
		return
	atmos_watched[O] = list(O.density, get_turf(O))

/datum/controller/subsystem/air/proc/process_atmos_watched()
	for(var/obj/O as anything in atmos_watched)
		var/list/seen = atmos_watched[O]
		var/turf/old_turf = seen[2]
		if(QDELETED(O))
			atmos_watched -= O
			old_turf?.air_update_turf()
			continue
		var/turf/now = get_turf(O)
		if(O.density != seen[1] || now != old_turf)
			atmos_watched[O] = list(O.density, now)
			now?.air_update_turf()
			if(old_turf && old_turf != now)
				old_turf.air_update_turf()

/datum/controller/subsystem/air/fire(resumed = FALSE)
	if(!resumed)
		process_atmos_watched()
	if(length(rebuild_queue) || length(expansion_queue))
		process_rebuilds()
		if(state != SS_RUNNING)
			return
	if(currentpart == SSAIR_PIPENETS || !resumed)
		process_pipenets(resumed)
		if(state != SS_RUNNING)
			return
		resumed = FALSE
		currentpart = SSAIR_ATMOSMACHINERY
	if(currentpart == SSAIR_ATMOSMACHINERY)
		process_atmos_machinery(resumed)
		if(state != SS_RUNNING)
			return
		resumed = FALSE
		currentpart = SSAIR_ACTIVETURFS
	if(currentpart == SSAIR_ACTIVETURFS)
		process_active_turfs(resumed)
		if(state != SS_RUNNING)
			return
		resumed = FALSE
		currentpart = SSAIR_EXCITEDGROUPS
	if(currentpart == SSAIR_EXCITEDGROUPS)
		process_excited_groups(resumed)
		if(state != SS_RUNNING)
			return
		resumed = FALSE
		currentpart = SSAIR_HOTSPOTS
	if(currentpart == SSAIR_HOTSPOTS)
		process_hotspots(resumed)
		if(state != SS_RUNNING)
			return
		process_high_pressure_delta()
		currentpart = SSAIR_PIPENETS

/datum/controller/subsystem/air/proc/process_pipenets(resumed = FALSE)
	if(!resumed)
		src.currentrun = networks.Copy()
	var/list/currentrun = src.currentrun
	while(currentrun.len)
		var/datum/thing = currentrun[currentrun.len]
		currentrun.len--
		if(thing)
			thing.process()
		else
			networks.Remove(thing)
		if(MC_TICK_CHECK)
			return

/datum/controller/subsystem/air/proc/process_atmos_machinery(resumed = FALSE)
	if(!resumed)
		src.currentrun = atmos_machinery.Copy()
	var/list/currentrun = src.currentrun
	while(currentrun.len)
		var/obj/machinery/M = currentrun[currentrun.len]
		currentrun.len--
		if(!M)
			atmos_machinery -= M
			continue
		if(M.process_atmos(wait / (1 SECONDS)) == PROCESS_KILL)
			stop_processing_machine(M)
		if(MC_TICK_CHECK)
			return

/datum/controller/subsystem/air/proc/add_to_rebuild_queue(obj/machinery/atmospherics/atmos_machine)
	if(istype(atmos_machine, /obj/machinery/atmospherics) && !atmos_machine.rebuilding)
		rebuild_queue += atmos_machine
		atmos_machine.rebuilding = TRUE

/datum/controller/subsystem/air/proc/add_to_expansion(datum/pipeline/line, starting_point)
	var/list/new_packet = new(SSAIR_REBUILD_QUEUE)
	new_packet[SSAIR_REBUILD_PIPELINE] = line
	new_packet[SSAIR_REBUILD_QUEUE] = list(starting_point)
	expansion_queue += list(new_packet)

/datum/controller/subsystem/air/proc/remove_from_expansion(datum/pipeline/line)
	for(var/list/packet in expansion_queue)
		if(packet[SSAIR_REBUILD_PIPELINE] == line)
			expansion_queue -= packet
			return

/datum/controller/subsystem/air/proc/process_rebuilds()
	var/list/currentrun = rebuild_queue
	while(currentrun.len || length(expansion_queue))
		while(currentrun.len && !length(expansion_queue))
			var/obj/machinery/atmospherics/remake = currentrun[currentrun.len]
			currentrun.len--
			if(!remake)
				continue
			remake.rebuild_pipes()
			if(MC_TICK_CHECK)
				return
		var/list/queue = expansion_queue
		while(queue.len)
			var/list/pack = queue[queue.len]
			var/datum/pipeline/linepipe = pack[SSAIR_REBUILD_PIPELINE]
			var/list/border = pack[SSAIR_REBUILD_QUEUE]
			expand_pipeline(linepipe, border)
			if(state != SS_RUNNING)
				return
			linepipe.building = FALSE
			queue.len--
			if(MC_TICK_CHECK)
				return

/// Rebuilds a pipeline by expanding outwards, while yielding when sane.
/datum/controller/subsystem/air/proc/expand_pipeline(datum/pipeline/net, list/border)
	while(border.len)
		var/obj/machinery/atmospherics/borderline = border[border.len]
		border.len--
		var/list/result = borderline.pipeline_expansion(net)
		if(!length(result))
			continue
		for(var/obj/machinery/atmospherics/considered_device in result)
			if(!istype(considered_device, /obj/machinery/atmospherics/pipe))
				considered_device.set_pipenet(net, borderline)
				net.add_machinery_member(considered_device)
				continue
			var/obj/machinery/atmospherics/pipe/item = considered_device
			if(net.members.Find(item))
				continue
			net.members += item
			border += item
			net.air.set_volume(net.air.return_volume() + item.volume)
			item.parent = net
			if(item.air_temporary)
				net.air.merge(item.air_temporary)
				item.air_temporary = null
		if(MC_TICK_CHECK)
			return

/datum/controller/subsystem/air/proc/start_processing_machine(obj/machinery/machine)
	if(machine.atmos_processing)
		return
	machine.atmos_processing = TRUE
	atmos_machinery += machine

/datum/controller/subsystem/air/proc/stop_processing_machine(obj/machinery/machine)
	if(!machine.atmos_processing)
		return
	machine.atmos_processing = FALSE
	atmos_machinery -= machine
	currentrun -= machine

/obj/machinery/var/atmos_processing = FALSE

/// Atmos machines override this; anything else dropped into the atmos process list is removed.
/obj/machinery/proc/process_atmos(seconds)
	return PROCESS_KILL

/datum/controller/subsystem/air/setup_pipenets()
	for(var/obj/machinery/atmospherics/AM in atmos_machinery)
		var/list/targets = AM.get_rebuild_targets()
		for(var/datum/pipeline/build_off as anything in targets)
			build_off.build_pipeline_blocking(AM)
		CHECK_TICK

/datum/controller/subsystem/air/setup_template_machinery(list/atmos_machines)
	var/obj/machinery/atmospherics/AM
	for(var/A in 1 to atmos_machines.len)
		AM = atmos_machines[A]
		AM.atmos_init()
		CHECK_TICK
	for(var/A in 1 to atmos_machines.len)
		AM = atmos_machines[A]
		var/list/targets = AM.get_rebuild_targets()
		for(var/datum/pipeline/build_off as anything in targets)
			build_off.build_pipeline_blocking(AM)
		CHECK_TICK

/datum/controller/subsystem/air/Initialize()
	gas_reactions = init_gas_reactions()
	return ..()
