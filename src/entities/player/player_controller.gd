class_name Player
extends CharacterBody2D

enum State {
	IDLE,
	RUN,
	JUMP,
	FALL,
	WALL_SLIDE,
	WALL_JUMP,
	DASH,
	ATTACK,
	HEAL,
	DEAD
}

var state: State = State.IDLE

@export_category("Movement Variable")
@export var move_speed: float = 120.0
@export var deceleration: float = 0.1
@export var gravity: float = 500.0

@export_category("Jump Variable")
@export var jump_force: float = 300.0
@export var double_jump_force: float = 280.0
@export var jump_max_amount: int = 2
@export var coyote_time: float = 0.15
@export var jump_buffer_time: float = 0.15
@export var fall_gravity_multiplier: float = 1.8
@export var jump_cut_multiplier: float = 2.5

var jump_amount: int = 0
var coyote_timer: float = 0.0
var jump_buffer_timer: float = 0.0

@export_category("Wall Jump Variable")
@export var wall_slide_speed: float = 20.0
@onready var left_ray: RayCast2D = $raycast/left_ray
@onready var right_ray: RayCast2D = $raycast/right_ray
@export var wall_x_force: float = 200.0
@export var wall_y_force: float = -220.0

@export_category("Dash Variable")
@export var dash_speed: float = 600.0
@export var dash_gravity: float = 0.0
@export var dash_number: int = 1
var facing_right: bool = true

@export_category("Melee Variable")
var attack_vfx_scene = preload("res://src/entities/player/attack_vfx.tscn")
var dash_vfx_scene = preload("res://src/entities/player/dash_vfx.tscn")

@export_category("Health Variable")
var hold_time: float = 1.0
var hold_timer: float = 0.0
var health_at_heal_start: float = 0.0

var is_invincible: bool = false
var invincibility_duration: float = 1.0

var sfx_players = {}
var was_on_floor: bool = true
var footstep_timer: float = 0.0

func _ready() -> void:
	$sword/CollisionShape2D.disabled = true

	var sounds = {
		"jump": "res://src/entities/player/sfx/coi_jump.wav",
		"dash": "res://src/entities/player/sfx/coi_dash_1.wav",
		"death": "res://src/entities/player/sfx/coi_death.wav",
		"damage": "res://src/entities/player/sfx/coi_take_damage.wav",
		"attack_miss": "res://src/entities/player/sfx/sword_4.mp3",
		"attack_hit_1": "res://src/entities/player/sfx/sword_1.wav",
		"attack_hit_2": "res://src/entities/player/sfx/sword_2.wav",
		"attack_hit_3": "res://src/entities/player/sfx/sword_3.wav",
		"landing": "res://src/entities/player/sfx/coi_landing.wav",
		"wall_slide": "res://src/entities/player/sfx/coi_wall_slide.mp3",
		"footstep": "res://src/entities/player/sfx/coi_footstep_grass.wav"
	}

	if has_node("sword"):
		$sword.area_entered.connect(_on_sword_hit)

	for key in sounds:
		var player = AudioStreamPlayer2D.new()
		player.stream = load(sounds[key])
		add_child(player)
		sfx_players[key] = player

# ─── Main loop ───────────────────────────────────────────────────────────────

func _physics_process(delta: float) -> void:
	if state == State.DEAD:
		return

	_update_timers(delta)
	_apply_gravity(delta)

	match state:
		State.IDLE, State.RUN:
			_apply_horizontal_movement()
			_try_jump()
			_try_dash()
			_try_heal()
		State.JUMP, State.FALL:
			_apply_horizontal_movement()
			_try_jump()
			_try_dash()
		State.WALL_SLIDE:
			velocity.y = wall_slide_speed
			_try_wall_jump()
		State.HEAL:
			velocity.x = 0
			_update_heal(delta)
		State.DASH, State.ATTACK, State.WALL_JUMP:
			pass

	flip()
	set_animation()
	move_and_slide()

	# Physics-driven transitions (post move_and_slide)
	match state:
		State.IDLE, State.RUN:
			if not is_on_floor():
				change_state(State.FALL)
			elif abs(velocity.x) > 0.1:
				change_state(State.RUN)
			else:
				change_state(State.IDLE)
		State.JUMP:
			if velocity.y >= 0:
				change_state(State.FALL)
			elif is_on_wall_only():
				change_state(State.WALL_SLIDE)
		State.FALL:
			if is_on_floor():
				change_state(State.RUN if abs(velocity.x) > 0.1 else State.IDLE)
			elif is_on_wall_only():
				change_state(State.WALL_SLIDE)
		State.WALL_SLIDE:
			if is_on_floor():
				change_state(State.IDLE)
			elif not is_on_wall_only():
				change_state(State.FALL)

	_handle_landing()
	_handle_footsteps(delta)
	_handle_wall_slide_sfx()

