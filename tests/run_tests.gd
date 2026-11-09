extends SceneTree
## Headless checks for the sim, the board, the reels, the daily seed and the
## telemetry row. Exit code 1 on any failure.
##   godot --headless --script tests/run_tests.gd

var _failed := 0
var _passed := 0


func _init() -> void:
	_determinism()
	_board()
	_no_cradles()
	_balls_settle()
	_reel_odds()
	_economy()
	_phases()
	_daily()
	_telemetry()
	print("\n%d passed, %d failed" % [_passed, _failed])
	quit(1 if _failed > 0 else 0)


func check(ok: bool, what: String) -> void:
	if ok:
		_passed += 1
	else:
		_failed += 1
		printerr("FAIL: ", what)


func _play(s: Sim, bot: Autopilot, frames: int) -> void:
	for i in frames:
		if s.is_over():
			return
		var d := bot.decide(s)
		s.step(d.move, d.target, d.fire)
		if s.phase == Sim.Phase.SETTLED:
			s.next_wave()


func _determinism() -> void:
	var a := Sim.create(42)
	var b := Sim.create(42)
	_play(a, Autopilot.new(0.8, 9), 3600)
	_play(b, Autopilot.new(0.8, 9), 3600)
	check(a.tray == b.tray and a.stats.kills == b.stats.kills and a.stats.spins == b.stats.spins, "same seed and inputs give the same run")
	check(a.board.pins == Sim.create(42).board.pins, "same seed gives the same board")
	check(a.board.pins != Sim.create(43).board.pins, "different seeds give different boards")
	# The board and formations do not depend on how you play.
	var c := Sim.create(42)
	_play(c, Autopilot.new(0.3, 1), 600)
	check(c.board.pins == a.board.pins, "play does not change the board")


func _board() -> void:
	for seed_value in 20:
		var b := Sim.create(seed_value).board
		check(b.pins.size() > 120 and b.pins.size() < 260, "pin count in range (%d)" % b.pins.size())
		var reel := Rect2(Tune.REEL_CENTER - Tune.REEL_SIZE / 2.0, Tune.REEL_SIZE)
		var clear := true
		for p in b.pins:
			if reel.grow(4).has_point(p) or p.x < Tune.LEFT or p.x > Tune.RIGHT:
				clear = false
		check(clear, "pins stay out of the reel window and inside the walls")
		for pk in b.pockets:
			var blocked := false
			for p in b.pins:
				if absf(p.x - pk.pos.x) < Board.mouth(pk) and p.y > pk.pos.y - 30.0 and p.y < pk.pos.y + 2.0:
					blocked = true
			check(not blocked, "nothing sits in the mouth of pocket kind %d" % pk.kind)
		check(b.pockets.size() == 6 and b.attacker().open == false, "six pockets, attacker shut")


## No two obstacles side by side leave a gap a ball can sit in but not fall
## through (a ball once wedged between a guide rail and the chucker's lip).
func _no_cradles() -> void:
	for seed_value in 20:
		var b := Sim.create(seed_value).board
		var points := PackedVector2Array(b.pins)
		for pk in b.pockets:
			if pk.kind == Board.Pocket.TULIP:
				points.append_array(Board.wings(pk))
				pk.open = true
				points.append_array(Board.wings(pk))
				pk.open = false
		var bad := []
		for i in points.size():
			var p := points[i]
			var near := [Vector2(Tune.LEFT, p.y), Vector2(Tune.RIGHT, p.y)]
			var reach := [Tune.PIN_R, Tune.PIN_R]
			for w in b.walls + [b.lid]:
				near.append(Board.closest_on_segment(p, w[0], w[1]))
				reach.append(Tune.PIN_R + w[2])
			# Wings are never checked against each other: a tulip is open or shut.
			for j in range(i + 1, points.size() if i < b.pins.size() else 0):
				near.append(points[j])
				reach.append(Tune.PIN_R * 2.0)
			for k in near.size():
				var d: Vector2 = near[k] - p
				var gap: float = d.length() - float(reach[k])
				if gap > 0.5 and gap <= Tune.BALL_R * 2.0 and absf(d.y) <= absf(d.x):
					bad.append("%s gap %.1f" % [p, gap])
		check(bad.is_empty(), "seed %d: no ball-sized cradles %s" % [seed_value, bad.slice(0, 4)])


