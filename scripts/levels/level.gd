extends Node2D
## Nivel: gestiona las salas, la cámara fija, los puntos de control y el reintento rápido.

const BLOCK := preload("res://scenes/platforms/solid_block.tscn")

## Posición de este nivel en la secuencia del juego (0, 1, 2).
@export var level_index := 0
## true = las salas se apilan hacia arriba (nivel 2): solo se puede avanzar a la siguiente sala.
@export var vertical := false
## Índice de la sala donde está el jefe (-1 = no hay jefe). Al entrar, la arena se cierra y empieza el combate.
@export var boss_room := -1
@export var respawn_delay := 0.5   # GDD 5.3: reaparecer en menos de 1 segundo
## Canción de fondo de este nivel (arrastra el archivo desde FileSystem en el Inspector).
@export var music: AudioStream

@onready var camera: Camera2D = $Camera
@onready var player = $Player
@onready var rooms: Array = $Rooms.get_children()

var current_room := 0
var _respawning := false
var _boss_started := false

func _ready() -> void:
	GameState.current_level = level_index
	GameState.timing = true
	Music.play(music)
	player.died.connect(_on_player_died)
	_enter_room(0)
	await player.respawn(rooms[0].get_spawn_position())

func _physics_process(_delta: float) -> void:
	if _respawning or player.dead:
		return
	var pos: Vector2 = player.global_position
	var rect: Rect2 = rooms[current_room].get_rect()
	# Caer por debajo de la sala = muerte
	if pos.y > rect.end.y + 4.0:
		player.die()
		return
	if rect.has_point(pos):
		return
	# La cámara pasa a la sala donde está el jugador (que también pasa a ser su punto de control)
	for i in rooms.size():
		if i == current_room:
			continue
		if vertical and i != current_room + 1:
			continue
		if rooms[i].get_rect().has_point(pos):
			_enter_room(i)
			return

func _enter_room(index: int) -> void:
	current_room = index
	camera.global_position = rooms[index].get_rect().get_center()
	if index == boss_room and not _boss_started:
		_boss_started = true
		_seal_arena(rooms[index])
		get_tree().call_group("boss", "start_fight")

## Cierra la entrada de la arena para que no se pueda huir del jefe.
func _seal_arena(room: Node2D) -> void:
	var wall := BLOCK.instantiate()
	wall.size = Vector2(16, 212)
	add_child(wall)
	wall.global_position = room.global_position + Vector2(-20, -16)

func _on_player_died() -> void:
	GameState.register_death()
	_respawning = true
	await get_tree().create_timer(respawn_delay, false).timeout
	get_tree().call_group("resettable", "reset")
	await player.respawn(rooms[current_room].get_spawn_position())
	_respawning = false
