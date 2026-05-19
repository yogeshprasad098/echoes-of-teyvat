extends Node
## Autoload. Pure resolver for elemental reactions.
## Stateless — holds the lookup table, multipliers, and display names only.

enum Reaction { NONE, VAPORIZE_FORWARD, VAPORIZE_REVERSE, OVERLOADED, ELECTRO_CHARGED }

const MULTIPLIERS := {
	Reaction.NONE:              1.0,
	Reaction.VAPORIZE_FORWARD:  2.0,
	Reaction.VAPORIZE_REVERSE:  1.5,
	Reaction.OVERLOADED:        1.75,
	Reaction.ELECTRO_CHARGED:   1.5,
}

const NAMES := {
	Reaction.NONE:              "",
	Reaction.VAPORIZE_FORWARD:  "VAPORIZE 2.0×",
	Reaction.VAPORIZE_REVERSE:  "VAPORIZE 1.5×",
	Reaction.OVERLOADED:        "OVERLOADED",
	Reaction.ELECTRO_CHARGED:   "ELECTRO-CHARGED",
}

## Resolves the reaction caused by applying [param incoming] to [param aura].
func resolve(incoming: String, aura: String) -> Reaction:
	if incoming == "" or aura == "":
		return Reaction.NONE
	if incoming == aura:
		return Reaction.NONE
	if aura == "hydro" and incoming == "pyro":
		return Reaction.VAPORIZE_FORWARD
	if aura == "pyro" and incoming == "hydro":
		return Reaction.VAPORIZE_REVERSE
	if (aura == "pyro" and incoming == "electro") or (aura == "electro" and incoming == "pyro"):
		return Reaction.OVERLOADED
	if (aura == "hydro" and incoming == "electro") or (aura == "electro" and incoming == "hydro"):
		return Reaction.ELECTRO_CHARGED
	return Reaction.NONE

## Returns the damage multiplier for [param r].
func multiplier(r: Reaction) -> float:
	return MULTIPLIERS.get(r, 1.0)

## Returns the player-facing label for [param r].
func display_name(r: Reaction) -> String:
	return NAMES.get(r, "")
