extends CanvasLayer
## Menú de pausa (tecla "pause"): reanudar, opciones y volver al menú principal.

@onready var root: Control = $Root
@onready var menu: Control = $Root/Center
@onready var options_menu: Control = $Root/OptionsMenu
@onready var resume_button: Button = $Root/Center/Menu/Resume
@onready var options_button: Button = $Root/Center/Menu/Options
@onready var restart_button: Button = $Root/Center/Menu/Restart
@onready var quit_button: Button = $Root/Center/Menu/Quit

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	root.visible = false
	resume_button.pressed.connect(resume)
	options_button.pressed.connect(_on_options)
	restart_button.pressed.connect(GameState.start_game)
	var main_menu_button := Button.new()
	main_menu_button.text = "Menú principal"
	quit_button.get_parent().add_child(main_menu_button)
	quit_button.get_parent().move_child(main_menu_button, quit_button.get_index())
	main_menu_button.pressed.connect(GameState.go_to_menu)
	quit_button.pressed.connect(func(): get_tree().quit())
	options_menu.closed.connect(_on_options_closed)

func _unhandled_input(event: InputEvent) -> void:
	if not event.is_action_pressed("pause"):
		return
	get_viewport().set_input_as_handled()
	if options_menu.visible:
		options_menu.close()
	elif root.visible:
		resume()
	else:
		pause()

func pause() -> void:
	get_tree().paused = true
	root.visible = true
	menu.visible = true
	resume_button.grab_focus()

func resume() -> void:
	get_tree().paused = false
	root.visible = false

func _on_options() -> void:
	menu.visible = false
	options_menu.open()

func _on_options_closed() -> void:
	menu.visible = true
	options_button.grab_focus()
