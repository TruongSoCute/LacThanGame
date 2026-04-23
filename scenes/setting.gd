extends Node2D

func _ready():
	Localization.translate_node(self)

func _on_back_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/main_menu.tscn")

func _on_language_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/language_menu.tscn")

func _on_keyboard_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/keyboard_setting.tscn")
