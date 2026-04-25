extends CanvasLayer

const HEART_ROW_SIZE = 8
const HEART_OFFSET = 110
@onready var coin_label = $coin_value
@onready var game_over_panel = $GameOver
@onready var restart_btn = $GameOver/VBoxContainer/RestartBtn
@onready var home_btn = $GameOver/VBoxContainer/HomeBtn
@onready var message_panel = $Message
@onready var message_label = $Message/NinePatchRect/Label

var prev_health: float = 4.0

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	add_to_group("gui")
	for i in Globals.health:
		var new_heart = Sprite2D.new()
		new_heart.texture = $heart.texture
		new_heart.hframes = $heart.hframes
		$heart.add_child(new_heart)
	# Hide the template sprite itself — children stay visible
	$heart.self_modulate = Color(1, 1, 1, 0)

	prev_health = Globals.health
	Globals.health_changed.connect(_on_health_changed)
	Globals.player_died.connect(_on_player_died)
	
	restart_btn.pressed.connect(_on_restart_pressed)
	home_btn.pressed.connect(_on_home_pressed)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	soul_regeneration()
	coin_label.text = str(Globals.coins)
	
	for heart in $heart.get_children():
		var index = heart.get_index()
		var x = (index % HEART_ROW_SIZE) * HEART_OFFSET
		var y = int(index / float(HEART_ROW_SIZE)) * HEART_OFFSET
		heart.position = Vector2(x, y)
		if float(index) < Globals.health:
			heart.modulate = Color(1, 1, 1, 1)
		else:
			heart.modulate = Color(1, 1, 1, 0.2)

func _on_health_changed(new_health: float):
	var damage = prev_health - new_health
	if damage > 0:
		# Tìm Player để spawn text trên đầu
		var player = get_tree().get_first_node_in_group("player")
		if player:
			_spawn_damage_text(player, damage)
	prev_health = new_health

func _spawn_damage_text(player: Node2D, damage: float):
	var label = Label.new()
	label.text = "-" + str(int(damage))
	label.add_theme_font_size_override("font_size", 20)
	label.add_theme_color_override("font_color", Color(1, 0.15, 0.15))
	label.add_theme_color_override("font_outline_color", Color(0, 0, 0))
	label.add_theme_constant_override("outline_size", 3)
	label.z_index = 100
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	
	# Đặt vị trí trên đầu Player
	label.global_position = player.global_position + Vector2(-15, -80)
	
	# Thêm vào scene (không phải CanvasLayer, mà vào world để text di chuyển đúng)
	player.get_parent().add_child(label)
	
	# Animation: bay lên + mờ dần
	var tween = label.create_tween()
	tween.set_parallel(true)
	tween.tween_property(label, "position:y", label.position.y - 50, 0.8).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	tween.tween_property(label, "modulate:a", 0.0, 0.8).set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_CUBIC)
	tween.chain().tween_callback(label.queue_free)

func soul_regeneration():
	$soul_bar.frame = 4 - int(round(Globals.soul * 4))

func _on_player_died():
	game_over_panel.visible = true

func _on_restart_pressed():
	Globals.reset_run_state()
	get_tree().reload_current_scene()

func _on_home_pressed():
	Globals.reset_run_state()
	get_tree().change_scene_to_file("res://src/ui/menus/main_menu/main_menu.tscn")

func show_message(text: String):
	message_label.text = text
	message_panel.visible = true
	var tween = create_tween()
	tween.tween_interval(2.0)
	tween.tween_callback(func(): message_panel.visible = false)
