class_name Sim
extends RefCounted
## One run of Pachinko Descent as plain data, stepped at a fixed 60 Hz. The House
## (the invaders) marches down; every one you shoot drops balls through the pins.
## Pockets pay balls into your tray, the start chucker spins the reels, and the
## tray is both your ammunition and your score. No nodes: the view reads this, and
## the tests and the autopilot drive it headless.
##
## Everything random comes from the run's seed, split into streams so the board,
## each wave's formation and the reel outcomes do not depend on how you play.

enum Phase { PLAYING, CLEARED, SETTLED, BUST, CASHED }
enum Kind { CHIP, DIE, CARD }

const KIND_NAMES := ["Chip", "Die", "Card"]
const KIND_HP := [1, 2, 1]
const KIND_BALLS := [1, 2, 1]
## How likely the bottom invader of a column is to be the one that fires.
const KIND_FIRE := [1.0, 1.0, 2.6]
## Rows top to bottom for the first waves; later waves reuse the last with swaps.
const ROW_PLANS := [
	[Kind.CARD, Kind.DIE, Kind.CHIP, Kind.CHIP, Kind.CHIP],
	[Kind.CARD, Kind.DIE, Kind.DIE, Kind.CHIP, Kind.CHIP],
	[Kind.CARD, Kind.CARD, Kind.DIE, Kind.DIE, Kind.CHIP],
	[Kind.CARD, Kind.CARD, Kind.DIE, Kind.DIE, Kind.DIE],
]


class Invader:
	var col: int
	var row: int
	var kind: int
	var hp: int
	var gold := false
	var alive := true
	## Seconds since last hit, for the view's flash.
	var hit_t := 9.0


class Ball:
	var pos: Vector2
	var vel: Vector2
	var gold := false
	var age := 0.0
	## Where the ball was when it last made progress (see _stalled), and how long ago.
	var anchor: Vector2
	var still := 0.0
	var kicks := 0


class Bolt:
	var pos: Vector2
	var vel: Vector2
	var pierce := false
	var last_hit: Object = null


var run_seed := 0
var board: Board
var wave := 0
var tray := 0
var phase := Phase.PLAYING
## "invaded" or "empty" once the run is bust.
var bust_reason := ""
var time := 0.0

var ship_x := Tune.W / 2.0
var ship_vx := 0.0
var cool := 0.0
var invuln := 0.0
var shield := false
var _dry := false

var bolts: Array[Bolt] = []
var invaders: Array[Invader] = []
## Centre of the column-0, row-0 slot; every invader sits on the grid from here.
var origin := Vector2()
var march_dir := 1.0
var shots := PackedVector2Array()
var _fire_t := 0.0

var balls: Array[Ball] = []

var saucer_on := false
var saucer_x := 0.0
var saucer_dir := 1.0
var _saucer_t := 0.0

var holds := 0
## The spin on the reels now: {} or Reels.roll() plus {t, len, stopped}.
var spin := {}
var last_symbols := PackedInt32Array([Reels.Sym.SEVEN, Reels.Sym.BAR, Reels.Sym.CHERRY])

var fever_t := 0.0
var spread_t := 0.0
var pierce_t := 0.0
var magnet_t := 0.0

## Things that happened during the last step, for sound and effects:
## {kind: StringName, pos?: Vector2, ...}
var events: Array[Dictionary] = []

## Totals for the result screen and telemetry.
var stats := {
	shots = 0, kills = 0, hits = 0, spins = 0, fevers = 0, prizes = 0,
	pocketed = 0, caught = 0, drained = 0, peak = 0, saucers = 0,
	## Tray change over each finished wave, bonus included.
	waves = [],
}
var clear_bonus := 0
var wave_start_tray := 0

var _rng := RandomNumberGenerator.new()
var _reel_rng := RandomNumberGenerator.new()
var _pin_events := 0


static func create(seed_value: int) -> Sim:
	var s := Sim.new()
	s.run_seed = seed_value
	s._rng.seed = mix(seed_value, 1)
	s._reel_rng.seed = mix(seed_value, 2)
	var board_rng := RandomNumberGenerator.new()
	board_rng.seed = mix(seed_value, 3)
	s.board = Board.build(board_rng)
	s.tray = Tune.START_BALLS
	s.stats.peak = s.tray
	s.start_wave(1)
	return s


