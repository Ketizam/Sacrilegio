extends Node2D
## Sala de un nivel: pantalla fija de 320x180 con su punto de control (Spawn).

@export var size := Vector2(320, 180)

func get_rect() -> Rect2:
	return Rect2(global_position, size)

func get_spawn_position() -> Vector2:
	return $Spawn.global_position
