import { test } from 'node:test';
import assert from 'node:assert/strict';
import { parsePromo } from './promo.ts';

test('accepts what the game sends', () => {
  assert.deepEqual(parsePromo({ to: 'det33', where: 'end' }), { to: 'det33', where: 'end' });
  assert.ok(parsePromo({ to: 'kepler452b', where: 'menu' }));
});

test('rejects anything else', () => {
  assert.equal(parsePromo(null), null);
  assert.equal(parsePromo([]), null);
  assert.equal(parsePromo({ to: 'det33' }), null, 'missing where');
  assert.equal(parsePromo({ to: 'det33', where: 'end', id: 'abc' }), null, 'extra key');
  assert.equal(parsePromo({ to: 'DET33', where: 'end' }), null, 'ids are lowercase');
  assert.equal(parsePromo({ to: 'x', where: 'end' }), null, 'too short');
  assert.equal(parsePromo({ to: 'a'.repeat(25), where: 'end' }), null, 'too long');
  assert.equal(parsePromo({ to: 'det33', where: 'pause' }), null, 'unknown place');
  assert.equal(parsePromo({ to: 7, where: 'end' }), null);
});
