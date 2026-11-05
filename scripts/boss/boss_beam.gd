extends Area2D
## Rayo vertical: primero se muestra una advertencia parpadeante y luego daña.

var armed := false

func setup(x: float, warn_time := 0.9, active_time := 0.35) -> void:
	position = Vector2(x, 90.0)
	_run(warn_time, active_time)

func _ready() -> void:
	monitoring = false
	$Visual.color = Color(1, 0.3, 0.37, 0.18)

func _run(warn_time: float, active_time: float) -> void:
	var tw := create_tween().set_loops(int(warn_time / 0.2))
	tw.tween_property($Visual, "color:a", 0.4, 0.1)
	tw.tween_property($Visual, "color:a", 0.12, 0.1)
	await get_tree().create_timer(warn_time, false).timeout
	tw.kill()
	armed = true
	monitoring = true
	$Visual.color = Color(1, 0.3, 0.37, 0.9)
	await get_tree().create_timer(active_time, false).timeout
	queue_free()

func _physics_process(_delta: float) -> void:
	if not armed:
		return
	for b in get_overlapping_bodies():
		if b.is_in_group("player"):
			b.die()
