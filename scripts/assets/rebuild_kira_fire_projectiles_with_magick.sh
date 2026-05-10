#!/usr/bin/env bash
set -euo pipefail

source_image="${1:-assets/characters/kira/generated_source/kira_clean_source_chromakey.png}"
work_dir="tmp/asset_generation/kira_clean/projectiles"
alpha_source="$work_dir/kira_clean_projectiles_alpha_magick.png"

mkdir -p "$work_dir" assets/projectiles/fireball assets/projectiles/fireball_medium assets/projectiles/fire_ability_burst
rm -f "$work_dir"/*.png

magick "$source_image" \
  -alpha set \
  -channel A \
  -fx '((g > r * 1.08) && (g > b * 1.08) && (g > 0.10)) ? 0 : a' \
  +channel \
  -fuzz 24% \
  -transparent "#07f809" \
  -channel A -threshold 40% +channel \
  -filter point \
  "$alpha_source"

make_frame() {
  local source_crop="$1"
  local output="$2"
  local rotate="${3:-0}"
  local extent="${4:-200x200}"

  magick "$alpha_source" \
    -crop "$source_crop" +repage \
    -trim +repage \
    -filter point \
    -resize "120x120>" \
    -background none \
    -rotate "$rotate" \
    -gravity center \
    -extent "$extent" \
    "$output"
}

for i in $(seq 0 29); do
  angle=$(( (i % 10) * 4 - 18 ))
  case $(( i % 5 )) in
    0) crop="34x32+700+64" ;;
    1) crop="42x34+1030+63" ;;
    2) crop="54x36+1202+62" ;;
    3) crop="68x38+1408+61" ;;
    *) crop="42x34+860+64" ;;
  esac
  make_frame "$crop" "assets/projectiles/fireball/img_${i}.png" "$angle"
done

for i in $(seq 0 29); do
  angle=$(( (i % 10) * 3 - 14 ))
  case $(( i % 5 )) in
    0) crop="78x60+1400+53" ;;
    1) crop="120x100+1300+641" ;;
    2) crop="116x96+1310+648" ;;
    3) crop="104x90+1324+652" ;;
    *) crop="92x76+1334+660" ;;
  esac
  make_frame "$crop" "assets/projectiles/fireball_medium/img_${i}.png" "$angle"
done

for i in $(seq 0 11); do
  angle=$(( (i % 6) * 3 - 8 ))
  case $(( i % 4 )) in
    0) crop="190x118+930+790" ;;
    1) crop="210x112+1040+792" ;;
    2) crop="180x108+1075+802" ;;
    *) crop="170x92+1115+806" ;;
  esac
  make_frame "$crop" "assets/projectiles/fire_ability_burst/img_${i}.png" "$angle"
done

cp "$alpha_source" assets/characters/kira/generated_source/kira_clean_projectiles_alpha_magick.png
