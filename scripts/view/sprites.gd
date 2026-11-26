class_name Sprites
extends RefCounted
## Draws every character and board prop from the 2.5D Cycles sprite suite, with
## continuous code-driven motion and clean primitive fallbacks when unloaded.

const CHIP_COLORS := [Color(0.92, 0.2, 0.32), Color(0.2, 0.55, 1.0), Color(0.15, 0.75, 0.45)]
const CHIP_ART := [&"chip_red", &"chip_blue", &"chip_green"]
const SHARD_ART := [&"shard_red", &"shard_blue", &"shard_green"]
const SYMBOL_ART := [&"sym_seven", &"sym_bar", &"sym_cherry", &"sym_bell", &"sym_star", &"sym_chip"]


static func invader(ci: CanvasItem, p: Vector2, kind: int, gold: bool, frame: int,
		hit_t: float, hp: int, row: int, phase := 0.0, look_dir := Vector2.ZERO, piece: Sim.Invader = null) -> void:
	var flash := clampf(1.0 - hit_t / 0.12, 0.0, 1.0)
	var ph := phase if phase != 0.0 else (0.0 if frame == 0 else PI)
	match kind:
		Sim.Kind.CHIP:
			_chip(ci, p, gold, frame, row, ph, look_dir, flash)
		Sim.Kind.DIE:
			_die(ci, p, gold, frame, hp, ph, flash)
		Sim.Kind.CARD:
			_card(ci, p, gold, frame, ph, flash)
		Sim.Kind.STACK:
			_stack(ci, p, gold, frame, row, hp, ph, look_dir, flash)
		Sim.Kind.DEALT:
			_card(ci, p, gold, frame, ph, flash)
			ci.draw_arc(p, 25.0, 0.0, TAU, 24, Color(Look.PINK, 0.7), 2.0, true)
		Sim.Kind.LOADED:
			_die(ci, p, gold, frame, 2, ph, flash)
			_pips_badge(ci, p, hp)
		Sim.Kind.DISC:
			_disc(ci, p, gold, piece.spin if piece else 0.0)
		Sim.Kind.BANDIT:
			_bandit(ci, p, gold, piece.reels if piece else PackedInt32Array([0, 1, 2]))
	if flash > 0.0:
		ci.draw_circle(p, 19.0, Color(1, 1, 1, 0.48 * flash))


static func _chip(ci: CanvasItem, p: Vector2, gold: bool, frame: int, row: int,
		phase: float, look_dir: Vector2, flash: float) -> void:
	var key: StringName = &"chip_gold" if gold else CHIP_ART[row % CHIP_ART.size()]
	if not Art.has(key):
		_chip_fallback(ci, p, gold, frame, row)
		return
	var hop := -absf(sin(phase)) * 1.8
	var tilt := sin(phase * 0.5) * 0.07
	var scl := Vector2(1.0 + flash * 0.16, 1.0 - flash * 0.14)
	# Three little sculpted shoes kicking out of phase.
	for i in 3:
		var fx := -9.0 + i * 9.0 + sin(phase + i * 2.1) * 3.2
		var fy := 13.5 - maxf(cos(phase + i * 2.1), 0.0) * 2.4
		Art.draw(ci, &"chip_foot", p + Vector2(fx, fy), Vector2(14, 14))
	var center := p + Vector2(0, hop)
	Art.draw(ci, key, center, Vector2(46, 46), tilt, scl)
	# Live-tracking glossy eyes.
	var look := look_dir.limit_length(1.0) * 1.5
	for s in [-1.0, 1.0]:
		var e := center + Vector2(s * 4.6, -1.6)
		Art.draw(ci, &"chip_eye_white", e, Vector2(10, 10))
		ci.draw_circle(e + look, 1.8, Color(0.05, 0.03, 0.1))
		ci.draw_circle(e + look + Vector2(-0.6, -0.6), 0.65, Color(1, 1, 1, 0.9))


