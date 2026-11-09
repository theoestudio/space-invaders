class_name Board
extends RefCounted
## The pachinko face: pins, spinners, pockets and the solid edges around the reel
## window. Built once per run from a seed (the daily run uses the day's seed, so
## everyone gets the same board). Pure data; Sim moves balls through it.

enum Pocket { START, SIDE, TULIP, ATTACKER }

## Two obstacles closer than this leave a gap a ball cannot fall through but can
## sit in, so pins keep at least this much clear space from walls, lips and wings.
const BALL_GAP := Tune.BALL_R * 2.0 + 3.0

## Grid cell size for pin lookups. Pins closer than this are found by checking the
## ball's cell and its eight neighbours.
const CELL := 32.0

var pins := PackedVector2Array()
## Each spinner: {pos: Vector2, r: float, spin: float (rad/s), angle: float}
var spinners: Array[Dictionary] = []
## Each pocket: {kind: Pocket, pos: Vector2 (mouth centre), half: float, pay: int, open: bool}
## TULIP pockets open wide after a catch and close on the next one; the ATTACKER
## only opens during fever.
var pockets: Array[Dictionary] = []
## Solid capsules [a, b, radius]: the reel window frame and guide rails.
var walls: Array[Array] = []
## The attacker's lid, solid while the attacker is shut.
var lid: Array = []

## Lip pins and tulip wings (open and shut), placed before the pin field so the
## field can keep clear of them.
var _fixed := PackedVector2Array()
var _cols := 0
var _grid: Array[PackedInt32Array] = []


static func build(rng: RandomNumberGenerator) -> Board:
	var b := Board.new()
	b._layout(rng)
	b._index_pins()
	return b


func _layout(rng: RandomNumberGenerator) -> void:
	var cx := Tune.W / 2.0
	var jx := rng.randf_range(-14, 14)
	var jy := rng.randf_range(-24, 24)

	# Pockets. The start chucker sits under the reel window, where the guide rails
	# funnel balls that roll off it.
	var reel_bottom := Tune.REEL_CENTER.y + Tune.REEL_SIZE.y / 2.0
	_pocket(Pocket.START, Vector2(cx, reel_bottom + 92), 12.0, Tune.POCKET_START_PAY)
	var side_y := 720.0 + rng.randf_range(-30, 30)
	# Far enough in that the outer upper lip leaves a ball's width to the edge.
	_pocket(Pocket.SIDE, Vector2(Tune.LEFT + 52, side_y), 14.0, Tune.POCKET_SIDE_PAY)
	_pocket(Pocket.SIDE, Vector2(Tune.RIGHT - 52, side_y), 14.0, Tune.POCKET_SIDE_PAY)
	var tulip_y := 905.0 + jy
	_pocket(Pocket.TULIP, Vector2(178 + jx, tulip_y), 14.0, Tune.POCKET_TULIP_PAY)
	_pocket(Pocket.TULIP, Vector2(Tune.W - 178 + jx, tulip_y), 14.0, Tune.POCKET_TULIP_PAY)
	_pocket(Pocket.ATTACKER, Vector2(cx, 1046), 64.0, Tune.POCKET_ATTACKER_PAY)
	lid = [Vector2(cx - 70, 1046), Vector2(cx + 70, 1046), 4.0]

	# The reel window: a framed box balls bounce off.
	var r := Rect2(Tune.REEL_CENTER - Tune.REEL_SIZE / 2.0, Tune.REEL_SIZE)
	var corners := [r.position, Vector2(r.end.x, r.position.y), r.end, Vector2(r.position.x, r.end.y)]
	for i in 4:
		walls.append([corners[i], corners[(i + 1) % 4], 5.0])
	# A roof over the window so balls split left and right instead of resting on it.
	walls.append([r.position + Vector2(-6, 0), Vector2(cx, r.position.y - 38), 4.0])
	walls.append([Vector2(cx, r.position.y - 38), Vector2(r.end.x + 6, r.position.y), 4.0])
	# Guide rails from under the window toward the start chucker. They stand in for
	# its upper lips, ending where a ball rolling off them drops toward the mouth.
	var start: Vector2 = pockets[0].pos
	walls.append([Vector2(r.position.x + 30, r.end.y + 34), start + Vector2(-30, -20), 3.0])
	walls.append([Vector2(r.end.x - 30, r.end.y + 34), start + Vector2(30, -20), 3.0])
	# Bottom funnel shoulders: the outer lanes ease toward the middle.
	walls.append([Vector2(Tune.LEFT, 1060), Vector2(Tune.LEFT + 54, 1100), 4.0])
	walls.append([Vector2(Tune.RIGHT, 1060), Vector2(Tune.RIGHT - 54, 1100), 4.0])

	# Spinners (windmills) above the shoulders of the window.
	for side in [-1, 1]:
		var p := Vector2(cx + side * (196 + rng.randf_range(-12, 12)), 492 + rng.randf_range(-16, 16))
		spinners.append({pos = p, r = 15.0, spin = side * rng.randf_range(5.0, 7.5), angle = rng.randf() * TAU})

	# Pocket lips: the two pins either side of each mouth that make it a cup.
	var lips := PackedVector2Array()
	for pk in pockets:
		if pk.kind == Pocket.ATTACKER:
			continue
		var half: float = pk.half + Tune.PIN_R + 1.0
		# A tulip's lips are its wings, which move: see wings().
		if pk.kind == Pocket.TULIP:
			_fixed.append_array(wings(pk))
			pk.open = true
			_fixed.append_array(wings(pk))
			pk.open = false
		else:
			lips.append(pk.pos + Vector2(-half, 0))
			lips.append(pk.pos + Vector2(half, 0))
		# A second pair higher up so balls are gathered toward the mouth. The
		# start chucker's guide rails do that job.
		if pk.kind != Pocket.START:
			lips.append(pk.pos + Vector2(-half - 10, -22))
			lips.append(pk.pos + Vector2(half + 10, -22))
	_fixed.append_array(lips)

	# The pin field: staggered rows, with some pins pulled (the seed decides which)
	# and clear space around everything above.
	var dy := 40.0
	var dx := 46.0
	var row := 0
	var y := Tune.PINS_TOP
	while y <= Tune.PINS_BOTTOM:
		var x := Tune.LEFT + 20.0 + (dx / 2.0 if row % 2 == 1 else 0.0)
		while x <= Tune.RIGHT - 20.0:
			var p := Vector2(x, y)
			if _clear(p, r) and rng.randf() > 0.14:
				pins.append(p)
			x += dx
		y += dy
		row += 1
	pins.append_array(lips)



