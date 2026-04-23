extends CanvasLayer

const HEART_ROW_SIZE = 8
const HEART_OFFSET = 16
@onready var coin_label = $coin_value
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	for i in Globals.health:
		var new_heart = Sprite2D.new()
		new_heart.texture = $heart.texture
		new_heart.hframes = $heart.hframes
		$heart.add_child(new_heart)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	soul_regeneration()
	coin_label.text = str(Globals.coins)
	
	for heart in $heart.get_children():
		var index = heart.get_index()
		var x = (index % HEART_ROW_SIZE) * HEART_OFFSET
		var y = (index / HEART_ROW_SIZE) * HEART_OFFSET
		heart.position = Vector2(x,y)
		
		var last_heart = floor(Globals.health)
		if index > last_heart:
			heart.frame = 0
		if index == last_heart:
			heart.frame = (Globals.health - last_heart) * 4
		if index < last_heart:
			heart.frame = 4

func soul_regeneration():
	if Globals.soul == 1.0:
		$soul_bar.frame = 0
	if Globals.soul == 0.75:
		$soul_bar.frame = 1
	if Globals.soul == 0.5:
		$soul_bar.frame = 2
	if Globals.soul == 0.25:
		$soul_bar.frame = 3
	if Globals.soul == 0.0:
		$soul_bar.frame = 4
