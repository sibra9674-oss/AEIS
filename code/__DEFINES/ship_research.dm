// Ship Researcher: mechanoid system (xeno cores -> gestator -> player controlled corrupted xenos)

///Trait kept for compatibility with the evolution check. Not used by the mechanoids anymore, they are not xenomorphs.
#define TRAIT_MECHANOID "mechanoid"
///Source used for TRAIT_MECHANOID
#define MECHANOID_TRAIT_SOURCE "mechanoid_gestator"

///Total bandwidth that living (or currently gestating) mechanoids may use on the whole ship. Scrapper = 1, gunner = 2, bulwark = 3.
#define MECHANOID_BANDWIDTH_MAX 6
///Metal sheets needed per point of bandwidth
#define MECHANOID_METAL_PER_BANDWIDTH 50
///Plasteel sheets needed per point of bandwidth
#define MECHANOID_PLASTEEL_PER_BANDWIDTH 25
///Gestation time per point of bandwidth
#define MECHANOID_GESTATION_TIME_PER_BANDWIDTH (90 SECONDS)
///How long the subnuclear encoder needs to turn a corpse into a core
#define MECHANOID_ENCODE_TIME (8 SECONDS)
///How many sheets of each material the gestator can hold
#define MECHANOID_MAX_STORED_SHEETS 300

///Damage multiplier of a bulwark with its shield up
#define MECHANOID_SHIELD_DAMAGE_COEFF 0.4
///How much slower a bulwark is with its shield up
#define MECHANOID_SHIELD_SLOWDOWN 1.5
///Delay before a self destructing bulwark explodes
#define MECHANOID_SELF_DESTRUCT_TIME (5 SECONDS)
///Power and falloff of the bulwark self destruct (cell_explosion)
#define MECHANOID_SELF_DESTRUCT_POWER 80
#define MECHANOID_SELF_DESTRUCT_FALLOFF 40

///Metal needed per point of bandwidth to resurrect a dead mechanoid
#define MECHANOID_RESURRECT_METAL_PER_BANDWIDTH 25
///Resurrecting takes this share of the normal gestation time
#define MECHANOID_RESURRECT_TIME_MULT 0.5
