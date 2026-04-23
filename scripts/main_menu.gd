extends Node2D


func _ready():
	Localization.translate_node(self)

func _on_start_pressed() -> void:
	get_tree().change_scene_to_file("res://level/level_0.tscn")

func _on_option_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/setting.tscn")

func _on_exit_pressed() -> void:
	get_tree().quit()
