extends Area2D
## Salida del nivel: al tocarla se pasa al siguiente nivel.

var _done := false

func _ready() -> void:
	body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node) -> void:
	if _done or not body.is_in_group("player"):
		return
	_done = true
	GameState.complete_level()
