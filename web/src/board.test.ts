import { test } from 'node:test';
import assert from 'node:assert/strict';
import { dailyDate, dailyNumber, runDay, boardScope } from './board.ts';

test('daily numbers and dates match the game (launch day is #1)', () => {
  assert.equal(dailyDate(1), '2026-11-06');
  assert.equal(dailyDate(4), '2026-11-09');
  assert.equal(dailyNumber('2026-11-09'), 4);
  assert.equal(dailyNumber('2027-03-01'), dailyNumber('2027-02-28') + 1);
});

test('a daily run is filed under its own day: today, or yesterday across midnight', () => {
  assert.equal(runDay('daily', 4, '2026-11-09'), '2026-11-09');
  assert.equal(runDay('daily', 3, '2026-11-09'), '2026-11-08');
  assert.equal(runDay('daily', 5, '2026-11-09'), null, 'a clock ahead');
  assert.equal(runDay('daily', 1, '2026-11-09'), null, 'long ago');
  assert.equal(runDay('daily', undefined, '2026-11-09'), '2026-11-09', 'older builds');
  assert.equal(runDay('arcade', 0, '2026-11-09'), '2026-11-09');
});

test('boards count only counted cash-outs, and only the daily board is per day', () => {
  const d = boardScope('daily', '2026-11-09');
  assert.match(d.where, /official = 1 AND outcome = 'cashed' AND day = \?/);
  assert.deepEqual(d.binds, ['2026-11-09']);
  assert.deepEqual(boardScope('arcade', '2026-11-09').binds, []);
});
