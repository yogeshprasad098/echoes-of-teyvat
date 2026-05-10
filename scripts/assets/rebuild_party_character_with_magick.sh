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
  frame idle_0 "76x111+48+15"
  frame idle_1 "73x111+147+15"
  frame idle_2 "72x111+239+15"
  frame idle_3 "73x111+330+15"

  frame run_0 "106x101+24+256"
  frame run_1 "99x96+195+259"
  frame run_2 "103x99+309+257"
  frame run_3 "86x96+449+260"
  frame run_4 "84x96+570+260"
  frame run_5 "90x96+716+262"

  frame attack_0 "127x107+469+18"
  frame attack_1 "112x105+641+21"
  frame attack_2 "109x105+823+21"
  frame attack_3 "109x104+1001+22"
  frame attack_4 "110x104+1173+22"
  frame attack_5 "112x102+1337+25"

  frame attack_6 "140x101+37+139"
  frame attack_7 "107x100+203+142"
  frame attack_8 "105x99+391+144"
  frame attack_9 "104x99+574+144"
  frame attack_10 "102x100+766+145"
  frame attack_11 "104x99+947+145"

  frame jump_0 "85x108+43+381"
  frame jump_1 "83x106+169+381"
  frame jump_2 "72x102+335+411"

  frame dodge_0 "111x96+828+436" "128x62>"
  frame dodge_1 "111x94+1014+438" "128x62>"
  frame dodge_2 "101x97+1178+440" "128x60>"
  frame dodge_3 "95x96+1345+445" "128x58>"

  frame hurt_0 "94x109+42+562"
  frame hurt_1 "80x111+181+554"

  frame throw_0 "98x94+434+578"
  frame throw_1 "125x118+586+570"
  frame throw_2 "144x121+737+573" "168x82>"

  frame skill_0 "72x105+34+707"
  frame skill_1 "92x84+162+724"
  frame skill_2 "127x70+306+734" "152x70>"

  frame death_0 "82x83+33+898" "x72"
  frame death_1 "108x79+294+903" "128x58>"
  frame death_2 "144x73+435+906" "136x56>"
  frame death_3 "128x64+670+914" "136x52>"
  frame death_4 "112x60+994+920" "128x50>"
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
strip throw "$work_dir/throw_0.png" "$work_dir/throw_1.png" "$work_dir/throw_2.png" "$work_dir/throw_2.png" "$work_dir/throw_1.png" "$work_dir/throw_0.png" "$work_dir/throw_2.png" "$work_dir/throw_1.png"
strip skill "$work_dir/skill_0.png" "$work_dir/skill_1.png" "$work_dir/skill_2.png" "$work_dir/skill_1.png"
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
