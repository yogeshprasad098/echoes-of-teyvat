from __future__ import annotations

import math
import random
from pathlib import Path

from PIL import Image, ImageDraw


ROOT = Path(__file__).resolve().parents[2]
TILESET_PATH = ROOT / "assets/tilesets/drowned_coast/drowned_coast_tileset.png"
BACKGROUND_ROOT = ROOT / "assets/backgrounds/drowned_coast"

TILE_SIZE = 32
ATLAS_SIZE = 128
BG_SIZE = (320, 180)

INK = (7, 22, 35, 255)
DEEP = (12, 56, 84, 255)
SEA = (24, 103, 135, 255)
FOAM = (133, 226, 232, 255)
SAND = (160, 139, 91, 255)
STONE = (66, 89, 100, 255)
STONE_DARK = (34, 55, 67, 255)
MOSS = (42, 132, 116, 255)
CORAL = (211, 91, 113, 255)


def main() -> None:
    random.seed(42)
    TILESET_PATH.parent.mkdir(parents=True, exist_ok=True)
    BACKGROUND_ROOT.mkdir(parents=True, exist_ok=True)
    build_tileset().save(TILESET_PATH)
    build_far_background().save(BACKGROUND_ROOT / "bg_far_fallback.png")
    build_mid_background().save(BACKGROUND_ROOT / "bg_mid.png")
    build_near_background().save(BACKGROUND_ROOT / "bg_near.png")


