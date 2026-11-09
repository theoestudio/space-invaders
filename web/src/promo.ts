/**
 * Validation for the "More from TwinSpear" click row: which game a player tapped and
 * where (the menu's list or the suggestion under a result). Pure, so it is tested under
 * Node. Exactly these two keys, nothing that could tell two players apart.
 */

export interface PromoRow {
  /** The tapped game's id from nathanielinman.com/games/index.json. */
  to: string;
  where: 'menu' | 'end';
}

/** Must match Telemetry.promo() in the game and PROMO_KEYS in tests/run_tests.gd. */
export const PROMO_KEYS = ['to', 'where'] as const;

export function parsePromo(body: unknown): PromoRow | null {
  if (typeof body !== 'object' || body === null || Array.isArray(body)) return null;
  const o = body as Record<string, unknown>;
  if (Object.keys(o).length !== PROMO_KEYS.length || !PROMO_KEYS.every((k) => k in o)) return null;
  if (typeof o.to !== 'string' || !/^[a-z0-9-]{2,24}$/.test(o.to)) return null;
  if (o.where !== 'menu' && o.where !== 'end') return null;
  return { to: o.to, where: o.where };
}
