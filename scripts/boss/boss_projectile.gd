extends Area2D
## Proyectil del jefe (también sirve para la ola rasante). Mata al jugador al tocarlo.

var direction := Vector2.RIGHT
var speed := 80.0

func setup(dir: Vector2, spd: float, scale_factor := 1.0) -> void:
	direction = dir
	speed = spd
	scale = Vector2.ONE * scale_factor

func _ready() -> void:
	body_entered.connect(_on_body_entered)

func _physics_process(delta: float) -> void:
	position += direction * speed * delta
	if position.x < -30.0 or position.x > 350.0 or position.y < -30.0 or position.y > 210.0:
		queue_free()

func _on_body_entered(body: Node) -> void:
	if body.is_in_group("player"):
		body.die()
		queue_free()
