#!/usr/bin/env python3
from __future__ import annotations

import re
from pathlib import Path

from PIL import Image, ImageChops, ImageFilter


ROOT = Path(__file__).resolve().parents[2]
RYNE_DIR = ROOT / "assets/characters/ryne"

IMAGEGEN_SOURCE = RYNE_DIR / "generated_source/ryne_imagegen_source_chromakey.png"
CHROMAKEY_SOURCE = RYNE_DIR / "generated_source/ryne_rework_source_chromakey.png"
ALPHA_SOURCE = RYNE_DIR / "generated_source/ryne_rework_source_alpha_pillow.png"
PREVIEW = RYNE_DIR / "generated_source/ryne_rework_preview.png"
WORK_DIR = ROOT / "tmp/asset_generation/ryne_clean/pillow_frames"

SOURCE_SIZE = (1536, 1024)
FRAME_WIDTH = 192
FRAME_HEIGHT = 96
CONTENT_HEIGHT = 92
OUTLINE = (18, 12, 26, 255)

FRAME_SPECS = {
    "idle_0": ("72x120+54+20", "x86"),
    "idle_1": ("74x120+164+19", "x86"),
    "idle_2": ("75x120+273+20", "x86"),
    "idle_3": ("75x120+381+20", "x86"),
    "run_0": ("100x104+39+155", "x86"),
    "run_1": ("96x104+198+154", "x86"),
    "run_2": ("104x103+356+155", "x86"),
    "run_3": ("110x103+498+156", "x86"),
    "run_4": ("112x103+646+156", "x86"),
    "run_5": ("122x103+790+156", "x86"),
    "attack_0": ("67x119+499+20", "x86"),
    "attack_1": ("122x106+618+33", "x86"),
    "attack_2": ("122x106+752+33", "x86"),
    "attack_3": ("133x106+905+33", "x86"),
    "attack_4": ("104x106+1095+33", "x86"),
    "attack_5": ("124x106+1275+33", "x86"),
    "jump_0": ("77x101+60+283", "x86"),
    "jump_1": ("112x115+230+268", "x86"),
    "jump_2": ("115x110+397+270", "x86"),
    "dodge_0": ("156x65+48+414", "128x60>"),
    "dodge_1": ("151x63+216+415", "128x60>"),
    "dodge_2": ("127x67+408+411", "128x60>"),
    "dodge_3": ("137x60+590+418", "128x58>"),
    "hurt_0": ("90x116+54+496", "x86"),
    "hurt_1": ("90x110+202+502", "x86"),
    "throw_0": ("83x113+51+625", "x86"),
    "throw_1": ("98x108+171+634", "x86"),
    "throw_2": ("140x109+305+634", "176x82>"),
    "skill_0": ("88x113+56+755", "x86"),
    "skill_1": ("86x126+212+753", "x86"),
    "skill_2": ("172x138+756+748", "184x84>"),
    "death_0": ("84x112+48+884", "x86"),
    "death_1": ("81x90+186+906", "x86"),
    "death_2": ("114x63+312+933", "128x60>"),
    "death_3": ("128x49+470+947", "128x48>"),
    "death_4": ("125x39+637+957", "128x40>"),
}

STRIPS = {
    "idle": ["idle_0", "idle_1", "idle_2", "idle_3"],
    "run": ["run_0", "run_1", "run_2", "run_3", "run_4", "run_5"],
    "attack": ["attack_0", "attack_1", "attack_2", "attack_3", "attack_4", "attack_5"] * 2,
    "jump": ["jump_0", "jump_1", "jump_2"],
    "dodge": ["dodge_0", "dodge_1", "dodge_2", "dodge_3"],
    "hurt": ["hurt_0", "hurt_1"],
    "throw": ["throw_0", "throw_1", "throw_2", "throw_2", "throw_1", "throw_0", "throw_2", "throw_1"],
    "skill": ["skill_0", "skill_1", "skill_2", "skill_1"],
    "death": ["death_0", "death_1", "death_2", "death_3", "death_4"],
}


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


def resize_to_fit(image: Image.Image, spec: str) -> Image.Image:
    target_w, target_h, limit = parse_resize(spec)
    source_w, source_h = image.size
    if target_w is None and target_h is None:
        return image
    if target_w is None:
        scale = target_h / source_h
    elif target_h is None:
        scale = target_w / source_w
    else:
        scale = min(target_w / source_w, target_h / source_h)
    if limit and scale >= 1:
        return image
    size = (max(1, round(source_w * scale)), max(1, round(source_h * scale)))
    return image.resize(size, Image.Resampling.NEAREST)


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
    return image


