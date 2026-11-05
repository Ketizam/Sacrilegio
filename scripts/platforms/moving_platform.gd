extends AnimatableBody2D
## Plataforma móvil con recorrido predecible (ida y vuelta, GDD 5.2).

@export var size := Vector2(32, 8)
@export var travel := Vector2(64, 0)   # desplazamiento total
@export var speed := 40.0
@export var wait_time := 0.3

var _origin := Vector2.ZERO
var _t := 0.0
var _dir := 1.0
var _wait := 0.0

func _ready() -> void:
	add_to_group("resettable")
	sync_to_physics = true
	_origin = position
	$Sprite.size = size
	var shape := RectangleShape2D.new()
	shape.size = size
	$CollisionShape2D.shape = shape
	$CollisionShape2D.position = size / 2.0

func reset() -> void:
	_t = 0.0
	_dir = 1.0
	_wait = 0.0
	position = _origin

func _physics_process(delta: float) -> void:
	if travel == Vector2.ZERO:
		return
	if _wait > 0.0:
		_wait -= delta
		return
	_t += _dir * speed * delta / travel.length()
	if _t >= 1.0:
		_t = 1.0
		_dir = -1.0
		_wait = wait_time
	elif _t <= 0.0:
		_t = 0.0
		_dir = 1.0
		_wait = wait_time
	position = _origin + travel * _t
