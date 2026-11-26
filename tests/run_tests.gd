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
	_floors()
	_formations()
	_cashier()
	_challenges()
	_daily()
	_telemetry()
	_more_games()
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


func _floors() -> void:
	check([1, 4, 5, 8, 17, 20, 21, 30].map(Floors.floor_of) == [1, 1, 2, 2, 5, 5, 6, 6], "four waves a floor, five floors, then After Hours")
	check(Floors.is_guard(4) and Floors.is_guard(20) and not Floors.is_guard(3) and not Floors.is_guard(24), "each floor's fourth wave is its guard, until After Hours")
	check(Sim.clear_bonus_for(4) == 2 * (Tune.CLEAR_BONUS + 3 * Tune.CLEAR_BONUS_PER_WAVE), "a guard pays double")
	for w in range(1, Tune.MAX_WAVE + 1):
		check(Floors.plan(w, RandomNumberGenerator.new()).size() == Tune.ROWS, "wave %d has a full plan" % w)
	# A new floor starts the formation back near the top.
	var w4 := Sim.create(11)
	w4.start_wave(4)
	var w5 := Sim.create(11)
	w5.start_wave(5)
	check(w5.origin.y < w4.origin.y and w5.origin.y > Sim.create(11).origin.y, "a new floor starts higher than the last guard, lower than floor 1")
	check(w5.march_speed() > w4.march_speed(), "but marches faster")
	# The lowest start still leaves room to play.
	var deep := Sim.create(11)
	deep.start_wave(Tune.MAX_WAVE)
	check(deep.origin.y + (Tune.ROWS - 1) * Tune.CELL.y + Tune.INVADER_HALF.y < Tune.INVADED_Y - 4 * Tune.MARCH_DROP, "the deepest wave starts at least four drops above the line")
	# Breaking the House: the Vault's guard doubles the tray; the daily ends there.
	for daily in [true, false]:
		var s := Daily.create(9) if daily else Sim.create(9)
		s.start_wave(Tune.VAULT_WAVE)
		s.tray = 100
		for inv in s.invaders:
			inv.alive = false
		s.step(0.0, NAN, false)
		check(s.tray == 2 * (100 + Sim.clear_bonus_for(Tune.VAULT_WAVE)) and s.broke_house(), "breaking the House doubles the tray (%d)" % s.tray)
		var guard := 0
		while s.phase != Sim.Phase.SETTLED and guard < 2000:
			s.step(0.0, NAN, false)
			guard += 1
		check(s.can_ride() != daily, "the daily ends at the Vault; arcade rides on into After Hours")
		s.next_wave()
		check(s.wave == (Tune.VAULT_WAVE if daily else Tune.VAULT_WAVE + 1), "riding past the Vault only in arcade")
	var last := Sim.create(9)
	last.start_wave(Tune.MAX_WAVE)
	for inv in last.invaders:
		inv.alive = false
	for i in 2000:
		last.step(0.0, NAN, false)
	check(last.phase == Sim.Phase.SETTLED and not last.can_ride(), "the House closes at wave %d" % Tune.MAX_WAVE)


## A settled run at wave `n` with `tray` balls, its cashier open.
## Every shape fits the board, holds no more than the leaderboard allows, can be
## cleared by the autopilot and can reach the line; the ring turns and only its
## lower arc fires.
func _formations() -> void:
	var plan := [Sim.Kind.CARD, Sim.Kind.DIE, Sim.Kind.CHIP, Sim.Kind.CHIP, Sim.Kind.CHIP]
	for w in range(1, Tune.MAX_WAVE + 1):
		check(Floors.shape(w, RandomNumberGenerator.new()) in Formations.ALL, "wave %d has a shape" % w)
	for shape in Formations.ALL:
		var s := Sim.create(31)
		s.form(shape, plan)
		var n := s.invaders.size()
		check(n >= 25 and n <= Tune.COLS * Tune.ROWS, "%s holds %d pieces" % [shape, n])
		var fits := true
		var bottom := -INF
		for inv in s.invaders:
			var p := s.invader_pos(inv)
			fits = fits and p.x > Tune.LEFT and p.x < Tune.RIGHT
			bottom = maxf(bottom, p.y)
		check(fits and bottom <= s.origin.y + (Tune.ROWS - 1) * Tune.CELL.y + 0.5, "%s fits the board and is no taller than the grid" % shape)
		s.tray = 2000
		var guard := 0
		var bot := Autopilot.new(1.0, 5)
		while s.phase == Sim.Phase.PLAYING and guard < 60 * 240:
			var d := bot.decide(s)
			s.step(d.move, d.target, d.fire)
			guard += 1
		check(s.phase != Sim.Phase.PLAYING and s.phase != Sim.Phase.BUST, "the autopilot clears a %s (%s after %ds)" % [shape, Sim.Phase.keys()[s.phase], guard / 60])
		var t := Sim.create(31)
		t.form(shape, plan)
		t.origin.y = Tune.INVADED_Y - (Tune.ROWS - 1) * Tune.CELL.y - Tune.INVADER_HALF.y + 1.0
		t.step(0.0, NAN, false)
		check(t.phase == Sim.Phase.BUST and t.bust_reason == "invaded", "a %s reaching the line busts the run" % shape)
	var r := Sim.create(31)
	r.form(Formations.RING, plan)
	var before := r.invader_pos(r.invaders[1]) - r.origin
	for i in 60:
		r.step(0.0, NAN, false)
	check((r.invader_pos(r.invaders[1]) - r.origin).distance_to(before) > 10.0, "the ring turns")
	var front := r._front()
	var mid := r.origin.y + (Tune.ROWS - 1) * Tune.CELL.y / 2.0
	check(not front.is_empty() and front.all(func(inv: Sim.Invader) -> bool: return r.invader_pos(inv).y >= mid - 1.0), "only the ring's lower arc fires")


