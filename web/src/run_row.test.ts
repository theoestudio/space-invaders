import { test } from 'node:test';
import assert from 'node:assert/strict';
import { parseRunRow } from './run_row.ts';

const good = {
  mode: 'daily', daily: 4, outcome: 'cashed', waves: 4, payout: 212, peak: 240, shots: 260, kills: 180,
  hits: 3, spins: 9, fevers: 1, pocketed: 70, caught: 40, official: true, rules: 2, bought: 2,
};

test('accepts what the game sends', () => {
  assert.deepEqual(parseRunRow(good), { ...good, floor: 1 });
  assert.ok(parseRunRow({ ...good, outcome: 'invaded', payout: 0 }));
  assert.ok(parseRunRow({ ...good, outcome: 'empty', payout: 0, waves: 0, kills: 20, bought: 0 }));
  assert.ok(parseRunRow({ ...good, official: false }), 'daily practice');
  assert.ok(parseRunRow({ ...good, mode: 'arcade', daily: 0 }));
  const { rules: _r, bought: _b, ...launch } = good;
  assert.deepEqual(parseRunRow(launch), { ...launch, rules: 1, floor: null }, 'builds from before the descent are rules 1');
  const { daily: _d, ...legacy } = launch;
  assert.ok(parseRunRow(legacy), 'older builds send no daily number');
});

test('the floor comes from the waves: cleared for a cash-out, plus the bust wave', () => {
  const floor = (o: object) => parseRunRow({ ...good, ...o })?.floor;
  assert.equal(floor({ waves: 4 }), 1, 'cashed after the Lobby guard');
  assert.equal(floor({ waves: 4, outcome: 'invaded', payout: 0 }), 2, 'bust on the first Card Room wave');
  assert.equal(floor({ waves: 0, outcome: 'empty', payout: 0, kills: 20, bought: 0 }), 1);
  assert.equal(floor({ waves: 20, kills: 900, peak: 2000, payout: 1900 }), 5, 'broke the Vault');
  assert.equal(floor({ mode: 'arcade', daily: 0, waves: 30, kills: 1350, peak: 2000, payout: 1900 }), 6, 'After Hours');
});

test('rules and fixtures', () => {
  assert.equal(parseRunRow({ ...good, rules: 1 }), null, 'only the current rules name themselves');
  assert.equal(parseRunRow({ ...good, rules: 3 }), null);
  assert.equal(parseRunRow({ ...good, bought: undefined }), null, 'rules 2 sends what it bought');
  const { bought: _b, ...half } = good;
  assert.equal(parseRunRow(half), null, 'rules without fixtures');
  assert.equal(parseRunRow({ ...good, bought: -1 }), null);
  assert.equal(parseRunRow({ ...good, outcome: 'empty', payout: 0, waves: 0, kills: 20 }), null, 'nothing to buy before a clear');
});

test('the daily number matches the mode', () => {
  assert.equal(parseRunRow({ ...good, daily: 0 }), null, 'a daily run names its daily');
  assert.equal(parseRunRow({ ...good, mode: 'arcade', daily: 4 }), null, 'arcade has none');
  assert.equal(parseRunRow({ ...good, daily: 1.5 }), null);
  assert.equal(parseRunRow({ ...good, daily: '4' }), null);
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
