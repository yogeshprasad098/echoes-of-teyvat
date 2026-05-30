extends Node
## Autoload. Boot-time HTTPRequest for the current banner.
## Emits banner_loaded(text) on success or graceful failure.

signal banner_loaded(text: String)
signal dialogue_line_ready(speaker: String, text: String)

const ENDPOINT := "https://gshimpact.vercel.app/api/banners/current"
const CACHE_KEY := "current_banner"
const REQUEST_TIMEOUT_SEC := 4.0
const FALLBACK_TEXT := "Banner data unavailable"
const API_CACHE := preload("res://scripts/api/api_cache.gd")
const DIALOGUE_LINES := {
	&"area_EmberFields": {"speaker": "Kira", "text": "The embers are shifting. Stay sharp."},
	&"area_EmberFieldsBoss1Arena": {"speaker": "Flame Warden", "text": "Step into the ring and burn."},
	&"area_EmberFieldsLevel2": {"speaker": "Marina", "text": "The heat is boxed in here. I can cool a path."},
	&"area_EmberFieldsBoss2Arena": {"speaker": "Tide Serpent", "text": "You brought fire to deep water."},
	&"area_EmberFieldsLevel3": {"speaker": "Ryne", "text": "That charge in the air is mine to answer."},
	&"area_EmberFieldsBoss3Arena": {"speaker": "Sparking Sentinel", "text": "Count the flash before the strike."},
	&"area_EmberFieldsLevel4": {"speaker": "Kira", "text": "Ashfall ahead. Keep the party tight."},
	&"area_EmberFieldsBoss4Arena": {"speaker": "Ash Colossus", "text": "Every step shakes loose another warning."},
	&"area_EmberFieldsLevel5": {"speaker": "Kira", "text": "Last ember route. No wasted motion."},
	&"area_EmberFieldsBoss5Arena": {"speaker": "Ember Tyrant", "text": "Five flames answer to me."},
	&"area_DrownedCoast": {"speaker": "Marina", "text": "Salt spray, broken stone, and a cleaner route forward."},
	&"area_DrownedCoastBoss1Arena": {"speaker": "Tide Warden", "text": "The coast tests every first step."},
	&"area_DrownedCoastLevel2": {"speaker": "Marina", "text": "The tide is cutting new paths through the ruins."},
	&"area_DrownedCoastBoss2Arena": {"speaker": "Reef Serpent", "text": "Break against the reef, little flame."},
	&"area_DrownedCoastLevel3": {"speaker": "Ryne", "text": "Wet stone still conducts. Step with intent."},
	&"area_DrownedCoastBoss3Arena": {"speaker": "Abyss Caller", "text": "The deep answers when I call."},
	&"area_DrownedCoastLevel4": {"speaker": "Kira", "text": "The coast keeps narrowing. We push through together."},
	&"area_DrownedCoastBoss4Arena": {"speaker": "Maelstrom Sentinel", "text": "Stand still and the current owns you."},
	&"area_DrownedCoastLevel5": {"speaker": "Marina", "text": "Final water route. Keep your balance and finish it."},
	&"area_DrownedCoastBoss5Arena": {"speaker": "Drowned Leviathan", "text": "All tides end here."},
	&"area_StormPeaks": {"speaker": "Ryne", "text": "Conductive ruins. Watch the gaps and ride the rhythm."},
	&"area_StormPeaksBoss1Arena": {"speaker": "Storm Harbinger", "text": "First thunder marks your climb."},
	&"area_StormPeaksLevel2": {"speaker": "Ryne", "text": "The current is tighter here. Time the jumps."},
	&"area_StormPeaksBoss2Arena": {"speaker": "Thunder Ravager", "text": "Every step feeds the storm."},
	&"area_StormPeaksLevel3": {"speaker": "Marina", "text": "Lightning over water is not friendly. Stay dry where you can."},
	&"area_StormPeaksBoss3Arena": {"speaker": "Arc Sentinel", "text": "Count the flash. Then count your mistakes."},
	&"area_StormPeaksLevel4": {"speaker": "Kira", "text": "These pylons are boxing us in. Break through fast."},
	&"area_StormPeaksBoss4Arena": {"speaker": "Tempest Colossus", "text": "The mountain answers with force."},
	&"area_StormPeaksLevel5": {"speaker": "Ryne", "text": "Final storm route. I will lead the charge."},
	&"area_StormPeaksBoss5Arena": {"speaker": "Storm Sovereign", "text": "No charge leaves this peak without my command."},
	&"switch_Kira": {"speaker": "Kira", "text": "I will take point."},
	&"switch_Marina": {"speaker": "Marina", "text": "Swapping in. I have the range."},
	&"switch_Ryne": {"speaker": "Ryne", "text": "Let me ground this charge."},
	&"skill_Kira": {"speaker": "Kira", "text": "Fire bomb out."},
	&"skill_Marina": {"speaker": "Marina", "text": "Burst current, forward."},
	&"skill_Ryne": {"speaker": "Ryne", "text": "Shockwave ready."},
	&"boss_defeat": {"speaker": "Party", "text": "The arena is clear. Move before it settles."},
	&"area_clear": {"speaker": "Party", "text": "Route clear. Keep the momentum."},
}

var _http: HTTPRequest = null
var _emitted: bool = false

func _ready() -> void:
	_http = HTTPRequest.new()
	_http.timeout = REQUEST_TIMEOUT_SEC
	add_child(_http)
	_http.request_completed.connect(_on_request_completed)

	var cached: Variant = API_CACHE.read(CACHE_KEY)
	if typeof(cached) == TYPE_DICTIONARY:
		_emit(_format(cached))
	fetch_current_banner()

## Requests the current banner and emits fallback text if the request cannot start.
func fetch_current_banner() -> void:
	if _http == null:
		_emit_fallback_if_silent()
		return
	var err: int = _http.request(ENDPOINT)
	if err != OK:
		_emit_fallback_if_silent()

## Emits a local quote line using the same signal/fallback pattern as banner data.
func request_dialogue_line(event_name: StringName, speaker_hint: String = "") -> void:
	var line := dialogue_line_for(event_name, speaker_hint)
	dialogue_line_ready.emit(line["speaker"], line["text"])

## Returns deterministic fallback dialogue for tests and offline play.
func dialogue_line_for(event_name: StringName, speaker_hint: String = "") -> Dictionary:
	if DIALOGUE_LINES.has(event_name):
		return DIALOGUE_LINES[event_name]
	if speaker_hint != "":
		return {"speaker": speaker_hint, "text": "I am ready."}
	return {"speaker": "Party", "text": "Keep moving."}

func _on_request_completed(result: int, response_code: int, _headers: PackedStringArray, body: PackedByteArray) -> void:
	if result != HTTPRequest.RESULT_SUCCESS or response_code != 200:
		_emit_fallback_if_silent()
		return
	var parsed: Variant = JSON.parse_string(body.get_string_from_utf8())
	if typeof(parsed) != TYPE_DICTIONARY:
		_emit_fallback_if_silent()
		return
	API_CACHE.write(CACHE_KEY, parsed)
	_emit(_format(parsed))

func _format(payload: Dictionary) -> String:
	var name_str: String = ""
	if payload.has("name"):
		name_str = str(payload["name"])
	elif payload.has("title"):
		name_str = str(payload["title"])
	var featured_str: String = ""
	if payload.has("featured"):
		var f: Variant = payload["featured"]
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
