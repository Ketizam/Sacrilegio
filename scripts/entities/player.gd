extends CharacterBody2D
## Jugador (GDD 5.1): correr con aceleración/fricción, salto de altura variable
## (sin doble salto) y dash en 8 direcciones con 1 uso en el aire.

signal died

@export_group("Movimiento")
@export var run_speed := 100.0
@export var acceleration := 900.0
@export var friction := 1100.0
@export var air_acceleration := 700.0
@export var gravity := 980.0
@export var max_fall_speed := 320.0
@export_group("Salto")
@export var jump_velocity := -330.0
@export var jump_cut_factor := 0.45   # al soltar el botón se recorta el salto
@export var coyote_time := 0.08
@export var jump_buffer_time := 0.10
@export_group("Dash")
@export var dash_speed := 260.0
@export var dash_duration := 0.15
@export var dash_cooldown := 0.2

var is_dashing := false
var can_dash := true
var dead := false

var _jumping := false
var _coyote := 0.0
var _jump_buffer := 0.0
var _facing := 1
var _dash_dir := Vector2.RIGHT
var _was_on_floor := true
var _winds := {}   # fuente -> Vector2
var _dash_cooldown_left := 0.0
# --- Animación procedural (sin sprites nuevos) ---
const AIR_ANIM := "run"          # imagen que se usa en el aire: "run" o "idle"
const SPRITE_FEET := 8.0         # distancia del centro del jugador a sus pies
const GHOST_INTERVAL := 0.035    # cada cuánto aparece una imagen residual al hacer dash

var _fall_speed := 0.0           # velocidad vertical justo antes de chocar (para el aplastamiento)
var _run_time := 0.0
var _idle_time := 0.0
var _ghost_timer := 0.0

@onready var sprite: AnimatedSprite2D = $Sprite
@onready var collision: CollisionShape2D = $CollisionShape2D
@onready var dash_timer: Timer = $DashTimer
@onready var death_particles: CPUParticles2D = $DeathParticles
@onready var dash_particles: CPUParticles2D = $DashParticles

func _ready() -> void:
	dash_timer.wait_time = dash_duration
	dash_timer.one_shot = true
	dash_timer.timeout.connect(_on_dash_timeout)
	sprite.position = Vector2(0, SPRITE_FEET)
	sprite.offset = Vector2(0, -SPRITE_FEET)

func _physics_process(delta: float) -> void:
	_dash_cooldown_left -= delta
	
	if dead:
		return
	if is_dashing:
		_dash_visuals(delta)
		move_and_slide()
		return

	var on_floor := is_on_floor()
	var wind := _total_wind()

	if on_floor:
		_coyote = coyote_time
		can_dash = true   # se recarga al tocar suelo (GDD 5.1)
		if not _was_on_floor:
			Sfx.play("land")
			_on_land()
	else:
		_coyote -= delta
		velocity.y = minf(velocity.y + (gravity + wind.y) * delta, max_fall_speed)
		if wind.y < 0.0:
			velocity.y = maxf(velocity.y, -140.0)
	_was_on_floor = on_floor

	# Salto con búfer y coyote time
	if Input.is_action_just_pressed("jump"):
		_jump_buffer = jump_buffer_time
	_jump_buffer -= delta
	if _jump_buffer > 0.0 and _coyote > 0.0:
		velocity.y = jump_velocity
		_jumping = true
		_jump_buffer = 0.0
		_coyote = 0.0
		Sfx.play("jump")
		_on_jump()
	# Salto de altura variable: soltar el botón recorta la subida
	if Input.is_action_just_released("jump") and _jumping and velocity.y < 0.0:
		velocity.y *= jump_cut_factor
		_jumping = false
	if velocity.y >= 0.0:
		_jumping = false

	# Dash
	if Input.is_action_just_pressed("dash") and can_dash and _dash_cooldown_left <= 0.0:
		_start_dash()
		return

	# Movimiento horizontal con aceleración y fricción cortas
	var dir := Input.get_axis("move_left", "move_right")
	if dir != 0.0:
		_facing = 1 if dir > 0.0 else -1
		var accel := acceleration if on_floor else air_acceleration
		velocity.x = move_toward(velocity.x, dir * run_speed, accel * delta)
	else:
		var f := friction if on_floor else air_acceleration * 0.5
		velocity.x = move_toward(velocity.x, 0.0, f * delta)

	velocity.x += wind.x
	_fall_speed = velocity.y
	move_and_slide()
	if not is_on_wall():
		velocity.x -= wind.x

	_update_visuals(dir, on_floor, delta)

