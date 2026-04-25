extends Node2D

@onready var continue_btn: Button = $"Button Manager/continue"

func _ready():
	Localization.translate_node(self)
	continue_btn.visible = Globals.has_save()

func _on_continue_pressed() -> void:
	Globals.load_game()

func _on_start_pressed() -> void:
	Globals.reset_run_state()
	get_tree().change_scene_to_file("res://src/levels/level_0/level_0.tscn")

func _on_option_pressed() -> void:
	get_tree().change_scene_to_file("res://src/ui/menus/setting/setting.tscn")

func _on_exit_pressed() -> void:
	get_tree().quit()