def trim(image: Image.Image) -> Image.Image:
    bbox = image.getchannel("A").getbbox()
    if bbox is None:
        return Image.new("RGBA", (1, 1), (0, 0, 0, 0))
    return image.crop(bbox)


def constrain(image: Image.Image) -> Image.Image:
    width, height = image.size
    scale = min(184 / width, 88 / height, 1.0)
    if scale >= 1:
        return image
    return image.resize((max(1, round(width * scale)), max(1, round(height * scale))), Image.Resampling.NEAREST)


def add_outline(image: Image.Image) -> Image.Image:
    alpha = image.getchannel("A")
    dilated = alpha.filter(ImageFilter.MaxFilter(3))
    outline_alpha = ImageChops.subtract(dilated, alpha)
    outline = Image.new("RGBA", image.size, OUTLINE)
    outline.putalpha(outline_alpha)
    return Image.alpha_composite(outline, image)


def clear_transparent_rgb(image: Image.Image) -> Image.Image:
    image = image.convert("RGBA")
    pixels = image.load()
    for y in range(image.height):
        for x in range(image.width):
            r, g, b, a = pixels[x, y]
            if a == 0:
                pixels[x, y] = (0, 0, 0, 0)
    return image


def load_imagegen_source() -> Image.Image:
    if not IMAGEGEN_SOURCE.exists():
        raise FileNotFoundError(
            f"Missing imagegen base sheet: {IMAGEGEN_SOURCE}. "
            "Generate Ryne's full chromakey source sheet with $imagegen first."
        )
    source = Image.open(IMAGEGEN_SOURCE).convert("RGBA")
    if source.size != SOURCE_SIZE:
        source = source.resize(SOURCE_SIZE, Image.Resampling.NEAREST)
    return source


def make_character_frame(source: Image.Image, name: str, crop_box: str, resize_spec: str) -> Path:
    frame = trim(source.crop(parse_box(crop_box)))
    frame = resize_to_fit(frame, resize_spec)
    frame = constrain(frame)

    content = Image.new("RGBA", (FRAME_WIDTH, CONTENT_HEIGHT), (0, 0, 0, 0))
    x = (FRAME_WIDTH - frame.width) // 2
    y = CONTENT_HEIGHT - frame.height
    content.alpha_composite(frame, (x, y))

    canvas = Image.new("RGBA", (FRAME_WIDTH, FRAME_HEIGHT), (0, 0, 0, 0))
    canvas.alpha_composite(content, (0, 0))
    canvas = clear_transparent_rgb(add_outline(canvas))

    path = WORK_DIR / f"{name}.png"
    canvas.save(path)
    return path


def write_strip(output_name: str, frame_paths: list[Path]) -> None:
    sheet = Image.new("RGBA", (FRAME_WIDTH * len(frame_paths), FRAME_HEIGHT), (0, 0, 0, 0))
    for index, path in enumerate(frame_paths):
        sheet.alpha_composite(Image.open(path).convert("RGBA"), (FRAME_WIDTH * index, 0))
    sheet.save(RYNE_DIR / f"{output_name}.png")


def write_preview() -> None:
    rows = [RYNE_DIR / f"{name}.png" for name in STRIPS]
    opened_rows = [Image.open(path).convert("RGBA") for path in rows]
    width = max(row.width for row in opened_rows)
    height = sum(row.height for row in opened_rows) + 8 * len(opened_rows)
    preview = Image.new("RGBA", (width, height), (26, 24, 22, 255))
    y = 0
    for row in opened_rows:
        y += 8
        preview.alpha_composite(row, (0, y))
        y += row.height
    preview.save(PREVIEW)


def main() -> None:
    RYNE_DIR.mkdir(parents=True, exist_ok=True)
    (RYNE_DIR / "generated_source").mkdir(parents=True, exist_ok=True)
    WORK_DIR.mkdir(parents=True, exist_ok=True)
    for old_frame in WORK_DIR.glob("*.png"):
        old_frame.unlink()

    chromakey_source = load_imagegen_source()
    chromakey_source.convert("RGB").save(CHROMAKEY_SOURCE)

    alpha_source = clear_transparent_rgb(remove_green_key(chromakey_source))
    alpha_source.save(ALPHA_SOURCE)

    frames = {
        name: make_character_frame(alpha_source, name, crop_box, resize_spec)
        for name, (crop_box, resize_spec) in FRAME_SPECS.items()
    }

    for strip_name, frame_names in STRIPS.items():
        write_strip(strip_name, [frames[name] for name in frame_names])

    write_preview()


if __name__ == "__main__":
    main()
