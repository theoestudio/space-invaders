# Pachinko Descent

A neon arcade shooter on a pachinko board. Play it at **[pachinko.twinspear.com](https://pachinko.twinspear.com)**.

The House (a formation of living casino chips, dice and playing cards) marches down
the board toward your launcher. Every one you break drops a steel ball through a
field of brass pins:

- **Pockets** pay balls into your tray: side +2, tulip +5, and the green start
  chucker +3. Shooting through a shut tulip springs it open.
- **The start chucker** banks a spin on the three reels in the middle of the board.
  Three sevens start a **fever**: free rapid fire, the gold attacker opens and pays
  +10 a ball, and a shower of balls comes down. Other triples give a spread shot,
  piercing bolts, a shield, a wide catch cup or 20 balls.
- **Your tray is everything.** Every shot costs a ball and a hit from the House
  spills twelve. Catch falling balls in the cup on your launcher for +1.

After each wave you choose: **cash out** (the tray is your score) or **let it ride**
into a faster, lower, harder wave with a bigger clear bonus. Bust (the House reaches
your rail, or the tray runs dry) and the House keeps everything.

**Daily run.** One seed a day, the same for everyone: the same board, formations and
reel draws in the same order. The first finished run counts; replays are practice.
Results copy as a spoiler-free row of squares.

**Arcade.** A fresh board every run; keeps your best payout.

Arrow keys or A/D move, Space fires, Esc pauses. On a phone or with a mouse, hold
anywhere and drag: the launcher follows your finger and fires on its own.

This repo started in 2016 as a small Space Invaders-style demo for my ion-cloud
JavaScript library; that version is tagged
[`v0-web-classic`](https://github.com/theoestudio/space-invaders/tree/v0-web-classic)
and still served from the `github.io` branch. Pachinko Descent replaced it in 2026.

## Layout

| Path | What |
| --- | --- |
| `scripts/core/` | The run as plain data: `Sim` (stepped at 60 Hz), `Board`, `Reels`, `Daily`, `Tune` (every number) and the `Autopilot`. No nodes. |
| `scripts/view/` | `Stage` draws a Sim: the board, the House, balls, neon glow, effects and the in-board HUD. All primitives, no image files. |
| `scripts/ui/` | Menu, pause, the cash-out choice, results and How to Play, built in code. |
| `scripts/autoload/` | Local profile (settings, records), sound, and the one telemetry call. |
| `shaders/` | The starfield behind the cabinet. |
| `tests/` | Headless sim tests, autopilot balance runs and a screenshot harness. |
| `tools/make-sounds.py` | Renders every sound effect and the music loop from code. |
| `web/` | Cloudflare Worker: serves the web export and records finished runs in D1. |

## Working on it

Needs the standard (non-.NET) Godot 4.7.2 editor as `godot` with its web export
templates installed, plus Node for `web/`.

```bash
make test       # sim, board, reels, daily and telemetry checks, plus the Worker's tests
make selfplay   # autopilot at three skill levels: busts and payout per cash-out wave
make shots      # screenshots of every screen at phone size, on a virtual display
make dev        # export and serve through the Worker on localhost:8787
make deploy     # tests, export, then wrangler deploy
```

Changing anything in `Tune`, `Board`, `Reels` or `Sim` changes every daily run from
then on. Run `make selfplay` to see what it does to the cash-out curve.

## Privacy

The game sends one row per finished run from the production site: mode, outcome,
waves cleared, payout, peak tray, shots, kills, hits taken, spins, fevers, balls
pocketed and caught, and whether a daily was a replay. No identifier, no timestamp
from the device, no seed. Two rows cannot be tied to the same person. Records stay
in the browser.

## Credits

Code and sound by Nathaniel Inman, MIT licensed. Fonts: Bungee and Outfit, both
under the SIL Open Font License (`fonts/`).
