extends Node
## Estado global: nivel actual, muertes y tiempo por nivel (GDD 11).

const LEVELS := [
	"res://scenes/levels/level_1.tscn",
	"res://scenes/levels/level_2.tscn",
	"res://scenes/levels/level_3.tscn",
]
const END := "res://scenes/ui/end_screen.tscn"
const MENU := "res://scenes/ui/main_menu.tscn"

var current_level := 0
var level_deaths: Array[int] = [0, 0, 0]
var level_times: Array[float] = [0.0, 0.0, 0.0]
var timing := false

func _process(delta: float) -> void:
	if timing and not get_tree().paused:
		level_times[current_level] += delta

func start_game() -> void:
	level_deaths.fill(0)
	level_times.fill(0.0)
	current_level = 0
	timing = true
	_go(LEVELS[0])

func complete_level() -> void:
	Sfx.play("win")
	if current_level + 1 < LEVELS.size():
		current_level += 1
		_go(LEVELS[current_level])
	else:
		finish_game()

func finish_game() -> void:
	timing = false
	_go(END)

func go_to_menu() -> void:
	timing = false
	_go(MENU)

func register_death() -> void:
	level_deaths[current_level] += 1

func total_deaths() -> int:
	var t := 0
	for d in level_deaths:
		t += d
	return t

func total_time() -> float:
	var t := 0.0
	for x in level_times:
		t += x
	return t

func format_time(t: float) -> String:
	var m := int(t) / 60
	var s := int(t) % 60
	var d := int((t - floorf(t)) * 10.0)
	return "%d:%02d.%d" % [m, s, d]

func _go(path: String) -> void:
	get_tree().paused = false
	get_tree().change_scene_to_file.call_deferred(path)