## Clears the wave the Sim is on, feeding every step to the tracker; returns what it met.
func _clear_with(s: Sim, t: Challenges.Tracker) -> Array[StringName]:
	t.feed(s)
	for inv in s.invaders:
		inv.alive = false
	var got: Array[StringName] = []
	for i in 5:
		s.step(0.0, NAN, false)
		got.append_array(t.feed(s))
	return got


## The challenge tracker meets each goal from what a run does, once a run, and the
## profile's daily history lines up the last 14 days.
func _challenges() -> void:
	for id in Challenges.ORDER:
		check(Challenges.ALL.has(id) and Challenges.comps_of(id) > 0, "%s has a name and pays comps" % id)
	check(Challenges.ORDER.size() == Challenges.ALL.size(), "every challenge is in the order")
	var s := Sim.create(9)
	var t := Challenges.Tracker.new()
	t.feed(s)
	s.events = [{kind = &"prize", prize = "fever"}]
	check(t.feed(s).is_empty(), "one fever is not a streak")
	check(t.feed(s) == [&"hot_streak"] and t.feed(s).is_empty(), "two fevers in one wave are, once")
	s = Sim.create(9)
	s.start_wave(8)
	t = Challenges.Tracker.new()
	var got := _clear_with(s, t)
	check(&"card_shark" in got and &"untouchable" in got, "clearing the Card Room's guard unhit meets both (%s)" % str(got))
	s = Sim.create(9)
	s.start_wave(8)
	t = Challenges.Tracker.new()
	t.feed(s)
	s.stats.hits += 1
	got = _clear_with(s, t)
	check(&"card_shark" in got and &"untouchable" not in got, "a hit on the guard wave spoils untouchable")
	s = Sim.create(9)
	s.form(Formations.RING, Floors.PLANS[3][0])
	t = Challenges.Tracker.new()
	t.feed(s)
	s.stats.shots += 30
	s.stats.kills += 25
	got = _clear_with(s, t)
	check(&"round_round" in got and &"sharpshooter" in got, "breaking a ring at 83%% meets both (%s)" % str(got))
	s = Sim.create(9)
	s.start_wave(Tune.VAULT_WAVE)
	t = Challenges.Tracker.new()
	check(&"broke_house" in _clear_with(s, t), "breaking the Vault's guard")
	s = Sim.create(9)
	s.start_wave(Tune.VAULT_WAVE + 1)
	t = Challenges.Tracker.new()
	check(&"night_shift" in _clear_with(s, t), "a wave After Hours")
	s = Sim.create(9)
	s.tray = 600
	s.phase = Sim.Phase.SETTLED
	s.cash_out()
	t = Challenges.Tracker.new()
	got = t.finish(s)
	check(&"lobby_roller" in got and &"window_shopper" not in got, "500 from the Lobby, not yet 1,000")
	s = Sim.create(9)
	s.start_wave(6)
	s.tray = 1200
	s.phase = Sim.Phase.SETTLED
	s.cash_out()
	check(Challenges.Tracker.new().finish(s) == [&"window_shopper"], "1,000 without buying")
	s.stats.bought = 1
	check(Challenges.Tracker.new().finish(s).is_empty(), "a buy spoils window shopping")
	s = Sim.create(9)
	for id in Fixtures.ORDER.slice(0, Fixtures.SLOTS):
		s.fixtures[id] = 1
	check(Challenges.Tracker.new().shopped(s) == [&"full_house"], "six fixtures at once")
	var profile: Node = preload("res://scripts/autoload/profile.gd").new()
	profile.daily = {20: {payout = 300, waves = 9, outcome = "cashed", floor = 3}, 21: {payout = 0, waves = 2, outcome = "invaded"}}
	var h: Array[Dictionary] = profile.daily_history(21)
	check(h.size() == 14 and h[0].number == 8 and h[13].number == 21, "14 days, oldest first")
	check(h[12].played and h[12].floor == 3 and h[12].payout == 300 and not h[11].played, "a played day keeps its floor")
	check(h[13].floor == 0 and h[13].outcome == "invaded", "older records have no floor")
	check(profile.daily_history(3).size() == 3, "no days before daily #1")
	profile.free()