static func _die(ci: CanvasItem, p: Vector2, gold: bool, frame: int, hp: int,
		phase: float, flash: float) -> void:
	var base := &"die_gold" if gold else &"die_ivory"
	var key := StringName(String(base) + ("_cracked" if hp <= 1 else ""))
	if not Art.has(key):
		_die_fallback(ci, p, gold, frame, hp)
		return
	var foot_key: StringName = &"die_foot_gold" if gold else &"die_foot_ivory"
	for s in [-1.0, 1.0]:
		var lift := maxf(sin(phase) * s, 0.0) * 3.0
		Art.draw(ci, foot_key, p + Vector2(s * 8.5, 14.5 - lift), Vector2(14, 14))
	var hop := -absf(cos(phase)) * 1.8
	var tilt := sin(phase) * 0.06
	var scl := Vector2(1.0 + flash * 0.16, 1.0 - flash * 0.14)
	Art.draw(ci, key, p + Vector2(0, hop), Vector2(46, 46), tilt, scl)


static func _card(ci: CanvasItem, p: Vector2, gold: bool, frame: int,
		phase: float, flash: float) -> void:
	var key: StringName = &"card_gold" if gold else &"card_red"
	if not Art.has(key):
		_card_fallback(ci, p, gold, frame)
		return
	var arm_key: StringName = &"card_arm_gold" if gold else &"card_arm_red"
	var hop := -absf(sin(phase)) * 2.0
	var tilt := sin(phase) * 0.08
	var scl := Vector2(1.0 + flash * 0.16, 1.0 - flash * 0.14)
	var center := p + Vector2(0, hop)
	var wave := sin(phase) * 0.48
	Art.draw(ci, arm_key, center + Vector2(-13, 0), Vector2(18, 18), -wave, Vector2(-1.0, 1.0))
	Art.draw(ci, arm_key, center + Vector2(13, 0), Vector2(18, 18), wave, Vector2.ONE)
	Art.draw(ci, key, center, Vector2(44, 55), tilt, scl)


static func shard(ci: CanvasItem, p: Vector2, type: int, row: int, gold: bool,
		rot: float, scale := 1.0, alpha := 1.0) -> void:
	type = Sim.BASE_KIND[type]
	var key: StringName
	if gold:
		key = &"shard_gold"
	elif type == Sim.Kind.DIE:
		key = &"shard_ivory"
	elif type == Sim.Kind.CARD:
		key = &"shard_red"
	else:
		key = SHARD_ART[row % SHARD_ART.size()]
	var mod := Color(1, 1, 1, alpha)
	if not Art.draw(ci, key, p, Vector2(18, 18) * scale, rot, Vector2.ONE, mod):
		ci.draw_circle(p, 4.0 * scale, Color(Look.GOLD if gold else Look.INK, alpha))


static func ship(ci: CanvasItem, x: float, y: float, tilt: float, tray_half: float,
		shield: bool, blink: bool, fever: bool, recoil := 0.0, cup_bounce := 0.0,
		barrels := 1, pierce_primed := false, deep_cup := 0, insured := false) -> void:
	if blink:
		return
	ship_back(ci, x, y, tilt, tray_half, fever, blink, recoil, cup_bounce, barrels, pierce_primed, deep_cup)
	ship_front(ci, x, y, tilt, tray_half, shield, blink, cup_bounce, deep_cup, insured)


