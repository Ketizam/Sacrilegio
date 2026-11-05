extends Area2D
## Resorte: impulso vertical fijo (GDD 5.2).

@export var force := 560.0

func _ready() -> void:
	body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node) -> void:
	if body.is_in_group("player") and body.velocity.y >= 0.0:
		body.bounce(force)
		var tw := create_tween()
		tw.tween_property($Sprite, "scale:y", 0.5, 0.05)
		tw.tween_property($Sprite, "scale:y", 1.0, 0.12)
