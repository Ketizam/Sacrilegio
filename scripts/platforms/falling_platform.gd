extends AnimatableBody2D
## Plataforma que se desploma tras pisarla (GDD 5.2). Reaparece al morir o tras un tiempo.

@export var size := Vector2(32, 8)
@export var shake_time := 0.45
@export var respawn_time := 3.0
## false = la plataforma está oculta hasta que `set_active(true)` (la usa el jefe en la fase 2).
@export var enabled_at_start := true

enum State { IDLE, SHAKING, FALLING, GONE }

var _state := State.IDLE
var _origin := Vector2.ZERO
var _timer := 0.0
var _fall_speed := 0.0
var _active := true

@onready var sprite: TextureRect = $Sprite
@onready var shape_node: CollisionShape2D = $CollisionShape2D
@onready var trigger: Area2D = $Trigger

func _ready() -> void:
	add_to_group("resettable")
	sync_to_physics = true
	_origin = position
	sprite.size = size
	var shape := RectangleShape2D.new()
	shape.size = size
	shape_node.shape = shape
	shape_node.position = size / 2.0
	var tshape := RectangleShape2D.new()
	tshape.size = Vector2(maxf(size.x - 4.0, 4.0), 4.0)
	$Trigger/CollisionShape2D.shape = tshape
	$Trigger/CollisionShape2D.position = Vector2(size.x / 2.0, -3.0)
	trigger.body_entered.connect(_on_body_entered)
	_active = enabled_at_start
	reset()

func set_active(value: bool) -> void:
	_active = value
	reset()

func reset() -> void:
	_state = State.IDLE
	_timer = 0.0
	_fall_speed = 0.0
	position = _origin
	sprite.position.x = 0.0
	visible = _active
	shape_node.set_deferred("disabled", not _active)
	trigger.set_deferred("monitoring", _active)

func _on_body_entered(body: Node) -> void:
	if _state == State.IDLE and _active and body.is_in_group("player"):
		_state = State.SHAKING
		_timer = shake_time

func _physics_process(delta: float) -> void:
	match _state:
		State.SHAKING:
			_timer -= delta
			sprite.position.x = float(randi_range(-1, 1))
			if _timer <= 0.0:
				sprite.position.x = 0.0
				_state = State.FALLING
				Sfx.play("fall")
		State.FALLING:
			_fall_speed = minf(_fall_speed + 700.0 * delta, 300.0)
			position.y += _fall_speed * delta
			if position.y > _origin.y + 140.0:
				_state = State.GONE
				_timer = respawn_time
				visible = false
				shape_node.set_deferred("disabled", true)
		State.GONE:
			_timer -= delta
			if _timer <= 0.0:
				reset()
