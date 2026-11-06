class_name Stage
extends Node2D
## Draws a Sim: the pachinko face, everything moving on it, the additive neon glow
## and the in-board HUD. Turns the sim's events into sound, sparks and pay
## pop-ups. Holds the pointer state for touch and mouse play.

const BOARD := Vector2(Tune.W, Tune.H)
const PAUSE_RECT := Rect2(Tune.RIGHT - 46, 30, 46, 46)

signal pause_pressed

var sim: Sim
## The attract demo runs silently with no HUD.
var demo := false
## Board x of the held pointer, or NAN.
var pointer_x := NAN
var pointer_down := false

var _face := Node2D.new()
var _field := Node2D.new()
var _glow := Node2D.new()
var _hud := Node2D.new()
var _fx: Array[Dictionary] = []
var _pops: Array[Dictionary] = []
var _shake := 0.0
var _t := 0.0
var _flash := 0.0
var _flash_color := Color.WHITE
var _rng := RandomNumberGenerator.new()
var _base := Vector2.ZERO
## Seconds since each pocket last paid, for its lamp.
var _pocket_lit := {}


func _ready() -> void:
	Look.init()
	_rng.randomize()
	for n in [_face, _field, _glow, _hud]:
		add_child(n)
	_glow.material = Look.additive()
	_face.draw.connect(_draw_face)
	_field.draw.connect(_draw_field)
	_glow.draw.connect(_draw_glow)
	_hud.draw.connect(_draw_hud)
	get_viewport().size_changed.connect(_layout)
	_layout()


func show_sim(s: Sim, is_demo: bool) -> void:
	sim = s
	demo = is_demo
	_fx.clear()
	_pops.clear()
	_pocket_lit.clear()
	_face.queue_redraw()


func _layout() -> void:
	var size := get_viewport().get_visible_rect().size
	_base = ((size - BOARD) / 2.0).floor()
	position = _base


## Height of empty screen above and below the board, in board pixels.
func spare() -> Vector2:
	return get_viewport().get_visible_rect().size - BOARD


func _process(delta: float) -> void:
	_t += delta
	_shake = maxf(_shake - delta * 2.2, 0.0)
	_flash = maxf(_flash - delta * 2.5, 0.0)
	position = _base + (Vector2(_rng.randf_range(-1, 1), _rng.randf_range(-1, 1)) * 9.0 * _shake * _shake if _shake > 0.0 else Vector2.ZERO)
	var keep: Array[Dictionary] = []
	for f in _fx:
		f.t += delta
		if f.t < f.life:
			f.vel.y += f.get("grav", 0.0) * delta
			f.pos += f.vel * delta
			keep.append(f)
	_fx = keep
	var kp: Array[Dictionary] = []
	for p in _pops:
		p.t += delta
		if p.t < 1.0:
			kp.append(p)
	_pops = kp
	for k in _pocket_lit.keys():
		_pocket_lit[k] += delta
	_field.queue_redraw()
	_glow.queue_redraw()
	_hud.queue_redraw()


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed and not demo and sim and PAUSE_RECT.grow(8).has_point(to_local(event.position)):
			pause_pressed.emit()
			get_viewport().set_input_as_handled()
			return
		pointer_down = event.pressed
		pointer_x = to_local(event.position).x if event.pressed else NAN
	elif event is InputEventMouseMotion and pointer_down:
		pointer_x = to_local(event.position).x


func release_pointer() -> void:
	pointer_down = false
	pointer_x = NAN


# --- events ------------------------------------------------------------------

