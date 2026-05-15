#!/usr/bin/env python3
from __future__ import annotations

from dataclasses import dataclass
from pathlib import Path
from statistics import pstdev

from PIL import Image


ROOT = Path(__file__).resolve().parents[2]
SOURCE_ROOT = Path("/Users/yogeshprasad/Downloads/GAME ASSETS")
KIRA_DIR = ROOT / "assets/characters/kira"
PROJECTILE_DIR = ROOT / "assets/projectiles/kira"
VFX_DIR = ROOT / "assets/vfx/kira"
QA_PREVIEW = Path("/tmp/echoes_kira_game_assets_pillow_preview_black.png")

CHAR_CELL = (192, 192)
CHAR_GROUND_Y = 158
CHAR_MAX_SIZE = (184, 92)
CHAR_INCLUDE_COMPONENT_MIN = 420
PROJECTILE_INCLUDE_COMPONENT_MIN = 120
VFX_INCLUDE_COMPONENT_MIN = 70


@dataclass(frozen=True)
class StripSpec:
    category: str
    source_name: str
    output: Path
    frame_count: int
    cell_size: tuple[int, int]
    max_size: tuple[int, int]
    mode: str
    ground_y: int | None = None
    include_component_min: int = 0


@dataclass
class Component:
    area: int
    bbox: tuple[int, int, int, int]
    pixels: list[tuple[int, int]]

    @property
    def center_x(self) -> float:
        left, _top, right, _bottom = self.bbox
        return (left + right) / 2.0


CHARACTER_STRIPS: dict[str, StripSpec] = {
    "idle": StripSpec("characters", "kira_idle_8f_target_1536x192_raw_imagegen.png", KIRA_DIR / "idle.png", 8, CHAR_CELL, CHAR_MAX_SIZE, "components", CHAR_GROUND_Y, CHAR_INCLUDE_COMPONENT_MIN),
    "run": StripSpec("characters", "kira_run_6f_target_1152x192_raw_imagegen.png", KIRA_DIR / "run.png", 6, CHAR_CELL, CHAR_MAX_SIZE, "components", CHAR_GROUND_Y, CHAR_INCLUDE_COMPONENT_MIN),
    "jump": StripSpec("characters", "kira_jump_4f_target_768x192_raw_imagegen.png", KIRA_DIR / "jump.png", 4, CHAR_CELL, CHAR_MAX_SIZE, "components", CHAR_GROUND_Y, CHAR_INCLUDE_COMPONENT_MIN),
    "fall": StripSpec("characters", "kira_fall_2f_target_384x192_raw_imagegen.png", KIRA_DIR / "fall.png", 2, CHAR_CELL, CHAR_MAX_SIZE, "components", CHAR_GROUND_Y, CHAR_INCLUDE_COMPONENT_MIN),
    "land": StripSpec("characters", "kira_land_2f_target_384x192_raw_imagegen.png", KIRA_DIR / "land.png", 2, CHAR_CELL, CHAR_MAX_SIZE, "components", CHAR_GROUND_Y, CHAR_INCLUDE_COMPONENT_MIN),
    "dodge": StripSpec("characters", "kira_dodge_4f_target_768x192_raw_imagegen.png", KIRA_DIR / "dodge.png", 4, CHAR_CELL, (184, 84), "components", CHAR_GROUND_Y, CHAR_INCLUDE_COMPONENT_MIN),
    "attack": StripSpec("characters", "kira_attack_6f_target_1152x192_raw_imagegen.png", KIRA_DIR / "attack.png", 6, CHAR_CELL, CHAR_MAX_SIZE, "components", CHAR_GROUND_Y, CHAR_INCLUDE_COMPONENT_MIN),
    "throw": StripSpec("characters", "kira_throw_8f_target_1536x192_raw_imagegen.png", KIRA_DIR / "throw.png", 8, CHAR_CELL, CHAR_MAX_SIZE, "components", CHAR_GROUND_Y, CHAR_INCLUDE_COMPONENT_MIN),
    "skill": StripSpec("characters", "kira_skill_6f_target_1152x192_raw_imagegen.png", KIRA_DIR / "skill.png", 6, CHAR_CELL, (184, 100), "components", CHAR_GROUND_Y, CHAR_INCLUDE_COMPONENT_MIN),
    "hurt": StripSpec("characters", "kira_hurt_2f_target_384x192_raw_imagegen.png", KIRA_DIR / "hurt.png", 2, CHAR_CELL, CHAR_MAX_SIZE, "components", CHAR_GROUND_Y, CHAR_INCLUDE_COMPONENT_MIN),
    "death": StripSpec("characters", "kira_death_6f_target_1152x192_raw_imagegen.png", KIRA_DIR / "death.png", 6, CHAR_CELL, CHAR_MAX_SIZE, "components", CHAR_GROUND_Y, CHAR_INCLUDE_COMPONENT_MIN),
}

