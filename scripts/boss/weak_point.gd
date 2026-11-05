extends Area2D
## Punto débil del jefe: se activa al atravesarlo con un dash.

signal hit

var active := false
var _t := 0.0

func activate(pos: Vector2) -> void:
	position = pos
	active = true
	visible = true
	set_deferred("monitoring", true)

func deactivate() -> void:
	active = false
	visible = false
	set_deferred("monitoring", false)

func _physics_process(delta: float) -> void:
	if not active or not monitoring:
		return
	_t += delta
	$Sprite.scale = Vector2.ONE * (1.0 + 0.15 * sin(_t * 8.0))
	for b in get_overlapping_bodies():
		if b.is_in_group("player") and b.is_dashing:
			deactivate()
			hit.emit()
			return
