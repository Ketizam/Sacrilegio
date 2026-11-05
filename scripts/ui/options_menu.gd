extends Control
## Opciones (GDD 10.2): volumen, pantalla completa y remapeo de controles.

signal closed

const LABELS := {
	"move_left": "Izquierda",
	"move_right": "Derecha",
	"jump": "Saltar",
	"dash": "Dash",
	"pause": "Pausa",
}

@onready var volume_slider: HSlider = $Panel/Margin/VBox/VolumeRow/Volume
@onready var fullscreen_check: CheckButton = $Panel/Margin/VBox/Fullscreen
@onready var bindings: GridContainer = $Panel/Margin/VBox/Bindings
@onready var back_button: Button = $Panel/Margin/VBox/Back

var _buttons := {}
var _listening := ""

func _ready() -> void:
	visible = false
	volume_slider.value = Settings.volume
	fullscreen_check.button_pressed = Settings.fullscreen
	volume_slider.value_changed.connect(_on_volume)
	fullscreen_check.toggled.connect(_on_fullscreen)
	back_button.pressed.connect(close)
	for action in Settings.ACTIONS:
		var l := Label.new()
		l.text = LABELS[action]
		l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		bindings.add_child(l)
		var b := Button.new()
		b.custom_minimum_size = Vector2(70, 0)
		b.text = Settings.key_text(action)
		b.pressed.connect(_start_listening.bind(action))
		bindings.add_child(b)
		_buttons[action] = b

func open() -> void:
	visible = true
	volume_slider.value = Settings.volume
	fullscreen_check.button_pressed = Settings.fullscreen
	back_button.grab_focus()

func close() -> void:
	if not visible:
		return
	_listening = ""
	_refresh()
	visible = false
	closed.emit()

func _on_volume(v: float) -> void:
	Settings.volume = v
	Settings.apply()
	Settings.save_settings()

func _on_fullscreen(on: bool) -> void:
	Settings.fullscreen = on
	Settings.apply()
	Settings.save_settings()

func _start_listening(action: String) -> void:
	_listening = action
	_buttons[action].text = "..."

func _refresh() -> void:
	for a in _buttons:
		_buttons[a].text = Settings.key_text(a)

func _input(event: InputEvent) -> void:
	if _listening == "" or not (event is InputEventKey) or not event.pressed or event.echo:
		return
	get_viewport().set_input_as_handled()
	if event.physical_keycode != KEY_ESCAPE:
		Settings.set_primary_key(_listening, event.physical_keycode)
	_listening = ""
	_refresh()
