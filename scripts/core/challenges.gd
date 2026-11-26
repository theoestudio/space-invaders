class_name Challenges
extends RefCounted
## Goals that outlast one run (docs/descent.md). Each pays comp points the first
## time it is met, in any mode, and the profile keeps which are done. A Tracker
## watches one run through its Sim events; it is pure, so the tests drive it.

const ALL := {
	&"hot_streak": {name = "Hot streak", text = "Hit two fevers in one wave", comps = 50},
	&"untouchable": {name = "Untouchable", text = "Clear a floor's guard without being hit", comps = 60},
	&"sharpshooter": {name = "Sharpshooter", text = "Clear a wave at 70% accuracy or better", comps = 40},
	&"lobby_roller": {name = "Lobby high roller", text = "Cash out 500 or more from the Lobby", comps = 40},
	&"card_shark": {name = "Card shark", text = "Clear the Card Room", comps = 30},
	&"pit_boss": {name = "Pit boss", text = "Clear the Dice Pit", comps = 50},
	&"wheelhouse": {name = "Wheelhouse", text = "Clear the Wheel Room", comps = 75},
	&"broke_house": {name = "Break the House", text = "Break the Vault's guard", comps = 150},
	&"night_shift": {name = "Night shift", text = "Clear a wave After Hours", comps = 100},
	&"round_round": {name = "Round and round", text = "Break a turning ring", comps = 30},
	&"full_house": {name = "Full house", text = "Own six fixtures at once", comps = 50},
	&"window_shopper": {name = "Window shopper", text = "Cash out 1,000 or more without buying a fixture", comps = 75},
}
const ORDER: Array[StringName] = [
	&"hot_streak", &"untouchable", &"sharpshooter", &"lobby_roller", &"card_shark", &"pit_boss",
	&"wheelhouse", &"broke_house", &"night_shift", &"round_round", &"full_house", &"window_shopper",
]

const LOBBY_CASH := 500
const WINDOW_CASH := 1000
const SHARP_ACCURACY := 0.7
## A wave needs this many shots before its accuracy counts.
const SHARP_MIN_SHOTS := 20
## The floor each "clear the floor" challenge names.
const FLOOR_CLEARS := {2: &"card_shark", 3: &"pit_boss", 4: &"wheelhouse"}


static func name_of(id: StringName) -> String:
	return ALL[id].name


static func comps_of(id: StringName) -> int:
	return ALL[id].comps


## Watches one run. Call feed() after every Sim.step, shopped() after a buy and
## finish() once the run is over; each returns the challenges met at that moment
## (each at most once a run).
class Tracker:
	var met: Array[StringName] = []
	var _wave := 0
	var _fevers := 0
	var _start := {}

	func feed(s: Sim) -> Array[StringName]:
		var out: Array[StringName] = []
		if s.wave != _wave:
			_wave = s.wave
			_fevers = 0
			_start = {shots = s.stats.shots, kills = s.stats.kills, hits = s.stats.hits}
		for e in s.events:
			match e.kind:
				&"prize":
					if e.prize == "fever":
						_fevers += 1
						if _fevers >= 2:
							_meet(&"hot_streak", out)
				&"clear":
					_cleared(s, out)
		return out

	## Call after a buy at the cashier (between steps).
	func shopped(s: Sim) -> Array[StringName]:
		var out: Array[StringName] = []
		if s.fixtures.size() >= Fixtures.SLOTS:
			_meet(&"full_house", out)
		return out

	func finish(s: Sim) -> Array[StringName]:
		var out: Array[StringName] = []
		if s.phase == Sim.Phase.CASHED:
			if s.floor_number() == 1 and s.payout() >= LOBBY_CASH:
				_meet(&"lobby_roller", out)
			if s.payout() >= WINDOW_CASH and int(s.stats.bought) == 0:
				_meet(&"window_shopper", out)
		return out

	func _cleared(s: Sim, out: Array[StringName]) -> void:
		var shots := int(s.stats.shots) - int(_start.get("shots", 0))
		var kills := int(s.stats.kills) - int(_start.get("kills", 0))
		var hits := int(s.stats.hits) - int(_start.get("hits", 0))
		if shots >= SHARP_MIN_SHOTS and kills >= SHARP_ACCURACY * shots:
			_meet(&"sharpshooter", out)
		if Floors.is_guard(s.wave):
			if hits == 0:
				_meet(&"untouchable", out)
			var f := s.floor_number()
			if FLOOR_CLEARS.has(f):
				_meet(FLOOR_CLEARS[f], out)
			if s.wave == Tune.VAULT_WAVE:
				_meet(&"broke_house", out)
		if s.floor_number() > Tune.FLOORS:
			_meet(&"night_shift", out)
		if Formations.turns(s.shape):
			_meet(&"round_round", out)

	func _meet(id: StringName, out: Array[StringName]) -> void:
		if id not in met:
			met.append(id)
			out.append(id)