func consume(events: Array[Dictionary]) -> void:
	var loud := not demo
	for e in events:
		match e.kind:
			&"pin":
				if loud:
					Sfx.play(&"pin", _rng.randf_range(0.85, 1.35), lerpf(-22.0, -11.0, clampf((e.speed - 140.0) / 400.0, 0.0, 1.0)))
			&"fire":
				if loud:
					Sfx.play(&"fire", 1.25 if e.free else 1.0, -8.0)
				_burst(e.pos, Look.CYAN, 4, 120.0, 0.18)
			&"dry":
				if loud:
					Sfx.play(&"dry")
				_pop(Vector2(sim.ship_x, Tune.SHIP_Y - 40), "EMPTY", Look.RED)
			&"enemy_fire":
				if loud:
					Sfx.play(&"zap", _rng.randf_range(0.9, 1.1), -14.0)
			&"clash":
				if loud:
					Sfx.play(&"clash", 1.0, -8.0)
				_burst(e.pos, Look.GOLD, 8, 160.0, 0.3)
			&"dent":
				if loud:
					Sfx.play(&"dent", _rng.randf_range(0.95, 1.1), -6.0)
				_burst(e.pos, Color(0.95, 0.92, 0.84), 6, 140.0, 0.3)
			&"kill":
				if loud:
					Sfx.play(&"kill", [1.0, 0.8, 1.2][e.type] * _rng.randf_range(0.95, 1.05), -3.0)
				var c: Color = Look.GOLD if e.gold else [Sprites.CHIP_COLORS[0], Color(0.95, 0.92, 0.84), Look.RED][e.type]
				_burst(e.pos, c, 16, 260.0, 0.55, 500.0)
				_ring(e.pos, c, 34.0, 0.3)
			&"hit":
				if loud:
					Sfx.play(&"hit")
				_shake = 1.0
				_flash = 0.6
				_flash_color = Look.RED
				_pop(e.pos + Vector2(0, -50), "-%d" % e.lost, Look.RED, 34)
				for i in mini(e.lost, 12):
					_fx.append({kind = &"ball", pos = e.pos + Vector2(0, -20), vel = Vector2(_rng.randf_range(-220, 220), _rng.randf_range(-420, -160)), t = 0.0, life = 1.4, grav = 1100.0})
			&"shielded":
				if loud:
					Sfx.play(&"shield")
				_ring(Vector2(sim.ship_x, Tune.SHIP_Y), Look.GOLD, 70.0, 0.4)
			&"saucer":
				if loud:
					Sfx.play(&"saucer", 1.0, -8.0)
			&"saucer_kill":
				if loud:
					Sfx.play(&"jackpot")
				_burst(e.pos, Look.VIOLET, 24, 300.0, 0.7, 400.0)
				_ring(e.pos, Look.GOLD, 60.0, 0.45)
				_pop(e.pos + Vector2(0, 30), "+SPIN", Look.GOLD, 26)
			&"pocket":
				_pocket_lit[e.pos] = 0.0
				var col := _pocket_color(e.pocket)
				if loud:
					Sfx.play(&"start" if e.pocket == Board.Pocket.START else &"pocket", 1.15 if e.gold else 1.0, -2.0)
				_pop(e.pos + Vector2(0, -26), "+%d" % e.pay, Look.GOLD if e.gold else col, 26 if e.pay < 10 else 32)
				_burst(e.pos, col, 10, 180.0, 0.4)
			&"catch":
				if loud:
					Sfx.play(&"catch", 1.2 if e.gold else _rng.randf_range(0.95, 1.08), -6.0)
				_pop(e.pos + Vector2(0, -24), "+%d" % e.pay, Look.GOLD if e.gold else Look.INK, 20)
			&"tulip":
				if loud:
					Sfx.play(&"tulip", 1.2 if e.open else 0.9, -8.0)
			&"drop":
				if loud:
					Sfx.play(&"drop", 1.0, -9.0)
			&"spin":
				if loud:
					Sfx.play(&"spin", 1.0, -8.0)
			&"reel_stop":
				if loud:
					Sfx.play(&"reel", 1.0 + e.reel * 0.08, -6.0)
			&"reach":
				if loud:
					Sfx.play(&"reach")
				_pop(Tune.REEL_CENTER + Vector2(0, -64), "REACH!", Look.PINK, 28)
			&"prize":
				_prize(e.prize, loud)
			&"fever_end":
				_pop(Tune.REEL_CENTER + Vector2(0, -64), "fever over", Look.MUTED, 22)
			&"clear":
				if loud:
					Sfx.play(&"clear")
			&"bust":
				if loud:
					Sfx.play(&"bust")
				_shake = 0.8


