extends Control
## Pantalla final: resumen de muertes y tiempo por nivel (GDD 11).

func _ready() -> void:
	var names := ["Nivel 1 - Base", "Nivel 2 - Ascenso", "Nivel 3 - Arena"]
	var lines: Array[String] = []
	for i in names.size():
		lines.append("%s   %s   %d muertes" % [names[i], GameState.format_time(GameState.level_times[i]), GameState.level_deaths[i]])
	lines.append("")
	lines.append("Total: %s   %d muertes" % [GameState.format_time(GameState.total_time()), GameState.total_deaths()])
	$Center/VBox/Stats.text = "\n".join(lines)
	$Center/VBox/Again.pressed.connect(GameState.start_game)
	$Center/VBox/Quit.pressed.connect(func(): get_tree().quit())
	$Center/VBox/Again.grab_focus()
	var quit_button: Button = $Center/VBox/Quit
	var menu_button := Button.new()
	menu_button.text = "Menú principal"
	menu_button.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	quit_button.get_parent().add_child(menu_button)
	quit_button.get_parent().move_child(menu_button, quit_button.get_index())
	menu_button.pressed.connect(GameState.go_to_menu)
