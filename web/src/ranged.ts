/**
 * Byte ranges for the music. Static assets ignore Range, and Safari won't play an <audio>
 * element from a server that does, so /music/* runs through the Worker (run_worker_first in
 * wrangler.jsonc) and is cut here. No Worker bindings, so it is tested under Node.
 */

/**
 * The single byte range a Range header asks for in a file of `size` bytes (browsers ask
 * for one at a time when they play media). null when there is no header the file can be
 * cut by, so the whole file goes back; 'unsatisfiable' when the range starts past the end.
 */
export function byteRange(header: string | null, size: number): { start: number; end: number } | 'unsatisfiable' | null {
  const m = /^bytes=(\d*)-(\d*)$/.exec((header ?? '').trim());
  if (!m || (m[1] === '' && m[2] === '')) return null;
  if (m[1] === '') {
    // A suffix: the last N bytes.
    const n = Number(m[2]);
    if (n === 0) return 'unsatisfiable';
    return { start: Math.max(size - n, 0), end: size - 1 };
  }
  const start = Number(m[1]);
  if (m[2] !== '' && Number(m[2]) < start) return null;
  if (start >= size) return 'unsatisfiable';
  return { start, end: m[2] === '' ? size - 1 : Math.min(Number(m[2]), size - 1) };
}

/**
 * A whole-file response cut to the Range the request asks for. Static assets ignore
 * Range, and Safari won't play an <audio> element from a server that does. Anything
 * but a plain 200 (a 304, a 404, a 206 should assets ever cut it themselves) passes
 * through untouched.
 */
export async function ranged(request: Request, response: Response): Promise<Response> {
  const headers = new Headers(response.headers);
  headers.set('Accept-Ranges', 'bytes');
  const header = request.headers.get('Range');
  if (response.status !== 200 || header === null) {
    return new Response(response.body, { status: response.status, headers });
  }
  const body = await response.arrayBuffer();
  // The bytes below are as decoded; they go out as they are.
  headers.delete('Content-Encoding');
  const range = byteRange(header, body.byteLength);
  if (range === null) {
    headers.set('Content-Length', String(body.byteLength));
    return new Response(body, { status: 200, headers });
  }
  if (range === 'unsatisfiable') {
    headers.delete('Content-Length');
    headers.set('Content-Range', `bytes */${body.byteLength}`);
    return new Response(null, { status: 416, headers });
  }
  headers.set('Content-Range', `bytes ${range.start}-${range.end}/${body.byteLength}`);
  headers.set('Content-Length', String(range.end - range.start + 1));
  return new Response(body.slice(range.start, range.end + 1), { status: 206, headers });
}
