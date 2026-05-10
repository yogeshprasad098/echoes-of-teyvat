#!/usr/bin/env bash
set -euo pipefail

source_image="${1:-assets/characters/kira/generated_source/kira_clean_source_chromakey.png}"
out_dir="assets/characters/kira"
work_dir="tmp/asset_generation/kira_clean/magick_frames"
alpha_source="tmp/asset_generation/kira_clean/kira_clean_source_alpha_magick.png"
frame_width=192
frame_height=96
content_height=92

mkdir -p "$work_dir" "$out_dir" "$out_dir/generated_source"
rm -f "$work_dir"/*.png

magick "$source_image" \
  -alpha set \
  -channel A \
  -fx '((g > r * 1.08) && (g > b * 1.08) && (g > 0.10)) ? 0 : a' \
  +channel \
  -fuzz 24% \
  -transparent "#07f809" \
  -channel A -threshold 40% +channel \
  -channel G \
  -fx '((a > 0) && (g > r * 1.05) && (g > b * 1.05)) ? max(r,b) * 0.72 : g' \
  +channel \
  -filter point \
  "$alpha_source"

frame() {
  local name="$1"
  local box="$2"
  local resize_spec="${3:-x86}"
  local size="${box%%+*}"
  local rest="${box#*+}"
  local x="${rest%%+*}"
  local y="${rest#*+}"

  magick "$alpha_source" \
    -crop "${size}+${x}+${y}" +repage \
    -trim +repage \
    -filter point \
    -resize "$resize_spec" \
    -background none \
    -gravity south \
    -extent "${frame_width}x${content_height}" \
    -gravity north \
    -extent "${frame_width}x${frame_height}" \
    "$work_dir/${name}_raw.png"

  magick \
    \( "$work_dir/${name}_raw.png" -alpha extract -threshold 1% -morphology Dilate Diamond:1 -fill "#1a0b10" -opaque white -transparent black \) \
    "$work_dir/${name}_raw.png" \
    -compose over \
    -composite \
    "$work_dir/${name}.png"
}

strip() {
  local output="$1"
  shift
  magick "$@" +append "$out_dir/${output}.png"
}

frame idle_0 "72x120+54+20"
frame idle_1 "61x120+174+19"
frame idle_2 "70x119+277+20"
frame idle_3 "72x120+383+19"

frame run_0 "92x103+48+156"
frame run_1 "82x103+199+156"
frame run_2 "86x103+351+156"
frame run_3 "89x103+489+156"
frame run_4 "86x102+629+156"
frame run_5 "91x105+775+154"

frame attack_0 "67x119+499+20"
frame attack_1 "135x106+600+33" "176x82>"
frame attack_2 "151x106+747+33" "176x82>"
frame attack_3 "166x106+912+33" "176x82>"
frame attack_4 "176x106+1095+33" "176x82>"
frame attack_5 "194x106+1284+33" "176x82>"

frame jump_0 "77x101+60+283"
frame jump_1 "99x113+235+267"
frame jump_2 "98x109+441+263"

frame dodge_0 "110x66+86+411" "128x60>"
frame dodge_1 "106x63+230+414" "128x60>"
frame dodge_2 "102x63+396+414" "128x60>"
frame dodge_3 "105x59+590+418" "128x58>"

frame hurt_0 "70x115+64+496"
frame hurt_1 "80x105+206+506"

frame throw_0 "83x113+51+625"
frame throw_1 "89x109+176+629"
frame throw_2 "140x109+305+634" "176x82>"

frame skill_0 "88x113+56+755"
frame skill_1 "86x126+212+753"
frame skill_2 "172x138+756+748" "184x84>"

frame death_0 "84x112+48+884"
frame death_1 "81x90+186+906"
frame death_2 "114x63+312+933" "128x60>"
frame death_3 "128x49+470+947" "128x48>"
frame death_4 "125x39+637+957" "128x40>"

strip idle "$work_dir/idle_0.png" "$work_dir/idle_1.png" "$work_dir/idle_2.png" "$work_dir/idle_3.png"
strip run "$work_dir/run_0.png" "$work_dir/run_1.png" "$work_dir/run_2.png" "$work_dir/run_3.png" "$work_dir/run_4.png" "$work_dir/run_5.png"
strip attack "$work_dir/attack_0.png" "$work_dir/attack_1.png" "$work_dir/attack_2.png" "$work_dir/attack_3.png" "$work_dir/attack_4.png" "$work_dir/attack_5.png" "$work_dir/attack_0.png" "$work_dir/attack_1.png" "$work_dir/attack_2.png" "$work_dir/attack_3.png" "$work_dir/attack_4.png" "$work_dir/attack_5.png"
strip jump "$work_dir/jump_0.png" "$work_dir/jump_1.png" "$work_dir/jump_2.png"
strip dodge "$work_dir/dodge_0.png" "$work_dir/dodge_1.png" "$work_dir/dodge_2.png" "$work_dir/dodge_3.png"
strip hurt "$work_dir/hurt_0.png" "$work_dir/hurt_1.png"
strip throw "$work_dir/throw_0.png" "$work_dir/throw_1.png" "$work_dir/throw_2.png" "$work_dir/throw_2.png" "$work_dir/throw_1.png" "$work_dir/throw_0.png" "$work_dir/throw_2.png" "$work_dir/throw_1.png"
strip skill "$work_dir/skill_0.png" "$work_dir/skill_1.png" "$work_dir/skill_2.png" "$work_dir/skill_1.png"
strip death "$work_dir/death_0.png" "$work_dir/death_1.png" "$work_dir/death_2.png" "$work_dir/death_3.png" "$work_dir/death_4.png"

magick \
  "$out_dir/idle.png" \
  "$out_dir/run.png" \
  "$out_dir/attack.png" \
  "$out_dir/jump.png" \
  "$out_dir/dodge.png" \
  "$out_dir/hurt.png" \
  "$out_dir/throw.png" \
  "$out_dir/skill.png" \
  "$out_dir/death.png" \
  -background "#1a1816" \
  -gravity west \
  -splice 0x8 \
  -append \
  "$out_dir/generated_source/kira_clean_preview.png"

cp "$alpha_source" "$out_dir/generated_source/kira_clean_source_alpha_magick.png"
