extends Node
## Autoload. Boot-time HTTPRequest for the current banner.
## Emits banner_loaded(text) on success or graceful failure.

signal banner_loaded(text: String)

const ENDPOINT := "https://gshimpact.vercel.app/api/banners/current"
const CACHE_KEY := "current_banner"
const REQUEST_TIMEOUT_SEC := 4.0
const FALLBACK_TEXT := "Banner data unavailable"

var _http: HTTPRequest = null
var _emitted: bool = false

func _ready() -> void:
	_http = HTTPRequest.new()
	_http.timeout = REQUEST_TIMEOUT_SEC
	add_child(_http)
	_http.request_completed.connect(_on_request_completed)

	var cached: Variant = APICache.read(CACHE_KEY)
	if typeof(cached) == TYPE_DICTIONARY:
		_emit(_format(cached))
	fetch_current_banner()

func fetch_current_banner() -> void:
	if _http == null:
		_emit_fallback_if_silent()
		return
	var err: int = _http.request(ENDPOINT)
	if err != OK:
		_emit_fallback_if_silent()

func _on_request_completed(result: int, response_code: int, _headers: PackedStringArray, body: PackedByteArray) -> void:
	if result != HTTPRequest.RESULT_SUCCESS or response_code != 200:
		_emit_fallback_if_silent()
		return
	var parsed: Variant = JSON.parse_string(body.get_string_from_utf8())
	if typeof(parsed) != TYPE_DICTIONARY:
		_emit_fallback_if_silent()
		return
	APICache.write(CACHE_KEY, parsed)
	_emit(_format(parsed))

func _format(payload: Dictionary) -> String:
	var name_str: String = ""
	if payload.has("name"):
		name_str = str(payload["name"])
	elif payload.has("title"):
		name_str = str(payload["title"])
	var featured_str: String = ""
	if payload.has("featured"):
		var f = payload["featured"]
		if f is Array and f.size() > 0:
			featured_str = str(f[0])
		elif f is String:
			featured_str = f
	if name_str == "" and featured_str == "":
		return FALLBACK_TEXT
	if featured_str == "":
		return "Banner: %s" % name_str
	if name_str == "":
		return "Featured: %s" % featured_str
	return "Banner: %s — Featured: %s" % [name_str, featured_str]

func _emit(text: String) -> void:
	_emitted = true
	banner_loaded.emit(text)

func _emit_fallback_if_silent() -> void:
	if not _emitted:
		_emit(FALLBACK_TEXT)