static func ship_back(ci: CanvasItem, x: float, y: float, tilt: float, tray_half: float,
		fever: bool, blink: bool, recoil := 0.0, cup_bounce := 0.0,
		barrels := 1, pierce_primed := false, deep_cup := 0) -> void:
	if blink:
		return
	if not Art.has(&"ship_hull"):
		_ship_fallback(ci, x, y, tilt, tray_half, false, blink, fever)
		return
	var p := Vector2(x, y)
	var lean := tilt * 3.5
	var bank := tilt * 0.07
	var hull_tint := Color(1.16, 0.80, 1.04) if fever else Color.WHITE
	var offsets: Array = [0.0] if barrels <= 1 else ([-11.0, 11.0] if barrels == 2 else [-14.0, 0.0, 14.0])
	for ox: float in offsets:
		var bscl := Vector2(0.86, 0.90) if (barrels >= 3 and absf(ox) > 1.0) else Vector2.ONE
		var bp := p + Vector2(lean + ox, -15.0 + recoil * 5.5)
		Art.draw(ci, &"ship_barrel", bp, Vector2(20, 36), bank, bscl)
		if pierce_primed:
			var tip := p + Vector2(lean + ox, -31.0 + recoil * 5.5)
			ci.draw_colored_polygon(PackedVector2Array([
				tip + Vector2(0, -8), tip + Vector2(4.5, 0), tip + Vector2(0, 5), tip + Vector2(-4.5, 0)
			]), Color(Look.PINK, 0.95))
			ci.draw_colored_polygon(PackedVector2Array([
				tip + Vector2(0, -5), tip + Vector2(2.0, 0), tip + Vector2(0, 2.5), tip + Vector2(-2.0, 0)
			]), Color(1, 1, 1, 0.95))
	Art.draw(ci, &"ship_hull", p + Vector2(0, 4), Vector2(90, 52), bank, Vector2.ONE, hull_tint)
	var cup_w := maxf(tray_half * 2.55, 68.0)
	var cup_h := 32.0 + deep_cup * 3.5
	var cup_y := -10.0 + deep_cup * 1.2 + cup_bounce * 3.0
	Art.draw_3slice_h(ci, &"ship_cup_back", p + Vector2(0, cup_y), Vector2(cup_w, cup_h), 0.24)


static func ship_front(ci: CanvasItem, x: float, y: float, _tilt: float, tray_half: float,
		shield: bool, blink: bool, cup_bounce := 0.0, deep_cup := 0, insured := false) -> void:
	if blink:
		return
	var p := Vector2(x, y)
	var cup_w := maxf(tray_half * 2.55, 68.0)
	var cup_h := 32.0 + deep_cup * 3.5
	var cup_y := -10.0 + deep_cup * 1.2 + cup_bounce * 3.0
	if Art.has(&"ship_cup_front"):
		Art.draw_3slice_h(ci, &"ship_cup_front", p + Vector2(0, cup_y), Vector2(cup_w, cup_h), 0.24)
	if deep_cup > 0:
		var lip_w := maxf(cup_w * 0.42, 24.0)
		ci.draw_polyline(PackedVector2Array([
			p + Vector2(-lip_w, cup_y + 2.0),
			p + Vector2(-lip_w * 0.55, cup_y + cup_h * 0.34),
			p + Vector2(0.0, cup_y + cup_h * 0.40),
			p + Vector2(lip_w * 0.55, cup_y + cup_h * 0.34),
			p + Vector2(lip_w, cup_y + 2.0),
		]), Color(Look.GOLD, 0.85), 2.2, true)
	if insured:
		ci.draw_arc(p + Vector2(0, -1), 36.5, PI * 1.08, PI * 1.92, 24, Color(Look.CYAN, 0.78), 2.2, true)
		ci.draw_arc(p + Vector2(0, -1), 38.5, PI * 1.12, PI * 1.88, 24, Color(Look.GOLD, 0.45), 1.4, true)
	if shield:
		ci.draw_arc(p + Vector2(0, -2), 42.0, PI * 1.05, PI * 1.95, 28, Color(Look.GOLD, 0.85), 3.0, true)
		ci.draw_arc(p + Vector2(0, -2), 45.0, PI * 1.08, PI * 1.92, 28, Color(1, 0.95, 0.7, 0.35), 1.5, true)


static func saucer(ci: CanvasItem, p: Vector2, t: float) -> void:
	if not Art.draw(ci, &"saucer", p, Vector2(80, 44), sin(t * 5.0) * 0.05):
		_saucer_fallback(ci, p, t)
		return
	for i in 5:
		var on := int(t * 8.0 + i) % 2 == 0
		ci.draw_circle(p + Vector2(-20 + i * 10, 4), 2.1, Look.GOLD if on else Look.PINK)


static func ball_shadow(ci: CanvasItem, p: Vector2, scale := 1.0, alpha := 0.72) -> void:
	Art.draw(ci, &"ball_shadow", p + Vector2(2.4, 3.2) * scale, Vector2(24, 24) * scale,
		0.0, Vector2.ONE, Color(1, 1, 1, alpha))