func _prize(prize: String, loud: bool) -> void:
	var label: String = {
		fever = "FEVER!", pierce = "PIERCING BOLTS", spread = "SPREAD SHOT",
		shield = "SHIELD", magnet = "WIDE TRAY", chips = "+%d" % Reels.CHIPS_PAY,
	}[prize]
	if loud:
		Sfx.play(&"fever" if prize == "fever" else &"prize")
	_pop(Tune.REEL_CENTER + Vector2(0, -70), label, Look.GOLD if prize != "fever" else Look.PINK, 40 if prize == "fever" else 30)
	_flash = 1.0 if prize == "fever" else 0.4
	_flash_color = Look.PINK if prize == "fever" else Look.GOLD
	_ring(Tune.REEL_CENTER, Look.GOLD, 160.0, 0.6)


func _pocket_color(kind: int) -> Color:
	match kind:
		Board.Pocket.START:
			return Look.GREEN
		Board.Pocket.SIDE:
			return Look.CYAN
		Board.Pocket.TULIP:
			return Look.PINK
	return Look.GOLD


func _burst(p: Vector2, c: Color, n: int, speed: float, life: float, grav := 0.0) -> void:
	for i in n:
		var a := _rng.randf() * TAU
		_fx.append({kind = &"spark", pos = p, vel = Vector2(cos(a), sin(a)) * speed * _rng.randf_range(0.3, 1.0), t = 0.0, life = life * _rng.randf_range(0.6, 1.0), color = c, grav = grav})


func _ring(p: Vector2, c: Color, r: float, life: float) -> void:
	_fx.append({kind = &"ring", pos = p, vel = Vector2.ZERO, t = 0.0, life = life, color = c, r = r})


func _pop(p: Vector2, s: String, c: Color, size := 24) -> void:
	_pops.append({pos = p, text = s, color = c, size = size, t = 0.0})


# --- the static face ---------------------------------------------------------

func _draw_face() -> void:
	var ci := _face
	var outer := Rect2(6, 96, Tune.W - 12, Tune.H - 104)
	Look.rounded(ci, outer.grow(4), 30, Color(0.02, 0.015, 0.05))
	# The face: a vertical gradient under glass.
	var r := Rect2(Tune.LEFT - 6, 100, Tune.RIGHT - Tune.LEFT + 12, Tune.H - 112)
	ci.draw_polygon(PackedVector2Array([r.position, Vector2(r.end.x, r.position.y), r.end, Vector2(r.position.x, r.end.y)]),
		PackedColorArray([Look.FACE_TOP, Look.FACE_TOP, Look.FACE_BOTTOM, Look.FACE_BOTTOM]))
	# A faint lattice so the glass reads as a surface.
	var y := 120.0
	while y < Tune.H - 20:
		ci.draw_line(Vector2(Tune.LEFT, y), Vector2(Tune.RIGHT, y), Color(1, 1, 1, 0.018), 1.0)
		y += 24.0
	Look.rounded(ci, outer, 26, Look.PINK, false, 3)
	Look.rounded(ci, outer.grow(-7), 22, Color(Look.CYAN, 0.55), false, 2)
	if sim == null:
		return
	var b := sim.board
	# Danger line: the House must not reach it.
	var x := Tune.LEFT + 4.0
	while x < Tune.RIGHT - 8.0:
		ci.draw_line(Vector2(x, Tune.INVADED_Y), Vector2(x + 10.0, Tune.INVADED_Y), Color(Look.RED, 0.35), 2.0)
		x += 20.0
	# The ship's rail.
	ci.draw_line(Vector2(Tune.LEFT, Tune.SHIP_Y + 20), Vector2(Tune.RIGHT, Tune.SHIP_Y + 20), Color(Look.CYAN, 0.25), 2.0)
	for w in b.walls.slice(4):
		ci.draw_line(w[0], w[1], Look.BRASS.darkened(0.3), w[2] * 2.0, true)
		ci.draw_line(w[0], w[1], Look.BRASS, w[2] * 0.8, true)
	# The reel window.
	var rr := Rect2(Tune.REEL_CENTER - Tune.REEL_SIZE / 2.0, Tune.REEL_SIZE)
	Look.rounded(ci, rr.grow(7), 12, Color(0.55, 0.58, 0.68))
	Look.rounded(ci, rr.grow(4), 10, Color(0.2, 0.2, 0.28))
	Look.rounded(ci, rr, 8, Color(0.015, 0.01, 0.03))
	for i in [1, 2]:
		var lx: float = rr.position.x + rr.size.x * i / 3.0
		ci.draw_line(Vector2(lx, rr.position.y + 4), Vector2(lx, rr.end.y - 4), Color(1, 1, 1, 0.08), 2.0)
	# Payline arrows: only the middle row counts.
	for side in [-1.0, 1.0]:
		var tip := Vector2(Tune.REEL_CENTER.x + side * (rr.size.x / 2.0 + 2.0), Tune.REEL_CENTER.y)
		ci.draw_colored_polygon(PackedVector2Array([tip, tip + Vector2(side * 10.0, -7), tip + Vector2(side * 10.0, 7)]), Look.PINK)
	for p in b.pins:
		Sprites.pin(ci, p)
	# Pay labels under the pockets.
	for pk in b.pockets:
		var label: String = "+%d" % pk.pay
		var c := _pocket_color(pk.kind)
		var off := Vector2(0, 30) if pk.kind != Board.Pocket.ATTACKER else Vector2(0, 34)
		Look.text(ci, pk.pos + off, label, 13, Color(c, 0.75), Look.display)
	Look.text(ci, b.pockets[0].pos + Vector2(0, 46), "SPIN", 10, Color(Look.GREEN, 0.6), Look.display)


