extends Node

# Localization Manager (Autoload: Localization)
# Hệ thống dịch thuật thủ công để tránh lỗi KEY_... khi chưa cấu hình Godot Localization

var current_lang = "vi"

var data = {
	"vi": {
		"KEY_START": "BẮT ĐẦU",
		"KEY_NEW_GAME": "GAME MỚI",
		"KEY_OPTION": "CÀI ĐẶT",
		"KEY_EXIT": "THOÁT",
		"KEY_CONTINUE": "TIẾP TỤC",
		"KEY_KEYBOARD": "BÀN PHÍM",
		"KEY_LANGUAGE": "NGÔN NGỮ",
		"KEY_BACK": "TRỞ VỀ",
		"KEY_SELECT_LANG": "CHỌN NGÔN NGỮ",
		"KEY_ENGLISH": "TIẾNG ANH",
		"KEY_VIETNAMESE": "TIẾNG VIỆT",
		"KEY_MOVE_LEFT": "DI CHUYỂN TRÁI",
		"KEY_MOVE_RIGHT": "DI CHUYỂN PHẢI",
		"KEY_JUMP": "NHẢY",
		"KEY_DASH": "LƯỚT",
		"KEY_ATTACK": "TẤN CÔNG",
		"KEY_HEAL": "HỒI MÁU",
		"KEY_PAUSE": "TẠM DỪNG",
		"KEY_KEYBOARD_SETTING": "CÀI ĐẶT PHÍM",
		"KEY_SAVE": "LƯU GAME",
		"KEY_LOAD": "TẢI GAME",
		"KEY_MENU": "MENU CHÍNH"
	},
	"en": {
		"KEY_START": "START",
		"KEY_NEW_GAME": "NEW GAME",
		"KEY_OPTION": "SETTINGS",
		"KEY_EXIT": "EXIT",
		"KEY_CONTINUE": "CONTINUE",
		"KEY_KEYBOARD": "KEYBOARD",
		"KEY_LANGUAGE": "LANGUAGE",
		"KEY_BACK": "BACK",
		"KEY_SELECT_LANG": "SELECT LANGUAGE",
		"KEY_ENGLISH": "ENGLISH",
		"KEY_VIETNAMESE": "VIETNAMESE",
		"KEY_MOVE_LEFT": "MOVE LEFT",
		"KEY_MOVE_RIGHT": "MOVE RIGHT",
		"KEY_JUMP": "JUMP",
		"KEY_DASH": "DASH",
		"KEY_ATTACK": "ATTACK",
		"KEY_HEAL": "HEAL",
		"KEY_PAUSE": "PAUSE",
		"KEY_KEYBOARD_SETTING": "KEYBOARD SETTINGS",
		"KEY_SAVE": "SAVE GAME",
		"KEY_LOAD": "LOAD GAME",
		"KEY_MENU": "MAIN MENU"
	}
}

func get_text(key: String) -> String:
	if data[current_lang].has(key):
		return data[current_lang][key]
	return key

func set_language(lang: String):
	current_lang = lang
	# Thông báo cho các scene cập nhật lại text nếu cần
	get_tree().call_group("auto_translate", "update_text")

func translate_node(node: Node):
	if node is Button or node is Label:
		# Lấy key gốc từ metadata nếu đã có, nếu chưa thì lấy từ text hiện tại
		var key = node.get_meta("original_key", "")
		if key == "":
			if node.text.begins_with("KEY_"):
				key = node.text
				node.set_meta("original_key", key)
		
		# Nếu tìm thấy key hợp lệ, tiến hành dịch
		if key != "":
			node.text = get_text(key)
			
	for child in node.get_children():
		translate_node(child)
