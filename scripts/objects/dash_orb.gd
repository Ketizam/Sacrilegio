extends Area2D

@export var respawn_time := 2.5

var _active := true

func _ready() -> void:
	add_to_group("resettable")
	body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node2D) -> void:
	if not _active:
		return

	if not body.is_in_group("player"):
		return

	if body.refill_dash():
		_active = false
		visible = false

		get_tree().create_timer(respawn_time).timeout.connect(reset)

func reset() -> void:
	_active = true
	visible = true
