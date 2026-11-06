#!/usr/bin/env python3
"""Renders every sound in assets/audio/ from code, so the set is reproducible and
license-free. Run from the repo root: python3 tools/make-sounds.py

Effects are 16-bit mono WAV. The music loop is rendered on a circular buffer so it
wraps without a seam, then encoded to Ogg Vorbis with ffmpeg.
"""
import subprocess
import wave
from pathlib import Path

import numpy as np

SR = 44100
OUT = Path("assets/audio")
RNG = np.random.default_rng(21)


def t_axis(seconds):
    return np.arange(int(SR * seconds)) / SR


def resonator(x, freq, q):
    """Two-pole band-pass: turns a noise burst into a pitched knock."""
    w = 2 * np.pi * freq / SR
    r = np.exp(-w / (2 * q))
    a1, a2 = -2 * r * np.cos(w), r * r
    y = np.zeros_like(x)
    for i in range(len(x)):
        y[i] = x[i] - a1 * y[i - 1] - a2 * y[i - 2] if i >= 2 else x[i]
    return y * (1 - r)


def lowpass(x, cutoff):
    a = np.exp(-2 * np.pi * cutoff / SR)
    y = np.zeros_like(x)
    acc = 0.0
    for i in range(len(x)):
        acc = (1 - a) * x[i] + a * acc
        y[i] = acc
    return y


def norm(x, peak):
    return x / (np.max(np.abs(x)) + 1e-9) * peak


def fade(x, ms=3):
    n = int(SR * ms / 1000)
    x[:n] *= np.linspace(0, 1, n)
    x[-n:] *= np.linspace(1, 0, n)
    return x


def write_wav(name, x):
    OUT.mkdir(parents=True, exist_ok=True)
    data = (np.clip(x, -1, 1) * 32767).astype("<i2")
    with wave.open(str(OUT / name), "wb") as w:
        w.setnchannels(1)
        w.setsampwidth(2)
        w.setframerate(SR)
        w.writeframes(data.tobytes())


def hz(midi):
    return 440.0 * 2 ** ((midi - 69) / 12)


def add(*xs):
    """Sums signals of different lengths, padding the shorter ones with silence."""
    out = np.zeros(max(len(x) for x in xs))
    for x in xs:
        out[: len(x)] += x
    return out


def mix_at(out, x, at):
    s = int(SR * at)
    end = min(len(out), s + len(x))
    out[s:end] += x[: end - s]
    return out


def sweep(f0, f1, seconds, shape="sine", curve=0.12):
    t = t_axis(seconds)
    f = f1 + (f0 - f1) * np.exp(-t / curve)
    ph = 2 * np.pi * np.cumsum(f) / SR
    if shape == "square":
        return np.sign(np.sin(ph)) * 0.6 + np.sin(ph) * 0.4
    if shape == "saw":
        return 2 * ((ph / (2 * np.pi)) % 1.0) - 1
    return np.sin(ph)


METAL = ((1, 1, 0.05), (2.76, 0.6, 0.035), (5.4, 0.4, 0.025), (8.93, 0.25, 0.015))


def bell(base, seconds, partials=((1, 1, 0.5), (2.0, 0.4, 0.3), (3.01, 0.25, 0.2), (4.2, 0.12, 0.12))):
    t = t_axis(seconds)
    x = np.zeros_like(t)
    for ratio, amp, dec in partials:
        x += amp * np.sin(2 * np.pi * base * ratio * t + RNG.uniform(0, 6.28)) * np.exp(-t / dec)
    a = int(SR * 0.002)
    x[:a] *= np.linspace(0, 1, a)
    return x


def tick(base=4200, seconds=0.06):
    """A steel ball glancing off a brass pin."""
    return bell(base, seconds, METAL)


def noise_burst(seconds, decay):
    t = t_axis(seconds)
    return RNG.standard_normal(len(t)) * np.exp(-t / decay)


def arpeggio(notes, gap, tail, amp=0.8, partials=None):
    out = np.zeros(int(SR * (gap * len(notes) + tail)))
    for i, f in enumerate(notes):
        b = bell(f, tail, partials) if partials else bell(f, tail)
        mix_at(out, b * amp, gap * i)
    return out


def rattle(n, seconds, spread):
    """Many balls clattering: a scatter of pin ticks."""
    out = np.zeros(int(SR * seconds))
    for _ in range(n):
        at = abs(RNG.normal(0, spread))
        if at < seconds - 0.08:
            mix_at(out, tick(RNG.uniform(3000, 6000), 0.06) * RNG.uniform(0.2, 0.7), at)
    return out


