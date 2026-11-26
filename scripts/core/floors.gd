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
const S := Sim.Kind.STACK
const T := Sim.Kind.DEALT
const L := Sim.Kind.LOADED
const R := Sim.Kind.DISC
const B := Sim.Kind.BANDIT

## Row plans top to bottom for each floor's waves; the last is its guard wave. A
## row is one kind, or an array of kinds repeated across its columns.
const PLANS := [
	# The Lobby: chips and a few dice.
	[[K, D, C, C, C], [K, D, D, C, C], [D, D, C, C, C], [D, D, D, C, C]],
	# The Card Room: cards lead, and dealt cards dive at the launcher.
	[[K, K, D, C, C], [[T, K, K], K, D, D, C], [K, [K, T], K, D, C], [[T, K], K, K, D, D]],
	# The Dice Pit: dice, some of them loaded.
	[[K, D, D, D, C], [K, [D, L, D], D, D, C], [K, D, [L, D, D], D, D], [K, [L, D, D], D, D, D]],
	# The Wheel Room: roulette discs and chip stacks.
	[[K, K, D, C, C], [K, [R, K, K], K, C, [S, C, C]], [K, K, [K, R, K], D, [C, S, C]], [K, [R, K, K], D, D, [S, C, C]]],
	# The Vault: bandits and everything else.
	[[K, K, D, D, D], [[B, K, K, K], K, K, D, D], [[K, B, K, K], K, [D, R, D, D], [L, D, D], [S, C, C]], [[B, K, K, K], K, [K, T, K], [L, D, D], [S, C, C]]],
]


## The kind at column `col` of a plan row.
static func kind_at(row: Variant, col: int) -> int:
	if row is Array:
		return row[col % row.size()]
	return row

## Each floor's shapes, wave by wave (Formations); the last is the guard's.
const SHAPES := [
	[&"grid", &"diamond", &"v", &"grid"],
	[&"chevron", &"split", &"diamond", &"grid"],
	[&"split", &"v", &"chevron", &"grid"],
	[&"diamond", &"ring", &"split", &"ring"],
	[&"chevron", &"ring", &"v", &"diamond"],
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


## The wave's formation shape. After Hours picks any shape.
static func shape(wave: int, rng: RandomNumberGenerator) -> StringName:
	var f := floor_of(wave)
	if f <= Tune.FLOORS:
		return SHAPES[f - 1][wave_in_floor(wave) - 1]
	return Formations.ALL[rng.randi_range(0, Formations.ALL.size() - 1)]


## How far below Tune.FORMATION_TOP the wave's formation starts: lower each wave
## within a floor, back near the top on a new floor (a little lower each floor).
static func start_drop(wave: int) -> float:
	var f := mini(floor_of(wave), Tune.FLOORS + 1)
	return (wave_in_floor(wave) - 1) * Tune.WAVE_DROP + (f - 1) * Tune.FLOOR_DROP
