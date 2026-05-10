#!/usr/bin/env python3
from __future__ import annotations

import re
from pathlib import Path

from PIL import Image, ImageChops, ImageFilter


ROOT = Path(__file__).resolve().parents[2]
OUT_DIR = ROOT / "assets/characters/marina"
SOURCE = OUT_DIR / "generated_source/marina_clean_source_chromakey.png"
ALPHA_SOURCE = OUT_DIR / "generated_source/marina_clean_source_alpha_pillow.png"
PREVIEW = OUT_DIR / "generated_source/marina_rework_preview.png"
WORK_DIR = ROOT / "tmp/asset_generation/marina_clean/pillow_frames"

FRAME_WIDTH = 192
FRAME_HEIGHT = 96
CONTENT_HEIGHT = 92
OUTLINE = (26, 11, 16, 255)
KEY_THRESHOLD = 42
DESPILL_THRESHOLD = 28
FOOT_LIFT = 3


def parse_box(box: str) -> tuple[int, int, int, int]:
    match = re.fullmatch(r"(\d+)x(\d+)\+(\d+)\+(\d+)", box)
    if not match:
        raise ValueError(f"invalid crop box: {box}")
    width, height, x, y = map(int, match.groups())
    return x, y, x + width, y + height


def parse_resize(spec: str) -> tuple[int | None, int | None, bool]:
    limit = spec.endswith(">")
    if limit:
        spec = spec[:-1]
    if spec.startswith("x"):
        return None, int(spec[1:]), limit
    if "x" in spec:
        left, right = spec.split("x", 1)
        return int(left) if left else None, int(right) if right else None, limit
    return int(spec), None, limit


def remove_green_key(image: Image.Image) -> Image.Image:
    image = image.convert("RGBA")
    pixels = image.load()
    for y in range(image.height):
        for x in range(image.width):
            r, g, b, a = pixels[x, y]
            if a == 0:
                pixels[x, y] = (0, 0, 0, 0)
                continue
            green_delta = g - max(r, b)
            if g > 70 and green_delta > KEY_THRESHOLD and g > int(r * 1.18) and g > int(b * 1.18):
                pixels[x, y] = (0, 0, 0, 0)
            elif green_delta > DESPILL_THRESHOLD and g > r and g > b:
                replacement = int(max(r, b) * 0.72)
                pixels[x, y] = (r, min(g, replacement), b, a)
    return image


def trim(image: Image.Image) -> Image.Image:
    alpha = image.getchannel("A")
    bbox = alpha.getbbox()
    if bbox is None:
        return Image.new("RGBA", (1, 1), (0, 0, 0, 0))
    return image.crop(bbox)


def resize_like_magick(image: Image.Image, spec: str) -> Image.Image:
    width, height, limit = parse_resize(spec)
    current_w, current_h = image.size

    if width is None and height is None:
        return image
    if width is None:
        scale = height / current_h
    elif height is None:
        scale = width / current_w
    else:
        scale = min(width / current_w, height / current_h)
        if not limit:
            # Match ImageMagick's aspect-preserving WxH behavior.
            scale = min(width / current_w, height / current_h)

    if limit and scale >= 1:
        return image

    new_size = (max(1, round(current_w * scale)), max(1, round(current_h * scale)))
    return image.resize(new_size, Image.Resampling.NEAREST)


def constrain(image: Image.Image) -> Image.Image:
    width, height = image.size
    scale = min(184 / width, 86 / height, 1.0)
    if scale >= 1:
        return image
    new_size = (max(1, round(width * scale)), max(1, round(height * scale)))
    return image.resize(new_size, Image.Resampling.NEAREST)


def add_outline(image: Image.Image) -> Image.Image:
    alpha = image.getchannel("A")
    dilated = alpha.filter(ImageFilter.MaxFilter(3))
    outline_alpha = ImageChops.subtract(dilated, alpha)
    outline = Image.new("RGBA", image.size, OUTLINE)
    outline.putalpha(outline_alpha)
    return Image.alpha_composite(outline, image)


def frame(source: Image.Image, name: str, box: str, resize_spec: str = "x86") -> Path:
    crop = trim(source.crop(parse_box(box)))
    crop = resize_like_magick(crop, resize_spec)
    crop = constrain(crop)

    content = Image.new("RGBA", (FRAME_WIDTH, CONTENT_HEIGHT), (0, 0, 0, 0))
    x = (FRAME_WIDTH - crop.width) // 2
    y = max(0, CONTENT_HEIGHT - crop.height - FOOT_LIFT)
    content.alpha_composite(crop, (x, y))

    canvas = Image.new("RGBA", (FRAME_WIDTH, FRAME_HEIGHT), (0, 0, 0, 0))
    canvas.alpha_composite(content, (0, 0))
    canvas = add_outline(canvas)

    # Avoid colored RGB data in transparent pixels; it reduces import/render fringes.
    pixels = canvas.load()
    for py in range(canvas.height):
        for px in range(canvas.width):
            r, g, b, a = pixels[px, py]
            if a == 0:
                pixels[px, py] = (0, 0, 0, 0)

    path = WORK_DIR / f"{name}.png"
    canvas.save(path)
    return path