PROJECTILE_STRIPS: dict[str, StripSpec] = {
    "small_fireball": StripSpec("projectiles", "kira_small_fireball_4f_target_256x64_raw_imagegen.png", PROJECTILE_DIR / "small_fireball.png", 4, (64, 64), (58, 48), "components", None, PROJECTILE_INCLUDE_COMPONENT_MIN),
    "large_fireball": StripSpec("projectiles", "kira_large_spell_projectile_6f_target_768x128_raw_imagegen.png", PROJECTILE_DIR / "large_fireball.png", 6, (128, 128), (120, 96), "components", None, PROJECTILE_INCLUDE_COMPONENT_MIN),
}

VFX_STRIPS: dict[str, StripSpec] = {
    "fire_burst": StripSpec("vfx", "kira_fire_burst_8f_target_1536x192_raw_imagegen.png", VFX_DIR / "fire_burst.png", 8, (192, 192), (184, 152), "segments", None, VFX_INCLUDE_COMPONENT_MIN),
}


def source_path(spec: StripSpec) -> Path:
    return SOURCE_ROOT / spec.category / "kira/imagegen_strips/raw_generated" / spec.source_name


def is_green_spill(r: int, g: int, b: int) -> bool:
    if g >= 170 and r <= 135 and b <= 135:
        return True
    return g >= 28 and g > r + 5 and g > b + 5 and g > max(r, b) * 1.08


def remove_green_to_alpha(image: Image.Image) -> Image.Image:
    image = image.convert("RGBA")
    pixels = image.load()
    for y in range(image.height):
        for x in range(image.width):
            r, g, b, a = pixels[x, y]
            if a == 0 or is_green_spill(r, g, b):
                pixels[x, y] = (0, 0, 0, 0)

    # Second pass catches one-pixel greenish fringes adjacent to transparent key.
    original = image.copy()
    src = original.load()
    dst = image.load()
    for y in range(image.height):
        for x in range(image.width):
            r, g, b, a = src[x, y]
            if a == 0:
                continue
            if not (g > r + 2 and g > b + 2 and g >= 22):
                continue
            touches_alpha = False
            for nx, ny in ((x + 1, y), (x - 1, y), (x, y + 1), (x, y - 1)):
                if 0 <= nx < image.width and 0 <= ny < image.height and src[nx, ny][3] == 0:
                    touches_alpha = True
                    break
            if touches_alpha:
                dst[x, y] = (0, 0, 0, 0)
    return clear_transparent_rgb(image)


def clear_transparent_rgb(image: Image.Image) -> Image.Image:
    image = image.convert("RGBA")
    pixels = image.load()
    for y in range(image.height):
        for x in range(image.width):
            if pixels[x, y][3] == 0:
                pixels[x, y] = (0, 0, 0, 0)
    return image


