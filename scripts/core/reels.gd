class_name Reels
extends RefCounted
## The three-reel display in the middle of the board. A ball in the start chucker
## banks a spin (up to four held); each spin's outcome is drawn when it starts.

enum Sym { SEVEN, BAR, CHERRY, BELL, STAR, CHIP }

const COUNT := 6
const NAMES := ["Seven", "Bar", "Cherry", "Bell", "Star", "Chip"]
## What a triple of each symbol does. CHIP pays balls straight into the tray.
const PRIZE := {
	Sym.SEVEN: "fever",
	Sym.BAR: "pierce",
	Sym.CHERRY: "spread",
	Sym.BELL: "shield",
	Sym.STAR: "magnet",
	Sym.CHIP: "chips",
}
const CHIPS_PAY := 20

## Out of 1000 spins.
const FEVER_ODDS := 70
const PRIZE_ODDS := 170
const REACH_ODDS := 220


## Returns {symbols: PackedInt32Array(3), triple: bool, reach: bool}. A reach is
## when the first two reels match, which holds the third reel longer for suspense.
static func roll(rng: RandomNumberGenerator) -> Dictionary:
	var r := rng.randi_range(0, 999)
	var a: int
	var c: int
	if r < FEVER_ODDS:
		return {symbols = PackedInt32Array([Sym.SEVEN, Sym.SEVEN, Sym.SEVEN]), triple = true, reach = true}
	if r < FEVER_ODDS + PRIZE_ODDS:
		a = rng.randi_range(1, COUNT - 1)
		return {symbols = PackedInt32Array([a, a, a]), triple = true, reach = true}
	if r < FEVER_ODDS + PRIZE_ODDS + REACH_ODDS:
		a = rng.randi_range(0, COUNT - 1)
		c = (a + rng.randi_range(1, COUNT - 1)) % COUNT
		return {symbols = PackedInt32Array([a, a, c]), triple = false, reach = true}
	a = rng.randi_range(0, COUNT - 1)
	var b := (a + rng.randi_range(1, COUNT - 1)) % COUNT
	c = rng.randi_range(0, COUNT - 1)
	return {symbols = PackedInt32Array([a, b, c]), triple = false, reach = false}
