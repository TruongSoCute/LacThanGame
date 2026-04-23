extends Node2D

func _ready():
	Localization.translate_node(self)
	update_button_styles()

func _on_english_pressed() -> void:
	Localization.set_language("en")
	Localization.translate_node(self)
	update_button_styles()

func _on_vietnamese_pressed() -> void:
	Localization.set_language("vi")
	Localization.translate_node(self)
	update_button_styles()

func update_button_styles():
	var en_btn = $CanvasLayer/Panel/VBoxContainer/English
	var vi_btn = $CanvasLayer/Panel/VBoxContainer/Vietnamese
	
	en_btn.modulate = Color(1, 1, 1)
	vi_btn.modulate = Color(1, 1, 1)
	
	var en_text = Localization.get_text("KEY_ENGLISH")
	var vi_text = Localization.get_text("KEY_VIETNAMESE")
	
	if Localization.current_lang == "en":
		en_btn.modulate = Color(1, 1, 0)
		en_btn.text = "▶ " + en_text
		vi_btn.text = vi_text
	elif Localization.current_lang == "vi":
		vi_btn.modulate = Color(1, 1, 0)
		vi_btn.text = "▶ " + vi_text
		en_btn.text = en_text

func _on_back_pressed() -> void:
	get_tree().change_scene_to_file("res://src/ui/menus/setting/setting.tscn")
