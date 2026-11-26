class_name Bosses
extends RefCounted
## The floor bosses (docs/descent.md). Each floor's guard wave is its boss with a
## small escort formation below it; breaking the boss clears the wave, breaks the
## escort and showers balls. The boss rides with the formation, and once the
## escort is gone the formation sinks on its own, so a boss left standing still
## invades. Sim runs them (Sim._tick_boss, Sim._bolt_hits_boss); this file holds
## their numbers and their state.

enum Id { DOORMAN, DEALER, PIT_BOSS, WHEEL, HOUSE }

const NAMES := ["The Doorman", "The Dealer", "The Pit Boss", "The Wheel", "The House"]
## One line for the intro card: how to beat it.
const HINTS := [
	"every hit sheds a layer",
	"break the shoe before it deals the floor full",
	"hit a die while it shows three or less",
	"only a bolt through the green zero counts",
	"hit the reels while the window is lit",
]
const HP := [14, 16, 12, 12, 15]
## Half the hit box around the boss's center (the Pit Boss: each of its two dice).
const HALF := [Vector2(32, 56), Vector2(58, 34), Vector2(34, 34), Vector2(60, 60), Vector2(92, 50)]
## Balls the boss showers when it breaks; every fourth is gold.
const SHOWER := [12, 16, 20, 24, 36]
## How far the boss's center sits below the formation's origin; the escort holds
## the grid's lowest two rows.
const RIDE_Y := 30.0

const DOORMAN_SPEED := 80.0
const DOORMAN_FIRE := 1.5
const DEALER_DEAL := 3.2
const DEALER_FIRE := 2.6
const PIT_ROLL := 2.4
const PIT_GAP := 52.0
const PIT_OPEN := 3
const WHEEL_SPIN := 1.6
const WHEEL_GAP := 0.5
const WHEEL_FIRE := 1.3
const WHEEL_SPEED := 40.0
const HOUSE_SPIN := 2.0
const HOUSE_LIT := 3.0
const HOUSE_SYMBOLS := 3


class Boss:
	var id: int
	var x: float
	var hp: int
	var max_hp: int
	var dir := 1.0
	## The boss's own clocks: its next attack, and its cycle (deal, roll, spin).
	var fire_t := 1.5
	var cycle_t := 2.0
	## The Pit Boss's two faces, the House's three reels.
	var faces := PackedInt32Array([1, 1, 1])
	## The Wheel's turn (its green zero faces this angle).
	var spin := 0.0
	## The House: true while its reel window is lit (it can be hurt).
	var lit := false
	var hit_t := 9.0


static func make(id: int) -> Boss:
	var b := Boss.new()
	b.id = id
	b.hp = HP[id]
	b.max_hp = HP[id]
	b.x = Tune.W / 2.0
	b.faces = PackedInt32Array([4, 5, 0])
	return b


## The boss for a wave, or -1 when the wave has none.
static func for_wave(wave: int) -> int:
	return Floors.floor_of(wave) - 1 if Floors.is_guard(wave) else -1


static func name_of(id: int) -> String:
	return NAMES[id]
