extends Node
## Ajustes del jugador: volumen, pantalla completa y remapeo de controles.
## Se guardan en user://settings.cfg

const PATH := "user://settings.cfg"
const ACTIONS := ["move_left", "move_right", "jump", "dash", "pause"]

var volume := 0.8
var fullscreen := false

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	load_settings()
	apply()

func apply() -> void:
	AudioServer.set_bus_mute(0, volume <= 0.001)
	AudioServer.set_bus_volume_db(0, linear_to_db(maxf(volume, 0.001)))
	var mode := DisplayServer.WINDOW_MODE_FULLSCREEN if fullscreen else DisplayServer.WINDOW_MODE_WINDOWED
	DisplayServer.window_set_mode(mode)

func load_settings() -> void:
	var cfg := ConfigFile.new()
	if cfg.load(PATH) != OK:
		return
	volume = cfg.get_value("audio", "volume", volume)
	fullscreen = cfg.get_value("video", "fullscreen", fullscreen)
	for a in ACTIONS:
		if cfg.has_section_key("controls", a):
			set_primary_key(a, int(cfg.get_value("controls", a)), false)

func save_settings() -> void:
	var cfg := ConfigFile.new()
	cfg.set_value("audio", "volume", volume)
	cfg.set_value("video", "fullscreen", fullscreen)
	for a in ACTIONS:
		cfg.set_value("controls", a, primary_key(a))
	cfg.save(PATH)

func primary_key(action: String) -> int:
	for e in InputMap.action_get_events(action):
		if e is InputEventKey:
			return e.physical_keycode
	return 0

func key_text(action: String) -> String:
	for e in InputMap.action_get_events(action):
		if e is InputEventKey:
			return e.as_text_physical_keycode()
	return "-"

## Reemplaza la primera tecla de la acción (la segunda tecla alternativa se conserva).
func set_primary_key(action: String, keycode: int, save := true) -> void:
	var events := InputMap.action_get_events(action)
	InputMap.action_erase_events(action)
	var replaced := false
	for e in events:
		if e is InputEventKey and not replaced:
			var ne := InputEventKey.new()
			ne.physical_keycode = keycode as Key
			InputMap.action_add_event(action, ne)
			replaced = true
		else:
			InputMap.action_add_event(action, e)
	if not replaced:
		var ne2 := InputEventKey.new()
		ne2.physical_keycode = keycode as Key
		InputMap.action_add_event(action, ne2)
	if save:
		save_settings()
