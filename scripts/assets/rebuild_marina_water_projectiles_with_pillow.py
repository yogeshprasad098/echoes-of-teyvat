#!/usr/bin/env python3
from __future__ import annotations

from pathlib import Path

from PIL import Image, ImageOps


ROOT = Path(__file__).resolve().parents[2]
SOURCE = ROOT / "assets/projectiles/marina_water_review/generated_source/marina_water_projectiles_imagegen_source_chromakey.png"
ALPHA_SOURCE = ROOT / "assets/projectiles/marina_water_review/generated_source/marina_water_projectiles_source_alpha_pillow.png"
PREVIEW = ROOT / "assets/projectiles/marina_water_review/marina_water_projectiles_preview.png"
PRIMARY_DIR = ROOT / "assets/projectiles/waterball"
ABILITY_FLY_DIR = ROOT / "assets/projectiles/waterball_medium"
ABILITY_BURST_DIR = ROOT / "assets/projectiles/water_ability_burst"

FRAME_SIZE = (200, 200)
PRIMARY_TARGET_MAX = (48, 42)
ABILITY_FLY_TARGET_MAX = (78, 66)
ABILITY_BURST_TARGET_MAX = (150, 112)

PRIMARY_CENTERS = [
    (111, 91),
    (251, 91),
    (391, 91),
    (530, 91),
    (666, 91),
    (805, 91),
    (945, 91),
    (111, 207),
    (251, 207),
    (391, 207),
    (530, 207),
    (666, 207),
    (805, 207),
    (945, 207),
    (1084, 207),
    (1222, 207),
]
ABILITY_FLY_CENTERS_X = [130, 309, 486, 664, 841, 1017, 1194, 1371]
ABILITY_FLY_CENTERS_Y = [361, 532]
ABILITY_BURST_CENTERS = [
    (123, 744),
    (386, 744),
    (614, 744),
    (850, 744),
    (1097, 744),
    (1347, 744),
    (123, 895),
    (386, 895),
    (614, 895),
    (850, 895),
    (1097, 895),
    (1347, 895),
]


def clear_transparent_rgb(image: Image.Image) -> Image.Image:
    image = image.convert("RGBA")
    pixels = image.load()
    for y in range(image.height):
        for x in range(image.width):
            r, g, b, a = pixels[x, y]
            if a == 0:
                pixels[x, y] = (0, 0, 0, 0)
    return image


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
    mirror: bool = False,
) -> Image.Image:
    cx, cy = center
    rx, ry = crop_radius
    crop = source.crop((max(0, cx - rx), max(0, cy - ry), min(source.width, cx + rx), min(source.height, cy + ry)))
    asset = resize_to_fit(trim(crop), max_size)
    if mirror:
        asset = ImageOps.mirror(asset)
    frame = Image.new("RGBA", FRAME_SIZE, (0, 0, 0, 0))
    frame.alpha_composite(asset, ((FRAME_SIZE[0] - asset.width) // 2, (FRAME_SIZE[1] - asset.height) // 2))
    return clear_transparent_rgb(frame)


def write_looped_frames(frames: list[Image.Image], output_dir: Path, count: int) -> list[Image.Image]:
    output_dir.mkdir(parents=True, exist_ok=True)
    written: list[Image.Image] = []
    for index in range(count):
        frame = frames[index % len(frames)]
        frame.save(output_dir / f"img_{index}.png")
        written.append(frame)
    return written


def write_preview(primary_frames: list[Image.Image], fly_frames: list[Image.Image], burst_frames: list[Image.Image]) -> None:
    cell_w, cell_h = 100, 100
    preview = Image.new("RGBA", (cell_w * 10, cell_h * 8), (24, 25, 28, 255))
    for index, frame in enumerate(primary_frames):
        preview.alpha_composite(frame.resize((cell_w, cell_h), Image.Resampling.NEAREST), ((index % 10) * cell_w, (index // 10) * cell_h))
    for index, frame in enumerate(fly_frames):
        preview.alpha_composite(frame.resize((cell_w, cell_h), Image.Resampling.NEAREST), ((index % 10) * cell_w, (3 + index // 10) * cell_h))
    for index, frame in enumerate(burst_frames):
        preview.alpha_composite(frame.resize((cell_w, cell_h), Image.Resampling.NEAREST), ((index % 6) * cell_w, (6 + index // 6) * cell_h))
    PREVIEW.parent.mkdir(parents=True, exist_ok=True)
    preview.resize((preview.width * 2, preview.height * 2), Image.Resampling.NEAREST).save(PREVIEW)


def main() -> None:
    if not SOURCE.exists():
        raise FileNotFoundError(f"Missing generated Marina water projectile source: {SOURCE}")

    alpha_source = remove_green_key(Image.open(SOURCE).convert("RGBA"))
    ALPHA_SOURCE.parent.mkdir(parents=True, exist_ok=True)
    alpha_source.save(ALPHA_SOURCE)

    primary_source_frames = [
        make_frame(alpha_source, center, (64, 48), PRIMARY_TARGET_MAX, mirror=True)
        for center in PRIMARY_CENTERS
    ]
    ability_fly_source_frames = [
        make_frame(alpha_source, (center_x, center_y), (84, 72), ABILITY_FLY_TARGET_MAX, mirror=True)
        for center_y in ABILITY_FLY_CENTERS_Y
        for center_x in ABILITY_FLY_CENTERS_X
    ]
    ability_burst_frames = [
        make_frame(alpha_source, center, (130, 88), ABILITY_BURST_TARGET_MAX)
        for center in ABILITY_BURST_CENTERS
    ]

    primary_frames = write_looped_frames(primary_source_frames, PRIMARY_DIR, 30)
    fly_frames = write_looped_frames(ability_fly_source_frames, ABILITY_FLY_DIR, 30)
    for index, frame in enumerate(ability_burst_frames):
        ABILITY_BURST_DIR.mkdir(parents=True, exist_ok=True)
        frame.save(ABILITY_BURST_DIR / f"img_{index}.png")

    write_preview(primary_frames, fly_frames, ability_burst_frames)


if __name__ == "__main__":
    main()
