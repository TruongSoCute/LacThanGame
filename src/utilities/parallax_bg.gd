extends ParallaxBackground

## Script điều khiển Parallax Background tự động
## Giúp đảm bảo các layer luôn khớp và lặp lại vô tận mà không bị khoảng trống

@export var camera_path: NodePath

func _ready():
	# Đặt background ở lớp dưới cùng
	layer = -1
	
	# Duyệt qua các layer con để tự động thiết lập Mirroring nếu chưa có
	for child in get_children():
		if child is ParallaxLayer:
			_setup_layer(child)

func _setup_layer(layer_node: ParallaxLayer):
	var sprite = null
	for child in layer_node.get_children():
		if child is Sprite2D:
			sprite = child
			break
	
	if sprite and sprite.texture:
		var tex_width = sprite.texture.get_width() * sprite.scale.x
		layer_node.motion_mirroring.x = round(tex_width)

func _process(_delta):
	var cam = get_viewport().get_camera_2d()
	if cam:
		pass
