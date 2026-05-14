from __future__ import annotations

from pathlib import Path

from PIL import Image


ROOT = Path(__file__).resolve().parents[2]
SOURCE = ROOT / "assets/enemies/grunt/generated_source/grunt_ember_fields_imagegen_source_chromakey.png"
ALPHA_SOURCE = ROOT / "assets/enemies/grunt/generated_source/grunt_ember_fields_source_alpha_pillow.png"
PREVIEW = ROOT / "assets/enemies/grunt/grunt_ember_fields_preview.png"
SPRITESHEET = ROOT / "assets/enemies/grunt/grunt_spritesheet.png"
FRAME_ROOT = ROOT / "assets/enemies/grunt"
SPRITE_FRAMES = ROOT / "resources/sprite_frames/grunt_sprite_frames.tres"

KEY = (0, 255, 0)
FRAME_SIZE = 64


ANIMATIONS: dict[str, list[tuple[int, int, int, int]]] = {
    "idle": [
        (141, 34, 270, 244),
        (345, 34, 469, 244),
        (537, 34, 661, 244),
        (345, 34, 469, 244),
    ],
    "walk": [
        (117, 276, 288, 481),
        (358, 276, 516, 481),
        (575, 276, 740, 485),
        (824, 276, 989, 485),
        (1046, 280, 1211, 485),
        (1264, 282, 1420, 487),
    ],
    "attack": [
        (115, 540, 293, 722),
        (398, 535, 672, 722),
        (712, 536, 981, 722),
        (1046, 536, 1190, 722),
    ],
    "death": [
        (132, 773, 306, 952),
        (363, 825, 542, 952),
        (601, 853, 826, 954),
        (901, 890, 1123, 952),
        (1220, 902, 1358, 951),
    ],
}

SPEEDS = {
    "idle": 6.0,
    "walk": 8.0,
    "attack": 10.0,
    "death": 8.0,
}

LOOPS = {
    "idle": True,
    "walk": True,
    "attack": False,
    "death": False,
}


def remove_green_key(image: Image.Image) -> Image.Image:
    out = image.convert("RGBA")
    pixels = out.load()
    for y in range(out.height):
        for x in range(out.width):
            r, g, b, a = pixels[x, y]
            green_distance = abs(r - KEY[0]) + abs(g - KEY[1]) + abs(b - KEY[2])
            if g > 165 and r < 95 and b < 95:
                pixels[x, y] = (r, g, b, 0)
            elif g > r * 1.8 and g > b * 1.8 and green_distance < 190:
                pixels[x, y] = (r, g, b, 0)
    return out


def trim_alpha(image: Image.Image) -> Image.Image:
    bbox = image.getbbox()
    if bbox is None:
        return Image.new("RGBA", (1, 1), (0, 0, 0, 0))
    return image.crop(bbox)


def quantize_frame(image: Image.Image) -> Image.Image:
    alpha = image.getchannel("A")
    rgb = image.convert("RGB").quantize(colors=16, method=Image.Quantize.MEDIANCUT).convert("RGBA")
    rgb.putalpha(alpha)
    return rgb


def fit_to_frame(sprite: Image.Image, target_height: int, bottom_margin: int) -> Image.Image:
    sprite = trim_alpha(sprite)
    scale = target_height / max(sprite.height, 1)
    width = max(1, round(sprite.width * scale))
    height = max(1, round(sprite.height * scale))
    sprite = sprite.resize((width, height), Image.Resampling.NEAREST)
    sprite = quantize_frame(sprite)

    frame = Image.new("RGBA", (FRAME_SIZE, FRAME_SIZE), (0, 0, 0, 0))
    x = (FRAME_SIZE - width) // 2
    y = FRAME_SIZE - bottom_margin - height
    frame.alpha_composite(sprite, (x, y))
    return frame


def target_for(animation: str, index: int) -> tuple[int, int]:
    if animation == "death":
        heights = [56, 43, 27, 20, 13]
        margins = [4, 5, 6, 7, 8]
        return heights[index], margins[index]
    if animation == "attack":
        return 56, 4
    return 58, 4


