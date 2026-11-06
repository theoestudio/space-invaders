extends Node
## Sound effects and the music loop. Every file in assets/audio is rendered by
## tools/make-sounds.py; rerun that instead of editing the audio by hand.

const NAMES := [
	"pin", "fire", "dry", "zap", "clash", "dent", "kill", "hit", "shield", "saucer",
	"jackpot", "start", "pocket", "catch", "tulip", "drop", "spin", "reel", "reach",
	"prize", "fever", "clear", "bust", "cashout", "select",
]
const MUSIC := preload("res://assets/audio/music.ogg")
const VOICES := 16
const MUSIC_DB := -15.0

var _streams := {}
var _players: Array[AudioStreamPlayer] = []
var _next := 0
var _music: AudioStreamPlayer


func _ready() -> void:
	for n: String in NAMES:
		_streams[StringName(n)] = load("res://assets/audio/%s.wav" % n)
	for i in VOICES:
		var p := AudioStreamPlayer.new()
		add_child(p)
		_players.append(p)
	var loop: AudioStreamOggVorbis = MUSIC.duplicate()
	loop.loop = true
	_music = AudioStreamPlayer.new()
	_music.stream = loop
	_music.volume_db = MUSIC_DB
	add_child(_music)
	Profile.changed.connect(_sync_music)
	_sync_music()


func play(name: StringName, pitch := 1.0, volume_db := 0.0) -> void:
	if not Profile.sound:
		return
	var p := _players[_next]
	_next = (_next + 1) % VOICES
	p.stream = _streams[name]
	p.pitch_scale = pitch
	p.volume_db = volume_db
	p.play()


## Fever speeds the music up a touch.
func set_fever(on: bool) -> void:
	_music.pitch_scale = 1.12 if on else 1.0


func _sync_music() -> void:
	if Profile.music and not _music.playing:
		_music.play()
	elif not Profile.music and _music.playing:
		_music.stop()
