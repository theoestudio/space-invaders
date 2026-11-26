class_name Formations
extends RefCounted
## The shapes a wave's House comes in (docs/descent.md). Each floor picks its shape
## per wave from Floors.SHAPES. Masks are Tune.ROWS rows of up to Tune.COLS cells
## ('#' a piece, '.' a gap); the row picks the piece kind from the floor's plan. The
## ring is an oval of pieces that turns around its middle as it marches.

const GRID := &"grid"
const V := &"v"
const DIAMOND := &"diamond"
const CHEVRON := &"chevron"
const SPLIT := &"split"
const RING := &"ring"

const MASKS := {
	&"grid": ["#########", "#########", "#########", "#########", "#########"],
	&"v": ["#########", "#########", ".#######.", "..#####..", "...###..."],
	&"diamond": ["..#####..", ".#######.", "#########", ".#######.", "..#####.."],
	&"chevron": ["###...###", "####.####", "#########", ".#######.", "..#####.."],
	&"split": ["####.####", "####.####", "####.####", "####.####", "####.####"],
}
const ALL: Array[StringName] = [&"grid", &"v", &"diamond", &"chevron", &"split", &"ring"]

## The ring: an outer and an inner oval (radii in board pixels, piece counts) around
## one piece in the middle, as tall as the grid so it starts and invades like one.
const RING_OVALS := [[Vector2(190, 100), 20], [Vector2(105, 50), 10]]


## One piece of a shape: where it sits from the formation's origin (the top-left
## cell of the grid), its oval radii and starting angle when it turns (zero radii
## when it does not), and the plan row that picks its kind.
class Slot:
	var home: Vector2
	var radius := Vector2.ZERO
	var angle := 0.0
	var row := 0


static func slots(shape: StringName) -> Array[Slot]:
	var out: Array[Slot] = []
	if shape == RING:
		var center := Vector2((Tune.COLS - 1) * Tune.CELL.x / 2.0, (Tune.ROWS - 1) * Tune.CELL.y / 2.0)
		out.append(_slot(center, Vector2.ZERO, 0.0))
		for oval: Array in RING_OVALS:
			var n: int = oval[1]
			for i in n:
				out.append(_slot(center, oval[0], TAU * i / n))
		return out
	var mask: Array = MASKS[shape]
	for row in mask.size():
		var line: String = mask[row]
		for col in line.length():
			if line[col] == "#":
				var s := _slot(Vector2(col * Tune.CELL.x, row * Tune.CELL.y), Vector2.ZERO, 0.0)
				out.append(s)
	return out


static func _slot(home: Vector2, radius: Vector2, angle: float) -> Slot:
	var s := Slot.new()
	s.home = home
	s.radius = radius
	s.angle = angle
	var y := home.y + sin(angle) * radius.y
	s.row = clampi(roundi(y / Tune.CELL.y), 0, Tune.ROWS - 1)
	return s


static func turns(shape: StringName) -> bool:
	return shape == RING
