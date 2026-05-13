#!/usr/bin/env python3
from __future__ import annotations

from pathlib import Path

from PIL import Image


ROOT = Path(__file__).resolve().parents[2]
SOURCE = ROOT / "assets/projectiles/kira_fireball_review/generated_source/kira_fireball_imagegen_source_chromakey.png"
ALPHA_SOURCE = ROOT / "assets/projectiles/kira_fireball_review/generated_source/kira_fireball_source_alpha_pillow.png"
PREVIEW = ROOT / "assets/projectiles/kira_fireball_review/kira_fireball_primary_preview.png"
OUTPUT_DIR = ROOT / "assets/projectiles/fireball"

FRAME_SIZE = (200, 200)
TARGET_MAX_SIZE = (48, 42)
KEY_GREEN_MIN = 80

CENTERS_X = [76, 213, 354, 493, 635, 779, 925, 1073, 1232, 1393]
CENTERS_Y = [153, 315]
CROP_RADIUS = (76, 58)


def remove_green_key(image: Image.Image) -> Image.Image:
    image = image.convert("RGBA")
    pixels = image.load()
    for y in range(image.height):
        for x in range(image.width):
            r, g, b, a = pixels[x, y]
            if a == 0:
                pixels[x, y] = (0, 0, 0, 0)
                continue
            if g > KEY_GREEN_MIN and g > r * 1.08 and g > b * 1.08:
                pixels[x, y] = (0, 0, 0, 0)
            elif g > r * 1.05 and g > b * 1.05:
                pixels[x, y] = (r, min(g, int(max(r, b) * 0.72)), b, a)
    return clear_transparent_rgb(image)


def clear_transparent_rgb(image: Image.Image) -> Image.Image:
    image = image.convert("RGBA")
    pixels = image.load()
    for y in range(image.height):
        for x in range(image.width):
            r, g, b, a = pixels[x, y]
            if a == 0:
                pixels[x, y] = (0, 0, 0, 0)
    return image


def trim(image: Image.Image) -> Image.Image:
    bbox = image.getchannel("A").getbbox()
    if bbox is None:
        return Image.new("RGBA", (1, 1), (0, 0, 0, 0))
    return image.crop(bbox)


def resize_to_target(image: Image.Image) -> Image.Image:
    scale = min(TARGET_MAX_SIZE[0] / image.width, TARGET_MAX_SIZE[1] / image.height)
    size = (max(1, round(image.width * scale)), max(1, round(image.height * scale)))
    return image.resize(size, Image.Resampling.NEAREST)


def crop_cell(source: Image.Image, center_x: int, center_y: int) -> Image.Image:
    radius_x, radius_y = CROP_RADIUS
    box = (
        max(0, center_x - radius_x),
        max(0, center_y - radius_y),
        min(source.width, center_x + radius_x),
        min(source.height, center_y + radius_y),
    )
    return trim(source.crop(box))


def make_frame(source: Image.Image, center_x: int, center_y: int) -> Image.Image:
    fireball = resize_to_target(crop_cell(source, center_x, center_y))
    canvas = Image.new("RGBA", FRAME_SIZE, (0, 0, 0, 0))
    x = (FRAME_SIZE[0] - fireball.width) // 2
    y = (FRAME_SIZE[1] - fireball.height) // 2
    canvas.alpha_composite(fireball, (x, y))
    return clear_transparent_rgb(canvas)


def write_preview(frames: list[Image.Image]) -> None:
    scale = 2
    cell_w, cell_h = FRAME_SIZE[0] // 2, FRAME_SIZE[1] // 2
    preview = Image.new("RGBA", (cell_w * 10, cell_h * 3), (26, 24, 22, 255))
    for index, frame in enumerate(frames):
        small = frame.resize((cell_w, cell_h), Image.Resampling.NEAREST)
        x = (index % 10) * cell_w
        y = (index // 10) * cell_h
        preview.alpha_composite(small, (x, y))
    PREVIEW.parent.mkdir(parents=True, exist_ok=True)
    preview.resize((preview.width * scale, preview.height * scale), Image.Resampling.NEAREST).save(PREVIEW)


def main() -> None:
    if not SOURCE.exists():
        raise FileNotFoundError(f"Missing generated fireball source: {SOURCE}")
    OUTPUT_DIR.mkdir(parents=True, exist_ok=True)
    source = Image.open(SOURCE).convert("RGBA")
    alpha_source = remove_green_key(source)
    ALPHA_SOURCE.parent.mkdir(parents=True, exist_ok=True)
    alpha_source.save(ALPHA_SOURCE)

    frames: list[Image.Image] = []
    source_frames: list[Image.Image] = []
    for center_y in CENTERS_Y:
        for center_x in CENTERS_X:
            source_frames.append(make_frame(alpha_source, center_x, center_y))

    for index in range(30):
        frame = source_frames[index % len(source_frames)]
        frame.save(OUTPUT_DIR / f"img_{index}.png")
        frames.append(frame)
    write_preview(frames)


if __name__ == "__main__":
    main()