func _settled(seed_value: int, n: int, tray: int) -> Sim:
	var s := Sim.create(seed_value)
	s.start_wave(n)
	for inv in s.invaders:
		inv.alive = false
	var guard := 0
	while s.phase != Sim.Phase.SETTLED and guard < 2000:
		s.step(0.0, NAN, false)
		guard += 1
	s.tray = tray
	return s


func _cashier() -> void:
	check(Fixtures.ORDER.size() == Fixtures.ALL.size() and Fixtures.ORDER.all(func(id: StringName) -> bool: return Fixtures.ALL.has(id)), "every fixture is in the draw order once")
	var a := _settled(5, 2, 500)
	var b := _settled(5, 2, 500)
	check(a.offers.size() == Fixtures.OFFERS and a.offers == b.offers, "the same run and wave offer the same fixtures (%s)" % str(a.offers))
	check(_settled(5, 3, 500).offers != a.offers or _settled(6, 2, 500).offers != a.offers, "offers change with the wave or the seed")
	var seen := {}
	for o in a.offers:
		seen[o] = true
	check(seen.size() == Fixtures.OFFERS, "offers do not repeat in one visit")
	# Buying costs the price, raises prices, and takes the offer off the counter.
	var id := a.offers[0]
	var cost := a.price(id)
	check(a.buy(0) and a.tray == 500 - cost and a.level(id) == 1 and a.offers[0] == &"", "a buy costs its price")
	check(not a.buy(0), "a bought offer is gone")
	check(a.price(a.offers[1]) == roundi(Fixtures.ALL[a.offers[1]].price * Fixtures.PRICE_GROWTH), "each buy raises prices")
	# Rerolls double and draw new offers.
	var before := a.offers.duplicate()
	var t := a.tray
	check(a.reroll() and a.tray == t - Fixtures.REROLL_PRICE and a.reroll_price() == Fixtures.REROLL_PRICE * 2, "a reroll costs 10, then 20")
	check(a.offers != before, "a reroll draws new offers")
	# Selling returns half what was paid.
	t = a.tray
	check(a.sell(id) and a.tray == t + cost / 2 and a.level(id) == 0, "a sale returns half")
	# No buying mid-wave, nothing unaffordable, six slots.
	var c := Sim.create(5)
	c.offers = [&"comps"]
	check(not c.can_buy(0), "the cashier only opens between waves")
	var d := _settled(5, 2, 3)
	check(not d.can_buy(0) and not d.can_buy(1) and not d.reroll(), "nothing the tray cannot pay for")
	var e := _settled(5, 2, 9999)
	for i in Fixtures.SLOTS:
		e.fixtures[Fixtures.ORDER[i]] = 1
	e.offers = [Fixtures.ORDER[Fixtures.SLOTS], Fixtures.ORDER[0]]
	check(not e.can_buy(0), "six slots at most")
	check(e.can_buy(1) == (Fixtures.ALL[Fixtures.ORDER[0]].stacks > 1), "an owned fixture still stacks")
	# The daily's last wave and a closed House open no cashier.
	var f := _settled(5, Tune.MAX_WAVE, 500)
	check(f.offers.is_empty(), "no cashier when there is no next wave")
	# Effects.
	var g := Sim.create(5)
	g.fixtures = {&"twin_barrel": 1, &"quick_reload": 1}
	for i in 30:
		g.step(0.0, NAN, true)
	check(g.bolts.size() <= Tune.MAX_BOLTS + 1 and g.cool <= Tune.BOLT_COOLDOWN * Fixtures.QUICK_RELOAD, "twin barrel and quick reload")
	var h := Sim.create(5)
	h.fixtures = {&"insurance": 1, &"padded_rail": 1}
	h.tray = 100
	h.shots.append(Vector2(h.ship_x, Tune.SHIP_Y - 2.0))
	h.step(0.0, NAN, false)
	check(h.tray == 100 and h.stats.hits == 1, "insurance takes the first hit of the wave")
	h.invuln = 0.0
	h.shots.append(Vector2(h.ship_x, Tune.SHIP_Y - 2.0))
	h.step(0.0, NAN, false)
	check(h.tray == 100 - roundi(Tune.HIT_SPILL * Fixtures.PADDED_SHARE), "the padded rail halves the spill")
	var big := Sim.create(5)
	big.tray = 2000
	big.shots.append(Vector2(big.ship_x, Tune.SHIP_Y - 2.0))
	big.step(0.0, NAN, false)
	check(big.tray == 2000 - roundi(2000 * Tune.HIT_SPILL_SHARE), "a hit on a big tray spills a share of it")
	var k := Sim.create(5)
	k.fixtures = {&"comps": 1, &"interest": 1}
	k.tray = 200
	for inv in k.invaders:
		inv.alive = false
	k.step(0.0, NAN, false)
	var bonus := roundi(Tune.CLEAR_BONUS * Fixtures.COMPS_MULT)
	var interest := mini(roundi((200 + bonus) * Fixtures.INTEREST_RATE), Fixtures.INTEREST_CAP)
	check(k.tray == 200 + bonus + interest, "comps and interest on a clear (%d)" % k.tray)
	var m := Sim.create(5)
	m.fixtures = {&"bent_nail": 2, &"deep_cup": 1, &"wide_cup": 1, &"deep_holds": 1, &"long_fever": 1}
	check(m._pocket_pay(m.board.pockets[0]) == Tune.POCKET_START_PAY + 2 * Fixtures.BENT_NAIL, "two bent nails pay 2 x BENT_NAIL in the chucker")
	check(m.tray_half() == Tune.TRAY_HALF + Fixtures.WIDE_CUP and m.max_holds() == Tune.MAX_HOLDS + 2 and m.fever_len() == Tune.FEVER_TIME + 4.0, "wide cup, deep holds, long fever")
	var rng := RandomNumberGenerator.new()
	rng.seed = 3
	var fevers := 0
	for i in 20000:
		var r := Reels.roll(rng, 140)
		if r.triple and r.symbols[0] == Reels.Sym.SEVEN:
			fevers += 1
	check(absf(fevers / 20000.0 - 0.14) < 0.01, "loaded reels raise the fever odds (%.3f)" % (fevers / 20000.0))


