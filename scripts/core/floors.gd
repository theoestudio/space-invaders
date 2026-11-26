class_name Floors
extends RefCounted
## The descent: five casino floors of Tune.WAVES_PER_FLOOR waves each, the last
## of them the floor's guard (its boss wave until the bosses exist), then After
## Hours, endless waves on mixed floors for arcade. See docs/descent.md.

const NAMES := ["The Lobby", "The Card Room", "The Dice Pit", "The Wheel Room", "The Vault"]
const AFTER_HOURS := "After Hours"

const C := Sim.Kind.CHIP
const D := Sim.Kind.DIE
const K := Sim.Kind.CARD

## Row plans top to bottom for each floor's waves; the last is its guard wave.
const PLANS := [
	# The Lobby: chips and a few dice.
	[[K, D, C, C, C], [K, D, D, C, C], [D, D, C, C, C], [D, D, D, C, C]],
	# The Card Room: cards lead.
	[[K, K, C, C, C], [K, K, D, C, C], [K, K, K, C, C], [K, K, K, K, D]],
	# The Dice Pit: dice.
	[[K, D, D, D, C], [D, D, D, C, C], [K, D, D, D, D], [D, D, D, D, D]],
	# The Wheel Room: everything mixed.
	[[K, K, D, D, C], [K, D, K, D, C], [K, K, D, D, D], [K, K, D, D, D]],
	# The Vault: the hardest.
	[[K, K, D, D, D], [K, K, K, D, D], [K, D, K, D, K], [K, K, K, D, D]],
]


## The floor a wave is on: 1 to Tune.FLOORS, then Tune.FLOORS + 1 for After Hours.
static func floor_of(wave: int) -> int:
	return mini((wave - 1) / Tune.WAVES_PER_FLOOR + 1, Tune.FLOORS + 1)


## 1 to Tune.WAVES_PER_FLOOR within the floor (After Hours keeps counting in fours).
static func wave_in_floor(wave: int) -> int:
	return (wave - 1) % Tune.WAVES_PER_FLOOR + 1


static func is_guard(wave: int) -> bool:
	return wave <= Tune.VAULT_WAVE and wave_in_floor(wave) == Tune.WAVES_PER_FLOOR


static func floor_name(floor_number: int) -> String:
	return NAMES[floor_number - 1] if floor_number <= Tune.FLOORS else AFTER_HOURS


## The floor's name inside a sentence: "the Card Room", "After Hours".
static func in_sentence(floor_number: int) -> String:
	var n := floor_name(floor_number)
	return "the" + n.substr(3) if n.begins_with("The ") else n


## The wave's rows, top to bottom. After Hours borrows a plan from a random floor
## and hardens a row or two.
static func plan(wave: int, rng: RandomNumberGenerator) -> Array:
	var f := floor_of(wave)
	if f <= Tune.FLOORS:
		return PLANS[f - 1][wave_in_floor(wave) - 1].duplicate()
	var rows: Array = PLANS[rng.randi_range(2, Tune.FLOORS - 1)][rng.randi_range(0, Tune.WAVES_PER_FLOOR - 1)].duplicate()
	for i in 2:
		rows[rng.randi_range(1, Tune.ROWS - 1)] = K if rng.randf() < 0.5 else D
	return rows


## How far below Tune.FORMATION_TOP the wave's formation starts: lower each wave
## within a floor, back near the top on a new floor (a little lower each floor).
static func start_drop(wave: int) -> float:
	var f := mini(floor_of(wave), Tune.FLOORS + 1)
	return (wave_in_floor(wave) - 1) * Tune.WAVE_DROP + (f - 1) * Tune.FLOOR_DROP
