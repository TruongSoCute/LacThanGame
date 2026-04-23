extends Node

var confirm_sound = preload("res://assets/sfx/ui/ui_comfirm.wav")

func _ready():
	process_mode = Node.PROCESS_MODE_ALWAYS
	
	_connect_buttons(get_tree().root)
	
	get_tree().node_added.connect(_on_node_added)

func _on_node_added(node):
	if node is Button:
		_connect_button(node)

func _connect_buttons(root):
	for child in root.get_children():
		if child is Button:
			_connect_button(child)
		_connect_buttons(child)

func _connect_button(button: Button):
	if not button.pressed.is_connected(_play_confirm):
		button.pressed.connect(_play_confirm)

func _play_confirm():
	var asp = AudioStreamPlayer.new()
	asp.stream = confirm_sound
	asp.bus = "Master" 
	add_child(asp)
	asp.play()
	asp.finished.connect(asp.queue_free)
