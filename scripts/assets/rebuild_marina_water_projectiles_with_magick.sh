#!/usr/bin/env bash
set -euo pipefail

source_image="${1:-assets/characters/marina/generated_source/marina_rework_source_chromakey.png}"
work_dir="tmp/asset_generation/marina_rework/projectiles"
alpha_source="$work_dir/marina_water_projectiles_alpha_magick.png"

mkdir -p "$work_dir" assets/projectiles/waterball assets/projectiles/waterball_medium assets/projectiles/water_ability_burst
rm -f "$work_dir"/*.png

magick "$source_image" \
  -alpha set \
  -fuzz 12% \
  -transparent "#00ff00" \
  -channel A \
  -fx '((g > r * 1.18) && (g > b * 1.18) && (g > 0.12)) ? 0 : a' \
  +channel \
  -channel A -threshold 35% +channel \
  -channel G \
  -fx '((a > 0) && (g > r * 1.25) && (g > b * 1.18)) ? max(r,b) * 0.70 : g' \
  +channel \
  -filter point \
  "$alpha_source"

make_frame() {
  local source_crop="$1"
  local output="$2"
  local rotate="${3:-0}"
  local extent="${4:-200x200}"
  local resize_spec="${5:-120x120>}"

  magick "$alpha_source" \
    -crop "$source_crop" +repage \
    -trim +repage \
    -filter point \
    -resize "$resize_spec" \
    -background none \
    -rotate "$rotate" \
    -gravity center \
    -extent "$extent" \
    "$output"
}

for i in $(seq 0 29); do
  angle=$(( (i % 10) * 3 - 14 ))
  case $(( i % 10 )) in
    0) crop="24x22+26+730" ;;
    1) crop="26x24+56+730" ;;
    2) crop="30x26+86+728" ;;
    3) crop="36x28+118+727" ;;
    4) crop="40x30+150+726" ;;
    5) crop="44x32+182+725" ;;
    6) crop="50x34+214+724" ;;
    7) crop="56x36+250+724" ;;
    8) crop="64x38+286+722" ;;
    *) crop="72x40+324+722" ;;
  esac
  make_frame "$crop" "assets/projectiles/waterball/img_${i}.png" "$angle"
done

for i in $(seq 0 29); do
  angle=$(( (i % 10) * 3 - 14 ))
  case $(( i % 5 )) in
    0) crop="64x48+24+782" ;;
    1) crop="82x52+100+780" ;;
    2) crop="92x54+198+780" ;;
    3) crop="104x56+300+780" ;;
    *) crop="124x58+386+778" ;;
  esac
  make_frame "$crop" "assets/projectiles/waterball_medium/img_${i}.png" "$angle" "200x200" "132x132>"
done

for i in $(seq 0 11); do
  angle=$(( (i % 6) * 2 - 5 ))
  case $(( i % 4 )) in
    0) crop="108x78+16+844" ;;
    1) crop="118x78+144+850" ;;
    2) crop="112x78+376+844" ;;
    *) crop="124x78+584+846" ;;
  esac
  make_frame "$crop" "assets/projectiles/water_ability_burst/img_${i}.png" "$angle" "200x200" "150x150>"
done

cp "$alpha_source" assets/characters/marina/generated_source/marina_water_projectiles_alpha_magick.png