func _update_visuals(dir: float, on_floor: bool, delta: float) -> void:
	sprite.flip_h = _facing < 0
	var moving := on_floor and dir != 0.0 and absf(velocity.x) > 5.0

	# Qué imagen usar
	if not on_floor:
		sprite.play(AIR_ANIM)
	elif moving:
		sprite.play("run")
	else:
		sprite.play("idle")

	# Escala (aplastar/estirar), rotación (inclinación) y altura de los pies objetivo
	var target_scale := Vector2.ONE
	var target_rot := 0.0
	var feet_lift := 0.0

	if not on_floor:
		# En el aire se estira según la velocidad vertical
		var s := clampf(absf(velocity.y) / 1000.0, 0.0, 0.2)
		target_scale = Vector2(1.0 - s * 0.6, 1.0 + s)
		target_rot = clampf(velocity.x / run_speed, -1.0, 1.0) * deg_to_rad(6.0)
	elif moving:
		# Corriendo: se inclina hacia delante y da un saltito en cada paso
		var speed_ratio := clampf(absf(velocity.x) / run_speed, 0.0, 1.0)
		_run_time += delta * 16.0 * speed_ratio
		target_rot = signf(velocity.x) * deg_to_rad(8.0) * speed_ratio
		feet_lift = roundf(absf(sin(_run_time)) * 1.4)
	else:
		# Quieto: respira (se alarga un poco y vuelve)
		_idle_time += delta
		target_scale = Vector2(1.0, 1.0 + (sin(_idle_time * 3.0) * 0.5 + 0.5) * 0.06)

	# Suavizado: los impulsos de salto/aterrizaje se relajan solos hasta el objetivo
	var k := 1.0 - exp(-14.0 * delta)
	sprite.scale = sprite.scale.lerp(target_scale, k)
	sprite.rotation = lerp_angle(sprite.rotation, target_rot, k)
	sprite.position.y = SPRITE_FEET - feet_lift

	# Indicador discreto de dash (GDD 10.2): el personaje se tiñe si no tiene dash
	sprite.modulate = Color.WHITE if can_dash else Color(0.55, 0.65, 1.0)
func _start_dash() -> void:
	is_dashing = true
	can_dash = false
	_jumping = false
	# 8 direcciones
	var v := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	var d := Vector2(
		signf(v.x) if absf(v.x) > 0.3 else 0.0,
		signf(v.y) if absf(v.y) > 0.3 else 0.0).normalized()
	if d == Vector2.ZERO:
		d = Vector2(_facing, 0)
	_dash_dir = d
	if d.x != 0.0:
		_facing = 1 if d.x > 0.0 else -1
	velocity = d * dash_speed
	dash_particles.emitting = true
	sprite.flip_h = _facing < 0
	sprite.play("run")
	sprite.modulate = Color(0.55, 0.65, 1.0)
	Sfx.play("dash")
	dash_timer.start()
	_ghost_timer = 0.0
	sprite.rotation = 0.0
	sprite.position.y = SPRITE_FEET
	if d.x != 0.0 and d.y == 0.0:
		_squash(Vector2(1.6, 0.6))    # dash horizontal: largo y bajo
	elif d.x == 0.0:
		_squash(Vector2(0.6, 1.6))    # dash vertical: alto y delgado
	else:
		_squash(Vector2(1.35, 0.8))   # diagonal
	_dust(4)

func _on_dash_timeout() -> void:
	_dash_cooldown_left = dash_cooldown
	is_dashing = false
	dash_particles.emitting = false
	velocity = _dash_dir * dash_speed * 0.3
	if velocity.y < 0.0:
		velocity.y *= 0.5

# ---------- API para el nivel ----------

func bounce(force: float) -> void:
	velocity.y = -force
	_jumping = false
	_coyote = 0.0
	Sfx.play("spring")
	is_dashing = false
	dash_timer.stop()
	dash_particles.emitting = false
	_squash(Vector2(0.6, 1.6))
	_dust(5)

## Devuelve true si realmente se recargó el dash (objeto de dash).
func refill_dash() -> bool:
	if dead:
		return false

	can_dash = true
	_dash_cooldown_left = 0.0

	Sfx.play("refill")
	return true

func set_wind(source: Object, push: Vector2) -> void:
	_winds[source] = push