# --- the moving field --------------------------------------------------------

func _draw_field() -> void:
	if sim == null:
		return
	var ci := _field
	var s := sim
	var b := s.board
	for sp in b.spinners:
		_spinner(ci, sp)
	for pk in b.pockets:
		_pocket(ci, pk)
	_reels(ci)
	for ball in s.balls:
		Sprites.ball(ci, ball.pos, ball.gold)
	var frame := int(s.origin.x / 14.0) % 2
	for inv in s.invaders:
		if inv.alive:
			Sprites.invader(ci, s.invader_pos(inv), inv.kind, inv.gold, frame, inv.hit_t, inv.hp, inv.row)
	if s.saucer_on:
		Sprites.saucer(ci, Vector2(s.saucer_x, Tune.SAUCER_Y), _t)
	for bolt in s.bolts:
		var tail := bolt.pos - bolt.vel.normalized() * 22.0
		var c := Look.PINK if bolt.pierce else Look.CYAN
		ci.draw_line(tail, bolt.pos, c, 4.0, true)
		ci.draw_line(tail, bolt.pos, Color(1, 1, 1, 0.9), 1.6, true)
	for shot in s.shots:
		var zig := 4.0 if int(_t * 16.0 + shot.x) % 2 == 0 else -4.0
		ci.draw_polyline(PackedVector2Array([shot + Vector2(0, -16), shot + Vector2(zig, -10), shot + Vector2(-zig, -4), shot + Vector2(0, 2)]), Look.RED.lightened(0.2), 3.0, true)
	var blink := s.invuln > 0.0 and int(s.invuln * 14.0) % 2 == 0
	if s.phase != Sim.Phase.BUST or s.bust_reason != "invaded":
		Sprites.ship(ci, s.ship_x, Tune.SHIP_Y, clampf(s.ship_vx / Tune.SHIP_SPEED, -1, 1), s.tray_half(), s.shield, blink, s.fever_t > 0.0)
	for f in _fx:
		var k: float = 1.0 - f.t / f.life
		match f.kind:
			&"spark":
				ci.draw_line(f.pos, f.pos - f.vel * 0.03, Color(f.color, k), 2.5, true)
			&"ring":
				ci.draw_arc(f.pos, f.r * (0.3 + 0.7 * (1.0 - k)), 0, TAU, 32, Color(f.color, k), 3.0, true)
			&"ball":
				Sprites.ball(ci, f.pos, false)
	for p in _pops:
		var a := clampf(1.6 - p.t * 1.6, 0.0, 1.0)
		var at: Vector2 = p.pos + Vector2(0, -40.0 * p.t)
		ci.draw_string_outline(Look.display, at - Vector2(200, 0), p.text, HORIZONTAL_ALIGNMENT_CENTER, 400, p.size, 6, Color(0, 0, 0, 0.7 * a))
		ci.draw_string(Look.display, at - Vector2(200, 0), p.text, HORIZONTAL_ALIGNMENT_CENTER, 400, p.size, Color(p.color, a))