func _pocket(kind: Pocket, pos: Vector2, half: float, pay: int) -> void:
	pockets.append({kind = kind, pos = pos, half = half, pay = pay, open = false})


func _clear(p: Vector2, reel: Rect2) -> bool:
	if reel.grow(18).has_point(p) or Rect2(reel.position.x - 10, reel.position.y - 40, reel.size.x + 20, 40).has_point(p):
		return false
	for pk in pockets:
		var d: Vector2 = p - pk.pos
		var reach: float = pk.half + 26.0
		if absf(d.x) < reach and d.y > -40 and d.y < 40:
			return false
	for w in walls:
		if _seg_dist(p, w[0], w[1]) < w[2] + Tune.PIN_R + BALL_GAP:
			return false
	for f in _fixed:
		if p.distance_to(f) < Tune.PIN_R * 2.0 + BALL_GAP:
			return false
	for s in spinners:
		if p.distance_to(s.pos) < 34.0:
			return false
	return true


static func _seg_dist(p: Vector2, a: Vector2, b: Vector2) -> float:
	return p.distance_to(closest_on_segment(p, a, b))


static func closest_on_segment(p: Vector2, a: Vector2, b: Vector2) -> Vector2:
	var ab := b - a
	var t := clampf((p - a).dot(ab) / maxf(ab.length_squared(), 0.0001), 0.0, 1.0)
	return a + ab * t


func _index_pins() -> void:
	_cols = int(ceil(Tune.W / CELL)) + 1
	var rows := int(ceil(Tune.H / CELL)) + 1
	_grid.resize(_cols * rows)
	for i in _grid.size():
		_grid[i] = PackedInt32Array()
	for i in pins.size():
		var c := _cell(pins[i])
		_grid[c].append(i)


func _cell(p: Vector2) -> int:
	var cx := clampi(int(p.x / CELL), 0, _cols - 1)
	var cy := clampi(int(p.y / CELL), 0, _grid.size() / _cols - 1)
	return cy * _cols + cx


## Indices of pins that could touch a ball at `p`.
func pins_near(p: Vector2) -> PackedInt32Array:
	var out := PackedInt32Array()
	if p.y < Tune.PINS_TOP - CELL or p.y > Tune.PINS_BOTTOM + CELL:
		return out
	var rows := _grid.size() / _cols
	var cx := int(p.x / CELL)
	var cy := int(p.y / CELL)
	for y in range(maxi(cy - 1, 0), mini(cy + 2, rows)):
		for x in range(maxi(cx - 1, 0), mini(cx + 2, _cols)):
			out.append_array(_grid[y * _cols + x])
	return out


func attacker() -> Dictionary:
	for pk in pockets:
		if pk.kind == Pocket.ATTACKER:
			return pk
	return {}


## Half-width of a pocket's mouth: a tulip's is wide when open.
static func mouth(pk: Dictionary) -> float:
	if pk.kind == Pocket.TULIP and pk.open:
		return pk.half + 12.0
	return pk.half


## The two wing tips of a tulip, which act as pins at the edges of its mouth.
static func wings(pk: Dictionary) -> PackedVector2Array:
	var half := mouth(pk) + Tune.PIN_R + 1.0
	var lift := -6.0 if pk.open else 0.0
	return PackedVector2Array([pk.pos + Vector2(-half, lift), pk.pos + Vector2(half, lift)])
