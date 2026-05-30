class_name GameAudioManager
extends Node
## Pooled audio service for gameplay cues and looping area beds.

const PLAYER_POOL_SIZE: int = 12
const SFX_BUS: StringName = &"Master"
const MUSIC_BUS: StringName = &"Master"

const SFX: Dictionary = {
	&"ui_start": preload("res://assets/sfx/ui_start.wav"),
	&"attack_1": preload("res://assets/sfx/attack_1.wav"),
	&"attack_2": preload("res://assets/sfx/attack_2.wav"),
	&"attack_3": preload("res://assets/sfx/attack_3.wav"),
	&"enemy_hit": preload("res://assets/sfx/enemy_hit.wav"),
	&"enemy_death": preload("res://assets/sfx/enemy_death.wav"),
	&"dodge": preload("res://assets/sfx/dodge.wav"),
	&"player_hurt": preload("res://assets/sfx/player_hurt.wav"),
	&"pyro_throw": preload("res://assets/sfx/pyro_throw.wav"),
	&"pyro_skill": preload("res://assets/sfx/pyro_skill.wav"),
	&"hydro_cast": preload("res://assets/sfx/hydro_cast.wav"),
	&"electro_strike": preload("res://assets/sfx/electro_strike.wav"),
	&"checkpoint": preload("res://assets/sfx/checkpoint.wav"),
	&"area_clear": preload("res://assets/sfx/area_clear.wav"),
	&"boss_defeat": preload("res://assets/sfx/boss_defeat.wav"),
	&"boss_attack": preload("res://assets/sfx/boss_attack.wav"),
}

const MUSIC: Dictionary = {
	&"ember_fields": preload("res://assets/music/milestone4/ember_fields_loop.wav"),
	&"boss": preload("res://assets/music/milestone4/boss_loop.wav"),
	&"storm_peaks": preload("res://assets/music/milestone4/storm_peaks_loop.wav"),
}

const SFX_VOLUME_DB: Dictionary = {
	&"enemy_hit": -3.0,
	&"dodge": -4.0,
	&"checkpoint": -2.0,
	&"area_clear": -3.0,
	&"boss_defeat": -2.0,
	&"boss_attack": -2.0,
}

var _players: Array[AudioStreamPlayer] = []
var _next_player_index: int = 0
var _music_player: AudioStreamPlayer = null
var _current_music: StringName = &""

func _ready() -> void:
	for index in PLAYER_POOL_SIZE:
		var player := AudioStreamPlayer.new()
		player.name = "SFXPlayer%d" % index
		player.bus = SFX_BUS
		add_child(player)
		_players.append(player)
	_music_player = AudioStreamPlayer.new()
	_music_player.name = "MusicPlayer"
	_music_player.bus = MUSIC_BUS
	_music_player.volume_db = -13.0
	_music_player.finished.connect(_on_music_finished)
	add_child(_music_player)

func play_sfx(cue: StringName, volume_offset_db: float = 0.0, pitch_jitter: float = 0.035) -> void:
	var stream: AudioStream = SFX.get(cue)
	if stream == null or _players.is_empty():
		return
	var player := _next_available_player()
	player.stop()
	player.stream = stream
	player.volume_db = float(SFX_VOLUME_DB.get(cue, 0.0)) + volume_offset_db
	player.pitch_scale = randf_range(1.0 - pitch_jitter, 1.0 + pitch_jitter)
	player.play()

func play_music(cue: StringName) -> void:
	if cue == _current_music and _music_player != null and _music_player.playing:
		return
	var stream: AudioStream = MUSIC.get(cue)
	if stream == null or _music_player == null:
		stop_music()
		return
	_current_music = cue
	_music_player.stop()
	_music_player.stream = _looping_copy(stream)
	_music_player.play()

func stop_music() -> void:
	_current_music = &""
	if _music_player:
		_music_player.stop()

func _next_available_player() -> AudioStreamPlayer:
	for player in _players:
		if not player.playing:
			return player
	var player := _players[_next_player_index]
	_next_player_index = (_next_player_index + 1) % _players.size()
	return player

func _looping_copy(stream: AudioStream) -> AudioStream:
	var copy := stream.duplicate() as AudioStream
	if copy is AudioStreamWAV:
		var wav := copy as AudioStreamWAV
		wav.loop_mode = AudioStreamWAV.LOOP_FORWARD
	return copy

func _on_music_finished() -> void:
	if _current_music != &"" and _music_player:
		_music_player.play()
