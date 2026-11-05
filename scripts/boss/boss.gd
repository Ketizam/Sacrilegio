extends Node2D
## Jefe final (GDD 7). No se golpea directamente: hay que atravesar su punto débil con un dash.
## 3 fases de 4 impactos. Cada ataque avisa visual y sonoramente antes de ejecutarse.
## SIN puntos de control por fase: el único es el inicio del combate. Si mueres, empiezas desde la fase 1.

const PROJECTILE := preload("res://scenes/boss/boss_projectile.tscn")
const BEAM := preload("res://scenes/boss/boss_beam.tscn")
const BEAM_COLUMNS := [24.0, 72.0, 120.0, 168.0, 216.0, 264.0, 296.0]
const FLOOR_Y := 152.0

@export var hits_per_phase := 4
# Valores por fase (fase 1, 2, 3)
@export var attack_interval := [1.5, 1.0, 0.55]
@export var projectile_speed := [95.0, 130.0, 165.0]
@export var shot_count := [1, 3, 5]
@export var shot_fan := [0.0, 26.0, 44.0]       # apertura total del abanico en grados
@export var shot_telegraph := [0.65, 0.5, 0.4]
@export var beam_count := [2, 3, 5]
@export var beam_warn := [0.9, 0.8, 0.65]
@export var sweep_warn := [0.9, 0.75, 0.6]
@export var weak_point_time := [4.5, 3.5, 2.8]  # si no lo golpeas a tiempo, cambia de lugar
## Posiciones (coordenadas de la sala) donde puede aparecer el punto débil.
@export var slot_positions: Array[Vector2] = []

var phase := 1
var hits := 0

var _started := false
var _done := false
var _gen := 0          # se incrementa para cancelar ataques en curso
var _busy := false
var _aiming := false
var _slot := -1
var _wp_time := 0.0
var _last_attack := ""
var _time := 0.0
var _body_y := 0.0

@onready var body_sprite: Sprite2D = $Body
@onready var weak_point: Area2D = $WeakPoint
@onready var attack_timer: Timer = $AttackTimer
@onready var aim_line: Line2D = $AimLine
@onready var attacks: Node2D = $Attacks

func _ready() -> void:
	add_to_group("resettable")
	add_to_group("boss")
	_body_y = body_sprite.position.y
	weak_point.hit.connect(_on_weak_point_hit)
	attack_timer.timeout.connect(_on_attack_timer)

## Lo llama el nivel cuando el jugador entra a la arena.
func start_fight() -> void:
	if _started:
		return
	_started = true
	phase = 1
	_enter_phase()

## Se llama al reaparecer el jugador: no hay checkpoint por fase, se reinicia todo el combate.
func reset() -> void:
	if _done or not _started:
		return
	phase = 1
	_enter_phase()

func _player() -> Node2D:
	return get_tree().get_first_node_in_group("player") as Node2D

func _player_pos() -> Vector2:
	var p := _player()
	return to_local(p.global_position) if p else Vector2(160, FLOOR_Y)

func _muzzle() -> Vector2:
	return body_sprite.position + Vector2(0, 14)

func _process(delta: float) -> void:
	_time += delta
	if not _done:
		body_sprite.position.y = _body_y + sin(_time * 2.0) * 3.0
	if _aiming:
		aim_line.points = PackedVector2Array([_muzzle(), _player_pos()])
	if _started and not _done and weak_point.active:
		_wp_time -= delta
		if _wp_time <= 0.0:
			_next_slot()

func _draw() -> void:
	# Indicador discreto: casillas de impactos y puntos de fase
	var x0 := 160.0 - 22.0
	for i in hits_per_phase:
		var c := Color(0.94, 0.74, 0.3) if i < hits else Color(0.26, 0.24, 0.45)
		draw_rect(Rect2(x0 + i * 12.0, 6.0, 9.0, 3.0), c)
	for i in 3:
		var c2 := Color(1, 0.3, 0.37) if i < phase else Color(0.26, 0.24, 0.45)
		draw_rect(Rect2(160.0 - 12.0 + i * 8.0, 12.0, 6.0, 2.0), c2)

# ---------- fases ----------

func _enter_phase() -> void:
	_gen += 1
	_busy = false
	_aiming = false
	_clear_attacks()
	hits = 0
	get_tree().call_group("phase2_platforms", "set_active", phase >= 2)
	_next_slot()
	attack_timer.start(1.4 if phase == 1 else 1.0)
	queue_redraw()

func _clear_attacks() -> void:
	for c in attacks.get_children():
		c.queue_free()
	aim_line.visible = false
	aim_line.modulate.a = 1.0
	body_sprite.modulate = Color.WHITE

func _next_slot() -> void:
	if slot_positions.is_empty():
		return
	var i := randi() % slot_positions.size()
	if slot_positions.size() > 1:
		while i == _slot:
			i = randi() % slot_positions.size()
	_slot = i
	_wp_time = weak_point_time[phase - 1]
	weak_point.activate(slot_positions[i])