def write_frames(source: Image.Image) -> dict[str, list[Path]]:
    written: dict[str, list[Path]] = {}
    for animation, boxes in ANIMATIONS.items():
        out_dir = FRAME_ROOT / animation
        out_dir.mkdir(parents=True, exist_ok=True)
        frames: list[Path] = []
        for index, box in enumerate(boxes):
            target_height, bottom_margin = target_for(animation, index)
            cropped = source.crop(box)
            frame = fit_to_frame(cropped, target_height, bottom_margin)
            out_path = out_dir / f"img_{index}.png"
            frame.save(out_path)
            frames.append(out_path)
        written[animation] = frames
    return written


def make_preview(written: dict[str, list[Path]]) -> None:
    columns = max(len(paths) for paths in written.values())
    rows = len(written)
    preview = Image.new("RGBA", (columns * FRAME_SIZE, rows * FRAME_SIZE), (0, 255, 0, 255))
    for row, animation in enumerate(["idle", "walk", "attack", "death"]):
        for col, frame_path in enumerate(written[animation]):
            preview.alpha_composite(Image.open(frame_path).convert("RGBA"), (col * FRAME_SIZE, row * FRAME_SIZE))
    PREVIEW.parent.mkdir(parents=True, exist_ok=True)
    preview.save(PREVIEW)

    sheet = Image.new("RGBA", preview.size, (0, 0, 0, 0))
    for row, animation in enumerate(["idle", "walk", "attack", "death"]):
        for col, frame_path in enumerate(written[animation]):
            sheet.alpha_composite(Image.open(frame_path).convert("RGBA"), (col * FRAME_SIZE, row * FRAME_SIZE))
    sheet.save(SPRITESHEET)


def res_path(path: Path) -> str:
    return "res://" + path.relative_to(ROOT).as_posix()


def write_sprite_frames(written: dict[str, list[Path]]) -> None:
    ext_lines: list[str] = []
    id_by_frame: dict[tuple[str, Path], str] = {}
    counter = 1
    for animation in ["attack", "death", "default", "idle", "walk"]:
        source_animation = "idle" if animation == "default" else animation
        for path in written[source_animation]:
            res_id = f"{animation}_{path.stem}_{counter}"
            id_by_frame[(animation, path)] = res_id
            ext_lines.append(f'[ext_resource type="Texture2D" path="{res_path(path)}" id="{res_id}"]')
            counter += 1

    animation_blocks: list[str] = []
    for animation in ["attack", "death", "default", "idle", "walk"]:
        source_animation = "idle" if animation == "default" else animation
        frame_entries = [
            '{\n"duration": 1.0,\n"texture": ExtResource("%s")\n}' % id_by_frame[(animation, path)]
            for path in written[source_animation]
        ]
        animation_blocks.append(
            '{\n'
            f'"frames": [{", ".join(frame_entries)}],\n'
            f'"loop": {"true" if LOOPS.get(animation, True) else "false"},\n'
            f'"name": &"{animation}",\n'
            f'"speed": {SPEEDS.get(animation, SPEEDS[source_animation]):.1f}\n'
            '}'
        )

    SPRITE_FRAMES.write_text(
        "[gd_resource type=\"SpriteFrames\" format=3]\n\n"
        + "\n".join(ext_lines)
        + "\n\n[resource]\nanimations = ["
        + ", ".join(animation_blocks)
        + "]\n",
        encoding="utf-8",
    )


def main() -> None:
    if not SOURCE.exists():
        raise FileNotFoundError(SOURCE)
    source = remove_green_key(Image.open(SOURCE))
    ALPHA_SOURCE.parent.mkdir(parents=True, exist_ok=True)
    source.save(ALPHA_SOURCE)
    written = write_frames(source)
    make_preview(written)
    write_sprite_frames(written)


if __name__ == "__main__":
    main()
