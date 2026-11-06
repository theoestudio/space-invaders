extends Node
## Local settings and the player's own record, saved to user:// (IndexedDB on the web).
## Nothing here leaves the device; Telemetry sends its own coarse, identifier-free row.

const PATH := "user://pachinko.cfg"

signal changed

var sound := true
var music := true
var seen_rules := false
## {runs, cashed, best, best_wave}
var arcade := {runs = 0, cashed = 0, best = 0, best_wave = 0}
## Run number -> {payout, waves (cleared), outcome, nets: Array[int]}. Only the
## first finished attempt counts.
var daily := {}

var _cfg := ConfigFile.new()


func _ready() -> void:
	if _cfg.load(PATH) != OK:
		return
	sound = _cfg.get_value("settings", "sound", true)
	music = _cfg.get_value("settings", "music", true)
	seen_rules = _cfg.get_value("settings", "seen_rules", false)
	arcade.merge(_cfg.get_value("record", "arcade", {}), true)
	daily = _cfg.get_value("record", "daily", {})


func save() -> void:
	_cfg.set_value("settings", "sound", sound)
	_cfg.set_value("settings", "music", music)
	_cfg.set_value("settings", "seen_rules", seen_rules)
	_cfg.set_value("record", "arcade", arcade)
	_cfg.set_value("record", "daily", daily)
	var err := _cfg.save(PATH)
	if err != OK:
		push_error("could not save profile: %s" % error_string(err))
	changed.emit()


## Returns true when this run set a new best payout.
func record_arcade(payout: int, cleared: int, cashed: bool) -> bool:
	arcade.runs += 1
	if cashed:
		arcade.cashed += 1
	var best := payout > int(arcade.best)
	arcade.best = maxi(int(arcade.best), payout)
	arcade.best_wave = maxi(int(arcade.best_wave), cleared)
	save()
	return best


func has_daily(number: int) -> bool:
	return daily.has(number)


## Returns true when this was the official (first) attempt.
func record_daily(number: int, result: Dictionary) -> bool:
	if daily.has(number):
		return false
	daily[number] = result
	save()
	return true


## Consecutive daily runs cashed out ending today (or yesterday, if today is unplayed).
func daily_streak(today: int) -> int:
	var n := today if daily.has(today) else today - 1
	var streak := 0
	while daily.has(n) and int(daily[n].payout) > 0:
		streak += 1
		n -= 1
	return streak


func daily_totals() -> Dictionary:
	var played := daily.size()
	var cashed := 0
	var best := 0
	for r: Dictionary in daily.values():
		if int(r.payout) > 0:
			cashed += 1
		best = maxi(best, int(r.payout))
	return {played = played, cashed = cashed, best = best}