def connected_components(image: Image.Image) -> list[Component]:
    image = image.convert("RGBA")
    pixels = image.load()
    width, height = image.size
    seen: set[tuple[int, int]] = set()
    components: list[Component] = []

    for y in range(height):
        for x in range(width):
            if (x, y) in seen or pixels[x, y][3] == 0:
                continue
            stack = [(x, y)]
            seen.add((x, y))
            members: list[tuple[int, int]] = []
            xs: list[int] = []
            ys: list[int] = []
            while stack:
                cx, cy = stack.pop()
                members.append((cx, cy))
                xs.append(cx)
                ys.append(cy)
                for nx, ny in ((cx + 1, cy), (cx - 1, cy), (cx, cy + 1), (cx, cy - 1)):
                    if nx < 0 or ny < 0 or nx >= width or ny >= height or (nx, ny) in seen:
                        continue
                    if pixels[nx, ny][3] == 0:
                        continue
                    seen.add((nx, ny))
                    stack.append((nx, ny))
            components.append(Component(len(members), (min(xs), min(ys), max(xs) + 1, max(ys) + 1), members))
    return components


def resize_to_fit(image: Image.Image, max_size: tuple[int, int]) -> tuple[Image.Image, float]:
    scale = min(max_size[0] / image.width, max_size[1] / image.height, 1.0)
    size = (max(1, round(image.width * scale)), max(1, round(image.height * scale)))
    if size == image.size:
        return image, 1.0
    return image.resize(size, Image.Resampling.NEAREST), scale


def component_group_image(source: Image.Image, components: list[Component]) -> Image.Image:
    left = min(component.bbox[0] for component in components)
    top = min(component.bbox[1] for component in components)
    right = max(component.bbox[2] for component in components)
    bottom = max(component.bbox[3] for component in components)
    output = Image.new("RGBA", (right - left, bottom - top), (0, 0, 0, 0))
    source_pixels = source.load()
    output_pixels = output.load()
    for component in components:
        for x, y in component.pixels:
            output_pixels[x - left, y - top] = source_pixels[x, y]
    return clear_transparent_rgb(output)


def estimate_character_anchor_x(image: Image.Image) -> float:
    bbox = image.getchannel("A").getbbox()
    if bbox is None:
        return image.width / 2.0
    left, top, right, bottom = bbox
    cutoff = top + int((bottom - top) * 0.45)
    pixels = image.load()
    xs: list[int] = []
    for y in range(cutoff, bottom):
        for x in range(left, right):
            r, g, b, a = pixels[x, y]
            if a == 0:
                continue
            # Keep fire/dust effects from pulling the body pivot away from the feet.
            if r > 170 and g > 70 and b < 80:
                continue
            xs.append(x)
    if not xs:
        xs = [x for y in range(top, bottom) for x in range(left, right) if pixels[x, y][3] != 0]
    return sum(xs) / len(xs) if xs else image.width / 2.0


def place_character_frame(frame: Image.Image, spec: StripSpec) -> Image.Image:
    bbox = frame.getchannel("A").getbbox()
    if bbox is None:
        return Image.new("RGBA", spec.cell_size, (0, 0, 0, 0))
    anchor_x = estimate_character_anchor_x(frame)
    cropped = frame.crop(bbox)
    anchor_in_crop = anchor_x - bbox[0]
    resized, scale = resize_to_fit(cropped, spec.max_size)
    scaled_anchor = anchor_in_crop * scale

    canvas = Image.new("RGBA", spec.cell_size, (0, 0, 0, 0))
    x = round((spec.cell_size[0] / 2.0) - scaled_anchor)
    y = (spec.ground_y or spec.cell_size[1]) - resized.height
    x = max(0, min(spec.cell_size[0] - resized.width, x))
    y = max(0, min(spec.cell_size[1] - resized.height, y))
    canvas.alpha_composite(resized, (x, y))
    return clear_transparent_rgb(canvas)