## Balls dropped across the top all finish (pocketed, caught or drained), and
## pockets catch a believable share.
func _balls_settle() -> void:
	var s := Sim.create(7)
	s.invaders.clear()
	s.phase = Sim.Phase.CLEARED
	s.ship_x = -1000.0
	var dropped := 0
	for i in 60:
		s._drop(Vector2(lerpf(Tune.LEFT + 20, Tune.RIGHT - 20, i / 59.0), 380.0), false)
		dropped += 1
	var frames := 0
	var oldest := 0.0
	while not s.balls.is_empty() and frames < 60 * 20:
		for ball in s.balls:
			oldest = maxf(oldest, ball.age)
		s.step(0.0, NAN, false)
		frames += 1
	check(s.balls.is_empty(), "every ball finishes within 20 s (%d left)" % s.balls.size())
	check(oldest < 12.0, "no ball needs the 14 s age cap (oldest %.1f s)" % oldest)
	# A ball that makes no progress is kicked STALL_KICKS times, then drained.
	var ball := Sim.Ball.new()
	ball.pos = Vector2(200, 600)
	ball.anchor = ball.pos
	var kicked := 0
	var drained_at := -1
	for i in 60 * 10:
		if s._stalled(ball, Tune.STEP):
			drained_at = i
			break
		if ball.vel != Vector2.ZERO:
			kicked += 1
			check(ball.vel.y < 0.0, "a stall kick hops the ball upward")
			ball.vel = Vector2.ZERO
	check(kicked == Tune.STALL_KICKS, "a stuck ball is kicked %d times (%d)" % [Tune.STALL_KICKS, kicked])
	check(drained_at > 0 and drained_at <= int((Tune.STALL_KICKS + 1) * Tune.STALL_TIME / Tune.STEP) + 1, "then drained, not left for the age cap")
	var share := float(s.stats.pocketed) / dropped
	check(share > 0.08 and share < 0.6, "pockets take a believable share (%.2f)" % share)


func _reel_odds() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 5
	var n := 40000
	var fever := 0
	var triple := 0
	var reach := 0
	var bad := false
	for i in n:
		var r := Reels.roll(rng)
		var sy: PackedInt32Array = r.symbols
		var is_triple := sy[0] == sy[1] and sy[1] == sy[2]
		if is_triple != r.triple or (sy[0] == sy[1]) != r.reach:
			bad = true
		if r.triple:
			triple += 1
			if sy[0] == Reels.Sym.SEVEN:
				fever += 1
		if r.reach:
			reach += 1
	check(not bad, "roll flags match the symbols shown")
	check(absf(float(fever) / n - Reels.FEVER_ODDS / 1000.0) < 0.01, "fever odds (%.3f)" % (float(fever) / n))
	check(absf(float(triple) / n - (Reels.FEVER_ODDS + Reels.PRIZE_ODDS) / 1000.0) < 0.012, "triple odds (%.3f)" % (float(triple) / n))


func _economy() -> void:
	var s := Sim.create(3)
	var start := s.tray
	s.step(0.0, NAN, true)
	check(s.tray == start - Tune.SHOT_COST and s.bolts.size() == 1, "a shot costs one ball")
	s.step(0.0, NAN, true)
	check(s.bolts.size() == 1, "the cooldown holds the second shot")
	# Fever shots are free.
	s.fever_t = 5.0
	s.cool = 0.0
	var before := s.tray
	s.step(0.0, NAN, true)
	check(s.tray == before, "fever shots are free")
	# A hit spills balls but never below zero.
	s = Sim.create(3)
	s.tray = 5
	s.shots.append(Vector2(s.ship_x, Tune.SHIP_Y - 2.0))
	s.step(0.0, NAN, false)
	check(s.tray == 0 and s.stats.hits == 1, "a hit spills at most the tray")
	s.shots.append(Vector2(s.ship_x, Tune.SHIP_Y - 2.0))
	s.step(0.0, NAN, false)
	check(s.stats.hits == 1, "no second hit while blinking")
	# A shield absorbs one hit.
	s = Sim.create(3)
	s.shield = true
	var t := s.tray
	s.shots.append(Vector2(s.ship_x, Tune.SHIP_Y - 2.0))
	s.step(0.0, NAN, false)
	check(s.tray == t and not s.shield, "the shield takes the hit")
	# Gold balls pay triple in a pocket.
	s = Sim.create(3)
	var pk: Dictionary = s.board.pockets[1]
	var ball := Sim.Ball.new()
	ball.pos = pk.pos + Vector2(0, 2)
	ball.vel = Vector2(0, 200)
	ball.gold = true
	t = s.tray
	check(s._pocketed(ball, pk.pos + Vector2(0, -6)), "a ball crossing the mouth is pocketed")
	check(s.tray == t + pk.pay * Tune.GOLD_MULT, "gold pays triple")