## A 32-bit splitmix-style hash of (seed, stream).
static func mix(a: int, b: int) -> int:
	var z := (a * 0x9E3779B9 + b * 0x7F4A7C15 + 0x632BE5AB) & 0xFFFFFFFF
	z = ((z ^ (z >> 16)) * 0x85EBCA6B) & 0xFFFFFFFF
	z = ((z ^ (z >> 13)) * 0xC2B2AE35) & 0xFFFFFFFF
	return z ^ (z >> 16)


func start_wave(n: int) -> void:
	wave = n
	phase = Phase.PLAYING
	wave_start_tray = tray
	clear_bonus = 0
	invaders.clear()
	shots.clear()
	saucer_on = false
	var wrng := RandomNumberGenerator.new()
	wrng.seed = mix(run_seed, 100 + n)
	var plan: Array = ROW_PLANS[mini(n - 1, ROW_PLANS.size() - 1)].duplicate()
	if n > ROW_PLANS.size():
		# Later waves: one or two rows harden.
		for i in mini(n - ROW_PLANS.size(), 2):
			plan[wrng.randi_range(1, Tune.ROWS - 1)] = Kind.CARD if wrng.randf() < 0.5 else Kind.DIE
	for row in Tune.ROWS:
		for col in Tune.COLS:
			var inv := Invader.new()
			inv.col = col
			inv.row = row
			inv.kind = plan[row]
			inv.hp = KIND_HP[inv.kind]
			invaders.append(inv)
	var golds := 2 + n / 3
	for i in golds:
		invaders[wrng.randi_range(0, invaders.size() - 1)].gold = true
	origin = Vector2((Tune.W - (Tune.COLS - 1) * Tune.CELL.x) / 2.0,
		Tune.FORMATION_TOP + minf((n - 1) * Tune.WAVE_DROP, Tune.WAVE_DROP_MAX))
	march_dir = 1.0 if wrng.randf() < 0.5 else -1.0
	_fire_t = _fire_gap() * 1.5
	_saucer_t = wrng.randf_range(Tune.SAUCER_GAP.x, Tune.SAUCER_GAP.y)


func next_wave() -> void:
	if phase == Phase.SETTLED and wave < Tune.MAX_WAVE:
		start_wave(wave + 1)


func cash_out() -> void:
	if phase == Phase.SETTLED:
		phase = Phase.CASHED


func is_over() -> bool:
	return phase == Phase.BUST or phase == Phase.CASHED


## What the run pays: the tray if cashed out, nothing if bust.
func payout() -> int:
	return tray if phase == Phase.CASHED else 0


func invader_pos(inv: Invader) -> Vector2:
	return origin + Vector2(inv.col * Tune.CELL.x, inv.row * Tune.CELL.y)


func alive_count() -> int:
	var n := 0
	for inv in invaders:
		if inv.alive:
			n += 1
	return n


func tray_half() -> float:
	return Tune.TRAY_HALF_MAGNET if magnet_t > 0.0 else Tune.TRAY_HALF


func march_speed() -> float:
	var dead := 1.0 - float(alive_count()) / float(invaders.size())
	return (Tune.MARCH_SPEED + Tune.MARCH_SPEED_PER_WAVE * (wave - 1)) * (1.0 + Tune.RUSH * dead * dead)


func _fire_gap() -> float:
	return maxf(Tune.FIRE_GAP - Tune.FIRE_GAP_PER_WAVE * (wave - 1), Tune.FIRE_GAP_MIN)


func _emit(kind: StringName, data := {}) -> void:
	data.kind = kind
	events.append(data)


# --- the step ----------------------------------------------------------------

## `move` is -1..1 from keys; `target` is a board x to steer toward (pointer), or
## NAN for none. `fire` holds the trigger.
func step(move: float, target: float, fire: bool) -> void:
	events.clear()
	if is_over():
		return
	var dt := Tune.STEP
	time += dt
	_pin_events = 0
	var playing := phase == Phase.PLAYING

	var before := ship_x
	if not is_nan(target):
		ship_x = move_toward(ship_x, target, Tune.SHIP_SPEED * dt)
	else:
		ship_x += clampf(move, -1.0, 1.0) * Tune.SHIP_SPEED * dt
	ship_x = clampf(ship_x, Tune.LEFT + Tune.SHIP_HALF, Tune.RIGHT - Tune.SHIP_HALF)
	ship_vx = (ship_x - before) / dt

	cool -= dt
	invuln -= dt
	if playing:
		_tick_powers(dt)
		if fire:
			_fire()
		else:
			_dry = false
	_move_bolts(dt)
	if playing:
		_march(dt)
		_enemy_fire(dt)
	_move_shots(dt)
	if playing:
		_move_saucer(dt)
	_move_balls(dt)
	for s in board.spinners:
		s.angle = fmod(s.angle + s.spin * dt, TAU)
	if playing:
		_run_reels(dt)
	for inv in invaders:
		inv.hit_t += dt
	_check_phase()
	stats.peak = maxi(stats.peak, tray)


