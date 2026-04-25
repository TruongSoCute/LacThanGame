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
	if not player:
		return
	player.velocity = Vector2.ZERO
	var spawn_x = global_position.x - 350
	var space = get_world_2d().direct_space_state
	var query = PhysicsRayQueryParameters2D.create(
		Vector2(spawn_x, global_position.y - 400),
		Vector2(spawn_x, global_position.y + 400),
		2
	)
	query.exclude = [player.get_rid()]
	var hit = space.intersect_ray(query)
	if hit:
		player.global_position = Vector2(spawn_x, hit.position.y - 65)
	else:
		player.global_position = global_position + Vector2(-350, -100)

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player") or body.is_in_group("Player"):
		if not transition_started:
			transition_started = true
			_change_level()

func _change_level() -> void:
	if target_level == "":
		print("LevelTransition: target_level chưa được thiết lập!")
		return
	SceneTransition.fade_to_level(target_level, transition_tag)
