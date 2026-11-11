#!/usr/bin/env python3
"""Encodes the music tracks for the site and lists them for the game.

    python3 tools/encode-music.py ~/Rime/pachinko/music

The sources are Suno WAVs kept outside the repo (see SOURCES.md next to them). Each
one is trimmed of leading and trailing silence, brought to TARGET_LUFS so every track
sits at one level, and encoded to Ogg Vorbis at about 80 kbps as
web/music/<name>.<hash>.ogg. The hash names a file by its bytes, so the Worker can
let browsers cache it forever. data/music.json lists each set's files in play order.

The tracks are fetched at run time (scripts/autoload/sfx.gd), never packed into the
.pck, so a player only downloads the track they hear.
"""
import hashlib
import json
import re
import shutil
import subprocess
import sys
import tempfile
from pathlib import Path

# Set -> sources in play order. "run" plays during waves and the cash-out choice,
# alternating the v6 and v6-wild synthwave takes; "lounge" plays on the menu and results.
SETS = {
    "run": ["synth-a", "synth-wild-a", "synth-b", "synth-wild-b"],
    "lounge": ["vapor-wild-a", "vapor-wild-b"],
}
# With Sfx.MUSIC_DB (-6) the music plays at about -24 LUFS: under the effects, but
# audible. Much quieter (about -37.5 LUFS) and sparse tracks vanish under play.
TARGET_LUFS = -18.0
BITRATE = "80k"
OUT = Path("web/music")
INDEX = Path("data/music.json")


def ffmpeg(*args):
    return subprocess.run(["ffmpeg", "-hide_banner", "-nostats", "-y", *args],
                          check=True, capture_output=True, text=True)


def loudness(path):
    err = ffmpeg("-i", str(path), "-af", "ebur128", "-f", "null", "-").stderr
    return float(re.findall(r"I:\s+(-?[\d.]+) LUFS", err)[-1])


def duration(path):
    out = subprocess.run(["ffprobe", "-v", "error", "-show_entries", "format=duration",
                          "-of", "csv=p=0", str(path)], check=True, capture_output=True, text=True)
    return float(out.stdout)


def encode(src, tmp):
    trimmed = tmp / f"{src.stem}.trim.wav"
    edge = "silenceremove=start_periods=1:start_threshold=-60dB:start_silence=0.05"
    ffmpeg("-i", str(src), "-af", f"{edge},areverse,{edge},areverse", str(trimmed))
    gain = TARGET_LUFS - loudness(trimmed)
    end = duration(trimmed)
    staged = tmp / f"{src.stem}.ogg"
    ffmpeg("-i", str(trimmed), "-af",
           f"volume={gain:.2f}dB,afade=t=in:d=0.05,afade=t=out:st={end - 1.5:.2f}:d=1.5",
           "-c:a", "libvorbis", "-b:a", BITRATE, "-fflags", "+bitexact", "-flags:a", "+bitexact",
           str(staged))
    digest = hashlib.sha256(staged.read_bytes()).hexdigest()[:10]
    name = f"{src.stem}.{digest}.ogg"
    shutil.move(staged, OUT / name)
    print(f"{name}: {end:.1f} s, {gain:+.1f} dB, {(OUT / name).stat().st_size / 1048576:.2f} MB")
    return name


def main():
    if len(sys.argv) != 2:
        sys.exit(__doc__)
    src_dir = Path(sys.argv[1]).expanduser()
    OUT.mkdir(parents=True, exist_ok=True)
    for old in OUT.glob("*.ogg"):
        old.unlink()
    index = {}
    with tempfile.TemporaryDirectory() as tmp:
        for set_name, stems in SETS.items():
            index[set_name] = [encode(src_dir / f"{stem}.wav", Path(tmp)) for stem in stems]
    INDEX.write_text(json.dumps(index, indent=2) + "\n")
    print("wrote", INDEX)


if __name__ == "__main__":
    main()
