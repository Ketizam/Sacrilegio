extends Control
## Menú principal: Jugar, Opciones y Salir. Se construye por código.

const OPTIONS_SCENE := preload("res://scenes/ui/options_menu.tscn")

const BG_COLOR := Color(0.07, 0.063, 0.122)
const TITLE_COLOR := Color(0.941, 0.737, 0.306)

## Música del menú (opcional): arrastra aquí una canción en el Inspector.
@export var music: AudioStream

var _menu: Control
var _options: Control
var _play_button: Button
var _options_button: Button

func _ready() -> void:
	print("menu listo")
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_build_background()
	_build_menu()
	_build_options()
	_play_button.grab_focus()
	
	modulate.a = 0.0
	create_tween().tween_property(self, "modulate:a", 1.0, 0.5)

func _build_background() -> void:
	var bg := ColorRect.new()
	bg.color = BG_COLOR
	add_child(bg)
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

func _build_menu() -> void:
	var center := CenterContainer.new()
	add_child(center)
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_menu = center

	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 6)
	center.add_child(box)

	var title := Label.new()
	title.text = "SACRILEGIO"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 28)
	title.add_theme_color_override("font_color", TITLE_COLOR)
	box.add_child(title)

	var spacer := Control.new()
	spacer.custom_minimum_size = Vector2(0, 10)
	box.add_child(spacer)

	_play_button = _add_button(box, "Jugar", _on_play)
	_options_button = _add_button(box, "Opciones", _on_options)
	if not OS.has_feature("web"):
		_add_button(box, "Salir", _on_quit)

func _build_options() -> void:
	_options = OPTIONS_SCENE.instantiate()
	add_child(_options)
	_options.closed.connect(_on_options_closed)

func _add_button(parent: Control, text: String, callback: Callable) -> Button:
	var b := Button.new()
	b.text = text
	b.custom_minimum_size = Vector2(100, 0)
	b.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	b.pressed.connect(_on_pressed.bind(callback))
	parent.add_child(b)
	return b

func _on_pressed(callback: Callable) -> void:
	Sfx.play("select")
	callback.call()

func _on_play() -> void:
	_play_button.disabled = true
	GameState.start_game()

func _on_options() -> void:
	_menu.visible = false
	_options.open()

func _on_options_closed() -> void:
	_menu.visible = true
	_options_button.grab_focus()

func _on_quit() -> void:
	get_tree().quit()

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel") and _options.visible:
		get_viewport().set_input_as_handled()
		_options.close()
