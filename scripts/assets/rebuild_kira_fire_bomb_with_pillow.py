#!/usr/bin/env python3
from __future__ import annotations

from pathlib import Path

from PIL import Image


ROOT = Path(__file__).resolve().parents[2]
SOURCE = ROOT / "assets/projectiles/kira_fire_bomb_review/generated_source/kira_fire_bomb_imagegen_source_chromakey.png"
ALPHA_SOURCE = ROOT / "assets/projectiles/kira_fire_bomb_review/generated_source/kira_fire_bomb_source_alpha_pillow.png"
PREVIEW = ROOT / "assets/projectiles/kira_fire_bomb_review/kira_fire_bomb_preview.png"
FLY_DIR = ROOT / "assets/projectiles/fireball_medium"
BURST_DIR = ROOT / "assets/projectiles/fire_ability_burst"

FRAME_SIZE = (200, 200)
FLY_TARGET_MAX = (72, 60)
BURST_TARGET_MAX = (150, 112)

FLY_CENTERS_X = [94, 235, 376, 519, 661]
FLY_CENTERS_Y = [103, 257]
BURST_CENTERS = [
    (130, 620),
    (376, 620),
    (618, 620),
    (852, 620),
    (1088, 620),
    (1305, 620),
    (143, 843),
    (374, 843),
    (617, 843),
    (855, 843),
    (1093, 843),
    (1306, 843),
]


def remove_green_key(image: Image.Image) -> Image.Image:
    image = image.convert("RGBA")
    pixels = image.load()
    for y in range(image.height):
        for x in range(image.width):
            r, g, b, a = pixels[x, y]
            if a == 0:
                pixels[x, y] = (0, 0, 0, 0)
                continue
            if g > 80 and g > r * 1.08 and g > b * 1.08:
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


def resize_to_fit(image: Image.Image, max_size: tuple[int, int]) -> Image.Image:
    scale = min(max_size[0] / image.width, max_size[1] / image.height, 1.0)
    size = (max(1, round(image.width * scale)), max(1, round(image.height * scale)))
    return image.resize(size, Image.Resampling.NEAREST)


def make_frame(
    source: Image.Image,
    center: tuple[int, int],
    crop_radius: tuple[int, int],
    max_size: tuple[int, int],
) -> Image.Image:
    cx, cy = center
    rx, ry = crop_radius
    crop = source.crop((max(0, cx - rx), max(0, cy - ry), min(source.width, cx + rx), min(source.height, cy + ry)))
    asset = resize_to_fit(trim(crop), max_size)
    frame = Image.new("RGBA", FRAME_SIZE, (0, 0, 0, 0))
    frame.alpha_composite(asset, ((FRAME_SIZE[0] - asset.width) // 2, (FRAME_SIZE[1] - asset.height) // 2))
    return clear_transparent_rgb(frame)


def write_preview(fly_frames: list[Image.Image], burst_frames: list[Image.Image]) -> None:
    cell_w, cell_h = 100, 100
    preview = Image.new("RGBA", (cell_w * 10, cell_h * 5), (26, 24, 22, 255))
    for index, frame in enumerate(fly_frames):
        small = frame.resize((cell_w, cell_h), Image.Resampling.NEAREST)
        preview.alpha_composite(small, ((index % 10) * cell_w, (index // 10) * cell_h))
    for index, frame in enumerate(burst_frames):
        small = frame.resize((cell_w, cell_h), Image.Resampling.NEAREST)
        preview.alpha_composite(small, ((index % 6) * cell_w, (3 + index // 6) * cell_h))
    PREVIEW.parent.mkdir(parents=True, exist_ok=True)
    preview.resize((preview.width * 2, preview.height * 2), Image.Resampling.NEAREST).save(PREVIEW)


def main() -> None:
    if not SOURCE.exists():
        raise FileNotFoundError(f"Missing generated fire bomb source: {SOURCE}")
    FLY_DIR.mkdir(parents=True, exist_ok=True)
    BURST_DIR.mkdir(parents=True, exist_ok=True)

    alpha_source = remove_green_key(Image.open(SOURCE).convert("RGBA"))
    ALPHA_SOURCE.parent.mkdir(parents=True, exist_ok=True)
    alpha_source.save(ALPHA_SOURCE)

    source_fly_frames: list[Image.Image] = []
    for center_y in FLY_CENTERS_Y:
        for center_x in FLY_CENTERS_X:
            frame = make_frame(alpha_source, (center_x, center_y), (86, 72), FLY_TARGET_MAX)
            source_fly_frames.append(frame)

    fly_frames: list[Image.Image] = []
    for index in range(30):
        frame = source_fly_frames[index % len(source_fly_frames)]
        frame.save(FLY_DIR / f"img_{index}.png")
        fly_frames.append(frame)

    burst_frames: list[Image.Image] = []
    for index, center in enumerate(BURST_CENTERS):
        frame = make_frame(alpha_source, center, (120, 110), BURST_TARGET_MAX)
        frame.save(BURST_DIR / f"img_{index}.png")
        burst_frames.append(frame)

    write_preview(fly_frames, burst_frames)


if __name__ == "__main__":
    main()