def sounds():
    s = {}
    s["pin"] = fade(norm(tick(), 0.6))
    s["fire"] = fade(norm(sweep(1900, 420, 0.16, "square", 0.05) * np.exp(-t_axis(0.16) / 0.06), 0.4))
    s["dry"] = fade(norm(resonator(noise_burst(0.07, 0.004), 900, 6), 0.4))
    s["zap"] = fade(norm(sweep(180, 520, 0.18, "saw", 0.08) * np.exp(-t_axis(0.18) / 0.07), 0.3))
    clash = add(resonator(noise_burst(0.25, 0.01), 2500, 3), 0.3 * bell(hz(96), 0.25, METAL))
    s["clash"] = fade(norm(clash, 0.5))
    dent = resonator(noise_burst(0.18, 0.006), 700, 8) + resonator(noise_burst(0.18, 0.006), 1500, 8) * 0.6
    s["dent"] = fade(norm(dent * np.exp(-t_axis(0.18) / 0.05), 0.55))
    kill = resonator(noise_burst(0.4, 0.03), 900, 2) * np.exp(-t_axis(0.4) / 0.09)
    kill += 0.5 * sweep(900, 140, 0.4, "square", 0.06) * np.exp(-t_axis(0.4) / 0.08)
    kill += 0.25 * bell(hz(88), 0.4, METAL)
    s["kill"] = fade(norm(kill, 0.7))
    hit = resonator(noise_burst(1.0, 0.08), 260, 1.5) * 1.5 + 0.6 * sweep(220, 50, 1.0, "saw", 0.15) * np.exp(-t_axis(1.0) / 0.2)
    hit += rattle(26, 1.0, 0.25)
    s["hit"] = fade(norm(hit, 0.8))
    s["shield"] = fade(norm(arpeggio([hz(m) for m in (84, 88, 91)], 0.03, 0.8, partials=METAL), 0.5))
    t = t_axis(0.9)
    s["saucer"] = fade(norm(np.sin(2 * np.pi * np.cumsum(700 + 160 * np.sin(2 * np.pi * 9 * t)) / SR) * np.sin(np.pi * t / 0.9) ** 0.5, 0.25))
    s["jackpot"] = fade(norm(add(arpeggio([hz(m) for m in (79, 83, 86, 91)], 0.05, 0.5), rattle(20, 0.9, 0.2)), 0.7))
    s["start"] = fade(norm(arpeggio([hz(81), hz(88)], 0.07, 0.6), 0.6))
    s["pocket"] = fade(norm(bell(hz(86), 0.6), 0.55))
    s["catch"] = fade(norm(add(bell(2600, 0.18, METAL), 0.6 * bell(3900, 0.12, METAL)), 0.5))
    s["tulip"] = fade(norm(resonator(noise_burst(0.1, 0.003), 1800, 10) + resonator(noise_burst(0.1, 0.003), 3400, 10), 0.45))
    t = t_axis(0.25)
    s["drop"] = fade(norm(np.sin(2 * np.pi * 70 * t) * np.exp(-t / 0.06) + 0.2 * resonator(noise_burst(0.25, 0.01), 140, 2), 0.6))
    spin = np.zeros(int(SR * 0.7))
    at = 0.0
    gap = 0.05
    while at < 0.65:
        mix_at(spin, resonator(noise_burst(0.03, 0.002), 2200, 12) * 0.6, at)
        at += gap
        gap = max(gap * 0.9, 0.018)
    s["spin"] = fade(norm(spin + 0.15 * sweep(300, 900, 0.7, "saw", 0.3), 0.4))
    reel = resonator(noise_burst(0.2, 0.006), 380, 4) * 1.4 + resonator(noise_burst(0.2, 0.003), 2800, 10) * 0.5
    s["reel"] = fade(norm(reel, 0.55))
    t = t_axis(0.9)
    reach = np.sin(2 * np.pi * np.cumsum(hz(76) * 2 ** (t * 1.2 / 1.0)) / SR) * np.sin(np.pi * t / 0.9)
    reach *= 0.6 + 0.4 * np.sin(2 * np.pi * 14 * t)
    s["reach"] = fade(norm(reach, 0.45))
    s["prize"] = fade(norm(arpeggio([hz(m) for m in (76, 79, 84, 88)], 0.07, 0.7), 0.6))
    fever = arpeggio([hz(m) for m in (72, 76, 79, 84, 88, 91, 96)], 0.06, 1.2)
    fever = np.concatenate([fever, np.zeros(int(SR * 0.6))])
    chord = sum(bell(hz(m), 1.6) for m in (72, 76, 79, 84)) * 0.5
    mix_at(fever, chord, 0.45)
    mix_at(fever, rattle(40, 1.6, 0.5), 0.0)
    s["fever"] = fade(norm(fever, 0.8))
    s["clear"] = fade(norm(arpeggio([hz(m) for m in (72, 76, 79, 84)], 0.1, 1.2), 0.65))
    s["bust"] = fade(norm(add(arpeggio([hz(m) for m in (67, 63, 60, 55)], 0.18, 1.2), 0.4 * sweep(300, 60, 1.6, "saw", 0.5) * np.exp(-t_axis(1.6) / 0.6)), 0.6))
    cash = np.zeros(int(SR * 1.8))
    mix_at(cash, arpeggio([hz(m) for m in (79, 84, 88, 91, 96)], 0.08, 1.0), 0.0)
    mix_at(cash, rattle(70, 1.7, 0.45), 0.05)
    s["cashout"] = fade(norm(cash, 0.75))
    s["select"] = fade(norm(bell(hz(96), 0.12, ((1, 1, 0.03), (2.0, 0.3, 0.02))), 0.25))
    return s


