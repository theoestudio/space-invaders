class_name Tune
extends RefCounted
## Every number that shapes play, in one place. Units are board pixels (the board
## is 720 x 1280) and seconds. Changing anything here changes the daily runs, so
## rerun `make selfplay` and `make test` afterwards.

const W := 720.0
const H := 1280.0
const STEP := 1.0 / 60.0
const BALL_SUBSTEPS := 3

# --- the board ---------------------------------------------------------------
const LEFT := 26.0
const RIGHT := 694.0
const PIN_R := 4.5
const BALL_R := 7.0
const GRAVITY := 1250.0
const RESTITUTION := 0.42
const FRICTION := 0.985
const MAX_BALL_SPEED := 820.0
## Pins live between these two heights.
const PINS_TOP := 420.0
const PINS_BOTTOM := 1070.0
const REEL_CENTER := Vector2(360, 590)
const REEL_SIZE := Vector2(216, 92)
const DRAIN_Y := 1250.0
## A ball that has not dropped STALL_RADIUS (or gone 4x that anywhere) in
## STALL_TIME gets kicked loose; after STALL_KICKS kicks it drains instead, so a
## wave never waits on a wedged ball.
const STALL_RADIUS := 10.0
const STALL_TIME := 1.0
const STALL_KICKS := 3

# --- the ship ----------------------------------------------------------------
const SHIP_Y := 1172.0
const SHIP_HALF := 34.0
const SHIP_SPEED := 560.0
## The catch tray on top of the ship.
const TRAY_HALF := 30.0
const TRAY_HALF_MAGNET := 66.0
const BOLT_SPEED := 1150.0
const BOLT_COOLDOWN := 0.2
const BOLT_COOLDOWN_RAPID := 0.09
const MAX_BOLTS := 2
const MAX_BOLTS_RAPID := 5
const HIT_INVULN := 1.4

# --- the House (invaders) ----------------------------------------------------
const COLS := 9
const ROWS := 5
const CELL := Vector2(58, 50)
const INVADER_HALF := Vector2(19, 15)
const FORMATION_TOP := 150.0
## Each wave of a floor starts this much lower than the last (Floors.start_drop);
## each floor starts FLOOR_DROP lower than the floor above.
const WAVE_DROP := 34.0
const FLOOR_DROP := 20.0
const MARCH_SPEED := 40.0
const MARCH_SPEED_PER_WAVE := 4.1
## When few are left they speed up: speed * (1 + RUSH * fraction_dead^2).
const RUSH := 3.2
const MARCH_DROP := 28.0
## How fast a turning formation (Formations.RING) turns, radians per second; it
## turns with its march, so it reverses at each edge.
const RING_TURN := 0.45
## A turning formation drops this share of MARCH_DROP at each edge: its lowest
## arc never clears while it turns, so it must come down slower.
const RING_DROP := 0.6

# --- the new pieces (Sim.Kind) -------------------------------------------------
## A dealt card dives every DIVE_GAP seconds or so (one at a time) and takes
## DIVE_TIME to swing down through the launcher's row and back.
const DIVE_GAP := 5.0
const DIVE_TIME := 3.2
## A loaded die rerolls its pips (its hits left, 1 to 6) this often.
const LOADED_REROLL := 3.0
## A roulette disc turns this fast (radians a second); a bolt meets it only when
## its gap faces the bolt within DISC_GAP radians.
const DISC_SPIN := 2.2
const DISC_GAP := 1.1
## A bandit pulls this often; three of a kind out of BANDIT_SYMBOLS fires a volley.
const BANDIT_GAP := 3.5
const BANDIT_SYMBOLS := 4
## Once a boss's escort is broken the boss sinks this fast (px a second).
const BOSS_SINK := 9.0
const INVADED_Y := 1120.0
const SHOT_SPEED := 300.0
const SHOT_SPEED_PER_WAVE := 12.0
## Seconds between House volleys at wave 1, and the floor.
const FIRE_GAP := 1.1
const FIRE_GAP_PER_WAVE := 0.04
const FIRE_GAP_MIN := 0.3
## House shots in the air: SHOTS_MAX_BASE + wave / SHOTS_PER_WAVES.
const SHOTS_MAX_BASE := 3
const SHOTS_PER_WAVES := 4

# --- the floors (docs/descent.md) ---------------------------------------------
const FLOORS := 5
const WAVES_PER_FLOOR := 4
## Clearing this wave, the Vault's guard, breaks the House. The daily ends here.
const VAULT_WAVE := FLOORS * WAVES_PER_FLOOR
## A floor's guard wave pays this times the clear bonus and carries more gold.
const GUARD_BONUS_MULT := 2
const GUARD_GOLDS := 3

# --- the croupier (the bonus saucer) ------------------------------------------
const SAUCER_Y := 112.0
const SAUCER_SPEED := 150.0
const SAUCER_GAP := Vector2(14.0, 24.0)
const SAUCER_BALLS := 5

# --- the tray (the money) -----------------------------------------------------
const START_BALLS := 60
const SHOT_COST := 1
const HIT_SPILL := 12
## A hit spills at least HIT_SPILL, or this share of the tray when that is more,
## so a hit still hurts a deep run.
const HIT_SPILL_SHARE := 0.02
const CATCH_PAY := 1
const GOLD_MULT := 3
const CLEAR_BONUS := 15
const CLEAR_BONUS_PER_WAVE := 10
const MAX_WAVE := 30
## The rules version sent with each run. The leaderboard ranks a run only against
## runs under the same rules, so bump it (and RULES in web/src/run_row.ts) when a
## change makes payouts incomparable with the old ones. 1 was the launch game, 2
## the descent (floors and the cashier).
const RULES := 2

# --- pockets ------------------------------------------------------------------
const POCKET_START_PAY := 3
const POCKET_SIDE_PAY := 2
const POCKET_TULIP_PAY := 5
const POCKET_ATTACKER_PAY := 10
const MAX_HOLDS := 4

# --- the reels ----------------------------------------------------------------
const SPIN_TIME := 1.9
const REACH_EXTRA := 1.3
const FEVER_TIME := 10.0
const POWER_TIME := 12.0
const FEVER_SHOWER := 14
