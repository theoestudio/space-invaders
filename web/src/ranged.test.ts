import { test } from 'node:test';
import assert from 'node:assert/strict';
import { byteRange, ranged } from './ranged.ts';

test('reads the byte range a media request asks for', () => {
  assert.deepEqual(byteRange('bytes=0-1', 100), { start: 0, end: 1 });
  assert.deepEqual(byteRange('bytes=10-', 100), { start: 10, end: 99 });
  assert.deepEqual(byteRange('bytes=90-500', 100), { start: 90, end: 99 });
  assert.deepEqual(byteRange('bytes=-30', 100), { start: 70, end: 99 });
  assert.deepEqual(byteRange('bytes=-300', 100), { start: 0, end: 99 });
  assert.equal(byteRange('bytes=100-', 100), 'unsatisfiable');
  assert.equal(byteRange('bytes=-0', 100), 'unsatisfiable');
  for (const whole of [null, '', 'bytes=-', 'bytes=5-2', 'bytes=0-1,5-6', 'items=0-1']) {
    assert.equal(byteRange(whole, 100), null, String(whole));
  }
});

test('cuts a whole file to the range asked for', async () => {
  const file = () => new Response(new Uint8Array([0, 1, 2, 3, 4, 5, 6, 7, 8, 9]), { headers: { 'Content-Type': 'audio/ogg' } });
  const get = (headers: Record<string, string> = {}) => new Request('https://example.com/music/a.ogg', { headers });

  const part = await ranged(get({ Range: 'bytes=2-4' }), file());
  assert.equal(part.status, 206);
  assert.equal(part.headers.get('Content-Range'), 'bytes 2-4/10');
  assert.equal(part.headers.get('Content-Length'), '3');
  assert.equal(part.headers.get('Content-Type'), 'audio/ogg');
  assert.deepEqual([...new Uint8Array(await part.arrayBuffer())], [2, 3, 4]);

  const whole = await ranged(get(), file());
  assert.equal(whole.status, 200);
  assert.equal(whole.headers.get('Accept-Ranges'), 'bytes');
  assert.equal((await whole.arrayBuffer()).byteLength, 10);

  const past = await ranged(get({ Range: 'bytes=10-' }), file());
  assert.equal(past.status, 416);
  assert.equal(past.headers.get('Content-Range'), 'bytes */10');

  const missing = await ranged(get({ Range: 'bytes=0-1' }), new Response('no', { status: 404 }));
  assert.equal(missing.status, 404);
});