func _spinner(ci: CanvasItem, sp: Dictionary) -> void:
	var c: Vector2 = sp.pos
	for i in 4:
		var a: float = sp.angle + i * PI / 2.0
		var d := Vector2(cos(a), sin(a))
		ci.draw_colored_polygon(PackedVector2Array([c + d.rotated(-0.35) * 5.0, c + d.rotated(-0.22) * sp.r, c + d.rotated(0.22) * sp.r, c + d.rotated(0.35) * 5.0]), Color(Look.VIOLET, 0.9))
	ci.draw_circle(c, 5.0, Look.BRASS)


func _pocket(ci: CanvasItem, pk: Dictionary) -> void:
	var c := _pocket_color(pk.kind)
	var p: Vector2 = pk.pos
	var half := Board.mouth(pk)
	match pk.kind:
		Board.Pocket.TULIP:
			var w := Board.wings(pk)
			ci.draw_rect(Rect2(p + Vector2(-pk.half, 0), Vector2(pk.half * 2.0, 16)), Color(0.02, 0.01, 0.04))
			for i in 2:
				var tip: Vector2 = w[i]
				var root := p + Vector2((-1.0 if i == 0 else 1.0) * (pk.half - 2.0), 14)
				ci.draw_colored_polygon(PackedVector2Array([root, tip + Vector2(0, -4), tip + Vector2((-1.0 if i == 0 else 1.0) * 5.0, 6)]), c)
			ci.draw_rect(Rect2(p + Vector2(-pk.half - 2, 14), Vector2(pk.half * 2.0 + 4, 6)), c.darkened(0.3))
		Board.Pocket.ATTACKER:
			var r := Rect2(p + Vector2(-72, -4), Vector2(144, 22))
			ci.draw_rect(r, Color(0.02, 0.01, 0.04))
			if pk.open:
				ci.draw_rect(Rect2(r.position, Vector2(r.size.x, 4)), Color(Look.GOLD, 0.5 + 0.5 * sin(_t * 18.0)))
				ci.draw_line(p + Vector2(-72, -4), p + Vector2(-80, -22), Look.GOLD, 4.0, true)
				ci.draw_line(p + Vector2(72, -4), p + Vector2(80, -22), Look.GOLD, 4.0, true)
			else:
				ci.draw_line(p + Vector2(-70, 0), p + Vector2(70, 0), Look.GOLD.darkened(0.3), 8.0)
				ci.draw_line(p + Vector2(-70, 0), p + Vector2(70, 0), Look.GOLD, 2.0)
			for i in 7:
				var on: bool = pk.open and int(_t * 10.0 + i) % 2 == 0
				ci.draw_circle(p + Vector2(-54 + i * 18, 12), 3.0, Look.GOLD if on else Look.GOLD.darkened(0.6))
		_:
			ci.draw_rect(Rect2(p + Vector2(-half, 0), Vector2(half * 2.0, 14)), Color(0.02, 0.01, 0.04))
			ci.draw_rect(Rect2(p + Vector2(-half - 4, 12), Vector2(half * 2.0 + 8, 5)), c)
			var lit: float = _pocket_lit.get(pk.pos, 9.0)
			ci.draw_circle(p + Vector2(0, 24), 3.5, c if lit < 0.6 else c.darkened(0.55))