def place_centered_frame(frame: Image.Image, spec: StripSpec) -> Image.Image:
    bbox = frame.getchannel("A").getbbox()
    if bbox is None:
        return Image.new("RGBA", spec.cell_size, (0, 0, 0, 0))
    cropped = frame.crop(bbox)
    resized, _scale = resize_to_fit(cropped, spec.max_size)
    canvas = Image.new("RGBA", spec.cell_size, (0, 0, 0, 0))
    x = (spec.cell_size[0] - resized.width) // 2
    y = (spec.cell_size[1] - resized.height) // 2
    canvas.alpha_composite(resized, (x, y))
    return clear_transparent_rgb(canvas)


def split_by_component_groups(source: Image.Image, spec: StripSpec) -> list[Image.Image]:
    components = [component for component in connected_components(source) if component.area >= spec.include_component_min]
    if len(components) < spec.frame_count:
        raise AssertionError(f"{spec.output.name}: expected at least {spec.frame_count} components, found {len(components)}")

    main = sorted(components, key=lambda component: component.area, reverse=True)[: spec.frame_count]
    main = sorted(main, key=lambda component: component.center_x)
    groups: list[list[Component]] = [[component] for component in main]

    main_ids = {id(component) for component in main}
    for component in components:
        if id(component) in main_ids:
            continue
        nearest = min(range(len(main)), key=lambda index: abs(main[index].center_x - component.center_x))
        groups[nearest].append(component)

    placed: list[Image.Image] = []
    for group in groups:
        group_image = component_group_image(source, group)
        if spec.ground_y is not None:
            placed.append(place_character_frame(group_image, spec))
        else:
            placed.append(place_centered_frame(group_image, spec))
    return placed


def split_by_bbox_segments(source: Image.Image, spec: StripSpec) -> list[Image.Image]:
    bbox = source.getchannel("A").getbbox()
    if bbox is None:
        return [Image.new("RGBA", spec.cell_size, (0, 0, 0, 0)) for _index in range(spec.frame_count)]
    left, top, right, bottom = bbox
    cropped = source.crop((left, top, right, bottom))
    frames: list[Image.Image] = []
    for index in range(spec.frame_count):
        seg_left = round(index * cropped.width / spec.frame_count)
        seg_right = round((index + 1) * cropped.width / spec.frame_count)
        segment = cropped.crop((seg_left, 0, seg_right, cropped.height))
        segment = remove_small_components(segment, spec.include_component_min)
        frames.append(place_centered_frame(segment, spec))
    return frames


def remove_small_components(image: Image.Image, minimum_area: int) -> Image.Image:
    components = connected_components(image)
    if not components:
        return image
    keep = [component for component in components if component.area >= minimum_area]
    if not keep:
        keep = [max(components, key=lambda component: component.area)]
    return component_group_image(image, keep)


def write_strip(frames: list[Image.Image], spec: StripSpec) -> None:
    sheet = Image.new("RGBA", (spec.cell_size[0] * spec.frame_count, spec.cell_size[1]), (0, 0, 0, 0))
    for index, frame in enumerate(frames):
        sheet.alpha_composite(frame, (index * spec.cell_size[0], 0))
    spec.output.parent.mkdir(parents=True, exist_ok=True)
    sheet.save(spec.output)


def process_strip(spec: StripSpec) -> None:
    path = source_path(spec)
    if not path.exists():
        raise FileNotFoundError(path)
    source = remove_green_to_alpha(Image.open(path))
    if spec.mode == "components":
        frames = split_by_component_groups(source, spec)
    else:
        frames = split_by_bbox_segments(source, spec)
    write_strip(frames, spec)


def atlas_resources(ext_id: str, prefix: str, frame_count: int, cell_size: tuple[int, int]) -> tuple[list[str], list[str]]:
    ids: list[str] = []
    chunks: list[str] = []
    for index in range(frame_count):
        atlas_id = f"AtlasTexture_{prefix}_{index}"
        ids.append(atlas_id)
        chunks.append(
            f'[sub_resource type="AtlasTexture" id="{atlas_id}"]\n'
            f'atlas = ExtResource("{ext_id}")\n'
            f"region = Rect2({index * cell_size[0]}, 0, {cell_size[0]}, {cell_size[1]})\n"
        )
    return ids, chunks


