extends CanvasLayer

var _overlay: ColorRect

func _ready() -> void:
	layer = 100
	_overlay = ColorRect.new()
	_overlay.color = Color(0, 0, 0, 0)
	_overlay.anchor_right = 1.0
	_overlay.anchor_bottom = 1.0
	_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_overlay)

func fade_to_level(target_level: String, door_tag: String) -> void:
	var t1 = create_tween()
	t1.tween_property(_overlay, "color:a", 1.0, 0.3)
	await t1.finished
	SceneManager.spawn_door_tag = door_tag
	get_tree().change_scene_to_file(target_level)
	await get_tree().process_frame
	await get_tree().process_frame
	var t2 = create_tween()
	t2.tween_property(_overlay, "color:a", 0.0, 0.4)
