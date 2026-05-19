extends SceneTree
## Unit: APICache write-then-read round-trips a JSON dict; missing key returns null.

func _init() -> void:
	var C = preload("res://scripts/api/api_cache.gd")

	var key: String = "test_round_trip"
	var payload: Dictionary = {"name": "Test Banner", "featured": ["A", "B"]}

	C.write(key, payload)
	var loaded: Variant = C.read(key)
	assert(typeof(loaded) == TYPE_DICTIONARY, "Expected Dictionary, got %s" % typeof(loaded))
	assert(loaded["name"] == "Test Banner")
	assert(loaded["featured"] == ["A", "B"])

	var missing: Variant = C.read("definitely_not_a_key_42")
	assert(missing == null, "Missing key should return null")

	C.delete(key)

	print("[unit_genshin_api_cache] PASS")
	quit()