func _reels(ci: CanvasItem) -> void:
	var s := sim
	var center := Tune.REEL_CENTER
	var w := Tune.REEL_SIZE.x / 3.0
	var radius := Tune.REEL_SIZE.y * 0.5
	for i in 3:
		var cx := center.x + (i - 1) * w
		var final_sym: int = s.last_symbols[i]
		var spinning := false
		var roll := 0.0
		if not s.spin.is_empty():
			final_sym = s.spin.symbols[i]
			var stop: float = (Sim.REEL_STOPS[i] * Tune.SPIN_TIME) if i < 2 else s.spin.len
			if s.spin.t < stop:
				spinning = true
				# Slows a little before the stop; the reach reel crawls.
				var speed := 11.0 if not (i == 2 and s.spin.reach and s.spin.t > Tune.SPIN_TIME * 0.78) else 3.5
				roll = s.spin.t * speed
		# Symbols sit on a drum: the one at angle 0 faces out.
		var base := final_sym
		var frac := 0.0
		if spinning:
			base = (final_sym + int(roll)) % Reels.COUNT
			frac = roll - floorf(roll)
		for k in [-1, 0, 1]:
			var sym := posmod(base - k, Reels.COUNT)
			var ang: float = (k + frac) * 0.95
			if absf(ang) > 1.35:
				continue
			var y := center.y + sin(ang) * radius * 0.92
			var squash := cos(ang)
			var alpha := clampf(squash * 1.3 - 0.2, 0.0, 1.0)
			Sprites.symbol(ci, Vector2(cx, y), sym, squash, alpha if spinning or k == 0 else alpha * 0.35)
	# Shading at the top and bottom of the drum.
	var rr := Rect2(center - Tune.REEL_SIZE / 2.0, Tune.REEL_SIZE)
	ci.draw_rect(Rect2(rr.position, Vector2(rr.size.x, 12)), Color(0, 0, 0, 0.5))
	ci.draw_rect(Rect2(Vector2(rr.position.x, rr.end.y - 12), Vector2(rr.size.x, 12)), Color(0, 0, 0, 0.5))
	# Hold lamps: banked spins.
	for i in Tune.MAX_HOLDS:
		var lp := Vector2(center.x - 27 + i * 18, rr.end.y + 18)
		ci.draw_circle(lp, 5.0, Look.GREEN if i < s.holds else Color(Look.GREEN, 0.15))


# --- glow --------------------------------------------------------------------

func _draw_glow() -> void:
	var ci := _glow
	var pulse := 0.5 + 0.5 * sin(_t * 2.0)
	var fever := sim != null and sim.fever_t > 0.0
	var edge := Look.PINK if not fever else Color.from_hsv(fmod(_t * 0.6, 1.0), 0.7, 1.0)
	var a := 0.16 + 0.06 * pulse
	Look.glow_rect(ci, Rect2(0, 80, 26, Tune.H - 80), Color(edge, a))
	Look.glow_rect(ci, Rect2(Tune.W - 26, 80, 26, Tune.H - 80), Color(edge, a))
	Look.glow_rect(ci, Rect2(20, 82, Tune.W - 40, 26), Color(edge, a))
	if _flash > 0.0:
		Look.glow_rect(ci, Rect2(-200, -200, Tune.W + 400, Tune.H + 400), Color(_flash_color, 0.22 * _flash))
	if sim == null:
		return
	var s := sim
	for bolt in s.bolts:
		Look.glow(ci, bolt.pos, 22.0, Color(Look.PINK if bolt.pierce else Look.CYAN, 0.55))
	for shot in s.shots:
		Look.glow(ci, shot, 18.0, Color(Look.RED, 0.5))
	for inv in s.invaders:
		if inv.alive and inv.gold:
			Look.glow(ci, s.invader_pos(inv), 34.0, Color(Look.GOLD, 0.28 + 0.12 * pulse))
	for ball in s.balls:
		if ball.gold:
			Look.glow(ci, ball.pos, 16.0, Color(Look.GOLD, 0.45))
	if s.saucer_on:
		Look.glow(ci, Vector2(s.saucer_x, Tune.SAUCER_Y), 46.0, Color(Look.VIOLET, 0.5))
	for pk in s.board.pockets:
		var c := _pocket_color(pk.kind)
		var lit: float = _pocket_lit.get(pk.pos, 9.0)
		var k := 0.18 + clampf(1.0 - lit / 0.5, 0.0, 1.0) * 0.6
		if pk.kind == Board.Pocket.ATTACKER:
			k = 0.55 + 0.25 * pulse if pk.open else 0.05
		elif pk.kind == Board.Pocket.TULIP and pk.open:
			k += 0.25
		Look.glow(ci, pk.pos + Vector2(0, 8), 30.0 + Board.mouth(pk), Color(c, k))
	if not s.spin.is_empty() and s.spin.reach and s.spin.t > Sim.REEL_STOPS[1] * Tune.SPIN_TIME:
		Look.glow_rect(ci, Rect2(Tune.REEL_CENTER - Tune.REEL_SIZE * 0.75, Tune.REEL_SIZE * 1.5), Color(Look.PINK, 0.25 + 0.2 * sin(_t * 20.0)))
	if s.phase != Sim.Phase.BUST or s.bust_reason != "invaded":
		var thr := Vector2(s.ship_x, Tune.SHIP_Y + 18)
		Look.glow(ci, thr, 26.0 + 4.0 * sin(_t * 30.0), Color(Look.PINK if fever else Look.CYAN, 0.45))
	for f in _fx:
		if f.kind == &"spark":
			Look.glow(ci, f.pos, 8.0, Color(f.color, 0.5 * (1.0 - f.t / f.life)))


