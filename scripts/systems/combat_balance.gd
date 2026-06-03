extends Node
## Central combat tuning for character damage, map resonance, and reaction bonuses.

const ELEMENT_PYRO := "pyro"
const ELEMENT_HYDRO := "hydro"
const ELEMENT_ELECTRO := "electro"

const REACTION_NONE := "none"
const REACTION_PYRO_RESONANCE := "pyro_resonance"
const REACTION_HYDRO_RESONANCE := "hydro_resonance"
const REACTION_ELECTRO_RESONANCE := "electro_resonance"
const REACTION_VAPORIZE := "vaporize"
const REACTION_OVERLOADED := "overloaded"
const REACTION_ELECTRO_CHARGED := "electro_charged"

const AURA_REACTION_NONE := 0
const AURA_REACTION_VAPORIZE_FORWARD := 1
const AURA_REACTION_VAPORIZE_REVERSE := 2
const AURA_REACTION_OVERLOADED := 3
const AURA_REACTION_ELECTRO_CHARGED := 4
const REACTION_BURST_SPAWNER := preload("res://scripts/effects/reaction_burst.gd")

const CHARACTER_ELEMENTS := {
	&"Kira": ELEMENT_PYRO,
	&"Marina": ELEMENT_HYDRO,
	&"Ryne": ELEMENT_ELECTRO,
}

const REACTION_DAMAGE_MULTIPLIERS := {
	REACTION_NONE: 1.0,
	REACTION_PYRO_RESONANCE: 1.15,
	REACTION_HYDRO_RESONANCE: 1.15,
	REACTION_ELECTRO_RESONANCE: 1.15,
	REACTION_VAPORIZE: 1.30,
	REACTION_OVERLOADED: 1.20,
	REACTION_ELECTRO_CHARGED: 1.15,
}

const REACTION_DPS_PROFILES := {
	REACTION_PYRO_RESONANCE: {
		"bonus_dps": 0.0,
		"duration_sec": 0.0,
		"note": "same-map Pyro resonance: direct damage boost only",
	},
	REACTION_HYDRO_RESONANCE: {
		"bonus_dps": 0.0,
		"duration_sec": 0.0,
		"note": "same-map Hydro resonance: direct damage boost only",
	},
	REACTION_ELECTRO_RESONANCE: {
		"bonus_dps": 0.0,
		"duration_sec": 0.0,
		"note": "same-map Electro resonance: direct damage boost only",
	},
	REACTION_VAPORIZE: {
		"bonus_dps": 0.0,
		"duration_sec": 0.0,
		"note": "burst damage reaction: no lingering DPS",
	},
	REACTION_OVERLOADED: {
		"bonus_dps": 0.0,
		"duration_sec": 0.0,
		"aoe_ratio": 0.40,
		"aoe_radius_px": 60.0,
		"note": "AoE knockback-style burst around target",
	},
	REACTION_ELECTRO_CHARGED: {
		"bonus_dps": 6.0,
		"duration_sec": 2.0,
		"chain_ratio": 0.50,
		"chain_radius_px": 100.0,
		"note": "chain damage plus short lingering charged damage budget",
	},
}

var current_map_element: String = ELEMENT_PYRO
var current_map_name: StringName = &"EmberFields"

func set_current_map(area_name: StringName) -> void:
	current_map_name = area_name
	current_map_element = map_element_for_area(area_name)

func map_element_for_area(area_name: StringName) -> String:
	var element := _element_from_area_name(area_name)
	return ELEMENT_PYRO if element == "" else element

func active_map_name() -> StringName:
	var live_area_name := _live_area_name()
	return current_map_name if live_area_name == &"" else live_area_name

func active_map_element() -> String:
	var live_map_element := _element_from_area_name(_live_area_name())
	return current_map_element if live_map_element == "" else live_map_element

func character_element(character_name: StringName) -> String:
	return CHARACTER_ELEMENTS.get(character_name, "")