func _tick_powers(dt: float) -> void:
	if fever_t > 0.0:
		fever_t -= dt
		if fever_t <= 0.0:
			board.attacker().open = false
			_emit(&"fever_end")
	spread_t = maxf(spread_t - dt, 0.0)
	pierce_t = maxf(pierce_t - dt, 0.0)
	magnet_t = maxf(magnet_t - dt, 0.0)


func _fire() -> void:
	var fever := fever_t > 0.0
	var limit := Tune.MAX_BOLTS_RAPID if fever else Tune.MAX_BOLTS
	var spread := spread_t > 0.0
	if spread:
		limit *= 3
	if cool > 0.0 or bolts.size() >= limit:
		return
	if not fever and tray < Tune.SHOT_COST:
		if not _dry:
			_dry = true
			_emit(&"dry")
		return
	if not fever:
		tray -= Tune.SHOT_COST
	var muzzle := Vector2(ship_x, Tune.SHIP_Y - 22)
	var angles := [0.0]
	if spread:
		angles = [-0.16, 0.0, 0.16]
	for a: float in angles:
		var b := Bolt.new()
		b.pos = muzzle
		b.vel = Vector2(sin(a), -cos(a)) * Tune.BOLT_SPEED
		b.pierce = pierce_t > 0.0
		bolts.append(b)
	cool = Tune.BOLT_COOLDOWN_RAPID if fever else Tune.BOLT_COOLDOWN
	stats.shots += 1
	_emit(&"fire", {pos = muzzle, free = fever})


func _move_bolts(dt: float) -> void:
	var keep: Array[Bolt] = []
	for b in bolts:
		b.pos += b.vel * dt
		var gone := b.pos.y < 70.0 or b.pos.x < Tune.LEFT or b.pos.x > Tune.RIGHT
		# Bolts meet House shots head-on and both burst.
		if not gone:
			for i in shots.size():
				if absf(shots[i].x - b.pos.x) < 9.0 and absf(shots[i].y - b.pos.y) < 16.0:
					_emit(&"clash", {pos = shots[i]})
					shots.remove_at(i)
					gone = not b.pierce
					break
		if not gone:
			gone = _bolt_hits_invader(b)
		if not gone and saucer_on and absf(b.pos.x - saucer_x) < 30.0 and absf(b.pos.y - Tune.SAUCER_Y) < 14.0:
			_kill_saucer()
			gone = true
		# Passing through a shut tulip springs it open.
		for pk in board.pockets:
			if pk.kind == Board.Pocket.TULIP and not pk.open and absf(b.pos.x - pk.pos.x) < 16.0 and absf(b.pos.y - pk.pos.y) < 14.0:
				pk.open = true
				_emit(&"tulip", {pos = pk.pos, open = true})
		if not gone:
			keep.append(b)
	bolts = keep


func _bolt_hits_invader(b: Bolt) -> bool:
	for inv in invaders:
		if not inv.alive or inv == b.last_hit:
			continue
		var p := invader_pos(inv)
		if absf(b.pos.x - p.x) < Tune.INVADER_HALF.x + 3.0 and absf(b.pos.y - p.y) < Tune.INVADER_HALF.y + 8.0:
			b.last_hit = inv
			inv.hp -= 1
			inv.hit_t = 0.0
			if inv.hp <= 0:
				_kill(inv, p)
			else:
				_emit(&"dent", {pos = p})
			return not b.pierce
	return false


func _kill(inv: Invader, p: Vector2) -> void:
	inv.alive = false
	stats.kills += 1
	_emit(&"kill", {pos = p, type = inv.kind, gold = inv.gold})
	for i in KIND_BALLS[inv.kind]:
		_drop(p + Vector2(_rng.randf_range(-8, 8), _rng.randf_range(-4, 4)), inv.gold)


func _drop(p: Vector2, gold: bool) -> void:
	var ball := Ball.new()
	ball.pos = p
	ball.anchor = p
	ball.vel = Vector2(_rng.randf_range(-70, 70), _rng.randf_range(-90, -10))
	ball.gold = gold
	balls.append(ball)


