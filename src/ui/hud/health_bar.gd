extends Control

@export var max_value: float = 5.0:
	set(v):
		max_value = v
		_update_segments()
@export var value: float = 5.0:
	set(v):
		value = v
		_update_segments()

@onready var container = $HBoxContainer

func _ready():
	_update_segments()

func _update_segments():
	if not is_inside_tree() or not container: return
	
	# Clear existing
	for child in container.get_children():
		child.queue_free()
	
	# Create segments
	for i in range(int(max_value)):
		var panel = Panel.new()
		panel.custom_minimum_size = Vector2(20, 8)
		
		var style = StyleBoxFlat.new()
		if i < int(value):
			style.bg_color = Color(0.8, 0, 0) # Red
		else:
			style.bg_color = Color(0.2, 0.2, 0.2) # Gray
		
		style.border_width_left = 1
		style.border_width_top = 1
		style.border_width_bottom = 1
		# Only the last segment gets a right border to avoid double borders
		style.border_width_right = 1 if i == int(max_value) - 1 else 0
		style.border_color = Color(0, 0, 0, 1) # Black border
		
		panel.add_theme_stylebox_override("panel", style)
		container.add_child(panel)
