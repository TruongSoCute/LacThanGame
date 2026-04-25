extends CanvasLayer

var _root: Control
var _visible: bool = false

func _ready() -> void:
	layer = 50
	process_mode = Node.PROCESS_MODE_ALWAYS
	_build_ui()
	_root.visible = false

func _build_ui() -> void:
	_root = Control.new()
	_root.anchor_right = 1.0
	_root.anchor_bottom = 1.0
	_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_root)

	var overlay = ColorRect.new()
	overlay.color = Color(0, 0, 0, 0.55)
	overlay.anchor_right = 1.0
	overlay.anchor_bottom = 1.0
	overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_root.add_child(overlay)

	var panel = Panel.new()
	panel.custom_minimum_size = Vector2(340, 340)
	panel.anchor_left = 0.5
	panel.anchor_top = 0.5
	panel.anchor_right = 0.5
	panel.anchor_bottom = 0.5
	panel.offset_left = -170
	panel.offset_top = -170
	panel.offset_right = 170
	panel.offset_bottom = 170
	_root.add_child(panel)

	var vbox = VBoxContainer.new()
	vbox.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT, Control.PRESET_MODE_MINSIZE, 24)
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_theme_constant_override("separation", 14)
	panel.add_child(vbox)

	var title = Label.new()
	title.text = "TẠM DỪNG"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 26)
	vbox.add_child(title)

	var spacer = Control.new()
	spacer.custom_minimum_size = Vector2(0, 8)
	vbox.add_child(spacer)

	_add_button(vbox, "Tiếp tục", _on_resume)
	_add_button(vbox, "Lưu game", _on_save)
	_add_button(vbox, "Tải game", _on_load)
	_add_button(vbox, "Menu chính", _on_main_menu)

func _add_button(parent: Node, text: String, callback: Callable) -> void:
	var btn = Button.new()
	btn.text = text
	btn.custom_minimum_size = Vector2(280, 50)
	btn.add_theme_font_size_override("font_size", 18)
	btn.pressed.connect(callback)
	parent.add_child(btn)

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
			_on_resume()
		else:
			show_menu()

func show_menu() -> void:
	_visible = true
	_root.visible = true
	get_tree().paused = true

func hide_menu() -> void:
	_visible = false
	_root.visible = false
	get_tree().paused = false

func _on_resume() -> void:
	hide_menu()

func _on_save() -> void:
	Globals.save_game()
	hide_menu()

func _on_load() -> void:
	hide_menu()
	Globals.load_game()

func _on_main_menu() -> void:
	hide_menu()
	Globals.reset_run_state()
	get_tree().change_scene_to_file("res://src/ui/menus/main_menu/main_menu.tscn")
