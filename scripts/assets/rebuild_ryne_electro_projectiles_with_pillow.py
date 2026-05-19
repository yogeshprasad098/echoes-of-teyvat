#!/usr/bin/env python3
from __future__ import annotations

from pathlib import Path

from PIL import Image


ROOT = Path(__file__).resolve().parents[2]
SOURCE = ROOT / "assets/projectiles/ryne_electro_review/generated_source/ryne_electro_projectiles_imagegen_source_chromakey.png"
ALPHA_SOURCE = ROOT / "assets/projectiles/ryne_electro_review/generated_source/ryne_electro_projectiles_source_alpha_pillow.png"
PREVIEW = ROOT / "assets/projectiles/ryne_electro_review/ryne_electro_projectiles_preview.png"
SLASH_DIR = ROOT / "assets/projectiles/ryne_electro_slash"
SHOCKWAVE_DIR = ROOT / "assets/projectiles/ryne_shockwave"
IMPACT_DIR = ROOT / "assets/projectiles/ryne_electro_impact"
EFFECT_FRAMES = ROOT / "resources/sprite_frames/ryne_electro_effect_sprite_frames.tres"
SHOCKWAVE_FRAMES = ROOT / "resources/sprite_frames/ryne_shockwave_sprite_frames.tres"

FRAME_SIZE = (200, 200)
SLASH_TARGET_MAX = (92, 64)
SHOCKWAVE_TARGET_MAX = (124, 72)
IMPACT_TARGET_MAX = (116, 116)

