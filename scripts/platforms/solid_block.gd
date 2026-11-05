@tool
extends StaticBody2D
## Bloque sólido o plataforma de un solo sentido. Se dimensiona con `size` (en píxeles).

@export var size := Vector2(16, 16): set = _set_size
@export var one_way := false: set = _set_one_way
@export var show_top_edge := true

func _set_size(v: Vector2) -> void:
	size = v
	_refresh()

func _set_one_way(v: bool) -> void:
	one_way = v
	_refresh()

func _ready() -> void:
	_refresh()

func _refresh() -> void:
	if not is_node_ready():
		return
	$Sprite.size = size
	$TopEdge.size = Vector2(size.x, 2)
	$TopEdge.visible = show_top_edge
	var shape := RectangleShape2D.new()
	shape.size = size
	$CollisionShape2D.shape = shape
	$CollisionShape2D.position = size / 2.0
	$CollisionShape2D.one_way_collision = one_way
