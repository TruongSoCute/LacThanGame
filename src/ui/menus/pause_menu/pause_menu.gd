extends Node2D

var _visible: bool = false

@onready var canvas_layer = $CanvasLayer

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	canvas_layer.layer = 50
	canvas_layer.visible = false
	add_to_group("auto_translate")
	Localization.translate_node(self)

func update_text():
	Localization.translate_node(self)

func _is_in_gameplay() -> bool:
	var scene = get_tree().current_scene
	if not scene:
		return false
	var path = scene.scene_file_path
	return not (path.contains("main_menu") or path.contains("setting") or path.contains("menus"))

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("menu_ingame"):
		if not _visible and not _is_in_gameplay():
			return
		get_viewport().set_input_as_handled()
		if _visible:
			_on_resume_pressed()
		else:
			show_menu()

func show_menu() -> void:
	_visible = true
	canvas_layer.visible = true
	get_tree().paused = true

func hide_menu() -> void:
	_visible = false
	canvas_layer.visible = false
	get_tree().paused = false

func _on_resume_pressed() -> void:
	hide_menu()

func _on_save_pressed() -> void:
	if Globals.has_method("save_game"):
		Globals.save_game()
	hide_menu()

func _on_load_pressed() -> void:
	hide_menu()
	if Globals.has_method("load_game"):
		Globals.load_game()

func _on_setting_pressed() -> void:
	hide_menu()
	get_tree().change_scene_to_file("res://src/ui/menus/setting/setting.tscn")

func _on_main_menu_pressed() -> void:
	hide_menu()
	Globals.reset_run_state()
	get_tree().change_scene_to_file("res://src/ui/menus/main_menu/main_menu.tscn")

func _on_back_pressed() -> void:
	hide_menu()