def animation_block(name: str, frame_ids: list[str], speed: float, loop: bool) -> str:
    frames = ", ".join(
        '{\n"duration": 1.0,\n"texture": SubResource("%s")\n}' % frame_id
        for frame_id in frame_ids
    )
    return (
        "{\n"
        f'"frames": [{frames}],\n'
        f'"loop": {"true" if loop else "false"},\n'
        f'"name": &"{name}",\n'
        f'"speed": {speed:.1f}\n'
        "}"
    )


def write_kira_sprite_frames() -> None:
    ext_ids = {
        "attack": "attack_sheet",
        "death": "death_sheet",
        "dodge": "dodge_sheet",
        "fall": "fall_sheet",
        "hurt": "hurt_sheet",
        "idle": "idle_sheet",
        "jump": "jump_sheet",
        "land": "land_sheet",
        "run": "run_sheet",
        "skill": "skill_sheet",
        "throw": "throw_sheet",
    }
    lines = ['[gd_resource type="SpriteFrames" format=3 uid="uid://cr2hls4tngh7e"]', ""]
    for name, ext_id in ext_ids.items():
        lines.append(f'[ext_resource type="Texture2D" path="res://assets/characters/kira/{name}.png" id="{ext_id}"]')
    lines.append("")

    atlas_ids: dict[str, list[str]] = {}
    for name, spec in CHARACTER_STRIPS.items():
        ids, chunks = atlas_resources(ext_ids[name], name, spec.frame_count, spec.cell_size)
        atlas_ids[name] = ids
        lines.extend(chunks)

    animations = [
        animation_block("attack", atlas_ids["attack"], 14.0, False),
        animation_block("attack_1", atlas_ids["attack"], 14.0, False),
        animation_block("attack_2", atlas_ids["attack"], 14.0, False),
        animation_block("attack_3", atlas_ids["attack"], 14.0, False),
        animation_block("death", atlas_ids["death"], 8.0, False),
        animation_block("dodge", atlas_ids["dodge"], 12.0, False),
        animation_block("fall", atlas_ids["fall"], 8.0, True),
        animation_block("hurt", atlas_ids["hurt"], 8.0, False),
        animation_block("idle", atlas_ids["idle"], 6.0, True),
        animation_block("jump", atlas_ids["jump"], 8.0, False),
        animation_block("land", atlas_ids["land"], 10.0, False),
        animation_block("run", atlas_ids["run"], 10.0, True),
        animation_block("skill", atlas_ids["skill"], 10.0, False),
        animation_block("throw", atlas_ids["throw"], 24.0, False),
    ]
    lines.append("[resource]")
    lines.append("animations = [" + ", ".join(animations) + "]")
    (ROOT / "resources/sprite_frames/kira_sprite_frames.tres").write_text("\n".join(lines) + "\n")


def write_projectile_sprite_frames() -> None:
    ids, chunks = atlas_resources("small_fireball_sheet", "fly", 4, (64, 64))
    (ROOT / "resources/sprite_frames/fire_orb_sprite_frames.tres").write_text(
        '[gd_resource type="SpriteFrames" format=3]\n\n'
        '[ext_resource type="Texture2D" path="res://assets/projectiles/kira/small_fireball.png" id="small_fireball_sheet"]\n\n'
        + "\n".join(chunks)
        + "\n[resource]\n"
        + "animations = ["
        + animation_block("fly", ids, 18.0, True)
        + "]\n"
    )

    fly_ids, fly_chunks = atlas_resources("large_fireball_sheet", "fly", 6, (128, 128))
    burst_ids, burst_chunks = atlas_resources("fire_burst_sheet", "burst", 8, (192, 192))
    impact_burst_ids = burst_ids[2:]
    (ROOT / "resources/sprite_frames/fireball_sprite_frames.tres").write_text(
        '[gd_resource type="SpriteFrames" format=3]\n\n'
        '[ext_resource type="Texture2D" path="res://assets/projectiles/kira/large_fireball.png" id="large_fireball_sheet"]\n'
        '[ext_resource type="Texture2D" path="res://assets/vfx/kira/fire_burst.png" id="fire_burst_sheet"]\n\n'
        + "\n".join(fly_chunks + burst_chunks)
        + "\n[resource]\n"
        + "animations = ["
        + animation_block("fly", fly_ids, 18.0, True)
        + ", "
        + animation_block("burst", impact_burst_ids, 20.0, False)
        + "]\n"
    )


