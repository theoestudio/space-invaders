extends Node
## Sound effects and music. Every file in assets/audio is rendered by
## tools/make-sounds.py; rerun that instead of editing the audio by hand.
##
## Music is Suno tracks served by the site (web/music, listed in data/music.json by
## tools/encode-music.py), fetched one at a time so the .pck stays small and a player
## downloads only what they hear. Each set plays its tracks in turn from a random
## start: "run" (synthwave) during waves and the cash-out choice, "lounge"
## (vaporwave) on the menu and results. Fever speeds up whatever is playing.

const NAMES := [
	"pin", "fire", "dry", "zap", "clash", "dent", "kill", "hit", "shield", "saucer",
	"jackpot", "start", "pocket", "catch", "tulip", "drop", "spin", "reel", "reach",
	"prize", "fever", "clear", "bust", "cashout", "select",
]
const VOICES := 16
## With tracks at -18 LUFS (tools/encode-music.py) the music plays at about -24 LUFS.
const MUSIC_DB := -6.0
const MUSIC_INDEX := "res://data/music.json"
## Where the tracks live off the web build (the editor, desktop runs).
const SITE := "https://pachinko.twinspear.com"
const SILENT_DB := -60.0
const FADE_IN := 2.0
const FADE_OUT := 1.2

var _streams := {}  # effect name -> AudioStream
var _players: Array[AudioStreamPlayer] = []
var _next := 0
var _music: AudioStreamPlayer
var _fade: Tween
var _base := ""
var _sets := {}  # set name -> Array of file names, in play order
var _set := &"lounge"
var _turn := {}  # set name -> index of the next track
var _want := ""  # the track that should be playing (or downloading)
var _tracks := {}  # file name -> AudioStreamOggVorbis, kept once fetched
var _fetching := {}  # file name -> true while its request is out


func _ready() -> void:
	for n: String in NAMES:
		_streams[StringName(n)] = load("res://assets/audio/%s.wav" % n)
	for i in VOICES:
		var p := AudioStreamPlayer.new()
		add_child(p)
		_players.append(p)
	_music = AudioStreamPlayer.new()
	_music.volume_db = MUSIC_DB
	_music.finished.connect(_next_track)
	add_child(_music)
	# Headless runs are the tests; they never need the network.
	if DisplayServer.get_name() == "headless":
		return
	_base = str(JavaScriptBridge.eval("location.origin", true)) if OS.has_feature("web") else SITE
	var index: Variant = JSON.parse_string(FileAccess.get_file_as_string(MUSIC_INDEX))
	if index is Dictionary:
		_sets = index
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


## Switch to a music set ("run" or "lounge"): the current track fades out and the
## set's next one fades in. Nothing happens when that set is already playing.
func music_for(set_name: StringName) -> void:
	if set_name == _set:
		return
	_set = set_name
	if not Profile.music or _base == "":
		return
	if _music.playing:
		_tween_volume(SILENT_DB, FADE_OUT).finished.connect(func() -> void:
			_music.stop()
			_next_track())
	else:
		_next_track()


func _sync_music() -> void:
	if not Profile.music:
		if _fade:
			_fade.kill()
		_music.stop()
		_want = ""
	elif not _music.playing and _want == "":
		_next_track()


func _next_track() -> void:
	var files: Array = _sets.get(String(_set), [])
	if not Profile.music or files.is_empty():
		return
	var i: int = _turn.get(_set, randi() % files.size())
	_turn[_set] = (i + 1) % files.size()
	_want = files[i]
	_fetch(_want)


func _fetch(file: String) -> void:
	if _tracks.has(file):
		_arrived(file)
		return
	if _fetching.has(file):
		return
	_fetching[file] = true
	var req := HTTPRequest.new()
	add_child(req)
	req.request_completed.connect(func(result: int, code: int, _h: PackedStringArray, body: PackedByteArray) -> void:
		req.queue_free()
		_fetching.erase(file)
		var stream: AudioStreamOggVorbis = null
		if result == HTTPRequest.RESULT_SUCCESS and code == 200:
			stream = AudioStreamOggVorbis.load_from_buffer(body)
		if stream == null:
			push_warning("music: could not load %s (result %d, HTTP %d)" % [file, result, code])
			if file == _want:
				_want = ""
			return
		_tracks[file] = stream
		_arrived(file))
	if req.request("%s/music/%s" % [_base, file]) != OK:
		push_warning("music: request for %s failed to start" % file)
		req.queue_free()
		_fetching.erase(file)
		if file == _want:
			_want = ""


## A track is in memory: start it if it is the one wanted, then fetch the set's next
## one in the background so the change between tracks has no gap.
func _arrived(file: String) -> void:
	if file != _want or not Profile.music or _music.playing:
		return
	_music.stream = _tracks[file]
	_music.volume_db = SILENT_DB
	_music.play()
	_tween_volume(MUSIC_DB, FADE_IN)
	var files: Array = _sets.get(String(_set), [])
	var upcoming: String = files[_turn.get(_set, 0)]
	if not _tracks.has(upcoming):
		_fetch(upcoming)


func _tween_volume(db: float, seconds: float) -> Tween:
	if _fade:
		_fade.kill()
	_fade = create_tween()
	_fade.tween_property(_music, "volume_db", db, seconds)
	return _fade