func _on_weak_point_hit() -> void:
	if _done:
		return
	hits += 1
	Sfx.play("hit")
	_gen += 1
	_busy = false
	_aiming = false
	_clear_attacks()
	var tw := create_tween()
	tw.tween_property(body_sprite, "modulate", Color(3, 3, 3, 1), 0.06)
	tw.tween_property(body_sprite, "modulate", Color.WHITE, 0.2)
	queue_redraw()
	if hits >= hits_per_phase:
		if phase >= 3:
			_victory()
		else:
			phase += 1
			_enter_phase()
	else:
		_next_slot()
		attack_timer.start(1.0)

func _victory() -> void:
	_done = true
	attack_timer.stop()
	weak_point.deactivate()
	Sfx.play("win")
	var tw := create_tween().set_parallel(true)
	tw.tween_property(body_sprite, "modulate:a", 0.0, 1.5)
	tw.tween_property(body_sprite, "scale", Vector2(1.6, 1.6), 1.5)
	await get_tree().create_timer(2.0, false).timeout
	GameState.finish_game()

# ---------- ataques ----------

func _on_attack_timer() -> void:
	var p := _player()
	if _done or _busy or p == null or p.dead:
		attack_timer.start(0.5)
		return
	var options := ["shot", "beams"]
	if phase >= 2:
		options.append("sweep")
	if phase >= 3:
		options.append("double_sweep")
	if options.size() > 1:
		options.erase(_last_attack)
	var choice: String = options.pick_random()
	_last_attack = choice
	var g := _gen
	_busy = true
	match choice:
		"shot": await _attack_shot(g)
		"beams": await _attack_beams(g)
		"sweep": await _attack_sweep(g, false)
		"double_sweep": await _attack_sweep(g, true)
	if g != _gen:
		return
	_busy = false
	attack_timer.start(attack_interval[phase - 1])

func _warn_color() -> void:
	body_sprite.modulate = Color(1.6, 0.6, 0.6)

func _attack_shot(g: int) -> void:
	var i := phase - 1
	Sfx.play("warn")
	_warn_color()
	aim_line.visible = true
	aim_line.default_color = Color(1, 0.3, 0.37, 0.6)
	_aiming = true
	await get_tree().create_timer(shot_telegraph[i], false).timeout
	if g != _gen: return
	_aiming = false     # la línea queda fija: avisa de la trayectoria
	await get_tree().create_timer(0.25, false).timeout
	if g != _gen: return
	var target: Vector2 = aim_line.points[1] if aim_line.points.size() > 1 else _muzzle() + Vector2.DOWN
	var base_dir := (target - _muzzle()).normalized()
	var n: int = shot_count[i]
	for k in n:
		var ang := 0.0
		if n > 1:
			ang = deg_to_rad(-shot_fan[i] / 2.0 + shot_fan[i] * k / float(n - 1))
		var pr := PROJECTILE.instantiate()
		attacks.add_child(pr)
		pr.position = _muzzle()
		pr.setup(base_dir.rotated(ang), projectile_speed[i])
	aim_line.visible = false
	body_sprite.modulate = Color.WHITE

func _attack_beams(g: int) -> void:
	var i := phase - 1
	Sfx.play("warn")
	_warn_color()
	var cols := BEAM_COLUMNS.duplicate()
	cols.shuffle()
	var chosen: Array = []
	var px := _player_pos().x
	var nearest: float = cols[0]
	for c in cols:   # una columna siempre cae sobre el jugador
		if absf(c - px) < absf(nearest - px):
			nearest = c
	chosen.append(nearest)
	cols.erase(nearest)
	var n: int = beam_count[i]
	while chosen.size() < n and not cols.is_empty():
		chosen.append(cols.pop_front())
	for x in chosen:
		var b := BEAM.instantiate()
		attacks.add_child(b)
		b.setup(x, beam_warn[i], 0.35)
	await get_tree().create_timer(beam_warn[i] + 0.45, false).timeout
	if g != _gen: return
	body_sprite.modulate = Color.WHITE

func _attack_sweep(g: int, both_sides: bool) -> void:
	var i := phase - 1
	Sfx.play("warn")
	_warn_color()
	aim_line.visible = true
	aim_line.default_color = Color(1, 0.3, 0.37, 0.6)
	aim_line.points = PackedVector2Array([Vector2(0, FLOOR_Y), Vector2(320, FLOOR_Y)])
	var tw := create_tween().set_loops(4)
	tw.tween_property(aim_line, "modulate:a", 0.2, 0.1)
	tw.tween_property(aim_line, "modulate:a", 1.0, 0.1)
	await get_tree().create_timer(sweep_warn[i], false).timeout
	tw.kill()
	aim_line.modulate.a = 1.0
	if g != _gen: return
	aim_line.visible = false
	var from_left := randf() < 0.5
	_spawn_wave(from_left)
	if both_sides:
		_spawn_wave(not from_left)
	body_sprite.modulate = Color.WHITE
	await get_tree().create_timer(1.0, false).timeout

func _spawn_wave(from_left: bool) -> void:
	var pr := PROJECTILE.instantiate()
	attacks.add_child(pr)
	pr.position = Vector2(-10.0 if from_left else 330.0, FLOOR_Y)
	pr.setup(Vector2.RIGHT if from_left else Vector2.LEFT, 120.0 + 15.0 * phase, 1.6)