func _march(dt: float) -> void:
	var lo := INF
	var hi := -INF
	var bottom := -INF
	for inv in invaders:
		if inv.alive:
			var p := invader_pos(inv)
			lo = minf(lo, p.x)
			hi = maxf(hi, p.x)
			bottom = maxf(bottom, p.y)
	if bottom == -INF:
		return
	origin.x += march_dir * march_speed() * dt
	var edge := Tune.INVADER_HALF.x + 6.0
	if (march_dir > 0.0 and hi + march_dir * march_speed() * dt > Tune.RIGHT - edge) or \
			(march_dir < 0.0 and lo + march_dir * march_speed() * dt < Tune.LEFT + edge):
		march_dir = -march_dir
		origin.y += Tune.MARCH_DROP
		_emit(&"drop")
	if bottom + Tune.INVADER_HALF.y >= Tune.INVADED_Y:
		phase = Phase.BUST
		bust_reason = "invaded"


func _enemy_fire(dt: float) -> void:
	_fire_t -= dt
	if _fire_t > 0.0:
		return
	_fire_t = _fire_gap() * _rng.randf_range(0.6, 1.35)
	if shots.size() >= 3 + wave / 2:
		return
	# The lowest live invader in each column is the one that can fire.
	var lowest := {}
	for inv in invaders:
		if inv.alive and (not lowest.has(inv.col) or inv.row > lowest[inv.col].row):
			lowest[inv.col] = inv
	if lowest.is_empty():
		return
	var shooter: Invader
	if _rng.randf() < 0.35:
		var best := INF
		for inv: Invader in lowest.values():
			var d := absf(invader_pos(inv).x - ship_x)
			if d < best:
				best = d
				shooter = inv
	else:
		var total := 0.0
		for inv: Invader in lowest.values():
			total += KIND_FIRE[inv.kind]
		var pick := _rng.randf() * total
		for inv: Invader in lowest.values():
			pick -= KIND_FIRE[inv.kind]
			shooter = inv
			if pick <= 0.0:
				break
	var p := invader_pos(shooter) + Vector2(0, Tune.INVADER_HALF.y)
	shots.append(p)
	_emit(&"enemy_fire", {pos = p})


func _move_shots(dt: float) -> void:
	var speed := Tune.SHOT_SPEED + Tune.SHOT_SPEED_PER_WAVE * (wave - 1)
	var keep := PackedVector2Array()
	for s in shots:
		s.y += speed * dt
		if s.y > Tune.H:
			continue
		if phase == Phase.PLAYING and absf(s.x - ship_x) < Tune.SHIP_HALF - 8.0 and absf(s.y - Tune.SHIP_Y) < 16.0:
			if invuln > 0.0:
				continue
			invuln = Tune.HIT_INVULN
			if shield:
				shield = false
				_emit(&"shielded", {pos = s})
			else:
				var lost := mini(tray, Tune.HIT_SPILL)
				tray -= lost
				stats.hits += 1
				_emit(&"hit", {pos = Vector2(ship_x, Tune.SHIP_Y), lost = lost})
			continue
		keep.append(s)
	shots = keep


func _move_saucer(dt: float) -> void:
	if not saucer_on:
		_saucer_t -= dt
		if _saucer_t <= 0.0:
			saucer_on = true
			saucer_dir = 1.0 if _rng.randf() < 0.5 else -1.0
			saucer_x = Tune.LEFT - 40.0 if saucer_dir > 0.0 else Tune.RIGHT + 40.0
			_emit(&"saucer")
		return
	saucer_x += saucer_dir * Tune.SAUCER_SPEED * dt
	if saucer_x < Tune.LEFT - 60.0 or saucer_x > Tune.RIGHT + 60.0:
		saucer_on = false
		_saucer_t = _rng.randf_range(Tune.SAUCER_GAP.x, Tune.SAUCER_GAP.y)


func _kill_saucer() -> void:
	saucer_on = false
	_saucer_t = _rng.randf_range(Tune.SAUCER_GAP.x, Tune.SAUCER_GAP.y)
	stats.saucers += 1
	var p := Vector2(saucer_x, Tune.SAUCER_Y)
	holds = mini(holds + 1, Tune.MAX_HOLDS)
	_emit(&"saucer_kill", {pos = p})
	for i in Tune.SAUCER_BALLS:
		_drop(p + Vector2((i - 2) * 9.0, 0), false)


# --- balls -------------------------------------------------------------------