def strip(output: str, frames: list[Path]) -> None:
    sheet = Image.new("RGBA", (FRAME_WIDTH * len(frames), FRAME_HEIGHT), (0, 0, 0, 0))
    for index, path in enumerate(frames):
        sheet.alpha_composite(Image.open(path).convert("RGBA"), (FRAME_WIDTH * index, 0))
    sheet.save(OUT_DIR / f"{output}.png")


def main() -> None:
    if not SOURCE.exists():
        raise FileNotFoundError(SOURCE)

    WORK_DIR.mkdir(parents=True, exist_ok=True)
    OUT_DIR.mkdir(parents=True, exist_ok=True)
    for old in WORK_DIR.glob("*.png"):
        old.unlink()

    source = remove_green_key(Image.open(SOURCE))
    source.save(ALPHA_SOURCE)

    frames: dict[str, Path] = {}

    def make(name: str, box: str, resize: str = "x86") -> None:
        frames[name] = frame(source, name, box, resize)

    make("idle_0", "118x126+28+10", "x88")
    make("idle_1", "118x126+146+10", "x88")
    make("idle_2", "118x126+266+10", "x88")
    make("idle_3", "118x126+146+10", "x88")

    make("run_0", "130x104+18+176", "x88")
    make("run_1", "130x104+142+176", "x88")
    make("run_2", "130x104+268+176", "x88")
    make("run_3", "130x104+388+176", "x88")
    make("run_4", "130x104+506+176", "x88")
    make("run_5", "130x104+624+176", "x88")

    for index, box in enumerate(["386", "506", "626", "746"] * 3):
        make(f"attack_{index}", f"118x126+{box}+10", "x88")

    make("jump_0", "118x106+24+328", "x86")
    make("jump_1", "124x106+146+328", "x86")
    make("jump_2", "124x106+268+328", "x86")

    make("dodge_0", "160x72+20+475", "132x64>")
    make("dodge_1", "166x72+196+475", "138x64>")
    make("dodge_2", "166x72+374+475", "138x64>")
    make("dodge_3", "166x72+544+475", "138x64>")

    make("hurt_0", "114x110+1074+460", "x86")
    make("hurt_1", "124x110+1250+460", "x86")

    for index, box in enumerate(["386", "506", "626", "746"] * 2):
        make(f"throw_{index}", f"118x126+{box}+10", "x88")

    make("skill_0", "118x126+24+746", "x88")
    make("skill_1", "128x126+204+746", "x88")
    make("skill_2", "136x126+392+746", "x88")
    make("skill_3", "142x126+586+746", "x88")

    make("death_0", "112x112+24+888", "x78")
    make("death_1", "124x104+150+898", "x72")
    make("death_2", "152x66+304+918", "132x62>")
    make("death_3", "162x58+470+930", "136x56>")
    make("death_4", "170x52+634+936", "140x52>")

    strip("idle", [frames[f"idle_{i}"] for i in range(4)])
    strip("run", [frames[f"run_{i}"] for i in range(6)])
    strip("attack", [frames[f"attack_{i}"] for i in range(12)])
    strip("jump", [frames[f"jump_{i}"] for i in range(3)])
    strip("dodge", [frames[f"dodge_{i}"] for i in range(4)])
    strip("hurt", [frames[f"hurt_{i}"] for i in range(2)])
    strip("throw", [frames[f"throw_{i}"] for i in range(8)])
    strip("skill", [frames[f"skill_{i}"] for i in range(4)])
    strip("death", [frames[f"death_{i}"] for i in range(5)])

    preview_rows = [
        OUT_DIR / "idle.png",
        OUT_DIR / "run.png",
        OUT_DIR / "attack.png",
        OUT_DIR / "jump.png",
        OUT_DIR / "dodge.png",
        OUT_DIR / "hurt.png",
        OUT_DIR / "throw.png",
        OUT_DIR / "skill.png",
        OUT_DIR / "death.png",
    ]
    total_height = sum(Image.open(path).height for path in preview_rows) + 8 * len(preview_rows)
    preview = Image.new("RGBA", (max(Image.open(path).width for path in preview_rows), total_height), (26, 24, 22, 255))
    y = 0
    for path in preview_rows:
        row = Image.open(path).convert("RGBA")
        y += 8
        preview.alpha_composite(row, (0, y))
        y += row.height
    preview.save(PREVIEW)


if __name__ == "__main__":
    main()
