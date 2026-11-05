extends "res://scripts/levels/room.gd"
## Sala de tutorial (antes del nivel 1). Construye por código el suelo, el escalón alto,
## el resorte, el orbe de dash y los carteles de ayuda.
## Los números de abajo se pueden cambiar para mover cosas de sitio.

const BLOCK := preload("res://scenes/platforms/solid_block.tscn")
const SPRING := preload("res://scenes/objects/spring.tscn")
const ORB := preload("res://scenes/objects/dash_orb.tscn")
const PIXEL_FONT = preload("res://assets/fonts/PixelOperator8.ttf")

const TITLE_SIZE := 8
const TEXT_SIZE := 8

const SPAWN_POS := Vector2(24, 152)
const SPRING_POS := Vector2(144, 152)   # esquina superior izquierda del resorte
const ORB_POS := Vector2(56, 106)       # centro del orbe
const ORB_POS2 := Vector2(115, 50)
const ORB_POS3 := Vector2(85, 78)       # centro del orbe 2
const STEP_X := 200.0                   # dónde empieza el escalón alto
const STEP_TOP := 56.0                  # altura de la parte de arriba del escalón (menor = más alto)

const FONT_SIZE := 8
const TEXT_COLOR := Color(0.9, 0.9, 1.0)
const TITLE_COLOR := Color(0.94, 0.74, 0.3)

func _ready() -> void:
	_build_spawn()
	_build_solids()
	_build_objects()
	_build_texts()

func _build_spawn() -> void:
	var spawn := Marker2D.new()
	spawn.name = "Spawn"
	spawn.position = SPAWN_POS
	add_child(spawn)

func _build_solids() -> void:
	_add_block(Vector2(-16, -16), Vector2(16, 212))    # pared izquierda
	_add_block(Vector2(0, -16), Vector2(320, 16))      # techo
	_add_block(Vector2(0, 160), Vector2(STEP_X, 20))   # suelo
	_add_block(Vector2(STEP_X, STEP_TOP), Vector2(size.x - STEP_X, size.y - STEP_TOP))   # escalón alto
	_add_block(Vector2(20, 57), Vector2(40, 7)) #pltaforma flotante

func _add_block(pos: Vector2, block_size: Vector2) -> void:
	var b := BLOCK.instantiate()
	b.size = block_size
	b.position = pos
	add_child(b)

func _build_objects() -> void:
	var spring := SPRING.instantiate()
	spring.position = SPRING_POS
	add_child(spring)
	var orb := ORB.instantiate()
	orb.position = ORB_POS
	add_child(orb)
	var orb2 := ORB.instantiate()
	orb2.position = ORB_POS2
	add_child(orb2)
	var orb3 := ORB.instantiate()
	orb3.position = ORB_POS3
	add_child(orb3)

func _build_texts() -> void:
	# Controles
	_add_label("CONTROLES", Vector2(8, 4), TITLE_COLOR, 8, 180)

	_add_label(
		"Mover: %s / %s\nSaltar: %s\nDash: %s + direccion\nPausa: %s"
		% [_keys("move_left"), _keys("move_right"),
		_keys("jump"), _keys("dash"), _keys("pause")],
		Vector2(8, 16), TEXT_COLOR, 8, 184
	)

	# Orbe
	_add_label("ORBE DE DASH", Vector2(8, 65), TITLE_COLOR, 8, 184)

	_add_label(
		"Dashea en el aire y toca\nel orbe para recuperar\ntu dash.",
		Vector2(8, 77), TEXT_COLOR, 8, 184
	)

	# Resorte
	_add_label("RESORTE", Vector2(236, 116), TITLE_COLOR, 8, 105)

	_add_label(
		"Pisa el resorte y saldras\nimpulsado hacia arriba.",
		Vector2(210, 128), TEXT_COLOR, 8, 105
	)

	# Salida
	_add_label("SALIDA >>", Vector2(236, STEP_TOP - 16),
	TITLE_COLOR, 8, 80)

func _add_label(
	text: String,
	pos: Vector2,
	color := TEXT_COLOR,
	font_size := 8,
	max_width := 184.0
) -> void:
	var l := Label.new()

	l.text = text
	l.position = pos
	l.size = Vector2(max_width, 48)

	l.add_theme_font_override("font", PIXEL_FONT)
	l.add_theme_font_size_override("font_size", font_size)
	l.add_theme_color_override("font_color", color)

	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART

	add_child(l)

## Nombres de todas las teclas asignadas a una acción, ej. "Space / C".
func _keys(action: String) -> String:
	var names := PackedStringArray()
	for e in InputMap.action_get_events(action):
		if e is InputEventKey:
			names.append(e.as_text_physical_keycode())
	return " / ".join(names) if names.size() > 0 else "-"
