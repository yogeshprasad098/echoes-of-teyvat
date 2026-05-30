class_name TitleBanner
extends Label
## Listens for GenshinAPIClient.banner_loaded and updates its text.

const HIDDEN_TEXTS := ["", "Banner data unavailable"]

func _ready() -> void:
	_set_frame_visible(false)
	var client: Node = get_tree().root.get_node_or_null("GenshinAPIClient")
	if client and client.has_signal("banner_loaded"):
		client.banner_loaded.connect(_on_banner_loaded)

func _on_banner_loaded(banner_text: String) -> void:
	var clean_text := banner_text.strip_edges()
	if HIDDEN_TEXTS.has(clean_text):
		_set_frame_visible(false)
		return
	text = clean_text
	_set_frame_visible(true)

func _set_frame_visible(is_visible: bool) -> void:
	var frame := get_parent() as Control
	if frame:
		frame.visible = is_visible