func _input(_event: InputEvent) -> void:
	if Input.is_action_just_pressed("melee_attack"):
		if state not in [State.WALL_SLIDE, State.ATTACK, State.HEAL, State.DEAD, State.DASH]:
			change_state(State.ATTACK)

# ─── State machine core ───────────────────────────────────────────────────────

func change_state(new_state: State) -> void:
	if state == new_state:
		return
	_on_state_exit(state)
	state = new_state
	_on_state_enter(new_state)

func _on_state_enter(s: State) -> void:
	match s:
		State.ATTACK:
			var sound = sfx_players["attack_miss"]
			sound.play(sound.stream.get_length() * 0.5)
			$anim.play("Attack")
			spawn_attack_vfx()
		State.DASH:
			dash_number -= 1
			sfx_players["dash"].play()
			spawn_dash_vfx()
			velocity.x = dash_speed if facing_right else -dash_speed
			_start_dash_timer()
		State.HEAL:
			hold_timer = 0.0
			health_at_heal_start = Globals.health
			$HealParticles.emitting = true
			$HealSFX.play()
		State.DEAD:
			_run_death_sequence()
		State.WALL_JUMP:
			var wall_normal = get_wall_normal()
			velocity.x = wall_normal.x * wall_x_force
			velocity.y = wall_y_force
			jump_amount = jump_max_amount - 1
			jump_buffer_timer = 0
			sfx_players["jump"].play()
			_start_wall_jump_timer()

func _on_state_exit(s: State) -> void:
	match s:
		State.HEAL:
			$HealParticles.emitting = false

# ─── Per-frame helpers ────────────────────────────────────────────────────────

func _update_timers(delta: float) -> void:
	if is_on_floor():
		coyote_timer = coyote_time
		jump_amount = jump_max_amount
		dash_number = 1
	else:
		coyote_timer -= delta

	if Input.is_action_just_pressed("jump"):
		jump_buffer_timer = jump_buffer_time
	else:
		jump_buffer_timer -= delta

func _apply_gravity(delta: float) -> void:
	match state:
		State.DASH:
			velocity.y = dash_gravity
		State.WALL_SLIDE:
			pass
		_:
			var g = gravity
			if velocity.y > 0:
				g *= fall_gravity_multiplier
			elif velocity.y < 0 and not Input.is_action_pressed("jump"):
				g *= jump_cut_multiplier
			velocity.y += g * delta

func _apply_horizontal_movement() -> void:
	var dir = Input.get_axis("move_left", "move_right")
	if dir:
		velocity.x = dir * move_speed
	else:
		velocity.x = move_toward(velocity.x, 0, move_speed * deceleration)

func _try_jump() -> void:
	if state not in [State.IDLE, State.RUN, State.JUMP, State.FALL]:
		return
	if jump_buffer_timer <= 0:
		return
	if coyote_timer > 0:
		velocity.y = -jump_force
		sfx_players["jump"].play()
		jump_amount -= 1
		jump_buffer_timer = 0
		coyote_timer = 0
		change_state(State.JUMP)
	elif jump_amount > 0:
		velocity.y = -double_jump_force
		sfx_players["jump"].play()
		jump_amount -= 1
		jump_buffer_timer = 0
		change_state(State.JUMP)
		$DoubleJumpParticles.restart()

func _try_dash() -> void:
	if state not in [State.IDLE, State.RUN, State.JUMP, State.FALL]:
		return
	if Input.is_action_just_pressed("dash") and dash_number >= 1:
		change_state(State.DASH)

func _try_heal() -> void:
	if state not in [State.IDLE, State.RUN]:
		return
	if not Input.is_action_just_pressed("healing") or not is_on_floor():
		return
	if Globals.soul < 0.5:
		var gui = get_tree().get_first_node_in_group("gui")
		if gui:
			gui.show_message("Không đủ năng lượng!")
		return
	if Globals.health < 4.0:
		change_state(State.HEAL)

func _try_wall_jump() -> void:
	if jump_buffer_timer > 0:
		change_state(State.WALL_JUMP)