func _phases() -> void:
	var s := Sim.create(11)
	s.cash_out()
	check(s.phase == Sim.Phase.PLAYING, "cannot cash out mid-wave")
	for inv in s.invaders:
		inv.alive = false
	s.step(0.0, NAN, false)
	check(s.phase == Sim.Phase.CLEARED, "an empty formation clears the wave")
	var bonus := Tune.CLEAR_BONUS
	check(s.clear_bonus == bonus, "wave 1 clear bonus")
	var guard := 0
	while s.phase != Sim.Phase.SETTLED and guard < 2000:
		s.step(0.0, NAN, false)
		guard += 1
	check(s.phase == Sim.Phase.SETTLED and s.stats.waves.size() == 1, "the wave settles once the balls are down")
	var tray := s.tray
	s.cash_out()
	check(s.is_over() and s.payout() == tray, "cashing out pays the tray")
	# Bust by invasion pays nothing.
	s = Sim.create(11)
	s.origin.y = Tune.INVADED_Y
	s.step(0.0, NAN, false)
	check(s.phase == Sim.Phase.BUST and s.bust_reason == "invaded" and s.payout() == 0, "the House reaching the line busts the run")
	check(s.stats.waves.size() == 1, "the bust wave is recorded")
	# Bust by running dry.
	s = Sim.create(11)
	s.tray = 0
	s.step(0.0, NAN, true)
	check(s.phase == Sim.Phase.BUST and s.bust_reason == "empty", "an empty tray with nothing in play busts the run")
	# Waves get harder.
	var w1 := Sim.create(11)
	var w5 := Sim.create(11)
	w5.start_wave(5)
	check(w5.origin.y > w1.origin.y and w5.march_speed() > w1.march_speed(), "later waves start lower and march faster")


func _daily() -> void:
	check(Daily.number_for(Daily.EPOCH) == 1, "launch day is run #1")
	check(Daily.number_for("2026-11-07") == 2, "the next day is #2")
	check(Daily.create(5).board.pins == Daily.create(5).board.pins, "a daily run is the same for everyone")
	check(Daily.seed_for(5) != Daily.seed_for(6), "neighbouring days differ")


## Must match web/src/run_row.ts.
const ROW_KEYS := ["mode", "outcome", "waves", "payout", "peak", "shots", "kills", "hits", "spins", "fevers", "pocketed", "caught", "official"]


func _telemetry() -> void:
	var s := Sim.create(21)
	_play(s, Autopilot.new(0.6, 2), 60 * 60 * 5)
	if not s.is_over():
		s.phase = Sim.Phase.BUST
		s.bust_reason = "invaded"
	var row: Dictionary = preload("res://scripts/autoload/telemetry.gd").row("arcade", s, true)
	var keys := row.keys().map(func(k: Variant) -> String: return str(k))
	keys.sort()
	var want := ROW_KEYS.duplicate()
	want.sort()
	check(keys == want, "telemetry row has exactly the expected keys")
	check(row.outcome in ["cashed", "invaded", "empty"], "outcome is one of three")
	check(row.payout == 0 or row.outcome == "cashed", "only a cash-out pays")
	check(row.kills <= row.shots * 3 + 20, "kills are bounded by shots")
	for k in ROW_KEYS:
		if k not in ["mode", "outcome", "official"]:
			check(row[k] is int and row[k] >= 0, "%s is a non-negative integer" % k)