func _daily() -> void:
	check(Daily.number_for(Daily.EPOCH) == 1, "launch day is run #1")
	check(Daily.number_for("2026-11-07") == 2, "the next day is #2")
	check(Daily.create(5).board.pins == Daily.create(5).board.pins, "a daily run is the same for everyone")
	check(Daily.seed_for(5) != Daily.seed_for(6), "neighbouring days differ")


## Must match web/src/run_row.ts.
const ROW_KEYS := ["mode", "daily", "outcome", "waves", "payout", "peak", "shots", "kills", "hits", "spins", "fevers", "pocketed", "caught", "official", "rules", "bought"]


func _telemetry() -> void:
	var s := Sim.create(21)
	_play(s, Autopilot.new(0.6, 2), 60 * 60 * 5)
	if not s.is_over():
		s.phase = Sim.Phase.BUST
		s.bust_reason = "invaded"
	var tel := preload("res://scripts/autoload/telemetry.gd")
	check(tel.row("daily", s, true, 4).daily == 4 and tel.row("arcade", s, true, 4).daily == 0, "only a daily row names its daily")
	var row: Dictionary = tel.row("arcade", s, true)
	var keys := row.keys().map(func(k: Variant) -> String: return str(k))
	keys.sort()
	var want := ROW_KEYS.duplicate()
	want.sort()
	check(keys == want, "telemetry row has exactly the expected keys")
	check(row.outcome in ["cashed", "invaded", "empty"], "outcome is one of three")
	check(row.payout == 0 or row.outcome == "cashed", "only a cash-out pays")
	check(row.kills <= row.shots * 3 + 20, "kills are bounded by shots")
	check(row.rules == Tune.RULES, "the row names its rules version")
	var worker := FileAccess.get_file_as_string("res://web/src/run_row.ts")
	check(worker.contains("export const RULES = %d;" % Tune.RULES), "web/src/run_row.ts accepts Tune.RULES")
	check(row.waves > 0 or row.bought == 0, "nothing is bought before a clear")
	for k in ROW_KEYS:
		if k not in ["mode", "outcome", "official"]:
			check(row[k] is int and row[k] >= 0, "%s is a non-negative integer" % k)
	_board_rows()


