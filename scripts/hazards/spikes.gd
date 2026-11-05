extends Area2D
## Pinchos: muerte instantánea (GDD 5.2). El origen es la esquina superior izquierda.

@export var width := 16.0

func _ready() -> void:
	$Sprite.size = Vector2(width, 10)
	var shape := RectangleShape2D.new()
	shape.size = Vector2(maxf(width - 4.0, 4.0), 5.0)
	$CollisionShape2D.shape = shape
	$CollisionShape2D.position = Vector2(width / 2.0, 7.0)
	body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node) -> void:
	if body.is_in_group("player"):
		body.die()
