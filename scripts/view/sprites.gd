class_name Sprites
extends RefCounted
## Every character and prop, drawn from primitives so nothing needs an image file.
## Each function draws centred on `p` into the given CanvasItem.

const CHIP_COLORS := [Color(0.92, 0.2, 0.32), Color(0.2, 0.55, 1.0), Color(0.15, 0.75, 0.45)]


static func invader(ci: CanvasItem, p: Vector2, kind: int, gold: bool, frame: int, hit_t: float, hp: int, row: int) -> void:
	var flash := clampf(1.0 - hit_t / 0.12, 0.0, 1.0)
	match kind:
		Sim.Kind.CHIP:
			_chip(ci, p, gold, frame, row)
		Sim.Kind.DIE:
			_die(ci, p, gold, frame, hp)
		Sim.Kind.CARD:
			_card(ci, p, gold, frame)
	if flash > 0.0:
		ci.draw_circle(p, 20.0, Color(1, 1, 1, 0.55 * flash))


static func _eyes(ci: CanvasItem, p: Vector2, gap: float, r: float, frame: int) -> void:
	var look := Vector2(0.0 if frame == 0 else 1.2, 1.4)
	for s in [-1.0, 1.0]:
		var e := p + Vector2(s * gap, 0)
		ci.draw_circle(e, r, Color(1, 1, 1))
		ci.draw_circle(e + look, r * 0.5, Color(0.05, 0.03, 0.1))


static func _chip(ci: CanvasItem, p: Vector2, gold: bool, frame: int, row: int) -> void:
	var base: Color = Look.GOLD if gold else CHIP_COLORS[row % CHIP_COLORS.size()]
	# Little legs that swap each march frame.
	var leg := Color(base.darkened(0.45))
	for i in 3:
		var x := -9.0 + i * 9.0
		var kick := (3.0 if (i + frame) % 2 == 0 else -3.0)
		ci.draw_line(p + Vector2(x, 10), p + Vector2(x + kick, 18), leg, 3.0, true)
	ci.draw_circle(p, 16.0, base.darkened(0.35))
	ci.draw_circle(p, 14.5, base)
	# Edge spots, the way a casino chip is striped.
	for i in 8:
		var a := i * TAU / 8.0 + (0.2 if frame == 1 else 0.0)
		var d := Vector2(cos(a), sin(a))
		ci.draw_line(p + d * 10.5, p + d * 14.0, Color(1, 1, 1, 0.9), 3.4, true)
	ci.draw_circle(p, 9.5, base.darkened(0.15))
	ci.draw_arc(p, 9.5, 0.0, TAU, 24, Color(1, 1, 1, 0.45), 1.2, true)
	_eyes(ci, p + Vector2(0, -1), 4.2, 2.8, frame)


static func _die(ci: CanvasItem, p: Vector2, gold: bool, frame: int, hp: int) -> void:
	var face := Look.GOLD.lightened(0.2) if gold else Color(0.95, 0.92, 0.84)
	var ink := Color(0.12, 0.08, 0.2)
	for s in [-1.0, 1.0]:
		var lift := 2.0 if (frame == 0) == (s < 0.0) else 0.0
		ci.draw_rect(Rect2(p + Vector2(s * 9.0 - 3.5, 13.0 - lift), Vector2(7, 6)), face.darkened(0.4))
	var r := Rect2(p - Vector2(15, 14), Vector2(30, 28))
	ci.draw_rect(r.grow(1.5), face.darkened(0.5))
	ci.draw_rect(r, face)
	ci.draw_rect(Rect2(r.position, Vector2(r.size.x, 5)), Color(1, 1, 1, 0.35))
	# Pips make the face: two eyes and a grin of three.
	_eyes(ci, p + Vector2(0, -4), 6.5, 3.2, frame)
	for i in 3:
		ci.draw_circle(p + Vector2(-6.0 + i * 6.0, 7.0 + (1.0 if i == 1 else 0.0)), 1.8, ink)
	if hp <= 1:
		ci.draw_polyline(PackedVector2Array([p + Vector2(10, -14), p + Vector2(6, -6), p + Vector2(11, -1), p + Vector2(7, 6)]), ink, 1.6, true)