# --- HUD ---------------------------------------------------------------------

func _draw_hud() -> void:
	if sim == null or demo:
		return
	var ci := _hud
	var s := sim
	# The tray: ball icon and count.
	Sprites.ball(ci, Vector2(Tune.LEFT + 16, 52), false)
	var low := s.tray < 10 and s.phase == Sim.Phase.PLAYING
	var tc := Look.RED if low and int(_t * 4.0) % 2 == 0 else Look.INK
	ci.draw_string(Look.display, Vector2(Tune.LEFT + 34, 66), str(s.tray), HORIZONTAL_ALIGNMENT_LEFT, -1, 40, tc)
	ci.draw_string(Look.sans_bold, Vector2(Tune.LEFT + 36, 86), "BALLS", HORIZONTAL_ALIGNMENT_LEFT, -1, 13, Look.MUTED)
	# Wave.
	Look.text(ci, Vector2(Tune.W / 2.0, 58), "WAVE %d" % s.wave, 28, Look.GOLD)
	var bonus := Tune.CLEAR_BONUS + Tune.CLEAR_BONUS_PER_WAVE * (s.wave - 1)
	Look.text(ci, Vector2(Tune.W / 2.0, 80), "clear bonus +%d" % bonus, 14, Look.MUTED, Look.sans)
	# Pause button.
	Look.rounded(ci, PAUSE_RECT, 10, Color(1, 1, 1, 0.06))
	Look.rounded(ci, PAUSE_RECT, 10, Color(Look.INK, 0.3), false, 1)
	ci.draw_rect(Rect2(PAUSE_RECT.position + Vector2(16, 14), Vector2(5, 18)), Look.INK)
	ci.draw_rect(Rect2(PAUSE_RECT.position + Vector2(26, 14), Vector2(5, 18)), Look.INK)
	# Active powers, right-aligned beside it.
	var x := Tune.RIGHT - 130.0
	var powers := []
	if s.fever_t > 0.0:
		powers.append(["FEVER", s.fever_t / Tune.FEVER_TIME, Look.PINK])
	if s.spread_t > 0.0:
		powers.append(["SPREAD", s.spread_t / Tune.POWER_TIME, Look.RED])
	if s.pierce_t > 0.0:
		powers.append(["PIERCE", s.pierce_t / Tune.POWER_TIME, Look.PINK])
	if s.magnet_t > 0.0:
		powers.append(["WIDE", s.magnet_t / Tune.POWER_TIME, Look.CYAN])
	if s.shield:
		powers.append(["SHIELD", 1.0, Look.GOLD])
	var y := 34.0
	for p in powers:
		ci.draw_string(Look.display, Vector2(x - 120, y + 12), p[0], HORIZONTAL_ALIGNMENT_RIGHT, 160, 13, p[2])
		ci.draw_rect(Rect2(x + 46, y + 2, 26, 8), Color(p[2], 0.2))
		ci.draw_rect(Rect2(x + 46, y + 2, 26 * p[1], 8), p[2])
		y += 18.0
