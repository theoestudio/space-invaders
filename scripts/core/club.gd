class_name Club
extends RefCounted
## The players' club (docs/descent.md): comp points from every finished run and
## from challenges raise a tier, and each tier unlocks a launcher for arcade and a
## fixture for the cashier's arcade pool. The daily always plays the Classic
## launcher and the base pool, so it stays the same game for everyone.

## Tiers, lowest first: name and the comp points that reach it.
const TIERS := [["Member", 0], ["Silver", 100], ["Gold", 300], ["Platinum", 700], ["Black", 1500]]

## Launchers: name, what it does and the tier (index into TIERS) that unlocks it.
const LAUNCHERS := {
	&"classic": {name = "Classic", text = "Two bolts in the air, the standard cup", tier = 0},
	&"twin": {name = "Twin", text = "Fires two bolts a shot for two balls; a narrower cup", tier = 1},
	&"magnet": {name = "Magnet", text = "A wide magnet cup; a slower reload", tier = 2},
	&"lancer": {name = "Lancer", text = "Every fourth bolt pierces; a narrow cup", tier = 3},
}
const LAUNCHER_ORDER: Array[StringName] = [&"classic", &"twin", &"magnet", &"lancer"]

## The club's fixtures (Fixtures.ALL), one per tier from Silver up.
const FIXTURE_TIERS := {&"saucer_bait": 1, &"croupier_tip": 2, &"hot_rail": 3, &"golden_touch": 4}

## Launcher numbers.
const TWIN_GAP := 9.0
const TWIN_CUP := 0.7
const MAGNET_COOLDOWN := 1.35
const LANCER_EVERY := 4
const LANCER_CUP := 0.6

## Comp points for a finished run: some for every floor below the Lobby it reached,
## some for the payout, and a bonus for breaking the House.
const COMPS_PER_FLOOR := 5
const COMPS_PER_BALLS := 50
const COMPS_BROKE := 25


static func tier_of(comps: int) -> int:
	var t := 0
	for i in TIERS.size():
		if comps >= TIERS[i][1]:
			t = i
	return t


static func tier_name(tier: int) -> String:
	return TIERS[tier][0]


## The next tier's index and its threshold, or -1 at the top.
static func next_tier(comps: int) -> int:
	var t := tier_of(comps)
	return t + 1 if t + 1 < TIERS.size() else -1


static func run_comps(s: Sim) -> int:
	var c := COMPS_PER_FLOOR * (s.floor_number() - 1) + s.payout() / COMPS_PER_BALLS
	if s.broke_house() and s.phase == Sim.Phase.CASHED:
		c += COMPS_BROKE
	return c


static func unlocked(launcher: StringName, comps: int) -> bool:
	return LAUNCHERS.has(launcher) and tier_of(comps) >= LAUNCHERS[launcher].tier


## The arcade cashier's pool for these comp points: the base pool plus the club
## fixtures the tier has unlocked.
static func pool(comps: int) -> Array[StringName]:
	var out: Array[StringName] = Fixtures.ORDER.duplicate()
	var t := tier_of(comps)
	for id: StringName in FIXTURE_TIERS:
		if t >= FIXTURE_TIERS[id]:
			out.append(id)
	return out


## What reaching `tier` unlocks, for the welcome toast.
static func unlocks(tier: int) -> String:
	var parts: Array[String] = []
	for id in LAUNCHER_ORDER:
		if LAUNCHERS[id].tier == tier:
			parts.append("the %s launcher" % LAUNCHERS[id].name)
	for id: StringName in FIXTURE_TIERS:
		if FIXTURE_TIERS[id] == tier:
			parts.append(Fixtures.name_of(id))
	return " and ".join(parts)
