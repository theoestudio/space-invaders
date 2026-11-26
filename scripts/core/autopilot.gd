class_name Autopilot
extends RefCounted
## A simple player for the attract screen and the balance tests: dodge House shots,
## catch balls that are about to land, otherwise line up under the lowest invader
## and fire. `skill` (0..1) sets aim error and reaction time. Between waves it
## shops at the cashier (shop) and decides whether to ride down or cash out (ride).

var skill := 0.7
var _rng := RandomNumberGenerator.new()
var _target := NAN
var _think := 0.0
var _aim_error := 0.0
## How close the House came to the line this wave and last (board pixels).
var _closest := INF
var _last_closest := INF

## What one stack of a fixture is worth over the rest of a run, in balls, measured
## by tests/fixture_value.gd (mid skill given it free from wave 1: the tray after
## wave 12 against none, survival included). Rough on purpose: a guide, not a solver.
const WORTH := {
	&"bent_nail": 60, &"side_comps": 60, &"tulip_bonus": 170, &"gold_leaf": 60,
	&"loaded_seven": 260, &"deep_holds": 140, &"long_fever": 220, &"sticky_prizes": 80,
	&"deep_cup": 80, &"wide_cup": 240, &"quick_reload": 280, &"twin_barrel": 260,
	&"piercing_tips": 400, &"interest": 160, &"comps": 280, &"padded_rail": 40, &"insurance": 40,
	&"saucer_bait": 90, &"croupier_tip": 120, &"hot_rail": 120, &"golden_touch": 200,
}
## The wave a run expects to reach at skill 0 and at skill 1, for what is left to earn.
const HORIZON := Vector2(10, 20)
## Balls kept back from shopping: every bolt costs one.
const RESERVE := 40


func _init(skill_level := 0.7, rng_seed := 1) -> void:
	skill = skill_level
	_rng.seed = rng_seed


## Returns {move: float, target: float, fire: bool} for Sim.step.
func decide(s: Sim) -> Dictionary:
	watch(s)
	_think -= Tune.STEP
	var danger := _danger(s)
	if not is_nan(danger):
		return {move = 0.0, target = danger, fire = false}
	if _think <= 0.0:
		_think = lerpf(0.35, 0.05, skill) * _rng.randf_range(0.6, 1.4)
		_aim_error = _rng.randf_range(-1.0, 1.0) * lerpf(30.0, 3.0, skill)
		_target = _choose(s)
	var fire := false
	if not is_nan(_target):
		fire = absf(_target - s.ship_x) < 10.0 and s.phase == Sim.Phase.PLAYING
	if s.fever_t > 0.0:
		fire = true
	return {move = 0.0, target = _target, fire = fire}


## Buys at the cashier between waves: the offer with the best worth for its price
## while one pays back at least its price, keeping a reserve. Low skill misjudges
## worth; high skill rerolls once when nothing is worth it. Returns what it bought.
func shop(s: Sim) -> Array[StringName]:
	var out: Array[StringName] = []
	var rerolled := false
	while s.phase == Sim.Phase.SETTLED:
		var best := -1
		var best_gain := 0.0
		for i in s.offers.size():
			if not s.can_buy(i) or s.tray - s.price(s.offers[i]) < RESERVE:
				continue
			var gain := _worth(s, s.offers[i]) / float(s.price(s.offers[i]))
			if gain > best_gain:
				best_gain = gain
				best = i
		if best >= 0 and best_gain >= 1.0:
			out.append(s.offers[best])
			s.buy(best)
			continue
		if skill >= 0.8 and not rerolled and s.reroll_price() * 20 <= s.tray and s.fixtures.size() < Fixtures.SLOTS:
			rerolled = true
			s.reroll()
			continue
		break
	return out


func _worth(s: Sim, id: StringName) -> float:
	var horizon := lerpf(HORIZON.x, HORIZON.y, skill)
	var left := clampf((horizon - s.wave) / 12.0, 0.0, 1.5)
	var w: float = WORTH[id]
	if id == &"interest":
		w = maxf(w, s.tray * Fixtures.INTEREST_RATE * (horizon - s.wave))
	var judged := 1.0 + _rng.randf_range(-1.0, 1.0) * lerpf(0.6, 0.1, skill)
	return w * left * judged