def music(path):
    """32 s loop at 120 bpm: a soft synthwave groove in A minor."""
    bpm = 120
    beat = 60 / bpm
    bars = 16
    loop = bars * 4 * beat
    n = int(SR * loop)
    buf = np.zeros(n)

    def put(x, at):
        idx = (int(SR * at) + np.arange(len(x))) % n
        np.add.at(buf, idx, x)

    prog = [(57, [69, 72, 76]), (53, [65, 69, 72]), (48, [67, 72, 76]), (55, [67, 71, 74])]  # Am F C G
    for bar in range(bars):
        root, chord = prog[(bar // 2) % 4]
        t0 = bar * 4 * beat
        # Bass: eighth notes, a soft square through a low-pass.
        for e in range(8):
            f = hz(root - 12 + (12 if e % 4 == 3 else 0))
            tt = t_axis(beat / 2)
            note = (np.sign(np.sin(2 * np.pi * f * tt)) * 0.5 + np.sin(2 * np.pi * f * tt)) * np.exp(-tt / 0.18)
            put(lowpass(note, 700) * 0.5, t0 + e * beat / 2)
        # Pad: detuned saws under a slow swell.
        tt = t_axis(4 * beat)
        pad = np.zeros_like(tt)
        for m in chord:
            for cents in (-7, 7):
                f = hz(m) * 2 ** (cents / 1200)
                pad += 2 * ((f * tt) % 1.0) - 1
        pad = lowpass(pad, 1400) * np.sin(np.pi * tt / (4 * beat)) ** 0.8
        put(pad * 0.07, t0)
        # Arp: sixteenths over the chord, every other bar pair.
        if bar >= 4:
            notes = chord + [chord[0] + 12]
            for e in range(16):
                f = hz(notes[(e * 3) % len(notes)] + 12)
                tt = t_axis(beat / 4)
                put(np.sin(2 * np.pi * f * tt) * np.exp(-tt / 0.07) * 0.08, t0 + e * beat / 4)
        # Kick on the beat, a closed hat on the offbeat.
        for b in range(4):
            tt = t_axis(0.25)
            kick = np.sin(2 * np.pi * np.cumsum(50 + 110 * np.exp(-tt / 0.03)) / SR) * np.exp(-tt / 0.12)
            put(kick * 0.45, t0 + b * beat)
            hat = resonator(noise_burst(0.05, 0.008), 8000, 1.2)
            put(hat * 0.12, t0 + b * beat + beat / 2)
    buf = norm(buf, 0.55)
    tmp = OUT / "_music.wav"
    write_wav(tmp.name, buf)
    subprocess.run(["ffmpeg", "-y", "-loglevel", "error", "-i", str(tmp), "-c:a", "libvorbis",
                    "-q:a", "3", str(path)], check=True)
    tmp.unlink()


def main():
    for name, x in sounds().items():
        write_wav(f"{name}.wav", x)
    music(OUT / "music.ogg")
    print("wrote", sorted(p.name for p in OUT.iterdir()))


if __name__ == "__main__":
    main()
