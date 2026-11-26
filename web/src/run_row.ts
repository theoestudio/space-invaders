/**
 * Validation for the one payload the game sends. Pure, so it is tested under Node.
 * Anything unexpected is rejected outright rather than coerced: the table should
 * only ever hold rows the real client could have produced.
 */

export interface RunRow {
  mode: 'daily' | 'arcade';
  /** The daily run's number (1 = launch day), 0 in arcade. Absent from older builds' rows. */
  daily?: number;
  outcome: 'cashed' | 'invaded' | 'empty';
  waves: number;
  payout: number;
  peak: number;
  shots: number;
  kills: number;
  hits: number;
  spins: number;
  fevers: number;
  pocketed: number;
  caught: number;
  official: boolean;
  /** The rules version (Tune.RULES). Builds from before the descent send none: rules 1. */
  rules: number;
  /** Fixtures bought at the cashier. Absent on rules 1. */
  bought?: number;
  /** The floor the run ended on, derived from the waves (not sent). Null on rules 1. */
  floor: number | null;
}

/** Must match ROW_KEYS in tests/run_tests.gd and Telemetry.row() in the game. */
export const KEYS = [
  'mode', 'daily', 'outcome', 'waves', 'payout', 'peak', 'shots', 'kills', 'hits', 'spins', 'fevers',
  'pocketed', 'caught', 'official', 'rules', 'bought',
] as const;

/** The rules the current build plays (Tune.RULES in the game). */
export const RULES = 2;
/** Floors under rules 2 (Tune.FLOORS, Tune.WAVES_PER_FLOOR); After Hours is floor 6. */
const FLOORS = 5;
const WAVES_PER_FLOOR = 4;

/** The floor wave `n` is on (Floors.floor_of in the game). */
export function floorOf(n: number): number {
  return Math.min(Math.floor((Math.max(n, 1) - 1) / WAVES_PER_FLOOR) + 1, FLOORS + 1);
}

/** Tune.START_BALLS, Tune.MAX_WAVE and the formation size (9 x 5) in the game. */
const START_BALLS = 60;
const MAX_WAVE = 30;
const PER_WAVE = 45;

const intIn = (v: unknown, lo: number, hi: number): v is number =>
  typeof v === 'number' && Number.isInteger(v) && v >= lo && v <= hi;

export function parseRunRow(body: unknown): RunRow | null {
  if (typeof body !== 'object' || body === null || Array.isArray(body)) return null;
  const o = body as Record<string, unknown>;
  // Builds from before the leaderboard send no daily number; builds from before the
  // descent send no rules or fixtures.
  const legacy = !('rules' in o);
  const want = KEYS.filter((k) => !(k === 'daily' && !('daily' in o)) && !(legacy && (k === 'rules' || k === 'bought')));
  if (Object.keys(o).length !== want.length || !want.every((k) => k in o)) return null;
  if (o.mode !== 'daily' && o.mode !== 'arcade') return null;
  if ('daily' in o && !(o.mode === 'arcade' ? o.daily === 0 : intIn(o.daily, 1, 99999))) return null;
  if (o.outcome !== 'cashed' && o.outcome !== 'invaded' && o.outcome !== 'empty') return null;
  if (typeof o.official !== 'boolean') return null;
  if (o.mode === 'arcade' && !o.official) return null;
  if (!intIn(o.waves, 0, MAX_WAVE) || !intIn(o.payout, 0, 99999) || !intIn(o.peak, START_BALLS, 99999)) return null;
  if (!intIn(o.shots, 0, 99999) || !intIn(o.hits, 0, 999) || !intIn(o.spins, 0, 999)) return null;
  if (!intIn(o.fevers, 0, 99) || !intIn(o.pocketed, 0, 9999) || !intIn(o.caught, 0, 9999)) return null;
  // A cash-out comes after at least one cleared wave and pays a tray that was at
  // most the peak; a bust pays nothing.
  if (o.outcome === 'cashed') {
    if (o.waves < 1 || o.payout < 1 || o.payout > o.peak) return null;
  } else if (o.payout !== 0) {
    return null;
  }
  // Waves reached: the cleared ones, plus the one that went bust.
  const reached = o.waves + (o.outcome === 'cashed' ? 0 : 1);
  if (!intIn(o.kills, 0, reached * PER_WAVE)) return null;
  if (o.fevers > o.spins) return null;
  if (legacy) return { ...(o as unknown as RunRow), rules: 1, floor: null };
  if (o.rules !== RULES || !intIn(o.bought, 0, 999)) return null;
  // The cashier opens only after a cleared wave.
  if (o.waves === 0 && o.bought !== 0) return null;
  return { ...(o as unknown as RunRow), floor: floorOf(reached) };
}
