class_name WebMusic
extends RefCounted
## Music played the browser's way on the web: an <audio> element pointed at the track on the
## site, so it streams from the CDN while it plays, holds a few MB however long the track
## is, and keeps playing through a frame the game spends busy. Godot's web default (sample
## playback) instead decodes a whole track into memory, about 80 MB for five minutes of
## stereo, and never frees it.
##
## Two decks, for crossfades. Each element runs through a Web Audio gain of its own, since
## iOS ignores an element's volume. Browsers start no sound before the page gets a gesture,
## so a track asked for earlier waits: the first tap or key press anywhere on the page opens
## the audio context and starts it (or plays a short silence on an idle deck, which is what
## lets later play() calls through on iOS). A hidden tab pauses the music and showing it
## resumes.
##
## open() returns null off the web and in browsers that can't play Ogg Vorbis in an
## <audio> element (iOS before 18.4); the caller downloads the track and plays it through
## Godot instead, with stream playback so it stays compressed in memory. A track that
## fails here (network, decoding, a refused play) emits failed(deck), and the caller
## should fall back the same way. The same file is in every Twinspear web game.

signal ended(deck: int)
signal failed(deck: int)

const JS := """(() => {
	if (window.gameMusic) return true;
	if (!document.createElement('audio').canPlayType('audio/ogg; codecs="vorbis"')) return false;
	// A tenth of a second of 16-bit silence: a WAV header, then zeros.
	const SILENCE = 'data:audio/wav;base64,UklGRkQDAABXQVZFZm10IBAAAAABAAEAQB8AAIA+AAACABAAZGF0YSAD' + 'A'.repeat(1070) + '==';
	const api = { ended: null, failed: null };
	const decks = [];
	let ctx = null;
	let unlocked = false;
	let hidden = document.hidden;
	const setup = () => {
		if (ctx) return;
		ctx = new (window.AudioContext || window.webkitAudioContext)();
		for (let i = 0; i < 2; i++) {
			const el = new Audio();
			el.preload = 'auto';
			el.preservesPitch = false;
			const gain = ctx.createGain();
			gain.gain.value = 0;
			ctx.createMediaElementSource(el).connect(gain);
			gain.connect(ctx.destination);
			const d = { el, gain, live: false, token: 0, blessed: false };
			d.lost = () => {
				if (!d.live) return;
				d.live = false;
				if (api.failed) api.failed(i);
			};
			el.addEventListener('ended', () => {
				if (!d.live) return;
				d.live = false;
				if (api.ended) api.ended(i);
			});
			el.addEventListener('error', d.lost);
			decks.push(d);
		}
	};
	const start = (d) => {
		if (!unlocked || hidden) return;
		d.blessed = true;
		d.el.play().catch((e) => { if (e.name !== 'AbortError') d.lost(); });
	};
	const unlock = () => {
		setup();
		unlocked = true;
		if (!hidden && ctx.state !== 'running') ctx.resume();
		for (const d of decks) {
			if (d.live && d.el.paused) start(d);
			else if (!d.blessed) {
				d.blessed = true;
				d.el.src = SILENCE;
				d.el.play().catch(() => {});
			}
		}
	};
	for (const type of ['pointerdown', 'touchend', 'keydown', 'click']) document.addEventListener(type, unlock, true);
	document.addEventListener('visibilitychange', () => {
		hidden = document.hidden;
		if (!ctx) return;
		if (hidden) ctx.suspend();
		else if (unlocked) ctx.resume();
		for (const d of decks) {
			if (!d.live) continue;
			if (hidden) d.el.pause();
			else start(d);
		}
	});
	const ramp = (d, to, seconds) => {
		const g = d.gain.gain;
		const now = ctx.currentTime;
		const from = g.value;
		g.cancelScheduledValues(now);
		g.setValueAtTime(from, now);
		g.linearRampToValueAtTime(to, now + Math.max(seconds, 0.02));
	};
	api.play = (i, url, level, seconds, rate) => {
		setup();
		const d = decks[i];
		d.token++;
		d.live = true;
		d.el.defaultPlaybackRate = rate;
		d.el.src = url;
		d.el.playbackRate = rate;
		d.gain.gain.cancelScheduledValues(ctx.currentTime);
		d.gain.gain.setValueAtTime(0, ctx.currentTime);
		ramp(d, level, seconds);
		start(d);
	};
	api.level = (i, level, seconds) => {
		if (ctx && decks[i].live) ramp(decks[i], level, seconds);
	};
	api.rate = (i, rate) => {
		if (!ctx) return;
		decks[i].el.defaultPlaybackRate = rate;
		decks[i].el.playbackRate = rate;
	};
	api.left = (i) => {
		const d = decks[i];
		if (!d || !d.live || !isFinite(d.el.duration)) return -1;
		return d.el.duration - d.el.currentTime;
	};
	api.fade = (i, seconds) => {
		const d = decks[i];
		if (!ctx || !d.live) return;
		d.live = false;
		const token = ++d.token;
		ramp(d, 0, seconds);
		setTimeout(() => {
			if (d.token !== token) return;
			d.el.pause();
			d.el.removeAttribute('src');
			d.el.load();
		}, seconds * 1000 + 100);
	};
	window.gameMusic = api;
	return true;
})()"""

var _api: JavaScriptObject
# Kept for as long as the player lives: the browser holds only a weak handle on them.
var _on_ended: JavaScriptObject
var _on_failed: JavaScriptObject


## The browser's music player, or null where it can't be used.
static func open() -> WebMusic:
	if not OS.has_feature("web") or DisplayServer.get_name() == "headless":
		return null
	# A JS boolean comes back as an int (1 or 0), so test it for truth, not against true.
	if not JavaScriptBridge.eval(JS, true):
		return null
	return WebMusic.new()


func _init() -> void:
	_api = JavaScriptBridge.get_interface("gameMusic")
	_on_ended = JavaScriptBridge.create_callback(func(args: Array) -> void: ended.emit(int(args[0])))
	_on_failed = JavaScriptBridge.create_callback(func(args: Array) -> void: failed.emit(int(args[0])))
	_api.ended = _on_ended
	_api.failed = _on_failed


## Starts `url` on a deck (0 or 1) from the top, fading in to `db` over `fade` seconds, at
## `speed` times normal (pitch moves with it, as AudioStreamPlayer.pitch_scale does). Asked
## for before the page's first gesture, it starts on that gesture.
func play(deck: int, url: String, db: float, fade: float, speed := 1.0) -> void:
	_api.play(deck, url, db_to_linear(db), fade, speed)


## Moves a playing deck's loudness to `db` over `seconds`.
func set_volume(deck: int, db: float, seconds := 0.0) -> void:
	_api.level(deck, db_to_linear(db), seconds)


## Plays a deck at `speed` times normal, pitch and all.
func set_speed(deck: int, speed: float) -> void:
	_api.rate(deck, speed)


## Seconds left in a deck's track, or -1 while its length isn't known yet (or it isn't playing).
func time_left(deck: int) -> float:
	return float(_api.left(deck))


## Fades a deck out over `fade` seconds, then stops it and lets go of the track.
func fade_out(deck: int, fade: float) -> void:
	_api.fade(deck, fade)