func _move_balls(dt_frame: float) -> void:
	var dt := dt_frame / Tune.BALL_SUBSTEPS
	var lid_shut: bool = not board.attacker().open
	var keep: Array[Ball] = []
	for ball in balls:
		var live := true
		ball.age += dt_frame
		for sub in Tune.BALL_SUBSTEPS:
			var prev := ball.pos
			ball.vel.y += Tune.GRAVITY * dt
			ball.pos += ball.vel * dt
			for i in board.pins_near(ball.pos):
				_bounce(ball, board.pins[i], Tune.PIN_R, true)
			for pk in board.pockets:
				if pk.kind == Board.Pocket.TULIP and ball.pos.distance_squared_to(pk.pos) < 3600.0:
					for w in Board.wings(pk):
						_bounce(ball, w, Tune.PIN_R + 1.0, true)
			for s in board.spinners:
				var n := _bounce(ball, s.pos, s.r, false)
				if n != Vector2.ZERO:
					ball.vel += Vector2(-n.y, n.x) * s.spin * s.r * 1.4
			for w in board.walls:
				_bounce(ball, Board.closest_on_segment(ball.pos, w[0], w[1]), w[2], false)
			if lid_shut:
				_bounce(ball, Board.closest_on_segment(ball.pos, board.lid[0], board.lid[1]), board.lid[2], false)
			if ball.pos.x < Tune.LEFT + Tune.BALL_R:
				ball.pos.x = Tune.LEFT + Tune.BALL_R
				ball.vel.x = absf(ball.vel.x) * 0.6
			elif ball.pos.x > Tune.RIGHT - Tune.BALL_R:
				ball.pos.x = Tune.RIGHT - Tune.BALL_R
				ball.vel.x = -absf(ball.vel.x) * 0.6
			ball.vel = ball.vel.limit_length(Tune.MAX_BALL_SPEED)
			if _pocketed(ball, prev) or _caught(ball):
				live = false
				break
			if ball.pos.y > Tune.DRAIN_Y or ball.age > 14.0:
				stats.drained += 1
				_emit(&"drain", {pos = ball.pos})
				live = false
				break
		if live and _stalled(ball, dt_frame):
			stats.drained += 1
			_emit(&"drain", {pos = ball.pos})
			live = false
		if live:
			keep.append(ball)
	balls = keep


## A ball that has neither dropped STALL_RADIUS nor gone four times that far in
## any direction for STALL_TIME is wedged, balanced on a pin or creeping along the
## shut lid: hop it up and sideways. Returns true once it has been kicked
## STALL_KICKS times and is stuck again, so the caller drains it.
func _stalled(ball: Ball, dt: float) -> bool:
	var d := ball.pos - ball.anchor
	if d.y > Tune.STALL_RADIUS or d.length() > Tune.STALL_RADIUS * 4.0:
		ball.anchor = ball.pos
		ball.still = 0.0
		return false
	ball.still += dt
	if ball.still < Tune.STALL_TIME:
		return false
	if ball.kicks >= Tune.STALL_KICKS:
		return true
	ball.kicks += 1
	ball.still = 0.0
	var side := -1.0 if _rng.randf() < 0.5 else 1.0
	ball.vel = Vector2(side * _rng.randf_range(120, 200), _rng.randf_range(-260, -180))
	return false


## Pushes the ball out of a circle at `c` and reflects it. Returns the contact
## normal, or ZERO when they do not touch.
func _bounce(ball: Ball, c: Vector2, r: float, pin: bool) -> Vector2:
	var d := ball.pos - c
	var reach := r + Tune.BALL_R
	var d2 := d.length_squared()
	if d2 >= reach * reach:
		return Vector2.ZERO
	var n := d / sqrt(d2) if d2 > 0.0001 else Vector2(1.0 if _rng.randf() < 0.5 else -1.0, -1.0).normalized()
	ball.pos = c + n * reach
	var vn := ball.vel.dot(n)
	if vn < 0.0:
		ball.vel -= (1.0 + Tune.RESTITUTION) * vn * n
		ball.vel *= Tune.FRICTION
		ball.vel.x += _rng.randf_range(-14.0, 14.0)
		if pin and vn < -140.0 and _pin_events < 2:
			_pin_events += 1
			_emit(&"pin", {pos = c, speed = -vn})
	return n