## Whether to ride down to another wave rather than cash out: on, unless the House
## came closer to the line last wave than this skill level is comfortable with and
## the tray is worth keeping.
func ride(s: Sim) -> bool:
	if not s.can_ride():
		return false
	var comfort := lerpf(3.0, 1.5, skill) * Tune.CELL.y
	return _last_closest > comfort or s.tray < 150


## Call each step: tracks how close the House comes to the line.
func watch(s: Sim) -> void:
	if s.phase == Sim.Phase.PLAYING:
		for inv in s.invaders:
			if inv.alive and inv.dive < 0.0:
				_closest = minf(_closest, Tune.INVADED_Y - (s.invader_pos(inv).y + Tune.INVADER_HALF.y))
	elif _closest != INF:
		_last_closest = _closest
		_closest = INF


## Where to shoot to hurt the boss now, or NAN while it is armored.
func _boss_aim(s: Sim) -> float:
	var b := s.boss
	var parts := s.boss_parts()
	match b.id:
		Bosses.Id.PIT_BOSS:
			for i in parts.size():
				if b.faces[i] <= Bosses.PIT_OPEN:
					return parts[i].x
			return NAN
		Bosses.Id.HOUSE:
			return parts[0].x if b.lit else NAN
		Bosses.Id.DOORMAN:
			var t := (Tune.SHIP_Y - parts[0].y) / Tune.BOLT_SPEED
			return parts[0].x + b.dir * Bosses.DOORMAN_SPEED * t
	return parts[0].x


func _danger(s: Sim) -> float:
	var reach := Tune.SHIP_HALF + 16.0
	var threats := Array(s.shots)
	for inv in s.invaders:
		if inv.alive and inv.dive >= 0.0:
			threats.append(s.invader_pos(inv))
	for shot: Vector2 in threats:
		if shot.y > Tune.SHIP_Y - 230.0 and shot.y < Tune.SHIP_Y + 10.0 and absf(shot.x - s.ship_x) < reach:
			if _rng.randf() > lerpf(0.55, 0.97, skill):
				return NAN
			var away := signf(s.ship_x - shot.x)
			if away == 0.0:
				away = 1.0
			var x := s.ship_x + away * (reach * 2.0)
			if x < Tune.LEFT + Tune.SHIP_HALF or x > Tune.RIGHT - Tune.SHIP_HALF:
				x = shot.x - away * (reach * 1.6)
			return x
	return NAN


func _choose(s: Sim) -> float:
	# Catch a ball that is low and reachable.
	var best_ball := NAN
	var best_t := INF
	for b in s.balls:
		if b.pos.y < 1050.0 or b.vel.y <= 0.0:
			continue
		var t := (Tune.SHIP_Y - 16.0 - b.pos.y) / maxf(b.vel.y, 120.0)
		var travel := absf(b.pos.x - s.ship_x) / Tune.SHIP_SPEED
		if travel < t + 0.05 and t < best_t:
			best_t = t
			best_ball = b.pos.x
	if not is_nan(best_ball) and s.phase != Sim.Phase.PLAYING or (not is_nan(best_ball) and _rng.randf() < lerpf(0.3, 0.8, skill)):
		return best_ball
	if s.phase != Sim.Phase.PLAYING:
		return NAN
	# A boss with its weak point open: go for it, always once its escort is gone.
	if s.boss_alive():
		var aim := _boss_aim(s)
		if not is_nan(aim) and (s.alive_count() == 0 or _rng.randf() < 0.6):
			return aim + _aim_error
	# Otherwise the lowest invader, nearest first, leading the march.
	var pick: Sim.Invader
	var pick_score := INF
	for inv in s.invaders:
		if not inv.alive:
			continue
		var p := s.invader_pos(inv)
		var score := -p.y * 2.0 + absf(p.x - s.ship_x)
		if score < pick_score:
			pick_score = score
			pick = inv
	if pick == null:
		return NAN
	var p := s.invader_pos(pick)
	var t := (Tune.SHIP_Y - p.y) / Tune.BOLT_SPEED
	return s.invader_pos_at(pick, t).x + _aim_error
