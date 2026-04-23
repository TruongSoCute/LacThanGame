class_name LevelTransition extends Node2D

@export_file("*.tscn") var target_level : String = ""
@export var wait_time : float = 2.0

@onready var area_2d: Area2D = $Area2D

var player_inside := false
var timer := 0.0
var all_enemies_dead := false
var transition_started := false

func _ready() -> void:
	area_2d.body_entered.connect(_on_body_entered)
	area_2d.body_exited.connect(_on_body_exited)

func _process(delta: float) -> void:
	if transition_started:
		return
	
	# Kiểm tra xem tất cả quái đã chết chưa
	if not all_enemies_dead:
		var enemies = get_tree().get_nodes_in_group("Enemy")
		if enemies.size() == 0:
			all_enemies_dead = true
			# Hiện thông báo cho player biết có thể qua màn
			var gui_nodes = get_tree().get_nodes_in_group("gui")
			if gui_nodes.size() > 0:
				gui_nodes[0].show_message("Đã tiêu diệt hết quái! Hãy đến cổng chuyển màn!")
		return
	
	# Nếu quái đã chết hết và player đang đứng trong vùng transition
	if player_inside:
		timer += delta
		if timer >= wait_time:
			transition_started = true
			_change_level()
	else:
		timer = 0.0

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player") or body.is_in_group("Player"):
		player_inside = true
		timer = 0.0
		if all_enemies_dead:
			var gui_nodes = get_tree().get_nodes_in_group("gui")
			if gui_nodes.size() > 0:
				gui_nodes[0].show_message("Đang chuyển màn...")

func _on_body_exited(body: Node2D) -> void:
	if body.is_in_group("player") or body.is_in_group("Player"):
		player_inside = false
		timer = 0.0

func _change_level() -> void:
	if target_level == "":
		print("LevelTransition: target_level chưa được thiết lập!")
		return
	Globals.health = Globals.max_health
	Globals.soul = 0.0
	get_tree().change_scene_to_file(target_level)