func _pocketed(ball: Ball, prev: Vector2) -> bool:
	for pk in board.pockets:
		if pk.kind == Board.Pocket.ATTACKER and not pk.open:
			continue
		if prev.y < pk.pos.y and ball.pos.y >= pk.pos.y and absf(ball.pos.x - pk.pos.x) < Board.mouth(pk) and ball.vel.y > 0.0:
			var pay: int = pk.pay * (Tune.GOLD_MULT if ball.gold else 1)
			tray += pay
			stats.pocketed += 1
			match pk.kind:
				Board.Pocket.START:
					var held := holds < Tune.MAX_HOLDS
					holds = mini(holds + 1, Tune.MAX_HOLDS)
					_emit(&"pocket", {pos = pk.pos, pocket = pk.kind, pay = pay, gold = ball.gold, held = held})
				Board.Pocket.TULIP:
					pk.open = not pk.open
					_emit(&"pocket", {pos = pk.pos, pocket = pk.kind, pay = pay, gold = ball.gold})
					_emit(&"tulip", {pos = pk.pos, open = pk.open})
				_:
					_emit(&"pocket", {pos = pk.pos, pocket = pk.kind, pay = pay, gold = ball.gold})
			return true
	return false


func _caught(ball: Ball) -> bool:
	var top := Tune.SHIP_Y - 16.0
	if ball.pos.y + Tune.BALL_R >= top and ball.pos.y < Tune.SHIP_Y + 4.0 and absf(ball.pos.x - ship_x) <= tray_half():
		var pay := Tune.CATCH_PAY * (Tune.GOLD_MULT if ball.gold else 1)
		tray += pay
		stats.caught += 1
		_emit(&"catch", {pos = ball.pos, pay = pay, gold = ball.gold})
		return true
	return false


# --- reels -------------------------------------------------------------------

## When each reel stops, as a fraction of the base spin time; the third waits for
## the spin's full length, which is longer on a reach.
const REEL_STOPS := [0.5, 0.78]


func _run_reels(dt: float) -> void:
	if spin.is_empty():
		if holds > 0:
			holds -= 1
			spin = Reels.roll(_reel_rng)
			spin.t = 0.0
			spin.len = Tune.SPIN_TIME + (Tune.REACH_EXTRA if spin.reach else 0.0)
			spin.stopped = 0
			stats.spins += 1
			_emit(&"spin")
		return
	spin.t += dt
	while spin.stopped < 2 and spin.t >= REEL_STOPS[spin.stopped] * Tune.SPIN_TIME:
		spin.stopped += 1
		_emit(&"reel_stop", {reel = spin.stopped - 1})
		if spin.stopped == 2 and spin.reach:
			_emit(&"reach")
	if spin.t >= spin.len:
		last_symbols = spin.symbols
		_emit(&"reel_stop", {reel = 2})
		var won: bool = spin.triple
		var sym: int = spin.symbols[0]
		spin = {}
		if won:
			_award(sym)


func _award(sym: int) -> void:
	var prize: String = Reels.PRIZE[sym]
	stats.prizes += 1
	match prize:
		"fever":
			stats.fevers += 1
			fever_t = Tune.FEVER_TIME
			board.attacker().open = true
			for i in Tune.FEVER_SHOWER:
				_drop(Vector2(_rng.randf_range(Tune.LEFT + 30, Tune.RIGHT - 30), _rng.randf_range(330, 410)), false)
		"pierce":
			pierce_t = Tune.POWER_TIME
		"spread":
			spread_t = Tune.POWER_TIME
		"shield":
			shield = true
		"magnet":
			magnet_t = Tune.POWER_TIME
		"chips":
			tray += Reels.CHIPS_PAY
	_emit(&"prize", {prize = prize, symbol = sym})


# --- phases ------------------------------------------------------------------

func _check_phase() -> void:
	match phase:
		Phase.PLAYING:
			if alive_count() == 0:
				phase = Phase.CLEARED
				clear_bonus = Tune.CLEAR_BONUS + Tune.CLEAR_BONUS_PER_WAVE * (wave - 1)
				tray += clear_bonus
				shots.clear()
				saucer_on = false
				_emit(&"clear", {bonus = clear_bonus})
			elif tray < Tune.SHOT_COST and fever_t <= 0.0 and balls.is_empty() and bolts.is_empty() \
					and holds == 0 and spin.is_empty():
				phase = Phase.BUST
				bust_reason = "empty"
		Phase.CLEARED:
			if balls.is_empty() and bolts.is_empty():
				phase = Phase.SETTLED
				stats.waves.append(tray - wave_start_tray)
				_emit(&"settled")
	if phase == Phase.BUST and stats.waves.size() < wave:
		stats.waves.append(tray - wave_start_tray)
		_emit(&"bust", {reason = bust_reason})
