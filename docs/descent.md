# The Descent

Pachinko Descent launched (2026-11-06) as one loop: the same 9x5 formation of
chips, dice and cards every wave, a little lower and faster each time, and a
choice after each wave to cash out or let it ride. Nothing changed during a run
and nothing carried between runs. This page turns that loop into a run with an
arc: a descent through five casino floors to the House's vault, a cashier where
the tray buys changes to the run, and a players' club that lasts between runs.

Every number here is a starting value for `make selfplay`, not a promise. Any
change to `Sim`, `Board`, `Reels` or `Tune` reseeds every daily run from the
deploy onward (see the README), so a balance pass ships as one change.

## The floors

A run goes down five floors. Each floor is three waves and a boss wave, so the
Vault's boss is wave 20. Each floor has its own mix of House pieces, its own
formations and, once the art lands, its own pin layout, palette and music.

| # | Floor | The House | Boss |
|---|---|---|---|
| 1 | The Lobby | chips, a few dice | the Doorman |
| 2 | The Card Room | cards lead; dealt cards dive | the Dealer |
| 3 | The Dice Pit | dice; loaded dice | the Pit Boss |
| 4 | The Wheel Room | roulette discs, chip stacks | the Wheel |
| 5 | The Vault | everything, bandits | the House |

- **Pacing.** Within a floor each wave starts lower than the last; a new floor
  starts the formation back near the top, a little lower each floor. March
  speed, House fire rate and shot speed climb with the run's wave number, slower
  than they did when the game ended around wave 8.
- **Formations.** Each floor picks a shape per wave (`Floors.SHAPES`): the grid,
  a V, a diamond, a chevron, two blocks split by a lane, and on the Wheel Room
  and the Vault a ring that turns as it marches. The ring drops less at each edge
  (`Tune.RING_DROP`), since its lowest arc never clears while it turns.
- **Hits.** A hit spills 12 balls or 2% of the tray, whichever is more, so a
  deep run still feels one.
- **The elevator.** Clearing a boss wave clears the floor: the panel between
  waves says so and names the floor below, and the next wave opens with the
  floor's banner.
- **The boss wave.** Until the bosses exist (below), a floor's boss wave is its
  guard: a formation of the floor's hardest pieces with extra gold, paying a
  double clear bonus.
- **The ending.** Clearing the Vault's boss breaks the House: the clear bonus
  doubles the tray. The daily run ends there; cashing out is the only button.
  Arcade can ride on into **After Hours**, endless waves on mixed floors, up to
  wave 30 (`Tune.MAX_WAVE`, which the leaderboard also checks).

## The cashier

After each cleared wave, before the choice to cash out or ride, the cashier
window offers three fixtures for the rest of the run, priced in tray balls. The
tray is still the score, so every buy is a bet that it pays for itself before
you cash out.

- Three offers per visit, drawn from a seeded stream by wave (and by reroll), so
  the daily's offers are the same for everyone who reaches that wave with the
  same fixtures. Shopping never changes the board, the formations or the reels.
- Each buy raises every price by 15%. A reroll costs 10 balls and doubles for
  each further reroll in the same visit.
- Six fixture slots. Selling one returns half what was paid for it.
- Some fixtures stack (up to the count shown).

Starting pool:

| Fixture | Does | Stacks |
|---|---|---|
| **Board** | | |
| Bent nail | Start chucker pays +4 | 2 |
| Side pocket comps | Side pockets pay +1 | 2 |
| Tulip bonus | Tulips pay +3 | 2 |
| Gold leaf | Two more gold pieces in every formation | 3 |
| **Reels** | | |
| Loaded seven | Fever odds up by a third | 2 |
| Deep holds | Two more held spins | 1 |
| Long fever | Fever lasts 4 s longer | 2 |
| Sticky prizes | Reel powers last twice as long | 1 |
| **Launcher** | | |
| Deep cup | Caught balls pay +1 | 2 |
| Wide cup | The catch cup is wider | 2 |
| Quick reload | A quarter off the shot cooldown | 2 |
| Twin barrel | One more bolt in the air | 2 |
| Piercing tips | Every fifth bolt pierces | 1 |
| **Tray** | | |
| Interest | 5% of the tray on each clear, up to 40 | 2 |
| Comps | Clear bonuses x1.5 | 1 |
| Padded rail | Hits spill half as much | 1 |
| Insurance | The first hit on each wave spills nothing | 1 |

Fixture icons are text until the art pipeline draws them.

## Balance (2026-11-26)

`make selfplay ARGS="36 20 shop 0.7"` plays whole runs with the autopilot buying
at the cashier (`Autopilot.shop`) and, in a second pass, cashing out when it
would (`Autopilot.ride`). `tests/fixture_value.gd` measures each fixture given
free from wave 1, which set `Autopilot.WORTH`. Riding every wave, 36 runs per
skill:

| Skill | Survive wave 8 | 12 | 16 | Break the Vault |
|---|---|---|---|---|
| 0.4 | 92% | 42% | 31% | 8% |
| 0.7 | 97% | 83% | 39% | 6% |
| 0.95 | 100% | 83% | 36% | 19% |

Every bust is an invasion, so fixtures that only pay balls never keep a run
alive; piercing tips, twin barrel, quick reload and the wide cup do. No fixture
is bought by more than two thirds of the runs that reach the Dice Pit. The
autopilot's skill levels differ less than players do (aim 54% to 58%), so the
playtest has the last word.

## Challenges and the daily history