func _update_heal(delta: float) -> void:
	if not is_on_floor() or Globals.health < health_at_heal_start:
		change_state(State.IDLE)
		return
	if Input.is_action_pressed("healing"):
		hold_timer += delta
		if hold_timer >= hold_time:
			can_healing()
			change_state(State.IDLE)
	else:
		change_state(State.IDLE)

# ─── Async state sequences ────────────────────────────────────────────────────

func _start_dash_timer() -> void:
	await get_tree().create_timer(0.2).timeout
	if state == State.DASH:
		change_state(State.FALL if not is_on_floor() else (State.RUN if abs(velocity.x) > 0.1 else State.IDLE))

func _start_wall_jump_timer() -> void:
	await get_tree().create_timer(0.12).timeout
	if state == State.WALL_JUMP:
		change_state(State.FALL)

func _run_death_sequence() -> void:
	sfx_players["death"].play()
	$anim.play("Die")
	await $anim.animation_finished
	await get_tree().create_timer(1.0).timeout
	Globals.player_died.emit()

# ─── Animation & visuals ──────────────────────────────────────────────────────

func set_animation() -> void:
	match state:
		State.ATTACK, State.DEAD:
			return
		State.WALL_SLIDE, State.WALL_JUMP:
			$anim.play("Wall")
		State.JUMP:
			$anim.play("Jump")
		State.FALL:
			$anim.play("Fall")
		State.RUN:
			$anim.play("Move")
		State.IDLE, State.HEAL, State.DASH:
			$anim.play("Idle")

	$Sprite2D.visible = true
	$AnimatedSprite2D.visible = false

func flip() -> void:
	if velocity.x > 0.0:
		facing_right = true
		scale.x = scale.y
	elif velocity.x < 0.0:
		facing_right = false
		scale.x = -scale.y

func spawn_attack_vfx() -> void:
	var vfx = attack_vfx_scene.instantiate()
	add_child(vfx)
	vfx.position = $sword/point.position

func spawn_dash_vfx() -> void:
	var vfx = dash_vfx_scene.instantiate()
	add_child(vfx)
	vfx.show_behind_parent = true
	vfx.position = Vector2(-60, 0)

# ─── SFX helpers ──────────────────────────────────────────────────────────────

func _handle_landing() -> void:
	var on_floor = is_on_floor()
	if on_floor and not was_on_floor:
		sfx_players["landing"].play()
	was_on_floor = on_floor

func _handle_footsteps(delta: float) -> void:
	if is_on_floor() and abs(velocity.x) > 0.1 and state not in [State.ATTACK, State.HEAL]:
		footstep_timer -= delta
		if footstep_timer <= 0:
			sfx_players["footstep"].play()
			footstep_timer = 0.35
	else:
		footstep_timer = 0.0
		if sfx_players["footstep"].playing:
			sfx_players["footstep"].stop()

func _handle_wall_slide_sfx() -> void:
	if state == State.WALL_SLIDE:
		if not sfx_players["wall_slide"].playing:
			sfx_players["wall_slide"].play()
	else:
		sfx_players["wall_slide"].stop()

# ─── Public API ───────────────────────────────────────────────────────────────

func reset_states() -> void:
	# Called by AnimationPlayer at the end of the Attack animation
	if Globals.health <= 0:
		change_state(State.DEAD)
		return
	if is_on_floor():
		change_state(State.RUN if abs(velocity.x) > 0.1 else State.IDLE)
	elif velocity.y < 0:
		change_state(State.JUMP)
	else:
		change_state(State.FALL)

func take_damage(amount: float) -> void:
	if is_invincible or state == State.DEAD:
		return
	Globals.health -= amount
	sfx_players["damage"].play()
	if Globals.health <= 0:
		change_state(State.DEAD)
	else:
		start_invincibility()

func start_invincibility() -> void:
	is_invincible = true
	var tween = create_tween()
	for i in range(5):
		tween.tween_property($Sprite2D, "modulate:a", 0.3, 0.1)
		tween.tween_property($Sprite2D, "modulate:a", 1.0, 0.1)
	await get_tree().create_timer(invincibility_duration).timeout
	is_invincible = false
	$Sprite2D.modulate.a = 1.0

func can_healing() -> void:
	if Globals.soul >= 0.5:
		Globals.health += 1
		Globals.soul -= 0.5

func _on_sword_hit(area: Area2D) -> void:
	if area.is_in_group("enemy") or (area.get_parent() and area.get_parent().is_in_group("Enemy")):
		if sfx_players["attack_miss"].playing:
			sfx_players["attack_miss"].stop()
		var random_index = randi() % 3 + 1
		sfx_players["attack_hit_" + str(random_index)].play()
