class_name TitleBanner
extends Label
## Listens for GenshinAPIClient.banner_loaded and updates its text.

func _ready() -> void:
	var client: Node = get_tree().root.get_node_or_null("GenshinAPIClient")
	if client and client.has_signal("banner_loaded"):
		client.banner_loaded.connect(_on_banner_loaded)

func _on_banner_loaded(text: String) -> void:
	self.text = text
