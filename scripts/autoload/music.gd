extends Node
## Reproduce la música de fondo. Uso: Music.play(cancion) / Music.stop()

const VOLUME_DB := -8.0   # volumen de la música (más negativo = más bajo)
const FADE_TIME := 0.8    # segundos de fundido al entrar y salir

var _player: AudioStreamPlayer
var _tween: Tween

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS   # sigue sonando en la pausa
	_player = AudioStreamPlayer.new()
	_player.volume_db = VOLUME_DB
	_player.finished.connect(_on_finished)
	add_child(_player)

func play(stream: AudioStream) -> void:
	if stream == null:
		return
	# Si esa misma canción ya está sonando, no la reiniciamos
	if _player.stream == stream and _player.playing:
		return
	if _tween:
		_tween.kill()
	_player.stream = stream
	_player.volume_db = -40.0
	_player.play()
	_tween = create_tween()
	_tween.tween_property(_player, "volume_db", VOLUME_DB, FADE_TIME)

func stop() -> void:
	if not _player.playing:
		return
	if _tween:
		_tween.kill()
	_tween = create_tween()
	_tween.tween_property(_player, "volume_db", -40.0, FADE_TIME)
	_tween.tween_callback(_player.stop)

# Seguro extra: si la canción termina, vuelve a empezar
func _on_finished() -> void:
	_player.play()