func clear_wind(source: Object) -> void:
	_winds.erase(source)

func _total_wind() -> Vector2:
	var t := Vector2.ZERO
	for k in _winds:
		t += _winds[k]
	return t

func die() -> void:
	if dead:
		return
	dead = true
	is_dashing = false
	dash_timer.stop()
	dash_particles.emitting = false
	velocity = Vector2.ZERO
	_winds.clear()
	_death_pop()
	sprite.visible = false
	collision.set_deferred("disabled", true)
	death_particles.restart()
	death_particles.emitting = true
	Sfx.play("death")
	died.emit()

func respawn(pos: Vector2) -> void:
	global_position = pos
	velocity = Vector2.ZERO
	can_dash = true
	_dash_cooldown_left = 0.0
	_jumping = false
	_jump_buffer = 0.0
	_coyote = 0.0
	_winds.clear()
	sprite.visible = true
	sprite.scale = Vector2(0.3, 1.5)
	sprite.rotation = 0.0
	_dust(5)
	sprite.modulate = Color.WHITE
	# Se reactiva la colisión DESPUÉS de que el motor registre la nueva posición;
	# si no, las áreas (pinchos) ven al jugador en su sitio anterior y lo matan otra vez.
	await get_tree().physics_frame
	await get_tree().physics_frame
	collision.disabled = false
	dead = false
	
	# ---------- Animación procedural ----------

func _squash(s: Vector2) -> void:
	sprite.scale = s

func _on_jump() -> void:
	_squash(Vector2(0.75, 1.3))
	_dust(3)

func _on_land() -> void:
	if _fall_speed < 60.0:
		return
	var impact := clampf(_fall_speed / max_fall_speed, 0.0, 1.0)
	_squash(Vector2(1.0 + 0.35 * impact, 1.0 - 0.35 * impact))
	_dust(2 + int(impact * 6.0))

func _dash_visuals(delta: float) -> void:
	_ghost_timer -= delta
	if _ghost_timer <= 0.0:
		_ghost_timer = GHOST_INTERVAL
		_spawn_ghost()

## Imagen residual azul que se desvanece detrás del jugador durante el dash.
func _spawn_ghost() -> void:
	var g := Sprite2D.new()
	g.texture = sprite.sprite_frames.get_frame_texture(sprite.animation, sprite.frame)
	g.offset = sprite.offset
	g.flip_h = sprite.flip_h
	g.scale = sprite.scale
	g.rotation = sprite.rotation
	g.modulate = Color(0.55, 0.65, 1.0, 0.6)
	var world := get_parent()
	world.add_child(g)
	world.move_child(g, get_index())   # justo detrás del jugador
	g.global_position = sprite.global_position
	var tw := g.create_tween()
	tw.tween_property(g, "modulate:a", 0.0, 0.25)
	tw.tween_callback(g.queue_free)

## Destello blanco que se expande y se desvanece al morir.
func _death_pop() -> void:
	var g := Sprite2D.new()
	g.texture = sprite.sprite_frames.get_frame_texture(sprite.animation, sprite.frame)
	g.offset = sprite.offset
	g.flip_h = sprite.flip_h
	g.modulate = Color(1, 1, 1, 0.9)
	var world := get_parent()
	world.add_child(g)
	g.global_position = sprite.global_position
	var tw := g.create_tween().set_parallel(true)
	tw.tween_property(g, "scale", Vector2(1.8, 1.8), 0.18)
	tw.tween_property(g, "modulate:a", 0.0, 0.18)
	tw.chain().tween_callback(g.queue_free)

## Nubecita de polvo en los pies.
func _dust(amount: int) -> void:
	var p := CPUParticles2D.new()
	p.one_shot = true
	p.emitting = false
	p.amount = amount
	p.lifetime = 0.35
	p.explosiveness = 1.0
	p.direction = Vector2(0, -1)
	p.spread = 70.0
	p.gravity = Vector2(0, 120)
	p.initial_velocity_min = 15.0
	p.initial_velocity_max = 35.0
	p.scale_amount_min = 1.0
	p.scale_amount_max = 2.0
	p.color = Color(0.8, 0.8, 0.9, 0.7)
	var world := get_parent()
	world.add_child(p)
	p.global_position = global_position + Vector2(0, SPRITE_FEET)
	p.emitting = true
	get_tree().create_timer(1.0, false).timeout.connect(p.queue_free)