static func ball(ci: CanvasItem, p: Vector2, gold: bool, scale := 1.0, alpha := 1.0) -> void:
	var key: StringName = &"ball_gold" if gold else &"ball_chrome"
	if not Art.draw(ci, key, p, Vector2(24, 24) * scale, 0.0, Vector2.ONE, Color(1, 1, 1, alpha)):
		var base := Look.GOLD if gold else Look.CHROME
		ci.draw_circle(p + Vector2(1.5, 2.0), Tune.BALL_R * scale, Color(0, 0, 0, 0.35 * alpha))
		ci.draw_circle(p, Tune.BALL_R * scale, Color(base.darkened(0.45), alpha))
		ci.draw_circle(p + Vector2(-0.8, -0.8), (Tune.BALL_R - 1.4) * scale, Color(base, alpha))
		ci.draw_circle(p + Vector2(-2.4, -2.6), 2.2 * scale, Color(1, 1, 1, 0.95 * alpha))


static func pin(ci: CanvasItem, p: Vector2) -> void:
	if not Art.draw(ci, &"pin_brass", p + Vector2(0.5, 0.8), Vector2(18, 18)):
		ci.draw_circle(p + Vector2(1.2, 1.8), Tune.PIN_R, Color(0, 0, 0, 0.45))
		ci.draw_circle(p, Tune.PIN_R, Look.BRASS.darkened(0.25))
		ci.draw_circle(p + Vector2(-0.8, -0.8), Tune.PIN_R - 1.4, Look.BRASS)
		ci.draw_circle(p + Vector2(-1.4, -1.6), 1.2, Color(1, 0.95, 0.8))


static func windmill(ci: CanvasItem, p: Vector2, angle: float, radius: float) -> void:
	var s := radius / 15.0
	if Art.has(&"windmill_blades"):
		Art.draw(ci, &"windmill_blades", p, Vector2(40, 40) * s, angle)
		Art.draw(ci, &"windmill_hub", p, Vector2(16, 16) * s)
		return
	for i in 4:
		var a := angle + i * PI / 2.0
		var d := Vector2(cos(a), sin(a))
		ci.draw_colored_polygon(PackedVector2Array([
			p + d.rotated(-0.35) * 5.0, p + d.rotated(-0.22) * radius,
			p + d.rotated(0.22) * radius, p + d.rotated(0.35) * 5.0]), Color(Look.VIOLET, 0.9))
	ci.draw_circle(p, 5.0, Look.BRASS)


static func rail_brass(ci: CanvasItem, a: Vector2, b: Vector2, r: float) -> void:
	if not Art.has(&"rail_brass_seg"):
		ci.draw_line(a, b, Look.BRASS.darkened(0.3), r * 2.0, true)
		ci.draw_line(a, b, Look.BRASS, r * 0.8, true)
		return
	var d := b - a
	var h := 32.0 * (r / 3.5)
	Art.draw(ci, &"rail_brass_cap", a, Vector2(h, h))
	Art.draw(ci, &"rail_brass_cap", b, Vector2(h, h))
	Art.draw(ci, &"rail_brass_seg", (a + b) * 0.5, Vector2(d.length(), h), d.angle())


static func pocket_back(ci: CanvasItem, pk: Dictionary, _open_t: float) -> void:
	var p: Vector2 = pk.pos
	match pk.kind:
		Board.Pocket.SIDE:
			if not Art.draw(ci, &"pocket_side_back", p + Vector2(0, 1), Vector2(64, 56)):
				_pocket_rect_fallback(ci, p, Board.mouth(pk), Look.CYAN)
		Board.Pocket.START:
			if not Art.draw(ci, &"pocket_start_back", p + Vector2(0, 1), Vector2(64, 56)):
				_pocket_rect_fallback(ci, p, Board.mouth(pk), Look.GREEN)
		Board.Pocket.TULIP:
			if not Art.draw(ci, &"pocket_tulip_back", p + Vector2(0, 1), Vector2(72, 56)):
				_pocket_rect_fallback(ci, p, pk.half, Look.PINK)
		Board.Pocket.ATTACKER:
			if pk.open:
				Art.draw(ci, &"attacker_open_back", p + Vector2(0, 4), Vector2(180, 52))
			else:
				if not Art.draw(ci, &"attacker_shut", p + Vector2(0, 6), Vector2(180, 44)):
					ci.draw_line(p + Vector2(-70, 0), p + Vector2(70, 0), Look.GOLD, 4.0)
				for i in 7:
					ci.draw_circle(p + Vector2(-54 + i * 18, 9), 2.8, Look.GOLD.darkened(0.65))