func reaction_for(character_name: StringName, map_element: String = "") -> String:
	var effective_map_element := active_map_element() if map_element == "" else map_element
	var element := character_element(character_name)
	if element == "" or effective_map_element == "":
		return REACTION_NONE
	if element == effective_map_element:
		match element:
			ELEMENT_PYRO:
				return REACTION_PYRO_RESONANCE
			ELEMENT_HYDRO:
				return REACTION_HYDRO_RESONANCE
			ELEMENT_ELECTRO:
				return REACTION_ELECTRO_RESONANCE
	if (element == ELEMENT_PYRO and effective_map_element == ELEMENT_HYDRO) or (element == ELEMENT_HYDRO and effective_map_element == ELEMENT_PYRO):
		return REACTION_VAPORIZE
	if (element == ELEMENT_PYRO and effective_map_element == ELEMENT_ELECTRO) or (element == ELEMENT_ELECTRO and effective_map_element == ELEMENT_PYRO):
		return REACTION_OVERLOADED
	if (element == ELEMENT_HYDRO and effective_map_element == ELEMENT_ELECTRO) or (element == ELEMENT_ELECTRO and effective_map_element == ELEMENT_HYDRO):
		return REACTION_ELECTRO_CHARGED
	return REACTION_NONE

func damage_multiplier(character_name: StringName, map_element: String = "") -> float:
	return REACTION_DAMAGE_MULTIPLIERS.get(reaction_for(character_name, map_element), 1.0)

func tuned_damage(character_name: StringName, _ability_name: StringName, base_damage: float, map_element: String = "") -> float:
	return snappedf(base_damage * damage_multiplier(character_name, map_element), 0.01)

func reaction_profile(character_name: StringName, map_element: String = "") -> Dictionary:
	return REACTION_DPS_PROFILES.get(reaction_for(character_name, map_element), {})

func reaction_visual_id(character_name: StringName, map_element: String = "") -> int:
	match reaction_for(character_name, map_element):
		REACTION_VAPORIZE:
			return AURA_REACTION_VAPORIZE_FORWARD
		REACTION_OVERLOADED:
			return AURA_REACTION_OVERLOADED
		REACTION_ELECTRO_CHARGED:
			return AURA_REACTION_ELECTRO_CHARGED
	return AURA_REACTION_NONE

func spawn_character_reaction_feedback(character_name: StringName, world_position: Vector2, map_element: String = "") -> void:
	var reaction_id := reaction_visual_id(character_name, map_element)
	if reaction_id == AURA_REACTION_NONE:
		return
	REACTION_BURST_SPAWNER.play_at(world_position, reaction_id)

func _live_area_name() -> StringName:
	var tree := get_tree()
	if tree == null or tree.current_scene == null:
		return &""
	return _find_area_name(tree.current_scene)

func _find_area_name(node: Node) -> StringName:
	if _element_from_area_name(node.name) != "":
		return node.name
	for child in node.get_children():
		var match_name := _find_area_name(child)
		if match_name != &"":
			return match_name
	return &""

func _element_from_area_name(area_name: StringName) -> String:
	var text := String(area_name)
	if text.begins_with("EmberFields"):
		return ELEMENT_PYRO
	if text.begins_with("DrownedCoast"):
		return ELEMENT_HYDRO
	if text.begins_with("StormPeaks"):
		return ELEMENT_ELECTRO
	return ""

func reaction_dps_profile_for_reaction(reaction: int) -> Dictionary:
	match reaction:
		AURA_REACTION_VAPORIZE_FORWARD, AURA_REACTION_VAPORIZE_REVERSE:
			return REACTION_DPS_PROFILES[REACTION_VAPORIZE]
		AURA_REACTION_OVERLOADED:
			return REACTION_DPS_PROFILES[REACTION_OVERLOADED]
		AURA_REACTION_ELECTRO_CHARGED:
			return REACTION_DPS_PROFILES[REACTION_ELECTRO_CHARGED]
	return {}

func overload_aoe_ratio() -> float:
	return float(REACTION_DPS_PROFILES[REACTION_OVERLOADED]["aoe_ratio"])

func overload_aoe_radius_px() -> float:
	return float(REACTION_DPS_PROFILES[REACTION_OVERLOADED]["aoe_radius_px"])

func electro_charged_chain_ratio() -> float:
	return float(REACTION_DPS_PROFILES[REACTION_ELECTRO_CHARGED]["chain_ratio"])

func electro_charged_chain_radius_px() -> float:
	return float(REACTION_DPS_PROFILES[REACTION_ELECTRO_CHARGED]["chain_radius_px"])
