extends CharacterBody2D

@export var health: int = 5
@export var damage = 1.0

func _process(_delta: float) -> void:
	if health <= 0:
		queue_free()

func _on_hitbox_area_entered(area: Area2D) -> void:
	if area.is_in_group("attack"):
		health -= 1
		if Globals.soul < 1.0:
			Globals.soul += 0.25


func _on_hitbox_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		Globals.health -= damage
