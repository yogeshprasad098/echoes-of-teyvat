#!/usr/bin/env bash
set -euo pipefail

character="${1:?usage: rebuild_party_character_with_magick.sh marina|ryne}"
out_dir="assets/characters/$character"
source_image="$out_dir/generated_source/${character}_rework_source_chromakey.png"
work_dir="tmp/asset_generation/${character}_rework/magick_frames"
alpha_source="tmp/asset_generation/${character}_rework/${character}_rework_source_alpha_magick.png"
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

build_marina() {
  frame idle_0 "155x222+91+29"
  frame idle_1 "155x222+91+29"
  frame idle_2 "155x222+91+29"
  frame idle_3 "155x222+91+29"

  frame run_0 "183x203+430+48"
  frame run_1 "188x199+692+51"
  frame run_2 "168x200+979+51"
  frame run_3 "200x189+1245+61"
  frame run_4 "183x203+430+48"
  frame run_5 "188x199+692+51"

  frame attack_0 "253x214+73+284"
  frame attack_1 "272x212+379+286"
  frame attack_2 "297x206+694+292"
  frame attack_3 "261x206+1218+292"
  frame attack_4 "253x214+73+284"
  frame attack_5 "272x212+379+286"

  frame jump_0 "235x206+65+524"
  frame jump_1 "178x176+382+529"
  frame jump_2 "178x176+382+529"

  frame dodge_0 "309x121+685+589" "128x62>"
  frame dodge_1 "210x117+1191+595" "126x62>"
  frame dodge_2 "309x121+685+589" "128x62>"
  frame dodge_3 "178x176+382+529" "x78"

  frame hurt_0 "173x209+74+760"
  frame hurt_1 "148x212+395+757"

  frame throw_0 "253x214+73+284"
  frame throw_1 "272x212+379+286"
  frame throw_2 "297x206+694+292"

  frame skill_0 "253x214+73+284"
  frame skill_1 "261x206+1218+292"
  frame skill_2 "337x86+1081+881" "150x58>"
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
  "$out_dir/generated_source/${character}_rework_preview.png"

cp "$alpha_source" "$out_dir/generated_source/${character}_rework_source_alpha_magick.png"