def build_tileset() -> Image.Image:
    atlas = Image.new("RGBA", (ATLAS_SIZE, ATLAS_SIZE), (0, 0, 0, 0))
    drawers = [
        draw_wet_stone_top,
        draw_wet_stone_body,
        draw_water_pool,
        draw_sand_edge,
        draw_left_cliff,
        draw_center_cliff,
        draw_right_cliff,
        draw_ruin_block,
        draw_mossy_cap,
        draw_dark_rock,
        draw_foam_lip,
        draw_coral_rock,
        draw_tide_tile,
        draw_shell_sand,
        draw_cracked_slab,
        draw_deep_fill,
    ]
    for index, drawer in enumerate(drawers):
        tile = Image.new("RGBA", (TILE_SIZE, TILE_SIZE), (0, 0, 0, 0))
        drawer(tile)
        atlas.alpha_composite(tile, ((index % 4) * TILE_SIZE, (index // 4) * TILE_SIZE))
    return atlas


def draw_wet_stone_top(tile: Image.Image) -> None:
    d = ImageDraw.Draw(tile)
    d.rectangle((0, 10, 31, 31), fill=STONE_DARK)
    d.rectangle((0, 0, 31, 13), fill=STONE)
    d.polygon([(0, 0), (31, 0), (31, 7), (23, 10), (14, 8), (7, 12), (0, 10)], fill=(82, 116, 126, 255))
    d.line((0, 13, 31, 13), fill=INK)
    d.line((2, 4, 11, 2, 20, 5, 30, 3), fill=FOAM, width=1)
    scatter(tile, MOSS, 10, y_range=(5, 28))


def draw_wet_stone_body(tile: Image.Image) -> None:
    d = ImageDraw.Draw(tile)
    d.rectangle((0, 0, 31, 31), fill=STONE_DARK)
    for y in range(4, 32, 8):
        d.line((0, y, 31, y + random.randint(-1, 1)), fill=INK)
    for x in range(6, 32, 11):
        d.line((x, 0, x + random.randint(-2, 2), 31), fill=(46, 71, 82, 255))
    scatter(tile, (76, 112, 124, 255), 18)


def draw_water_pool(tile: Image.Image) -> None:
    d = ImageDraw.Draw(tile)
    d.rectangle((0, 0, 31, 31), fill=DEEP)
    for y in range(4, 31, 7):
        d.arc((2, y - 6, 29, y + 6), 12, 168, fill=SEA)
    d.line((0, 4, 31, 2), fill=FOAM)
    d.line((3, 16, 17, 14), fill=(80, 190, 208, 255))
    d.line((19, 23, 30, 22), fill=(80, 190, 208, 255))


def draw_sand_edge(tile: Image.Image) -> None:
    d = ImageDraw.Draw(tile)
    d.rectangle((0, 0, 31, 31), fill=SAND)
    d.polygon([(0, 0), (31, 0), (31, 7), (21, 10), (12, 7), (0, 11)], fill=(204, 181, 120, 255))
    d.line((0, 11, 31, 7), fill=INK)
    scatter(tile, (105, 91, 60, 255), 22)


def draw_left_cliff(tile: Image.Image) -> None:
    d = ImageDraw.Draw(tile)
    d.rectangle((10, 0, 31, 31), fill=STONE_DARK)
    d.rectangle((0, 0, 12, 31), fill=INK)
    d.line((14, 4, 29, 2), fill=(79, 109, 118, 255), width=2)
    scatter(tile, MOSS, 9)


def draw_center_cliff(tile: Image.Image) -> None:
    d = ImageDraw.Draw(tile)
    d.rectangle((0, 0, 31, 31), fill=(47, 72, 84, 255))
    d.rectangle((0, 0, 31, 7), fill=(90, 123, 132, 255))
    d.line((0, 8, 31, 8), fill=INK)
    scatter(tile, (31, 51, 63, 255), 24)


def draw_right_cliff(tile: Image.Image) -> None:
    d = ImageDraw.Draw(tile)
    d.rectangle((0, 0, 21, 31), fill=STONE_DARK)
    d.rectangle((20, 0, 31, 31), fill=INK)
    d.line((2, 3, 18, 5), fill=(79, 109, 118, 255), width=2)
    scatter(tile, MOSS, 9)


def draw_ruin_block(tile: Image.Image) -> None:
    d = ImageDraw.Draw(tile)
    d.rectangle((0, 0, 31, 31), fill=(55, 79, 90, 255))
    d.rectangle((3, 3, 28, 28), outline=INK)
    d.line((4, 14, 27, 12), fill=(35, 55, 66, 255))
    d.line((15, 4, 14, 28), fill=(35, 55, 66, 255))
    d.rectangle((20, 5, 25, 10), fill=MOSS)


def draw_mossy_cap(tile: Image.Image) -> None:
    d = ImageDraw.Draw(tile)
    d.rectangle((0, 9, 31, 31), fill=STONE_DARK)
    d.rectangle((0, 0, 31, 12), fill=MOSS)
    d.line((0, 12, 31, 12), fill=INK)
    d.line((4, 4, 26, 3), fill=(96, 188, 160, 255))


def draw_dark_rock(tile: Image.Image) -> None:
    d = ImageDraw.Draw(tile)
    d.rectangle((0, 0, 31, 31), fill=(22, 42, 55, 255))
    for _ in range(5):
        x = random.randint(0, 24)
        y = random.randint(2, 28)
        d.line((x, y, x + random.randint(4, 10), y - random.randint(0, 4)), fill=(49, 76, 88, 255))


def draw_foam_lip(tile: Image.Image) -> None:
    d = ImageDraw.Draw(tile)
    d.rectangle((0, 0, 31, 31), fill=SEA)
    d.polygon([(0, 0), (31, 0), (31, 9), (25, 7), (18, 12), (9, 8), (0, 13)], fill=FOAM)
    d.line((0, 13, 31, 9), fill=INK)


def draw_coral_rock(tile: Image.Image) -> None:
    draw_wet_stone_body(tile)
    d = ImageDraw.Draw(tile)
    d.line((8, 23, 8, 13), fill=CORAL, width=2)
    d.line((8, 17, 4, 13), fill=CORAL, width=2)
    d.line((8, 18, 13, 13), fill=CORAL, width=2)
    d.line((22, 25, 22, 16), fill=(235, 143, 91, 255), width=2)


def draw_tide_tile(tile: Image.Image) -> None:
    d = ImageDraw.Draw(tile)
    d.rectangle((0, 0, 31, 31), fill=DEEP)
    d.polygon([(0, 20), (8, 17), (15, 21), (24, 18), (31, 20), (31, 31), (0, 31)], fill=STONE_DARK)
    d.line((1, 17, 12, 15), fill=FOAM)
    d.line((18, 14, 30, 13), fill=FOAM)


def draw_shell_sand(tile: Image.Image) -> None:
    draw_sand_edge(tile)
    d = ImageDraw.Draw(tile)
    d.arc((7, 17, 17, 27), 200, 340, fill=(239, 221, 174, 255), width=2)
    d.arc((20, 8, 28, 16), 20, 160, fill=(239, 221, 174, 255), width=1)


def draw_cracked_slab(tile: Image.Image) -> None:
    draw_ruin_block(tile)
    d = ImageDraw.Draw(tile)
    d.line((4, 5, 13, 13, 10, 22, 19, 29), fill=INK)
    d.line((16, 12, 26, 7), fill=INK)


def draw_deep_fill(tile: Image.Image) -> None:
    d = ImageDraw.Draw(tile)
    d.rectangle((0, 0, 31, 31), fill=DEEP)
    scatter(tile, (18, 72, 99, 255), 28)


def build_far_background() -> Image.Image:
    image = vertical_gradient(BG_SIZE, (7, 31, 54), (28, 100, 132))
    d = ImageDraw.Draw(image)
    d.rectangle((0, 115, 319, 179), fill=(14, 69, 101, 255))
    draw_wave_lines(d, 118, 176, (56, 151, 174, 180), spacing=13)
    d.polygon([(0, 96), (42, 74), (78, 92), (116, 68), (162, 101), (0, 118)], fill=(20, 67, 82, 255))
    d.polygon([(175, 94), (223, 64), (268, 80), (319, 55), (319, 122), (175, 119)], fill=(18, 61, 78, 255))
    d.ellipse((239, 22, 282, 65), fill=(119, 205, 205, 90))
    return image


def build_mid_background() -> Image.Image:
    image = vertical_gradient(BG_SIZE, (12, 48, 75), (31, 116, 137))
    d = ImageDraw.Draw(image)
    d.rectangle((0, 123, 319, 179), fill=(17, 80, 111, 255))
    draw_wave_lines(d, 126, 176, (99, 203, 211, 190), spacing=11)
    for x, top, width in [(30, 84, 30), (88, 70, 40), (224, 78, 34), (272, 92, 28)]:
        d.polygon([(x, 124), (x + width // 2, top), (x + width, 124)], fill=(39, 70, 81, 255))
        d.polygon([(x + 4, 124), (x + width // 2, top + 10), (x + width - 4, 124)], fill=(58, 95, 103, 255))
        d.line((x + 5, 121, x + width - 6, 119), fill=FOAM, width=1)
    d.rectangle((134, 90, 176, 128), fill=(45, 75, 86, 255))
    d.rectangle((142, 76, 168, 92), fill=(59, 96, 106, 255))
    d.rectangle((151, 53, 159, 77), fill=(43, 72, 84, 255))
    d.line((134, 128, 176, 128), fill=INK)
    return image


def build_near_background() -> Image.Image:
    image = vertical_gradient(BG_SIZE, (10, 45, 68), (23, 97, 118))
    d = ImageDraw.Draw(image)
    d.rectangle((0, 112, 319, 179), fill=(13, 67, 94, 255))
    draw_wave_lines(d, 114, 178, (112, 221, 224, 210), spacing=9)
    for x in range(-20, 340, 52):
        d.polygon([(x, 179), (x + 16, 133), (x + 46, 125), (x + 72, 179)], fill=(31, 54, 66, 255))
        d.polygon([(x + 8, 175), (x + 24, 140), (x + 46, 134), (x + 62, 175)], fill=(56, 86, 94, 255))
        d.line((x + 11, 141, x + 43, 134), fill=(88, 127, 131, 255), width=1)
    for x in [28, 64, 236, 282]:
        d.line((x, 166, x + 1, 136), fill=MOSS, width=2)
        d.line((x, 148, x - 8, 139), fill=(91, 184, 160, 255), width=1)
        d.line((x, 152, x + 9, 144), fill=(91, 184, 160, 255), width=1)
    return image


def vertical_gradient(size: tuple[int, int], top: tuple[int, int, int], bottom: tuple[int, int, int]) -> Image.Image:
    width, height = size
    image = Image.new("RGBA", size)
    d = ImageDraw.Draw(image)
    for y in range(height):
        t = y / max(1, height - 1)
        color = tuple(int(top[i] * (1.0 - t) + bottom[i] * t) for i in range(3)) + (255,)
        d.line((0, y, width, y), fill=color)
    return image


def draw_wave_lines(d: ImageDraw.ImageDraw, y_min: int, y_max: int, color: tuple[int, int, int, int], *, spacing: int) -> None:
    for y in range(y_min, y_max, spacing):
        for x in range(-20, 340, 38):
            points = []
            for step in range(0, 34, 4):
                points.append((x + step, y + int(math.sin((x + step) * 0.16) * 2)))
            d.line(points, fill=color, width=1)


def scatter(tile: Image.Image, color: tuple[int, int, int, int], count: int, *, y_range: tuple[int, int] = (0, 31)) -> None:
    pixels = tile.load()
    for _ in range(count):
        x = random.randint(1, 30)
        y = random.randint(y_range[0], y_range[1])
        pixels[x, y] = color


if __name__ == "__main__":
    main()
