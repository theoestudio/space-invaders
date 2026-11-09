/**
 * The leaderboard: cash-outs only, from counted runs (daily replays are practice). The
 * daily board is one day's daily run, which everyone plays on the same seed; the arcade
 * board is all time, over every seed. Rows carry no identifier, so the board is scores,
 * not names: a finished run learns its own rank in the reply to the row it sent.
 */

/** Daily #1 was played on this UTC date (Daily.EPOCH in the game). */
export const DAILY_EPOCH = '2026-11-06';
export const BOARD_SIZE = 10;

export interface BoardEntry { payout: number; waves: number }
export interface Board {
  /** 'daily' boards name the daily number they rank. */
  mode: 'daily' | 'arcade';
  daily: number;
  top: BoardEntry[];
  /** Cash-outs on this board, this run's included. */
  total: number;
  /** This run's place (1 = best; ties share the higher place), or null when it does not place. */
  rank: number | null;
}

const DAY_MS = 86_400_000;

/** The UTC date (YYYY-MM-DD) daily run `n` belongs to. */
export function dailyDate(n: number): string {
  return new Date(Date.parse(DAILY_EPOCH) + (n - 1) * DAY_MS).toISOString().slice(0, 10);
}

/** The daily number for a UTC date. */
export function dailyNumber(date: string): number {
  return Math.round((Date.parse(date) - Date.parse(DAILY_EPOCH)) / DAY_MS) + 1;
}

/** A daily run is filed under its own date, as long as that is today or yesterday (a run
 * that started before UTC midnight); anything else is a wrong clock and is refused. */
export function runDay(mode: 'daily' | 'arcade', daily: number | undefined, today: string): string | null {
  if (mode === 'arcade' || daily === undefined) return today;
  const n = dailyNumber(today);
  return daily === n || daily === n - 1 ? dailyDate(daily) : null;
}

/** WHERE clause and its bindings for one board. */
export function boardScope(mode: 'daily' | 'arcade', day: string): { where: string; binds: string[] } {
  return mode === 'daily'
    ? { where: `mode = 'daily' AND official = 1 AND outcome = 'cashed' AND day = ?`, binds: [day] }
    : { where: `mode = 'arcade' AND official = 1 AND outcome = 'cashed'`, binds: [] };
}
