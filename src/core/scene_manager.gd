extends Node

const scene_0 = preload("res://src/levels/level_0/level_0.tscn")
const scene_1 = preload("res://src/levels/level_1/level_1.tscn")

var spawn_door_tag

func go_to_level(level_tag, destination_tag):
	var scene_to_load
	
	match level_tag:
		"level_0":
			scene_to_load = scene_0
		"level_1": 
			scene_to_load = scene_1
			
	if scene_to_load != null:
		spawn_door_tag = destination_tag
		get_tree().change_scene_to_packed(scene_to_load)