def write_qa_preview() -> None:
    rows = [Image.open(spec.output).convert("RGBA") for spec in CHARACTER_STRIPS.values()]
    width = max(row.width for row in rows)
    height = sum(row.height for row in rows) + 8 * (len(rows) + 1)
    preview = Image.new("RGBA", (width, height), (0, 0, 0, 255))
    y = 8
    for row in rows:
        preview.alpha_composite(row, (0, y))
        y += row.height + 8
    QA_PREVIEW.parent.mkdir(parents=True, exist_ok=True)
    preview.save(QA_PREVIEW)


def visible_data(image: Image.Image):
    data = image.get_flattened_data() if hasattr(image, "get_flattened_data") else image.getdata()
    return [pixel for pixel in data if pixel[3] != 0]


def frame_bbox(sheet: Image.Image, index: int, cell_size: tuple[int, int]) -> tuple[int, int, int, int] | None:
    frame = sheet.crop((index * cell_size[0], 0, (index + 1) * cell_size[0], cell_size[1]))
    return frame.getchannel("A").getbbox()


def verify_strip(name: str, spec: StripSpec) -> None:
    image = Image.open(spec.output).convert("RGBA")
    expected = (spec.cell_size[0] * spec.frame_count, spec.cell_size[1])
    if image.size != expected:
        raise AssertionError(f"{name}: expected {expected}, got {image.size}")
    if image.mode != "RGBA":
        raise AssertionError(f"{name}: expected RGBA, got {image.mode}")
    if image.getchannel("A").getbbox() is None:
        raise AssertionError(f"{name}: strip is blank")
    for r, g, b, _a in visible_data(image):
        if is_green_spill(r, g, b):
            raise AssertionError(f"{name}: green spill remains at RGB({r}, {g}, {b})")
    for index in range(spec.frame_count):
        bbox = frame_bbox(image, index, spec.cell_size)
        if bbox is None:
            raise AssertionError(f"{name}: frame {index} is blank")
        if spec.ground_y is not None and abs(bbox[3] - spec.ground_y) > 2:
            raise AssertionError(f"{name}: frame {index} ground {bbox[3]} does not match {spec.ground_y}")


def verify_character_drift(name: str, spec: StripSpec) -> None:
    image = Image.open(spec.output).convert("RGBA")
    anchors: list[float] = []
    for index in range(spec.frame_count):
        frame = image.crop((index * spec.cell_size[0], 0, (index + 1) * spec.cell_size[0], spec.cell_size[1]))
        anchors.append(estimate_character_anchor_x(frame))
    if pstdev(anchors) > 7.0:
        raise AssertionError(f"{name}: character pivot drift too high: {anchors}")


def main() -> None:
    for spec in CHARACTER_STRIPS.values():
        process_strip(spec)
    for spec in PROJECTILE_STRIPS.values():
        process_strip(spec)
    for spec in VFX_STRIPS.values():
        process_strip(spec)

    write_kira_sprite_frames()
    write_projectile_sprite_frames()
    write_qa_preview()

    for name, spec in CHARACTER_STRIPS.items():
        verify_strip(name, spec)
        verify_character_drift(name, spec)
    for name, spec in PROJECTILE_STRIPS.items():
        verify_strip(name, spec)
    for name, spec in VFX_STRIPS.items():
        verify_strip(name, spec)


if __name__ == "__main__":
    main()
