class_name APICache
extends Object
## Disk cache for API responses. Stored as JSON under user://api_cache/.
## Static methods only — no autoload needed.

const CACHE_DIR := "user://api_cache/"

static func _ensure_dir() -> void:
	var d := DirAccess.open("user://")
	if d == null:
		return
	if not d.dir_exists("api_cache"):
		d.make_dir("api_cache")

static func _path(key: String) -> String:
	return CACHE_DIR + key + ".json"

static func write(key: String, value: Variant) -> void:
	_ensure_dir()
	var f: FileAccess = FileAccess.open(_path(key), FileAccess.WRITE)
	if f == null:
		return
	f.store_string(JSON.stringify(value))
	f.close()

static func read(key: String) -> Variant:
	var path: String = _path(key)
	if not FileAccess.file_exists(path):
		return null
	var f: FileAccess = FileAccess.open(path, FileAccess.READ)
	if f == null:
		return null
	var content: String = f.get_as_text()
	f.close()
	var parsed: Variant = JSON.parse_string(content)
	return parsed

static func delete(key: String) -> void:
	var path: String = _path(key)
	if FileAccess.file_exists(path):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