static func _card(ci: CanvasItem, p: Vector2, gold: bool, frame: int) -> void:
	var edge := Look.GOLD if gold else Look.RED
	var arm := edge.darkened(0.3)
	var swing := 5.0 if frame == 0 else -5.0
	ci.draw_line(p + Vector2(-12, 2), p + Vector2(-20, -4 + swing), arm, 3.0, true)
	ci.draw_line(p + Vector2(12, 2), p + Vector2(20, -4 - swing), arm, 3.0, true)
	var r := Rect2(p - Vector2(12, 17), Vector2(24, 34))
	ci.draw_rect(r.grow(1.5), edge.darkened(0.4))
	ci.draw_rect(r, Color(0.98, 0.96, 0.94))
	ci.draw_rect(r.grow(-3), edge, false, 1.4)
	# A diamond for a single staring eye.
	var d := PackedVector2Array([p + Vector2(0, -9), p + Vector2(8, 0), p + Vector2(0, 9), p + Vector2(-8, 0)])
	ci.draw_colored_polygon(d, edge)
	ci.draw_circle(p + Vector2(0 if frame == 0 else 1, 1), 3.4, Color(1, 1, 1))
	ci.draw_circle(p + Vector2(0 if frame == 0 else 1, 2), 1.8, Color(0.05, 0.03, 0.1))
	ci.draw_string(Look.display, p + Vector2(-10, -7), "J", HORIZONTAL_ALIGNMENT_LEFT, -1, 8, edge)


static func ship(ci: CanvasItem, x: float, y: float, tilt: float, tray_half: float, shield: bool, blink: bool, fever: bool) -> void:
	if blink:
		return
	var p := Vector2(x, y)
	var hull := Color(0.16, 0.18, 0.3)
	var edge := Look.PINK if fever else Look.CYAN
	var lean := tilt * 4.0
	var body := PackedVector2Array([
		p + Vector2(-34, 12), p + Vector2(-26 + lean, -4), p + Vector2(26 + lean, -4), p + Vector2(34, 12),
		p + Vector2(18, 16), p + Vector2(-18, 16)])
	ci.draw_colored_polygon(body, hull)
	var outline := body.duplicate()
	outline.append(body[0])
	ci.draw_polyline(outline, edge, 2.0, true)
	# The barrel.
	ci.draw_rect(Rect2(p + Vector2(-4 + lean, -24), Vector2(8, 22)), hull.lightened(0.2))
	ci.draw_rect(Rect2(p + Vector2(-4 + lean, -24), Vector2(8, 4)), edge)
	# The catch tray on top: a shallow cup.
	var tw := tray_half
	var cup := PackedVector2Array([p + Vector2(-tw, -16), p + Vector2(-tw + 6, -6), p + Vector2(tw - 6, -6), p + Vector2(tw, -16)])
	ci.draw_polyline(cup, Look.GOLD, 3.0, true)
	ci.draw_circle(p + Vector2(-20, 6), 2.5, edge)
	ci.draw_circle(p + Vector2(20, 6), 2.5, edge)
	if shield:
		ci.draw_arc(p + Vector2(0, -2), 42.0, PI * 1.05, PI * 1.95, 28, Look.GOLD, 2.5, true)


static func saucer(ci: CanvasItem, p: Vector2, t: float) -> void:
	ci.draw_colored_polygon(_ellipse(p + Vector2(0, 2), Vector2(30, 9), 24), Color(0.36, 0.2, 0.62))
	ci.draw_colored_polygon(_ellipse(p + Vector2(0, -4), Vector2(14, 11), 20), Color(0.55, 0.85, 1.0, 0.85))
	# The croupier's green visor.
	ci.draw_colored_polygon(PackedVector2Array([p + Vector2(-15, -6), p + Vector2(15, -6), p + Vector2(10, -1), p + Vector2(-10, -1)]), Color(0.2, 0.85, 0.45))
	ci.draw_polyline(_ellipse(p + Vector2(0, 2), Vector2(30, 9), 24, true), Look.GOLD, 1.6, true)
	for i in 5:
		var on := int(t * 8.0 + i) % 2 == 0
		ci.draw_circle(p + Vector2(-20 + i * 10, 5), 2.2, Look.GOLD if on else Look.PINK)