static func pocket_front(ci: CanvasItem, pk: Dictionary, open_t: float, t: float, lit := 9.0) -> void:
	var p: Vector2 = pk.pos
	match pk.kind:
		Board.Pocket.SIDE:
			Art.draw(ci, &"pocket_side_front", p + Vector2(0, 1), Vector2(64, 56))
			ci.draw_circle(p + Vector2(0, 23), 3.4, Look.CYAN if lit < 0.6 else Look.CYAN.darkened(0.55))
		Board.Pocket.START:
			Art.draw(ci, &"pocket_start_front", p + Vector2(0, 1), Vector2(64, 56))
			ci.draw_circle(p + Vector2(0, 23), 3.4, Look.GREEN if lit < 0.6 else Look.GREEN.darkened(0.55))
		Board.Pocket.TULIP:
			var ang := lerpf(0.08, -0.70, open_t)
			Art.draw(ci, &"tulip_petal_left", p + Vector2(-12, 6), Vector2(48, 48), ang)
			Art.draw(ci, &"tulip_petal_right", p + Vector2(12, 6), Vector2(48, 48), -ang)
			Art.draw(ci, &"pocket_tulip_front", p + Vector2(0, 1), Vector2(72, 56))
		Board.Pocket.ATTACKER:
			if pk.open:
				Art.draw(ci, &"attacker_open_front", p + Vector2(0, 4), Vector2(180, 52))
				for i in 7:
					var on := int(t * 10.0 + i) % 2 == 0
					ci.draw_circle(p + Vector2(-54 + i * 18, 12), 3.0, Look.GOLD if on else Look.GOLD.darkened(0.55))


## A reel symbol at `p`; `squash` (0..1) flattens it vertically along the curved drum.
static func symbol(ci: CanvasItem, p: Vector2, sym: int, squash: float, alpha := 1.0) -> void:
	var sq := maxf(squash, 0.01)
	if sym >= 0 and sym < SYMBOL_ART.size() and Art.has(SYMBOL_ART[sym]):
		var shade := lerpf(0.55, 1.0, clampf(squash, 0.0, 1.0))
		Art.draw(ci, SYMBOL_ART[sym], p, Vector2(52, 52), 0.0, Vector2(1.0, sq), Color(shade, shade, shade, alpha))
		return
	ci.draw_set_transform(p, 0.0, Vector2(1.0, sq))
	var a := alpha
	match sym:
		Reels.Sym.SEVEN:
			ci.draw_string_outline(Look.display, Vector2(-14, 15), "7", HORIZONTAL_ALIGNMENT_LEFT, -1, 40, 5, Color(1, 0.85, 0.3, a))
			ci.draw_string(Look.display, Vector2(-14, 15), "7", HORIZONTAL_ALIGNMENT_LEFT, -1, 40, Color(1, 0.18, 0.25, a))
		Reels.Sym.BAR:
			ci.draw_rect(Rect2(-24, -11, 48, 22), Color(0.1, 0.08, 0.14, a))
			ci.draw_rect(Rect2(-24, -11, 48, 22), Color(1, 0.85, 0.3, a), false, 2.0)
			ci.draw_string(Look.display, Vector2(-20, 7), "BAR", HORIZONTAL_ALIGNMENT_CENTER, 40, 14, Color(1, 1, 1, a))
		Reels.Sym.CHERRY:
			ci.draw_line(Vector2(-7, 4), Vector2(2, -14), Color(0.3, 0.8, 0.3, a), 2.5, true)
			ci.draw_line(Vector2(8, 6), Vector2(2, -14), Color(0.3, 0.8, 0.3, a), 2.5, true)
			ci.draw_circle(Vector2(-8, 8), 8.0, Color(0.9, 0.1, 0.2, a))
			ci.draw_circle(Vector2(9, 9), 8.0, Color(0.9, 0.1, 0.2, a))
		Reels.Sym.BELL:
			var bell := PackedVector2Array([Vector2(0, -16), Vector2(8, -12), Vector2(11, 0), Vector2(16, 10), Vector2(-16, 10), Vector2(-11, 0), Vector2(-8, -12)])
			ci.draw_colored_polygon(bell, Color(1, 0.78, 0.2, a))
			ci.draw_circle(Vector2(0, 13), 4.0, Color(1, 0.6, 0.15, a))
		Reels.Sym.STAR:
			var pts := PackedVector2Array()
			for i in 10:
				var r := 17.0 if i % 2 == 0 else 7.5
				var ang := -PI / 2.0 + i * PI / 5.0
				pts.append(Vector2(cos(ang), sin(ang)) * r)
			ci.draw_colored_polygon(pts, Color(Look.CYAN, a))
		Reels.Sym.CHIP:
			ci.draw_circle(Vector2.ZERO, 16.0, Color(0.15, 0.7, 0.4, a))
			ci.draw_circle(Vector2.ZERO, 9.0, Color(0.1, 0.5, 0.3, a))
			ci.draw_string(Look.display, Vector2(-10, 5), "20", HORIZONTAL_ALIGNMENT_CENTER, 20, 11, Color(1, 1, 1, a))
	ci.draw_set_transform(Vector2.ZERO)