Twelve challenges (`Challenges`) pay comp points the first time each is met, in
either mode: two fevers in one wave, a guard cleared unhit, a 70% wave, 500 from
the Lobby, clearing the Card Room, the Dice Pit and the Wheel Room, breaking the
Vault, a wave After Hours, a ring broken, six fixtures at once and 1,000 cashed
without buying. The Daily card shows the last 14 dailies as lamps; the Records
panel lists them with payout and floor, and the challenges with what they pay.
Comp points wait for the players' club to spend them.

## The players' club

Comp points (`Club`) come from challenges and from every finished run: 5 for
each floor below the Lobby it reached, 1 for every 50 balls paid and 25 for
breaking the House. Tiers by comp points unlock a launcher for arcade (picked on
the Arcade card) and a fixture for the arcade cashier:

| Tier | Comps | Launcher | Fixture |
|---|---|---|---|
| Member | 0 | **Classic**: two bolts in the air, the standard cup | |
| Silver | 100 | **Twin**: two bolts a shot for two balls, a narrower cup | Saucer bait: the saucer comes twice as often |
| Gold | 300 | **Magnet**: a wide magnet cup, a slower reload | Croupier's tip: every spin pays +3 |
| Platinum | 700 | **Lancer**: every fourth bolt pierces, a narrow cup | Hot rail: a pocketed gold ball banks a spin |
| Black | 1,500 | | Golden touch: gold balls pay x4 |

Against Classic (13.1 waves cleared at mid skill, `tests/fixture_value.gd` with
`launcher:<id>`), Twin clears 13.5 with a smaller early tray, Magnet 12.4 with a
bigger one and Lancer 13.9: a late reward, a little ahead. The daily always
plays Classic and the base pool, so it stays fair. Records stay in the browser.

## The House's new pieces

`Sim.Kind` adds five pieces; plan rows (`Floors.PLANS`) can mix kinds column by
column, so a floor brings them in one in two or three rather than whole rows.

- **Chip stack** (Wheel Room, Vault): three layers; each hit sheds one and a ball.
- **Dealt card** (Card Room, Vault): every few seconds one leaves the formation,
  swoops down through the launcher's row (a hit if it touches the launcher) and
  back to its place. A diving card never counts toward an invasion.
- **Loaded die** (Dice Pit, Vault): rerolls its pips, 1 to 6, every 3 s. Hits
  stick, so it breaks when it shows no more pips than the hits it has taken:
  shoot it while it shows low.
- **Roulette disc** (Wheel Room, Vault): turns; a bolt that meets its rim glances
  away sideways, and only one that meets its green gap counts.
- **Bandit** (Vault): pulls every few seconds; three of a kind (1 in 16) fires a
  three-shot volley.

They draw as placeholders built from the launch pieces (`Sprites._stack`,
`_disc`, `_bandit`, a pips badge on the die and a ring on the dealt card) until
the art pipeline renders them. With them in, riding every wave (36 runs): mid
skill survives wave 12 in 72% of runs and breaks the Vault in 14%; top skill 67%
and 19%. The Card Room now costs a few runs; the Wheel Room is the steepest floor.

## The bosses

Each floor's guard wave is its boss (`Bosses`) over a two-row escort of the
floor's pieces. Breaking the boss clears the wave, breaks the escort and
showers balls (a fourth of them gold); the guard's double clear bonus still
pays. The boss rides with the formation, and once its escort is broken the
formation sinks on its own (`Tune.BOSS_SINK`), so a boss left standing still
invades. An intro card names it with its trick, a bar shows its health.

| Boss | Floor | HP | Attack | Weak point |
|---|---|---|---|---|
| The Doorman | Lobby | 14 | paces the top, drops a shot every 1.5 s | anywhere; each hit sheds a layer and a ball |
| The Dealer | Card Room | 16 | deals a dealt card into its escort every 3.2 s, fires pairs | anywhere |
| The Pit Boss | Dice Pit | 12 | two dice roll every 2.4 s; the roll sets the volley (1 to 3 shots) | a die showing 3 or less |
| The Wheel | Wheel Room | 12 | paces, fires from its rim | a bolt through its turning green zero; the rim glances |
| The House | Vault | 15 | reels spin 2 s, then fire 2, 4 or 7 shots on no, two or three of a kind | the reel window while it is lit (3 s) |

Tests check the mid-skill autopilot beats each one in at least two of three
tries. With bosses in, riding every wave (36 runs): mid skill survives wave 12
in 86% of runs and breaks the Vault in 14%; top skill 89% and 22%. They draw as
placeholders (`Sprites.boss`) until the art pipeline renders them.

## Feel

Hit-stop (view only; the sim keeps its 60 Hz step) and shake on breaks and boss
hits, a tray counter that rolls, a small payout for quick kill chains, longer
reach drama on the reels and a jackpot sequence when a pocket pays big.

## Sprites the art pipeline owes

The 2.5D rework (Blender plus generated textures, 2026-11-26) draws the current
pieces. The Descent adds:

- five new pieces: chip stack (3 layers), dealt card, loaded die (pips 1 to 6),
  roulette disc (with gap), bandit (three small reels);
- five bosses, each with a hurt state;
- a palette and cabinet dressing per floor, plus After Hours;
- four launchers;
- 17 fixture icons;
- an elevator transition between floors.

## Tasks

Filed under `pachinko` in Waybill with `ref:descent`: floors, cashier,
formations, pieces, bosses, floor boards, impact, autopilot, players' club,
leaderboard versioning, challenges, attract demo, floor music and the playtest.
