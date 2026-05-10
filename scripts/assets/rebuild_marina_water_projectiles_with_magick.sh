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
    0) crop="22x18+20+931" ;;
    1) crop="28x20+55+930" ;;
    2) crop="34x24+95+927" ;;
    3) crop="42x26+128+925" ;;
    4) crop="48x30+166+920" ;;
    5) crop="54x34+207+918" ;;
    6) crop="62x38+252+917" ;;
    7) crop="72x42+315+914" ;;
    8) crop="82x48+356+910" ;;
    *) crop="94x54+487+908" ;;
  esac
  make_frame "$crop" "assets/projectiles/waterball/img_${i}.png" "$angle"
done

for i in $(seq 0 29); do
  angle=$(( (i % 10) * 3 - 14 ))
  case $(( i % 5 )) in
    0) crop="88x58+468+908" ;;
    1) crop="104x64+525+905" ;;
    2) crop="116x70+585+900" ;;
    3) crop="128x78+668+896" ;;
    *) crop="142x86+757+894" ;;
  esac
  make_frame "$crop" "assets/projectiles/waterball_medium/img_${i}.png" "$angle" "200x200" "132x132>"
done

for i in $(seq 0 11); do
  angle=$(( (i % 6) * 2 - 5 ))
  case $(( i % 4 )) in
    0) crop="118x68+872+900" ;;
    1) crop="124x70+993+900" ;;
    2) crop="128x80+1110+895" ;;
    *) crop="146x88+1230+891" ;;
  esac
  make_frame "$crop" "assets/projectiles/water_ability_burst/img_${i}.png" "$angle" "200x200" "150x150>"
done

cp "$alpha_source" assets/characters/marina/generated_source/marina_water_projectiles_alpha_magick.png
