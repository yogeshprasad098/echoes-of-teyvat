extends SceneTree
## Unit: ElementalReactions resolves every (aura, incoming) pair to the spec table.

func _init() -> void:
	var R = preload("res://scripts/systems/elemental_reactions.gd")
	var er = R.new()

	var NONE = R.Reaction.NONE
	var V_FWD = R.Reaction.VAPORIZE_FORWARD
	var V_REV = R.Reaction.VAPORIZE_REVERSE
	var OVR = R.Reaction.OVERLOADED
	var EC = R.Reaction.ELECTRO_CHARGED

	assert(er.resolve("pyro", "") == NONE)
	assert(er.resolve("hydro", "") == NONE)
	assert(er.resolve("electro", "") == NONE)

	assert(er.resolve("pyro", "pyro") == NONE)
	assert(er.resolve("hydro", "hydro") == NONE)
	assert(er.resolve("electro", "electro") == NONE)

	assert(er.resolve("pyro", "hydro") == V_FWD, "Hydro aura + Pyro hit = Vaporize 2.0×")
	assert(er.resolve("hydro", "pyro") == V_REV, "Pyro aura + Hydro hit = Vaporize 1.5×")

	assert(er.resolve("electro", "pyro") == OVR)
	assert(er.resolve("pyro", "electro") == OVR)

	assert(er.resolve("electro", "hydro") == EC)
	assert(er.resolve("hydro", "electro") == EC)

	assert(er.multiplier(NONE) == 1.0)
	assert(er.multiplier(V_FWD) == 2.0)
	assert(er.multiplier(V_REV) == 1.5)
	assert(er.multiplier(OVR) == 1.75)
	assert(er.multiplier(EC) == 1.5)

	assert(er.display_name(V_FWD) == "VAPORIZE 2.0×")
	assert(er.display_name(V_REV) == "VAPORIZE 1.5×")
	assert(er.display_name(OVR) == "OVERLOADED")
	assert(er.display_name(EC) == "ELECTRO-CHARGED")
	assert(er.display_name(NONE) == "")

	er.free()
	print("[unit_elemental_reactions] PASS")
	quit()
