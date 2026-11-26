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

The run descends five casino floors (the Lobby, the Card Room, the Dice Pit, the
Wheel Room and the Vault), four waves each, the last a guard worth a double clear
bonus. Breaking the Vault's guard doubles the tray.

After each wave the **cashier** sells fixtures for the rest of the run with tray
balls (a bent nail, a twin barrel, interest on the tray and so on), and then you
choose: **cash out** (the tray is your score) or **let it ride** into a faster,
harder wave with a bigger clear bonus. Bust (the House reaches your rail, or the
tray runs dry) and the House keeps everything. See `docs/descent.md`.

**Daily run.** One seed a day, the same for everyone: the same board, formations,
reel draws and cashier offers in the same order. It ends at the Vault. The first
finished run counts; replays are practice. Results copy as a spoiler-free row of
squares.

**Arcade.** A fresh board every run; past the Vault it goes on into After Hours, up
to wave 30. Keeps your best payout.

Arrow keys or A/D move, Space fires, Esc pauses. Between waves, 1 to 3 buy, X
rerolls, C cashes out and R rides. On a phone or with a mouse, hold
anywhere and drag: the launcher follows your finger and fires on its own.

This repo started in 2016 as a small Space Invaders-style demo for my ion-cloud
JavaScript library; that version is tagged
[`v0-web-classic`](https://github.com/theoestudio/space-invaders/tree/v0-web-classic)
and still served from the `github.io` branch. Pachinko Descent replaced it in 2026.

## Layout

| Path | What |
| --- | --- |
| `scripts/core/` | The run as plain data: `Sim` (stepped at 60 Hz), `Board`, `Reels`, `Floors`, `Fixtures` (the cashier), `Daily`, `Tune` (every number) and the `Autopilot`. No nodes. |
| `scripts/view/` | `Stage` draws a Sim in depth-sorted layers: the cabinet, the House, balls dropping into pockets, neon glow, effects and the in-board HUD, using 2.5D Cycles miniatures in `assets/art/`. |
| `scripts/ui/` | Menu, pause, the cash-out choice, results and How to Play, built in code. |
| `scripts/autoload/` | Local profile (settings, records), sound and music, and the one telemetry call. |
| `shaders/` | The starfield behind the cabinet. |
| `tests/` | Headless sim tests, autopilot balance runs and a screenshot harness. |
| `tools/make-sounds.py` | Renders every sound effect from code. |
| `tools/encode-music.py` | Encodes the music tracks into `web/music/` and lists them in `data/music.json`: synthwave during runs, vaporwave on the menu and results. The game fetches one track at a time from the site. |
| `web/` | Cloudflare Worker: serves the web export, records finished runs in D1 and answers each with the leaderboard. |

## Working on it

Needs the standard (non-.NET) Godot 4.7.2 editor as `godot` with its web export
templates installed, plus Node for `web/`.

```bash
make test       # sim, board, reels, daily and telemetry checks, plus the Worker's tests
make selfplay   # autopilot at three skill levels: busts and payout per cash-out wave
make shots      # screenshots of every screen at phone size, on a virtual display
make music      # re-encode web/music from the Suno WAVs (MUSIC_SRC, default ~/Rime/pachinko/music)
make art        # re-render the 2.5D miniatures in assets/art/ via Blender Cycles
make dev        # export and serve through the Worker on localhost:8787
make deploy     # tests, export, then wrangler deploy
```

Changing anything in `Tune`, `Board`, `Reels` or `Sim` changes every daily run from
then on. Run `make selfplay` to see what it does to the cash-out curve.
When a change makes payouts incomparable with the old ones, bump `Tune.RULES` and
`RULES` in `web/src/run_row.ts`: the leaderboard ranks runs only against runs under
the same rules. Apply new D1 migrations with `cd web && npm run db:migrate` before
deploying a build that writes their columns.

## Privacy

The game sends one row per finished run from the production site: mode, outcome,
waves cleared, payout, peak tray, shots, kills, hits taken, spins, fevers, balls
pocketed and caught, fixtures bought, the rules version and whether a daily was a
replay. The server adds the floor the run ended on (from the waves) and the date
the row arrived. No identifier, no timestamp
from the device, no seed. Two rows cannot be tied to the same person. Records stay
in the browser.

## Credits

Code and sound by Nathaniel Inman, MIT licensed. Fonts: Bungee and Outfit, both
under the SIL Open Font License (`fonts/`).
