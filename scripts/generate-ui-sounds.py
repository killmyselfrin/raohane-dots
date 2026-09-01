#!/usr/bin/env python3
"""Generate soft Raohane-owned UI feedback WAVs in the user cache.

The feedback is intentionally subtle: short low-mid sine layers with smooth
attacks and dark decays. This avoids the sharp high-frequency chirps that get
tiring when repeated across the shell, while keeping Raohane independent from
system sound themes.
"""

from __future__ import annotations

import argparse
import math
import pathlib
import struct
import wave

SAMPLE_RATE = 48_000


def envelope(
    t: float,
    duration: float,
    attack: float = 0.006,
    decay: float = 4.2,
) -> float:
    """Smooth attack plus exponential/tapered release with no hard edges."""
    attack_position = min(1.0, t / max(attack, 0.001))
    attack_gain = math.sin(attack_position * math.pi / 2) ** 2
    release_position = min(1.0, t / max(duration, 0.001))
    release_gain = math.exp(-decay * release_position) * max(0.0, 1.0 - release_position)
    return attack_gain * release_gain


def sine(frequency: float, t: float, phase: float = 0.0) -> float:
    return math.sin(2 * math.pi * frequency * t + phase)


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
    # A very short, dark "tock". No bright partials above ~500 Hz.
    write_tone(
        directory / "ui-tap.wav",
        0.052,
        lambda t, d: envelope(t, d, 0.0045, 4.8) * (
            0.105 * sine(300, t)
            + 0.032 * sine(455, t, 0.35)
        ),
    )

    # Slightly rising but still restrained; intended for navigation between
    # pages/steps rather than sounding like a notification.
    write_tone(
        directory / "ui-navigate.wav",
        0.074,
        lambda t, d: envelope(t, d, 0.006, 4.0) * (
            0.085 * sine(350 + 55 * (t / d), t)
            + 0.026 * sine(520, t, 0.25)
        ),
    )

    # Confirmation is a soft two-stage resonance, not a melodic chime.
    def confirm(t: float, duration: float) -> float:
        value = envelope(t, duration, 0.007, 3.5) * (
            0.066 * sine(330, t)
            + 0.018 * sine(495, t, 0.3)
        )
        if t >= 0.034:
            shifted = t - 0.034
            value += envelope(shifted, duration - 0.034, 0.006, 4.2) * (
                0.052 * sine(410, shifted)
                + 0.014 * sine(560, shifted, 0.2)
            )
        return value

    write_tone(directory / "ui-confirm.wav", 0.118, confirm)


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("directory")
    args = parser.parse_args()
    generate(pathlib.Path(args.directory).expanduser())
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
