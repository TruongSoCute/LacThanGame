class_name LevelTransition extends Node2D

@export_file("*.tscn") var target_level : String = ""
@export var spawn_tag: String = ""
@export var transition_tag: String = ""

@onready var area_2d: Area2D = $Area2D
@onready var portal_particles: CPUParticles2D = $PortalParticles

var transition_started := false

func _ready() -> void:
	area_2d.body_entered.connect(_on_body_entered)
	portal_particles.emitting = true
	if spawn_tag != "" and SceneManager.spawn_door_tag == spawn_tag:
		SceneManager.spawn_door_tag = ""
		call_deferred("_reposition_player")

func _reposition_player() -> void:
	var player = get_parent().get_node_or_null("Player")
	if player:
		player.global_position = global_position + Vector2(-350, 0)

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player") or body.is_in_group("Player"):
		if not transition_started:
			transition_started = true
			_change_level()

func _change_level() -> void:
	if target_level == "":
		print("LevelTransition: target_level chưa được thiết lập!")
		return
	SceneManager.spawn_door_tag = transition_tag
	Globals.health = Globals.max_health
	Globals.soul = 0.0
	get_tree().change_scene_to_file(target_level)