# --- primitive fallbacks (headless or before asset import) ----------------------

static func _eyes_fallback(ci: CanvasItem, p: Vector2, gap: float, r: float, frame: int) -> void:
	var look := Vector2(0.0 if frame == 0 else 1.2, 1.4)
	for s in [-1.0, 1.0]:
		var e := p + Vector2(s * gap, 0)
		ci.draw_circle(e, r, Color(1, 1, 1))
		ci.draw_circle(e + look, r * 0.5, Color(0.05, 0.03, 0.1))


static func _chip_fallback(ci: CanvasItem, p: Vector2, gold: bool, frame: int, row: int) -> void:
	var base: Color = Look.GOLD if gold else CHIP_COLORS[row % CHIP_COLORS.size()]
	ci.draw_circle(p, 15.0, base)
	_eyes_fallback(ci, p + Vector2(0, -1), 4.2, 2.8, frame)


static func _die_fallback(ci: CanvasItem, p: Vector2, gold: bool, frame: int, hp: int) -> void:
	var face := Look.GOLD.lightened(0.2) if gold else Color(0.95, 0.92, 0.84)
	ci.draw_rect(Rect2(p - Vector2(15, 14), Vector2(30, 28)), face)
	_eyes_fallback(ci, p + Vector2(0, -4), 6.5, 3.2, frame)
	if hp <= 1:
		ci.draw_line(p + Vector2(10, -14), p + Vector2(6, 6), Color(0.12, 0.08, 0.2), 1.6)


static func _card_fallback(ci: CanvasItem, p: Vector2, gold: bool, frame: int) -> void:
	var edge := Look.GOLD if gold else Look.RED
	ci.draw_rect(Rect2(p - Vector2(12, 17), Vector2(24, 34)), Color(0.98, 0.96, 0.94))
	ci.draw_rect(Rect2(p - Vector2(9, 14), Vector2(18, 28)), edge, false, 1.4)
	ci.draw_circle(p + Vector2(0 if frame == 0 else 1, 1), 3.4, edge)


static func _ship_fallback(ci: CanvasItem, x: float, y: float, _tilt: float, tray_half: float,
		shield: bool, blink: bool, fever: bool) -> void:
	if blink:
		return
	var p := Vector2(x, y)
	var edge := Look.PINK if fever else Look.CYAN
	ci.draw_rect(Rect2(p - Vector2(30, 6), Vector2(60, 18)), Color(0.16, 0.18, 0.3))
	ci.draw_line(p + Vector2(-tray_half, -16), p + Vector2(tray_half, -16), Look.GOLD, 3.0)
	if shield:
		ci.draw_arc(p, 42.0, PI * 1.05, PI * 1.95, 24, Look.GOLD, 2.5)