## The leaderboard lines under the result (Telemetry.board_rows): ties share a place, this
## run is marked once, and a run below the top gets its own line.
func _board_rows() -> void:
	var tel := preload("res://scripts/autoload/telemetry.gd")
	var top := [{payout = 300.0, waves = 6.0}, {payout = 120.0, waves = 4.0}, {payout = 120.0, waves = 3.0}, {payout = 50.0, waves = 2.0}]
	var rows := tel.board_rows({top = top, total = 4, rank = 2.0}, 120, 3)
	check(rows.map(func(r: Dictionary) -> int: return r.place) == [1, 2, 2, 4], "ties share a place (%s)" % str(rows))
	check(rows.filter(func(r: Dictionary) -> bool: return r.you).size() == 1 and rows[1].you, "the run is marked once, at its rank")
	rows = tel.board_rows({top = top, total = 40, rank = 37.0}, 12, 1)
	check(rows.size() == 5 and rows[4].you and rows[4].gap and rows[4].place == 37 and rows[4].payout == 12, "a run below the top gets its own line")
	rows = tel.board_rows({top = top, total = 4, rank = null}, 0, 2)
	check(rows.size() == 4 and rows.all(func(r: Dictionary) -> bool: return not r.you), "a bust or practice run is not marked")
	check(tel.board_rows({top = [], total = 0, rank = null}, 0, 0).is_empty(), "an empty board has no lines")


## Must match web/src/promo.ts.
const PROMO_KEYS := ["to", "where"]


## "More from Twinspear" (MoreGames): the bundled list parses, this game is never listed,
## the best fit comes first, Steam links are tagged, and the click row carries nothing else.
func _more_games() -> void:
	var games := MoreGames.bundled()
	check(games.size() >= 3, "the bundled games list parses (%d games)" % games.size())
	var ranked := MoreGames.ranked(games)
	check(ranked.all(func(g: Dictionary) -> bool: return g.id != MoreGames.SELF), "Pachinko never lists itself")
	check(ranked.size() == games.size() - 1, "every other game is listed")
	check(ranked[0].id == "det33", "an arcade shooter's players see DET-33 first (got %s)" % ranked[0].id)
	var steam: Dictionary = ranked[0]
	var url := MoreGames.link(steam, "end")
	check(url.begins_with(steam.url) and "utm_source=pachinko" in url and "utm_medium=app" in url and "utm_campaign=end" in url, "Steam links carry UTM tags (%s)" % url)
	check("utm_medium=itch&" in MoreGames.link(steam, "menu", MoreGames.SELF, "itch"), "the UTM medium says where the game was played")
	for pair: Array in [["pachinko.twinspear.com", "site"], ["html-classic.itch.zone", "itch"], ["v6p9d9t4.ssl.hwcdn.net", "itch"],
			["nathanielinman.itch.io", "itch"], ["localhost", "dev"], ["", "dev"], ["Games.Example.com", "games.example.com"],
			["notitch.zone.evil.com", "notitch.zone.evil.com"], ["eviltwinspear.com", "eviltwinspear.com"], ["a&b=c", "abc"]]:
		check(MoreGames.host_label(pair[0]) == pair[1], "host %s is labelled %s (got %s)" % [pair[0], pair[1], MoreGames.host_label(pair[0])])
	var web: Dictionary = ranked[1]
	check(MoreGames.link(web, "menu") == web.url, "links to the free browser games stay plain")
	check(MoreGames.parse("not json").is_empty() and MoreGames.parse('{"version": 2, "games": []}').is_empty(), "a broken or newer feed is ignored")
	check(MoreGames.parse('{"version": 1, "games": [{"id": "x"}, {"id": "ok", "title": "Ok", "pitch": "p", "url": "http://insecure", "platform": "web", "free": true, "audience": []}]}').is_empty(), "malformed or non-https entries are dropped")
	var tel := preload("res://scripts/autoload/telemetry.gd")
	var keys: Array = tel.promo_row("det33", "end").keys().map(func(k: Variant) -> String: return str(k))
	keys.sort()
	check(keys == PROMO_KEYS, "the click row has exactly the expected keys")
