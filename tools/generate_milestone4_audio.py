#!/usr/bin/env python3
"""Generate lightweight milestone 4 game audio cues as WAV files."""

from __future__ import annotations

import math
import random
import wave
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
SFX_DIR = ROOT / "assets" / "sfx"
MUSIC_DIR = ROOT / "assets" / "music" / "milestone4"
SAMPLE_RATE = 44_100


def clamp(value: float) -> float:
    return max(-1.0, min(1.0, value))


def env(index: int, total: int, attack: float = 0.01, release: float = 0.08) -> float:
    t = index / SAMPLE_RATE
    duration = total / SAMPLE_RATE
    if t < attack:
        return t / attack
    if t > duration - release:
        return max(0.0, (duration - t) / release)
    return 1.0


def write_wav(path: Path, samples: list[float]) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    peak = max(0.001, max(abs(sample) for sample in samples))
    gain = 0.86 / peak
    with wave.open(str(path), "wb") as wav:
        wav.setnchannels(1)
        wav.setsampwidth(2)
        wav.setframerate(SAMPLE_RATE)
        data = bytearray()
        for sample in samples:
            value = int(clamp(sample * gain) * 32767)
            data += value.to_bytes(2, "little", signed=True)
        wav.writeframes(data)


def tone(path: Path, duration: float, start_hz: float, end_hz: float, amp: float = 0.5, noise: float = 0.0) -> None:
    total = int(duration * SAMPLE_RATE)
    rng = random.Random(path.name)
    phase = 0.0
    samples: list[float] = []
    for i in range(total):
        ratio = i / max(1, total - 1)
        hz = start_hz + (end_hz - start_hz) * ratio
        phase += math.tau * hz / SAMPLE_RATE
        shaped = math.sin(phase) + 0.35 * math.sin(phase * 2.01)
        shaped += noise * rng.uniform(-1.0, 1.0)
        samples.append(shaped * amp * env(i, total))
    write_wav(path, samples)


def burst(path: Path, duration: float, base_hz: float, amp: float = 0.6, crackle: float = 0.4) -> None:
    total = int(duration * SAMPLE_RATE)
    rng = random.Random(path.name)
    samples: list[float] = []
    for i in range(total):
        t = i / SAMPLE_RATE
        falloff = math.exp(-t * 9.0)
        body = math.sin(math.tau * base_hz * t) * falloff
        click = rng.uniform(-1.0, 1.0) * crackle * falloff
        samples.append((body + click) * amp * env(i, total, 0.002, 0.08))
    write_wav(path, samples)


def chord(path: Path, duration: float, notes: tuple[float, ...], amp: float = 0.25, pulse: float = 0.0) -> None:
    total = int(duration * SAMPLE_RATE)
    samples: list[float] = []
    phases = [0.0 for _ in notes]
    for i in range(total):
        t = i / SAMPLE_RATE
        value = 0.0
        for note_index, hz in enumerate(notes):
            phases[note_index] += math.tau * hz / SAMPLE_RATE
            value += math.sin(phases[note_index]) + 0.18 * math.sin(phases[note_index] * 2.0)
        tremolo = 1.0 + pulse * math.sin(math.tau * 2.0 * t)
        samples.append((value / len(notes)) * amp * tremolo * env(i, total, 0.05, 0.2))
    write_wav(path, samples)


def rhythm_loop(path: Path, duration: float, root_hz: float, accent_hz: float) -> None:
    total = int(duration * SAMPLE_RATE)
    rng = random.Random(path.name)
    samples: list[float] = []
    for i in range(total):
        t = i / SAMPLE_RATE
        beat = (t * 2.0) % 1.0
        pulse = math.exp(-beat * 9.0)
        drone = math.sin(math.tau * root_hz * t) * 0.22
        fifth = math.sin(math.tau * root_hz * 1.5 * t) * 0.12
        shimmer = math.sin(math.tau * accent_hz * t) * 0.08 * (0.5 + 0.5 * math.sin(math.tau * 0.25 * t))
        grit = rng.uniform(-1.0, 1.0) * 0.04 * pulse
        samples.append((drone + fifth + shimmer + grit) * env(i, total, 0.2, 0.3))
    write_wav(path, samples)


def main() -> None:
    for directory in (SFX_DIR, MUSIC_DIR):
        directory.mkdir(parents=True, exist_ok=True)

    tone(SFX_DIR / "ui_start.wav", 0.35, 520, 1040, 0.42, 0.02)
    tone(SFX_DIR / "attack_1.wav", 0.16, 420, 180, 0.62, 0.18)
    tone(SFX_DIR / "attack_2.wav", 0.18, 520, 210, 0.66, 0.2)
    tone(SFX_DIR / "attack_3.wav", 0.24, 680, 140, 0.78, 0.28)
    burst(SFX_DIR / "enemy_hit.wav", 0.16, 170, 0.72, 0.55)
    burst(SFX_DIR / "enemy_death.wav", 0.42, 120, 0.78, 0.65)
    tone(SFX_DIR / "dodge.wav", 0.18, 260, 620, 0.45, 0.25)
    burst(SFX_DIR / "player_hurt.wav", 0.22, 100, 0.62, 0.5)
    tone(SFX_DIR / "pyro_throw.wav", 0.24, 300, 820, 0.52, 0.22)
    burst(SFX_DIR / "pyro_skill.wav", 0.55, 82, 0.86, 0.8)
    tone(SFX_DIR / "hydro_cast.wav", 0.34, 760, 320, 0.48, 0.08)
    tone(SFX_DIR / "electro_strike.wav", 0.2, 1200, 260, 0.65, 0.35)
    tone(SFX_DIR / "checkpoint.wav", 0.6, 480, 960, 0.46, 0.01)
    chord(SFX_DIR / "area_clear.wav", 1.05, (392, 494, 659, 784), 0.34, 0.12)
    chord(SFX_DIR / "boss_defeat.wav", 1.2, (196, 247, 330, 392), 0.42, 0.08)
    burst(SFX_DIR / "boss_attack.wav", 0.4, 72, 0.78, 0.5)

    rhythm_loop(MUSIC_DIR / "ember_fields_loop.wav", 8.0, 98.0, 392.0)
    rhythm_loop(MUSIC_DIR / "boss_loop.wav", 8.0, 73.42, 293.66)
    rhythm_loop(MUSIC_DIR / "storm_peaks_loop.wav", 8.0, 110.0, 659.25)


if __name__ == "__main__":
    main()
