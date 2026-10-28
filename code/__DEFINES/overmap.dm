// Space combat defines (NSV13 overmap port)
#define SC_QUAD_FORE_STARBOARD 1
#define SC_QUAD_AFT_STARBOARD 2
#define SC_QUAD_AFT_PORT 3
#define SC_QUAD_FORE_PORT 4

#define SC_ROLE_HELM "helm"
#define SC_ROLE_TACTICAL "tactical"
#define SC_ROLE_DRADIS "dradis"

#define SC_CTRL_PILOT 1
#define SC_CTRL_GUNNER 2


/// Pixels of the space z-level per distance unit. 32 = one unit is one tile, exactly like NSV13 overmap.
#define SC_PX_PER_KM 32
/// Simulation step of the subsystem in deciseconds (also the client-side interpolation time).
#define SC_STEP 1
#define SC_DUST_HALF_X 22
#define SC_DUST_HALF_Y 16
