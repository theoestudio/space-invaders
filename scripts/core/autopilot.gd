class_name Autopilot
extends RefCounted
## A simple player for the attract screen and the balance tests: dodge House shots,
## catch balls that are about to land, otherwise line up under the lowest invader
## and fire. `skill` (0..1) sets aim error and reaction time.

var skill := 0.7
var _rng := RandomNumberGenerator.new()
var _target := NAN
var _think := 0.0
var _aim_error := 0.0


func _init(skill_level := 0.7, rng_seed := 1) -> void:
	skill = skill_level
	_rng.seed = rng_seed


## Returns {move: float, target: float, fire: bool} for Sim.step.
func decide(s: Sim) -> Dictionary:
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


func _danger(s: Sim) -> float:
	var reach := Tune.SHIP_HALF + 16.0
	for shot in s.shots:
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
	return p.x + s.march_dir * s.march_speed() * t + _aim_error
