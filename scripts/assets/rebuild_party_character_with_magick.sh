#!/usr/bin/env bash
set -euo pipefail

character="${1:?usage: rebuild_party_character_with_magick.sh marina|ryne}"
out_dir="assets/characters/$character"
source_image="$out_dir/generated_source/${character}_rework_source_chromakey.png"
if [[ "$character" == "marina" && -f "$out_dir/generated_source/marina_clean_source_chromakey.png" ]]; then
  source_image="$out_dir/generated_source/marina_clean_source_chromakey.png"
fi
work_dir="tmp/asset_generation/${character}_rework/magick_frames"
alpha_source="tmp/asset_generation/${character}_rework/${character}_rework_source_alpha_magick.png"
frame_width=192
frame_height=96
content_height=92

mkdir -p "$work_dir" "$out_dir" "$out_dir/generated_source"
rm -f "$work_dir"/*.png

if [[ "$character" == "marina" ]]; then
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
else
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
fi

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
    -resize "184x88>" \
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

build_marina() {
  frame idle_0 "118x126+28+10" "x88"
  frame idle_1 "118x126+146+10" "x88"
  frame idle_2 "118x126+266+10" "x88"
  frame idle_3 "118x126+146+10" "x88"

  frame run_0 "130x104+18+176" "x88"
  frame run_1 "130x104+142+176" "x88"
  frame run_2 "130x104+268+176" "x88"
  frame run_3 "130x104+388+176" "x88"
  frame run_4 "130x104+506+176" "x88"
  frame run_5 "130x104+624+176" "x88"

  frame attack_0 "118x126+386+10" "x88"
  frame attack_1 "118x126+506+10" "x88"
  frame attack_2 "118x126+626+10" "x88"
  frame attack_3 "118x126+746+10" "x88"
  frame attack_4 "118x126+386+10" "x88"
  frame attack_5 "118x126+506+10" "x88"
  frame attack_6 "118x126+626+10" "x88"
  frame attack_7 "118x126+746+10" "x88"
  frame attack_8 "118x126+386+10" "x88"
  frame attack_9 "118x126+506+10" "x88"
  frame attack_10 "118x126+626+10" "x88"
  frame attack_11 "118x126+746+10" "x88"

  frame jump_0 "118x106+24+328" "x86"
  frame jump_1 "124x106+146+328" "x86"
  frame jump_2 "124x106+268+328" "x86"

  frame dodge_0 "160x72+20+475" "132x64>"
  frame dodge_1 "166x72+196+475" "138x64>"
  frame dodge_2 "166x72+374+475" "138x64>"
  frame dodge_3 "166x72+544+475" "138x64>"

  frame hurt_0 "114x110+1074+460" "x86"
  frame hurt_1 "124x110+1250+460" "x86"

  frame throw_0 "118x126+386+10" "x88"
  frame throw_1 "118x126+506+10" "x88"
  frame throw_2 "118x126+626+10" "x88"
  frame throw_3 "118x126+746+10" "x88"
  frame throw_4 "118x126+386+10" "x88"
  frame throw_5 "118x126+506+10" "x88"
  frame throw_6 "118x126+626+10" "x88"
  frame throw_7 "118x126+746+10" "x88"

  frame skill_0 "118x126+24+746" "x88"
  frame skill_1 "128x126+204+746" "x88"
  frame skill_2 "136x126+392+746" "x88"
  frame skill_3 "142x126+586+746" "x88"

  frame death_0 "112x112+24+888" "x78"
  frame death_1 "124x104+150+898" "x72"
  frame death_2 "152x66+304+918" "132x62>"
  frame death_3 "162x58+470+930" "136x56>"
  frame death_4 "170x52+634+936" "140x52>"
}

build_ryne() {
  frame idle_0 "98x190+69+54"
  frame idle_1 "97x190+231+54"
  frame idle_2 "97x190+394+54"
  frame idle_3 "98x190+69+54"

  frame run_0 "184x175+594+68"
  frame run_1 "193x176+806+68"
  frame run_2 "196x172+1036+71"
  frame run_3 "191x165+1275+77"
  frame run_4 "184x175+594+68"
  frame run_5 "193x176+806+68"

  frame attack_0 "132x173+62+302"
  frame attack_1 "180x173+273+302"
  frame attack_2 "168x172+512+303"
  frame attack_3 "171x173+741+302"
  frame attack_4 "194x178+955+297"
  frame attack_5 "235x182+1216+293"

  frame jump_0 "142x187+61+504"
  frame jump_1 "151x176+296+515"
  frame jump_2 "179x144+528+537"

  frame dodge_0 "274x124+802+558" "128x62>"
  frame dodge_1 "228x105+1136+579" "126x58>"
  frame dodge_2 "274x124+802+558" "128x62>"
  frame dodge_3 "151x176+296+515" "x78"

  frame hurt_0 "157x177+53+761"
  frame hurt_1 "175x181+267+757"

  frame throw_0 "132x173+62+302"
  frame throw_1 "180x173+273+302"
  frame throw_2 "168x172+512+303"

  frame skill_0 "198x174+1082+761"
  frame skill_1 "243x222+1219+713"
  frame skill_2 "250x99+765+836" "150x58>"
}

case "$character" in
  marina) build_marina ;;
  ryne) build_ryne ;;
  *) echo "Unsupported character: $character" >&2; exit 2 ;;
esac

strip idle "$work_dir/idle_0.png" "$work_dir/idle_1.png" "$work_dir/idle_2.png" "$work_dir/idle_3.png"
strip run "$work_dir/run_0.png" "$work_dir/run_1.png" "$work_dir/run_2.png" "$work_dir/run_3.png" "$work_dir/run_4.png" "$work_dir/run_5.png"
if [[ "$character" == "marina" ]]; then
  strip attack "$work_dir/attack_0.png" "$work_dir/attack_1.png" "$work_dir/attack_2.png" "$work_dir/attack_3.png" "$work_dir/attack_4.png" "$work_dir/attack_5.png" "$work_dir/attack_6.png" "$work_dir/attack_7.png" "$work_dir/attack_8.png" "$work_dir/attack_9.png" "$work_dir/attack_10.png" "$work_dir/attack_11.png"
else
  strip attack "$work_dir/attack_0.png" "$work_dir/attack_1.png" "$work_dir/attack_2.png" "$work_dir/attack_3.png" "$work_dir/attack_4.png" "$work_dir/attack_5.png" "$work_dir/attack_0.png" "$work_dir/attack_1.png" "$work_dir/attack_2.png" "$work_dir/attack_3.png" "$work_dir/attack_4.png" "$work_dir/attack_5.png"
fi
strip jump "$work_dir/jump_0.png" "$work_dir/jump_1.png" "$work_dir/jump_2.png"
strip dodge "$work_dir/dodge_0.png" "$work_dir/dodge_1.png" "$work_dir/dodge_2.png" "$work_dir/dodge_3.png"
strip hurt "$work_dir/hurt_0.png" "$work_dir/hurt_1.png"
if [[ "$character" == "marina" ]]; then
  strip throw "$work_dir/throw_0.png" "$work_dir/throw_1.png" "$work_dir/throw_2.png" "$work_dir/throw_3.png" "$work_dir/throw_4.png" "$work_dir/throw_5.png" "$work_dir/throw_6.png" "$work_dir/throw_7.png"
  strip skill "$work_dir/skill_0.png" "$work_dir/skill_1.png" "$work_dir/skill_2.png" "$work_dir/skill_3.png"
else
  strip throw "$work_dir/throw_0.png" "$work_dir/throw_1.png" "$work_dir/throw_2.png" "$work_dir/throw_2.png" "$work_dir/throw_1.png" "$work_dir/throw_0.png" "$work_dir/throw_2.png" "$work_dir/throw_1.png"
  strip skill "$work_dir/skill_0.png" "$work_dir/skill_1.png" "$work_dir/skill_2.png" "$work_dir/skill_1.png"
fi
if [[ "$character" == "marina" ]]; then
  strip death "$work_dir/death_0.png" "$work_dir/death_1.png" "$work_dir/death_2.png" "$work_dir/death_3.png" "$work_dir/death_4.png"
else
  strip death "$work_dir/hurt_0.png" "$work_dir/hurt_1.png" "$work_dir/dodge_0.png" "$work_dir/hurt_0.png" "$work_dir/hurt_0.png"
fi

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
  "$out_dir/generated_source/${character}_rework_preview.png"

cp "$alpha_source" "$out_dir/generated_source/${character}_rework_source_alpha_magick.png"
