extends Area2D
## Corriente de viento (nivel 2). `push.x` = velocidad horizontal añadida (px/s),
## `push.y` = aceleración vertical (negativa = empuja hacia arriba).

@export var size := Vector2(48, 80)
@export var push := Vector2(60, 0)

func _ready() -> void:
	var shape := RectangleShape2D.new()
	shape.size = size
	$CollisionShape2D.shape = shape
	$CollisionShape2D.position = size / 2.0
	$Tint.size = size
	var p: CPUParticles2D = $Particles
	p.position = size / 2.0
	p.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	p.emission_rect_extents = size / 2.0
	var dir := push.normalized() if push != Vector2.ZERO else Vector2.RIGHT
	p.direction = dir
	p.initial_velocity_min = 40.0
	p.initial_velocity_max = 70.0
	p.amount = clampi(int(size.x * size.y / 250.0), 6, 40)
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)

func _on_body_entered(body: Node) -> void:
	if body.is_in_group("player"):
		body.set_wind(self, push)

func _on_body_exited(body: Node) -> void:
	if body.is_in_group("player"):
		body.clear_wind(self)
