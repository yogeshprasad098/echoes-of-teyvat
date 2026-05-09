#!/usr/bin/env bash
set -euo pipefail

source_image="${1:-assets/characters/kira/generated_source/kira_rework_source_chromakey.png}"
out_dir="assets/characters/kira"
work_dir="tmp/asset_generation/kira_rework/magick_frames"
alpha_source="tmp/asset_generation/kira_rework/kira_rework_source_alpha_magick.png"
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

frame idle_0 "92x141+103+39"
frame idle_1 "99x144+275+36"
frame idle_2 "101x144+433+36"
frame idle_3 "95x144+607+36"

frame run_0 "117x144+103+218"
frame run_1 "112x140+292+219"
frame run_2 "114x140+479+219"
frame run_3 "115x141+660+218"
frame run_4 "124x144+843+218"
frame run_5 "110x144+1028+218"

frame attack_0 "142x140+62+397"
frame attack_1 "183x140+271+398"
frame attack_2 "170x140+494+397"
frame attack_3 "205x135+734+402"
frame attack_4 "120x131+934+407"
frame attack_5 "182x123+1156+415"

frame jump_0 "123x148+112+576"
frame jump_1 "98x131+325+593"
frame jump_2 "123x135+525+593"

frame dodge_0 "187x96+735+632" "124x64>"
frame dodge_1 "123x135+525+593" "x78"
frame dodge_2 "187x96+735+632" "124x64>"
frame dodge_3 "114x119+232+839" "x78"

frame hurt_0 "111x139+66+816"
frame hurt_1 "123x148+112+576"

frame throw_0 "114x119+232+839"
frame throw_1 "121x129+403+829"
frame throw_2 "149x126+543+832"

frame skill_0 "137x145+891+813"
frame skill_1 "147x145+1051+813"
frame skill_2 "199x194+1243+765"

strip idle "$work_dir/idle_0.png" "$work_dir/idle_1.png" "$work_dir/idle_2.png" "$work_dir/idle_3.png"
strip run "$work_dir/run_0.png" "$work_dir/run_1.png" "$work_dir/run_2.png" "$work_dir/run_3.png" "$work_dir/run_4.png" "$work_dir/run_5.png"
strip attack "$work_dir/attack_0.png" "$work_dir/attack_1.png" "$work_dir/attack_2.png" "$work_dir/attack_3.png" "$work_dir/attack_4.png" "$work_dir/attack_5.png" "$work_dir/attack_0.png" "$work_dir/attack_1.png" "$work_dir/attack_2.png" "$work_dir/attack_3.png" "$work_dir/attack_4.png" "$work_dir/attack_5.png"
strip jump "$work_dir/jump_0.png" "$work_dir/jump_1.png" "$work_dir/jump_2.png"
strip dodge "$work_dir/dodge_0.png" "$work_dir/dodge_1.png" "$work_dir/dodge_2.png" "$work_dir/dodge_3.png"
strip hurt "$work_dir/hurt_0.png" "$work_dir/hurt_1.png"
strip throw "$work_dir/throw_0.png" "$work_dir/throw_1.png" "$work_dir/throw_2.png" "$work_dir/throw_2.png" "$work_dir/throw_1.png" "$work_dir/throw_0.png" "$work_dir/throw_2.png" "$work_dir/throw_1.png"
strip skill "$work_dir/skill_0.png" "$work_dir/skill_1.png" "$work_dir/skill_2.png" "$work_dir/skill_1.png"
strip death "$work_dir/hurt_0.png" "$work_dir/hurt_1.png" "$work_dir/dodge_0.png" "$work_dir/hurt_0.png" "$work_dir/hurt_0.png"

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
  "$out_dir/generated_source/kira_rework_preview.png"

cp "$alpha_source" "$out_dir/generated_source/kira_rework_source_alpha_magick.png"
