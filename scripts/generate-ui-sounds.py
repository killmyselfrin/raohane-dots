#!/usr/bin/env python3
"""Generate tiny Raohane-owned UI feedback WAVs in the user cache.

The tones are deliberately short and quiet. Keeping them generated avoids a
system sound-theme dependency and keeps the source release text-friendly.
"""

from __future__ import annotations

import argparse
import math
import pathlib
import struct
import wave

SAMPLE_RATE = 48_000


def envelope(t: float, duration: float, attack: float = 0.008, release: float = 2.6) -> float:
    attack_gain = min(1.0, t / max(attack, 0.001))
    release_gain = max(0.0, 1.0 - t / duration) ** release
    return attack_gain * release_gain


def write_tone(path: pathlib.Path, duration: float, sample) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    frame_count = int(SAMPLE_RATE * duration)
    with wave.open(str(path), "wb") as output:
        output.setnchannels(1)
        output.setsampwidth(2)
        output.setframerate(SAMPLE_RATE)
        frames = bytearray()
        for index in range(frame_count):
            t = index / SAMPLE_RATE
            value = max(-1.0, min(1.0, float(sample(t, duration))))
            frames.extend(struct.pack("<h", int(value * 32767)))
        output.writeframes(frames)


def generate(directory: pathlib.Path) -> None:
    write_tone(
        directory / "ui-tap.wav",
        0.060,
        lambda t, d: envelope(t, d) * 0.19 * (
            math.sin(2 * math.pi * 880 * t)
            + 0.22 * math.sin(2 * math.pi * 1320 * t)
        ),
    )

    write_tone(
        directory / "ui-navigate.wav",
        0.085,
        lambda t, d: envelope(t, d, 0.010, 2.2) * 0.16 * (
            math.sin(2 * math.pi * (620 + 140 * t / d) * t)
            + 0.18 * math.sin(2 * math.pi * 980 * t)
        ),
    )

    def confirm(t: float, duration: float) -> float:
        gain = envelope(t, duration, 0.012, 2.0)
        value = 0.12 * math.sin(2 * math.pi * 660 * t)
        if t > 0.035:
            shifted = t - 0.035
            value += 0.14 * math.sin(2 * math.pi * 880 * shifted)
        return gain * value

    write_tone(directory / "ui-confirm.wav", 0.145, confirm)


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("directory")
    args = parser.parse_args()
    generate(pathlib.Path(args.directory).expanduser())
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
