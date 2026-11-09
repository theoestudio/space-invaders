/**
 * pachinko.twinspear.com
 *
 *   GET  /*            the Godot web build (static assets, see scripts/stage.ts)
 *   GET  /index.wasm   the engine, stored pre-gzipped: at ~40 MB it is over the
 *                      25 MiB per-asset limit, ~10 MB compressed is under it
 *   POST /api/run      one coarse, identifier-free row per finished run; the reply
 *                      is that run's leaderboard (src/board.ts) with its rank
 *
 * The studio dashboard (internal.twinspear.com) reads the `pachinko` D1 database
 * directly. The only numbers served back out are the leaderboard's payouts and waves.
 */
import { parseRunRow } from './run_row.ts';
import { BOARD_SIZE, boardScope, dailyNumber, runDay, type Board, type BoardEntry } from './board.ts';

export interface Env {
  ASSETS: Fetcher;
  DB: D1Database;
}

const ORIGIN = 'https://pachinko.twinspear.com';
const MAX_BODY = 1024;

const empty = (status: number) => new Response(null, { status, headers: { 'Cache-Control': 'no-store' } });

async function ingest(request: Request, env: Env): Promise<Response> {
  if (request.method !== 'POST') return empty(405);
  // Only the page on this origin sends rows. Not a security boundary (anyone can
  // set the header), just a filter for stray traffic.
  if (request.headers.get('Origin') !== ORIGIN) return empty(403);
  const raw = await request.text();
  if (raw.length > MAX_BODY) return empty(413);
  let body: unknown;
  try {
    body = JSON.parse(raw);
  } catch {
    return empty(400);
  }
  const row = parseRunRow(body);
  if (!row) return empty(400);
  const day = runDay(row.mode, row.daily, new Date().toISOString().slice(0, 10));
  if (!day) return empty(400);
  const insert = env.DB.prepare(
    `INSERT INTO runs (id, day, mode, outcome, waves, payout, peak, shots, kills, hits, spins, fevers, pocketed, caught, official)
     VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)`,
  )
    .bind(
      crypto.randomUUID(), day, row.mode, row.outcome, row.waves, row.payout,
      row.peak, row.shots, row.kills, row.hits, row.spins, row.fevers, row.pocketed, row.caught, row.official ? 1 : 0,
    );
  const scope = boardScope(row.mode, day);
  const [, top, count] = await env.DB.batch([
    insert,
    env.DB.prepare(`SELECT payout, waves FROM runs WHERE ${scope.where} ORDER BY payout DESC, waves DESC LIMIT ${BOARD_SIZE}`)
      .bind(...scope.binds),
    env.DB.prepare(`SELECT COUNT(*) AS total, COALESCE(SUM(payout > ?), 0) AS above FROM runs WHERE ${scope.where}`)
      .bind(row.payout, ...scope.binds),
  ]);
  const { total, above } = count.results[0] as { total: number; above: number };
  const placed = row.official && row.outcome === 'cashed';
  const board: Board = {
    mode: row.mode,
    daily: row.mode === 'daily' ? dailyNumber(day) : 0,
    top: top.results as unknown as BoardEntry[],
    total,
    rank: placed ? above + 1 : null,
  };
  return Response.json(board, { headers: { 'Cache-Control': 'no-store' } });
}

async function wasm(request: Request, env: Env): Promise<Response> {
  const headers = new Headers();
  const inm = request.headers.get('If-None-Match');
  if (inm) headers.set('If-None-Match', inm);
  const asset = await env.ASSETS.fetch(new URL('/index.wasm.gz', request.url), { headers });
  if (asset.status === 304) return new Response(null, { status: 304, headers: { ETag: asset.headers.get('ETag') ?? '' } });
  if (!asset.ok) return asset;
  return new Response(asset.body, {
    // The bytes are already gzip; tell the runtime not to touch them.
    encodeBody: 'manual',
    headers: {
      'Content-Type': 'application/wasm',
      'Content-Encoding': 'gzip',
      'Cache-Control': 'public, max-age=0, must-revalidate',
      ETag: asset.headers.get('ETag') ?? '',
    },
  });
}

export default {
  async fetch(request, env): Promise<Response> {
    const { pathname } = new URL(request.url);
    if (pathname === '/api/run') return ingest(request, env);
    if (pathname === '/index.wasm') return wasm(request, env);
    return env.ASSETS.fetch(request);
  },
} satisfies ExportedHandler<Env>;
