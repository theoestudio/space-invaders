import { test } from 'node:test';
import assert from 'node:assert/strict';
import { parseRunRow } from './run_row.ts';

const good = {
  mode: 'daily', outcome: 'cashed', waves: 4, payout: 212, peak: 240, shots: 260, kills: 180,
  hits: 3, spins: 9, fevers: 1, pocketed: 70, caught: 40, official: true,
};

test('accepts what the game sends', () => {
  assert.deepEqual(parseRunRow(good), good);
  assert.ok(parseRunRow({ ...good, outcome: 'invaded', payout: 0 }));
  assert.ok(parseRunRow({ ...good, outcome: 'empty', payout: 0, waves: 0, kills: 20 }));
  assert.ok(parseRunRow({ ...good, official: false }), 'daily practice');
  assert.ok(parseRunRow({ ...good, mode: 'arcade' }));
});

test('rejects anything else', () => {
  assert.equal(parseRunRow(null), null);
  assert.equal(parseRunRow([]), null);
  assert.equal(parseRunRow({ ...good, extra: 1 }), null, 'extra key');
  const { caught: _c, ...missing } = good;
  assert.equal(parseRunRow(missing), null, 'missing key');
  assert.equal(parseRunRow({ ...good, mode: 'versus' }), null, 'mode');
  assert.equal(parseRunRow({ ...good, outcome: 'won' }), null, 'outcome');
  assert.equal(parseRunRow({ ...good, outcome: 'invaded' }), null, 'a bust pays nothing');
  assert.equal(parseRunRow({ ...good, waves: 0 }), null, 'a cash-out clears a wave first');
  assert.equal(parseRunRow({ ...good, payout: 300 }), null, 'payout above peak');
  assert.equal(parseRunRow({ ...good, peak: 10 }), null, 'peak below the starting tray');
  assert.equal(parseRunRow({ ...good, kills: 181, waves: 4 }), null, 'more kills than four waves hold');
  assert.equal(parseRunRow({ ...good, fevers: 10 }), null, 'more fevers than spins');
  assert.equal(parseRunRow({ ...good, mode: 'arcade', official: false }), null, 'arcade is never practice');
  assert.equal(parseRunRow({ ...good, shots: 1.5 }), null, 'integers only');
  assert.equal(parseRunRow({ ...good, official: 1 }), null, 'booleans only');
  assert.equal(parseRunRow({ ...good, waves: 31 }), null, 'wave cap');
});
