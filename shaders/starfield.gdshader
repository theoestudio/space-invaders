shader_type canvas_item;
// Deep-space backdrop behind the cabinet: drifting stars over a slow nebula.
// `fever` (0..1) warms it toward pink.

uniform float fever = 0.0;
uniform float aspect = 0.5625;

float hash(vec2 p) {
	p = fract(p * vec2(123.34, 456.21));
	p += dot(p, p + 45.32);
	return fract(p.x * p.y);
}

float noise(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	vec2 u = f * f * (3.0 - 2.0 * f);
	return mix(mix(hash(i), hash(i + vec2(1.0, 0.0)), u.x), mix(hash(i + vec2(0.0, 1.0)), hash(i + vec2(1.0, 1.0)), u.x), u.y);
}

float stars(vec2 uv, float scale, float speed) {
	vec2 p = uv * scale + vec2(0.0, -TIME * speed);
	vec2 cell = floor(p);
	vec2 f = fract(p) - 0.5;
	float h = hash(cell);
	if (h < 0.92) {
		return 0.0;
	}
	vec2 off = vec2(hash(cell + 7.1), hash(cell + 3.3)) - 0.5;
	float d = length(f - off * 0.6);
	float twinkle = 0.6 + 0.4 * sin(TIME * (2.0 + h * 5.0) + h * 40.0);
	return smoothstep(0.08, 0.0, d) * twinkle;
}

void fragment() {
	vec2 uv = vec2(UV.x * aspect, UV.y);
	float n = noise(uv * 2.2 + vec2(TIME * 0.01, TIME * 0.02)) * 0.6 + noise(uv * 5.0 - TIME * 0.015) * 0.4;
	vec3 deep = vec3(0.025, 0.02, 0.06);
	vec3 nebula = mix(vec3(0.16, 0.05, 0.28), vec3(0.4, 0.06, 0.24), fever);
	vec3 col = deep + nebula * pow(n, 2.2) * 0.55;
	col += vec3(0.0, 0.25, 0.32) * pow(noise(uv * 1.3 + 4.0), 3.0) * 0.4;
	float s = stars(uv, 60.0, 0.4) + stars(uv, 30.0, 0.8) * 0.8 + stars(uv, 14.0, 1.6) * 0.6;
	col += vec3(0.85, 0.9, 1.0) * s;
	COLOR = vec4(col, 1.0);
}