static func _saucer_fallback(ci: CanvasItem, p: Vector2, _t: float) -> void:
	ci.draw_circle(p, 18.0, Color(0.36, 0.2, 0.62))


static func _pocket_rect_fallback(ci: CanvasItem, p: Vector2, half: float, c: Color) -> void:
	ci.draw_rect(Rect2(p + Vector2(-half, 0), Vector2(half * 2.0, 14)), Color(0.02, 0.01, 0.04))
	ci.draw_rect(Rect2(p + Vector2(-half - 4, 12), Vector2(half * 2.0 + 8, 5)), c)


# --- placeholders for the descent's new pieces --------------------------------
# Drawn from the launch pieces until the 2.5D pipeline renders their own art
# (docs/descent.md, "Sprites the art pipeline owes").

## A chip stack: one chip for each layer left, offset like a short tower.
static func _stack(ci: CanvasItem, p: Vector2, gold: bool, frame: int, row: int, hp: int,
		phase: float, look_dir: Vector2, flash: float) -> void:
	var base: Color = Look.GOLD if gold else CHIP_COLORS[row % CHIP_COLORS.size()]
	for i in range(hp - 1, 0, -1):
		var c := p + Vector2(0, 5.0 * i)
		ci.draw_circle(c, 18.0, base.darkened(0.35 + 0.1 * i))
		ci.draw_arc(c, 18.0, 0.0, PI, 16, Color(1, 1, 1, 0.35), 2.0, true)
	_chip(ci, p, gold, frame, row, phase, look_dir, flash)


## A loaded die's pips (its hits left) on a small badge.
static func _pips_badge(ci: CanvasItem, p: Vector2, hp: int) -> void:
	var c := p + Vector2(14, -14)
	ci.draw_circle(c, 9.0, Color(0.08, 0.04, 0.12, 0.92))
	ci.draw_arc(c, 9.0, 0.0, TAU, 18, Look.PINK, 1.6, true)
	Look.text(ci, c + Vector2(-9, 6), str(hp), 14, Look.INK, Look.sans_bold, HORIZONTAL_ALIGNMENT_CENTER, 18.0)


## A roulette disc: red and black sectors with its green gap facing `spin`.
static func _disc(ci: CanvasItem, p: Vector2, gold: bool, spin: float) -> void:
	var n := 12
	for i in n:
		var a0 := spin + TAU * i / n
		var pts := PackedVector2Array([p])
		for k in 4:
			pts.append(p + Vector2.from_angle(a0 + TAU / n * k / 3.0) * 19.0)
		var col: Color = Color(0.1, 0.75, 0.35) if i == 0 else (Color(0.8, 0.12, 0.18) if i % 2 == 1 else Color(0.08, 0.06, 0.1))
		ci.draw_colored_polygon(pts, col)
	ci.draw_arc(p, 19.0, 0.0, TAU, 32, Look.GOLD if gold else Color(0.9, 0.8, 0.5), 2.5, true)
	ci.draw_circle(p, 5.0, Look.GOLD if gold else Color(0.85, 0.75, 0.45))


## A one-armed bandit: a little cabinet with three reels.
static func _bandit(ci: CanvasItem, p: Vector2, gold: bool, reels: PackedInt32Array) -> void:
	Look.rounded(ci, Rect2(p - Vector2(18, 20), Vector2(36, 40)), 6, Color(0.32, 0.1, 0.42))
	Look.rounded(ci, Rect2(p - Vector2(18, 20), Vector2(36, 40)), 6, Look.GOLD if gold else Look.PINK, false, 2.0)
	var cols := [Look.RED, Look.GOLD, Look.CYAN, Look.GREEN]
	for i in 3:
		var c := p + Vector2(-10 + i * 10, -4)
		ci.draw_rect(Rect2(c - Vector2(4, 6), Vector2(8, 12)), Color(0.95, 0.93, 0.88))
		ci.draw_circle(c, 3.0, cols[reels[i] % cols.size()])
	ci.draw_line(p + Vector2(19, -6), p + Vector2(24, -14), Color(0.8, 0.8, 0.85), 2.0)
	ci.draw_circle(p + Vector2(24, -15), 3.0, Look.RED)
