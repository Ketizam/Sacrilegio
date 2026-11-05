extends Node
## Reproduce efectos de sonido: Sfx.play("jump")

const NAMES := ["jump", "land", "dash", "death", "refill", "spring", "warn", "hit", "select", "win", "fall"]

var _streams := {}
var _players: Array[AudioStreamPlayer] = []

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	for n in NAMES:
		_streams[n] = load("res://assets/audio/sfx/%s.wav" % n)
	for i in 8:
		var p := AudioStreamPlayer.new()
		add_child(p)
		_players.append(p)

func play(sound: String) -> void:
	var s = _streams.get(sound)
	if s == null:
		return
	for p in _players:
		if not p.playing:
			p.stream = s
			p.play()
			return
	_players[0].stream = s
	_players[0].play()
