extends Node2D

signal health_changed(new_health: float)
signal player_died

var max_health: float = 4.0
var soul = 0.0
var coins : int = 0

var health: float = 4.0 :
	set(value):
		health = clamp(value, 0, max_health)
		health_changed.emit(health)

var dead_enemies: Dictionary = {}
var has_load_position: bool = false
var saved_player_pos: Vector2 = Vector2.ZERO

func mark_enemy_dead(key: String) -> void:
	dead_enemies[key] = true

func is_enemy_dead(key: String) -> bool:
	return dead_enemies.get(key, false)

func has_save() -> bool:
	return FileAccess.file_exists("user://save_game.json")

func save_game() -> void:
	var scene = get_tree().current_scene
	var player = scene.get_node_or_null("Player") if scene else null
	var pos = player.global_position if player else Vector2.ZERO
	var data = {
		"health": health,
		"soul": soul,
		"coins": coins,
		"dead_enemies": dead_enemies,
		"level": scene.scene_file_path if scene else "",
		"player_x": pos.x,
		"player_y": pos.y
	}
	var file = FileAccess.open("user://save_game.json", FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(data))
		file.close()

func load_game() -> void:
	if not FileAccess.file_exists("user://save_game.json"):
		return
	var file = FileAccess.open("user://save_game.json", FileAccess.READ)
	if not file:
		return
	var data = JSON.parse_string(file.get_as_text())
	file.close()
	if not data:
		return
	health = data.get("health", max_health)
	soul = data.get("soul", 0.0)
	coins = data.get("coins", 0)
	dead_enemies = data.get("dead_enemies", {})
	has_load_position = true
	saved_player_pos = Vector2(data.get("player_x", 0.0), data.get("player_y", 0.0))
	get_tree().change_scene_to_file(data.get("level", "res://src/levels/level_0/level_0.tscn"))

func reset_run_state() -> void:
	dead_enemies = {}
	has_load_position = false
	saved_player_pos = Vector2.ZERO
	health = max_health
	soul = 0.0
	coins = 0

func _process(_delta: float) -> void:
	pass
