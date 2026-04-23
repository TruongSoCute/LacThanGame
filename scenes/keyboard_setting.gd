extends Node2D

@onready var action_list = $CanvasLayer/Panel/ScrollContainer/ActionList

var actions = {
	"move_left": "KEY_MOVE_LEFT",
	"move_right": "KEY_MOVE_RIGHT",
	"jump": "KEY_JUMP",
	"dash": "KEY_DASH",
	"melee_attack": "KEY_ATTACK",
	"healing": "KEY_HEAL"
}

var remapping_action = null
var remapping_button = null

func _ready():
	Localization.translate_node(self)
	create_action_list()

func create_action_list():
	for action in actions:
		var hbox = HBoxContainer.new()
		hbox.custom_minimum_size.y = 60
		
		var label = Label.new()
		label.text = Localization.get_text(actions[action])
		label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		label.add_theme_font_size_override("font_size", 24) 
		
		var button = Button.new()
		button.custom_minimum_size.x = 200
		button.add_theme_font_size_override("font_size", 24)
		button.text = get_current_key_text(action)
		button.pressed.connect(_on_remap_button_pressed.bind(action, button))
		
		hbox.add_child(label)
		hbox.add_child(button)
		action_list.add_child(hbox)

func get_current_key_text(action):
	var events = InputMap.action_get_events(action)
	if events.size() > 0:
		return events[0].as_text().replace(" (Physical)", "")
	return "None"

func _on_remap_button_pressed(action, button):
	if remapping_action == null:
		remapping_action = action
		remapping_button = button
		button.text = "..." # Trạng thái chờ nhấn phím
		button.modulate = Color(1, 1, 0)

func _input(event):
	if remapping_action != null and event is InputEventKey and event.is_pressed():
		# Thay đổi phím trong InputMap
		InputMap.action_erase_events(remapping_action)
		InputMap.action_add_event(remapping_action, event)
		
		# Cập nhật UI
		remapping_button.text = event.as_text().replace(" (Physical)", "")
		remapping_button.modulate = Color(1, 1, 1)
		
		# Reset trạng thái
		remapping_action = null
		remapping_button = null
		
		# Ngăn chặn phím vừa nhấn kích hoạt các chức năng khác ngay lập tức
		get_viewport().set_input_as_handled()

func _on_back_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/setting.tscn")