SLASH_CENTERS = [
    (133, 101),
    (291, 101),
    (449, 101),
    (611, 101),
    (768, 101),
    (928, 101),
    (1085, 101),
    (1245, 101),
    (1398, 101),
    (133, 260),
    (291, 260),
    (449, 260),
    (611, 260),
    (768, 260),
    (928, 260),
    (1085, 260),
]
SHOCKWAVE_CENTERS = [
    (125, 422),
    (306, 422),
    (488, 422),
    (670, 422),
    (852, 422),
    (125, 575),
    (306, 575),
    (488, 575),
    (670, 575),
    (852, 575),
]
IMPACT_CENTERS = [
    (137, 747),
    (348, 747),
    (560, 747),
    (773, 747),
    (984, 747),
    (1197, 747),
    (137, 905),
    (348, 905),
    (560, 905),
    (773, 905),
    (984, 905),
    (1197, 905),
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
) -> Image.Image:
    cx, cy = center
    rx, ry = crop_radius
    crop = source.crop((max(0, cx - rx), max(0, cy - ry), min(source.width, cx + rx), min(source.height, cy + ry)))
    asset = resize_to_fit(trim(crop), max_size)
    frame = Image.new("RGBA", FRAME_SIZE, (0, 0, 0, 0))
    frame.alpha_composite(asset, ((FRAME_SIZE[0] - asset.width) // 2, (FRAME_SIZE[1] - asset.height) // 2))
    return clear_transparent_rgb(frame)


def write_frames(frames: list[Image.Image], output_dir: Path) -> None:
    output_dir.mkdir(parents=True, exist_ok=True)
    for old_frame in output_dir.glob("img_*.png"):
        old_frame.unlink()
    for index, frame in enumerate(frames):
        frame.save(output_dir / f"img_{index}.png")


def write_preview(slash_frames: list[Image.Image], shockwave_frames: list[Image.Image], impact_frames: list[Image.Image]) -> None:
    cell_w, cell_h = 100, 100
    preview = Image.new("RGBA", (cell_w * 8, cell_h * 6), (22, 20, 28, 255))
    for index, frame in enumerate(slash_frames):
        preview.alpha_composite(frame.resize((cell_w, cell_h), Image.Resampling.NEAREST), ((index % 8) * cell_w, (index // 8) * cell_h))
    for index, frame in enumerate(shockwave_frames):
        preview.alpha_composite(frame.resize((cell_w, cell_h), Image.Resampling.NEAREST), ((index % 8) * cell_w, (2 + index // 8) * cell_h))
    for index, frame in enumerate(impact_frames):
        preview.alpha_composite(frame.resize((cell_w, cell_h), Image.Resampling.NEAREST), ((index % 6) * cell_w, (4 + index // 6) * cell_h))
    PREVIEW.parent.mkdir(parents=True, exist_ok=True)
    preview.resize((preview.width * 2, preview.height * 2), Image.Resampling.NEAREST).save(PREVIEW)


def res_path(path: Path) -> str:
    return "res://" + str(path.relative_to(ROOT))


def texture_resource_lines(folder: Path, count: int, prefix: str) -> list[str]:
    return [
        f'[ext_resource type="Texture2D" path="{res_path(folder / f"img_{index}.png")}" id="{index + 1}_{prefix}"]'
        for index in range(count)
    ]


def animation_block(name: str, ids: list[str], speed: float, loop: bool) -> str:
    frames: list[str] = []
    for texture_id in ids:
        frames.append('{\n"duration": 1.0,\n"texture": ExtResource("' + texture_id + '")\n}')
    return (
        '{\n'
        '"frames": [\n'
        + ", ".join(frames)
        + '],\n'
        f'"loop": {str(loop).lower()},\n'
        f'"name": &"{name}",\n'
        f'"speed": {speed}\n'
        '}'
    )


def write_sprite_frames_resource(path: Path, ext_lines: list[str], animations: list[str]) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    text = "[gd_resource type=\"SpriteFrames\" format=3]\n\n"
    text += "\n".join(ext_lines)
    text += "\n\n[resource]\nanimations = ["
    text += ", ".join(animations)
    text += "]\n"
    path.write_text(text)


def main() -> None:
    if not SOURCE.exists():
        raise FileNotFoundError(f"Missing generated Ryne electro source: {SOURCE}")

    alpha_source = remove_green_key(Image.open(SOURCE).convert("RGBA"))
    ALPHA_SOURCE.parent.mkdir(parents=True, exist_ok=True)
    alpha_source.save(ALPHA_SOURCE)

    slash_frames = [make_frame(alpha_source, center, (86, 68), SLASH_TARGET_MAX) for center in SLASH_CENTERS]
    shockwave_frames = [make_frame(alpha_source, center, (86, 74), SHOCKWAVE_TARGET_MAX) for center in SHOCKWAVE_CENTERS]
    impact_frames = [make_frame(alpha_source, center, (94, 94), IMPACT_TARGET_MAX) for center in IMPACT_CENTERS]

    write_frames(slash_frames, SLASH_DIR)
    write_frames(shockwave_frames, SHOCKWAVE_DIR)
    write_frames(impact_frames, IMPACT_DIR)
    write_preview(slash_frames, shockwave_frames, impact_frames)

    effect_ext_lines = texture_resource_lines(SLASH_DIR, len(slash_frames), "slash")
    effect_ext_lines += texture_resource_lines(IMPACT_DIR, len(impact_frames), "impact")
    slash_ids = [f"{index + 1}_slash" for index in range(len(slash_frames))]
    impact_ids = [f"{index + 1}_impact" for index in range(len(impact_frames))]
    write_sprite_frames_resource(
        EFFECT_FRAMES,
        effect_ext_lines,
        [
            animation_block("slash", slash_ids, 52.0, False),
            animation_block("impact", impact_ids, 34.0, False),
        ],
    )

    shockwave_ext_lines = texture_resource_lines(SHOCKWAVE_DIR, len(shockwave_frames), "shockwave")
    shockwave_ids = [f"{index + 1}_shockwave" for index in range(len(shockwave_frames))]
    write_sprite_frames_resource(
        SHOCKWAVE_FRAMES,
        shockwave_ext_lines,
        [animation_block("wave", shockwave_ids, 40.0, False)],
    )


if __name__ == "__main__":
    main()
