extends SceneTree
## Verifies all expected autoloads are declared in project.godot.
## Note: `--script` mode does not instantiate autoloads; we check ProjectSettings directly.

const EXPECTED := [
	"ScreenShake",
	"HitStop",
	"CheckpointSystem",
	"ElementalReactions",
	"CharacterSwitcher",
	"GenshinAPIClient",
	"ProjectilePool",
]

func _init() -> void:
	for name in EXPECTED:
		var key: String = "autoload/" + name
		assert(ProjectSettings.has_setting(key), "%s autoload not registered in project.godot" % name)
		var path: String = ProjectSettings.get_setting(key)
		assert(path.begins_with("*"), "%s must be a singleton (prefixed with *)" % name)
		assert(ResourceLoader.exists(path.lstrip("*")), "%s script file missing" % name)

	print("[unit_autoloads_registered] PASS")
	quit()
