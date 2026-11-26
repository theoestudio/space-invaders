class_name Fixtures
extends RefCounted
## The cashier's stock: fixtures bought with tray balls between waves that change
## the rest of the run (docs/descent.md). Pure data; Sim keeps what was bought and
## reads the effects through Sim.level().

## Each fixture: name, what it does, its group, base price in balls and how many
## times it stacks. ORDER is the draw order, so keep new fixtures at the end: the
## daily's offers come from it.
const ALL := {
	&"bent_nail": {name = "Bent nail", text = "Start chucker pays +2", group = "Board", price = 40, stacks = 2},
	&"side_comps": {name = "Side pocket comps", text = "Side pockets pay +1", group = "Board", price = 30, stacks = 2},
	&"tulip_bonus": {name = "Tulip bonus", text = "Tulips pay +3", group = "Board", price = 35, stacks = 2},
	&"gold_leaf": {name = "Gold leaf", text = "One more gold piece every wave", group = "Board", price = 45, stacks = 3},
	&"loaded_seven": {name = "Loaded seven", text = "Fever odds up by a third", group = "Reels", price = 60, stacks = 2},
	&"deep_holds": {name = "Deep holds", text = "Hold two more spins", group = "Reels", price = 35, stacks = 1},
	&"long_fever": {name = "Long fever", text = "Fever lasts 4 s longer", group = "Reels", price = 40, stacks = 2},
	&"sticky_prizes": {name = "Sticky prizes", text = "Reel powers last half again", group = "Reels", price = 40, stacks = 1},
	&"deep_cup": {name = "Deep cup", text = "Caught balls pay +1", group = "Launcher", price = 30, stacks = 2},
	&"wide_cup": {name = "Wide cup", text = "A wider catch cup", group = "Launcher", price = 35, stacks = 2},
	&"quick_reload": {name = "Quick reload", text = "A quarter off the cooldown", group = "Launcher", price = 50, stacks = 2},
	&"twin_barrel": {name = "Twin barrel", text = "One more bolt in the air", group = "Launcher", price = 55, stacks = 2},
	&"piercing_tips": {name = "Piercing tips", text = "Every fifth bolt pierces", group = "Launcher", price = 45, stacks = 1},
	&"interest": {name = "Interest", text = "5% of the tray on each clear", group = "Tray", price = 50, stacks = 2},
	&"comps": {name = "Comps", text = "Clear bonuses x1.5", group = "Tray", price = 60, stacks = 1},
	&"padded_rail": {name = "Padded rail", text = "A hit spills 8, not 12", group = "Tray", price = 35, stacks = 1},
	&"insurance": {name = "Insurance", text = "First hit each wave spills nothing", group = "Tray", price = 30, stacks = 1},
}
const ORDER: Array[StringName] = [
	&"bent_nail", &"side_comps", &"tulip_bonus", &"gold_leaf",
	&"loaded_seven", &"deep_holds", &"long_fever", &"sticky_prizes",
	&"deep_cup", &"wide_cup", &"quick_reload", &"twin_barrel", &"piercing_tips",
	&"interest", &"comps", &"padded_rail", &"insurance",
]

## Offers per visit, fixture slots, price growth per buy, the first reroll's
## price (it doubles for each further reroll in one visit) and the share of what
## was paid that a sale returns.
const OFFERS := 3
const SLOTS := 6
const PRICE_GROWTH := 1.15
const REROLL_PRICE := 10
const SELL_SHARE := 0.5

const INTEREST_RATE := 0.05
const INTEREST_CAP := 40
const COMPS_MULT := 1.5
const PADDED_SPILL := 8
const QUICK_RELOAD := 0.75
const PIERCE_EVERY := 5
const WIDE_CUP := 10.0
const LONG_FEVER := 4.0
const STICKY_PRIZES := 1.5
const DEEP_HOLDS := 2


static func name_of(id: StringName) -> String:
	return ALL[id].name