static func _ellipse(c: Vector2, r: Vector2, n: int, closed := false) -> PackedVector2Array:
	var pts := PackedVector2Array()
	for i in n + (1 if closed else 0):
		var a := TAU * i / n
		pts.append(c + Vector2(cos(a) * r.x, sin(a) * r.y))
	return pts


static func ball(ci: CanvasItem, p: Vector2, gold: bool) -> void:
	var base := Look.GOLD if gold else Look.CHROME
	ci.draw_circle(p + Vector2(1.5, 2.0), Tune.BALL_R, Color(0, 0, 0, 0.35))
	ci.draw_circle(p, Tune.BALL_R, base.darkened(0.45))
	ci.draw_circle(p + Vector2(-0.8, -0.8), Tune.BALL_R - 1.4, base)
	ci.draw_circle(p + Vector2(-2.4, -2.6), 2.2, Color(1, 1, 1, 0.95))


static func pin(ci: CanvasItem, p: Vector2) -> void:
	ci.draw_circle(p + Vector2(1.2, 1.8), Tune.PIN_R, Color(0, 0, 0, 0.45))
	ci.draw_circle(p, Tune.PIN_R, Look.BRASS.darkened(0.25))
	ci.draw_circle(p + Vector2(-0.8, -0.8), Tune.PIN_R - 1.4, Look.BRASS)
	ci.draw_circle(p + Vector2(-1.4, -1.6), 1.2, Color(1, 0.95, 0.8))


## A reel symbol at `p`; `squash` (0..1) flattens it vertically as it rolls over
## the top or bottom of the drum.
static func symbol(ci: CanvasItem, p: Vector2, sym: int, squash: float, alpha := 1.0) -> void:
	ci.draw_set_transform(p, 0.0, Vector2(1.0, maxf(squash, 0.01)))
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
			ci.draw_circle(Vector2(-10, 5), 2.2, Color(1, 1, 1, 0.8 * a))
			ci.draw_circle(Vector2(7, 6), 2.2, Color(1, 1, 1, 0.8 * a))
		Reels.Sym.BELL:
			var bell := PackedVector2Array([Vector2(0, -16), Vector2(8, -12), Vector2(11, 0), Vector2(16, 10), Vector2(-16, 10), Vector2(-11, 0), Vector2(-8, -12)])
			ci.draw_colored_polygon(bell, Color(1, 0.78, 0.2, a))
			ci.draw_circle(Vector2(0, 13), 4.0, Color(1, 0.6, 0.15, a))
			ci.draw_line(Vector2(-6, -8), Vector2(-9, 4), Color(1, 1, 1, 0.6 * a), 2.0, true)
		Reels.Sym.STAR:
			var pts := PackedVector2Array()
			for i in 10:
				var r := 17.0 if i % 2 == 0 else 7.5
				var ang := -PI / 2.0 + i * PI / 5.0
				pts.append(Vector2(cos(ang), sin(ang)) * r)
			ci.draw_colored_polygon(pts, Color(Look.CYAN, a))
		Reels.Sym.CHIP:
			ci.draw_circle(Vector2.ZERO, 16.0, Color(0.15, 0.7, 0.4, a))
			for i in 6:
				var ang := i * TAU / 6.0
				var d := Vector2(cos(ang), sin(ang))
				ci.draw_line(d * 11.0, d * 15.5, Color(1, 1, 1, a), 4.0, true)
			ci.draw_circle(Vector2.ZERO, 9.0, Color(0.1, 0.5, 0.3, a))
			ci.draw_string(Look.display, Vector2(-10, 5), "20", HORIZONTAL_ALIGNMENT_CENTER, 20, 11, Color(1, 1, 1, a))
	ci.draw_set_transform(Vector2.ZERO)
