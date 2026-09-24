#!/usr/bin/env bash
# Builds the web clips and posters in ../media from the original footage.
#
# Originals are only ever read (ffmpeg -i). Every output path is checked to be inside
# media/ before ffmpeg is allowed to write it, so this script cannot overwrite a source.
#
#   tools/make_media.sh            # build everything that is missing
#   FORCE=1 tools/make_media.sh    # rebuild everything
set -euo pipefail

SITE="$(cd "$(dirname "$0")/.." && pwd)"
OUT="$SITE/media"
RAW="$HOME/AmberLab/Project-Isaac-RL/summer_2026/videos/raw_videos"
SIM="$HOME/AmberLab/Project-Isaac-RL/sprout/logs/video"
ANIM="$HOME/AmberLab/Project-Isaac-RL/summer_2026/submission_code/generator_rl_video/out"

X264=(-c:v libx264 -preset slow -pix_fmt yuv420p -movflags +faststart -an)

guard() {  # guard <output> <input>...
  local out; out="$(realpath -m "$1")"; shift
  case "$out" in "$OUT"/*) ;; *) echo "refusing to write outside media/: $out" >&2; exit 1;; esac
  for i in "$@"; do
    [[ -f "$i" ]] || { echo "missing source: $i" >&2; exit 1; }
    [[ "$(realpath "$i")" != "$out" ]] || { echo "output would overwrite source: $i" >&2; exit 1; }
  done
}
skip() { [[ -z "${FORCE:-}" && -s "$1" ]]; }

poster() {  # poster <clip> <time>
  local clip="$OUT/video/$1.mp4" p="$OUT/poster/$1.webp"
  guard "$p" "$clip"; skip "$p" && return
  ffmpeg -loglevel error -y -ss "$2" -i "$clip" -frames:v 1 -c:v libwebp -quality 80 "$p"
}

# clip <name> <source> <in s> <out s> [width] [poster s]   trimmed, scaled, 30 fps, silent
clip() {
  local name=$1 src=$2 a=$3 b=$4 w=${5:-1280} pt=${6:-}
  local o="$OUT/video/$name.mp4"
  guard "$o" "$src"
  if ! skip "$o"; then
    echo "  $name  <- $(basename "$src") [$a, $b]"
    ffmpeg -loglevel error -y -ss "$a" -to "$b" -i "$src" \
      -vf "fps=30,scale=$w:-2:flags=lanczos" -crf 26 "${X264[@]}" "$o"
  fi
  poster "$name" "${pt:-$(python3 -c "print(min(1.0, ($b-$a)/2))")}"
}

# pair <name> <pre-trained> <fine-tuned>   side by side, the shorter run freezes on its last frame
pair() {
  local name=$1 l=$2 r=$3 o="$OUT/video/$1.mp4"
  guard "$o" "$l" "$r"
  if ! skip "$o"; then
    echo "  $name  <- $(basename "$l") | $(basename "$r")"
    ffmpeg -loglevel error -y -i "$l" -i "$r" -filter_complex "
      [0:v]fps=30,scale=960:540:flags=lanczos,tpad=stop_mode=clone:stop_duration=30,setsar=1[a];
      [1:v]fps=30,scale=960:540:flags=lanczos,tpad=stop_mode=clone:stop_duration=30,setsar=1[b];
      [a][b]hstack=inputs=2,drawbox=x=957:y=0:w=6:h=ih:color=white:t=fill[v]" -map "[v]" -t "$(ffprobe -v error -show_entries format=duration -of csv=p=0 "$r")" \
      -crf 25 "${X264[@]}" "$o"
  fi
  poster "$name" 1.0
}

mkdir -p "$OUT/video" "$OUT/poster"

echo "hardware"   # in/out points are the ones used in videos/paper_video_v2/paper_video_v2.kdenlive
clip hw-red-stairs      "$RAW/red_stairs_lower_ascent-60fps.mp4"           63.50  82.80
clip hw-entrance        "$RAW/gt_entrance_lower_ascent_decent-60fps.mp4"   53.47  71.83
clip hw-parking-stairs  "$RAW/parking_stairs_up-60fps.mp4"                 60.42  72.68
clip hw-interior-stairs "$RAW/stairs_up_down_interior-60fps.mp4"          124.55 131.35
clip hw-stairs-up-down  "$RAW/stairs_2_up_down-60fps.mp4"                  68.93  82.38
clip hw-box-jump        "$RAW/box_jump_3_pallet_side0001.mp4"              71.35  82.35
clip hw-running-jump    "$RAW/running_jump_outside-60fps.mp4"              10.47  16.72
clip hw-walk-jump       "$RAW/walk_jump_outside_20001.mp4"                 22.58  29.77
clip hw-run-turn        "$RAW/running_turning_outside-60fps.mp4"           26.93  33.17
clip hw-walk-outside    "$RAW/walk_outside_near-60fps.mp4"                 64.15  77.60 1280 7

echo "simulation: pre-trained vs fine-tuned"
pair ft-stairs-9   "$SIM/wall_stairs_parent_a/wall_stairs_parent_a.mp4" "$SIM/wall_stairs_ft_a/wall_stairs_ft_a.mp4"
pair ft-stairs-28  "$SIM/wall_stairs_parent_b/wall_stairs_parent_b.mp4" "$SIM/wall_stairs_ft_b/wall_stairs_ft_b.mp4"
pair ft-stairs-32  "$SIM/wall_stairs_parent_c/wall_stairs_parent_c.mp4" "$SIM/wall_stairs_ft_c/wall_stairs_ft_c.mp4"
pair ft-boxes-20   "$SIM/two_box_parent_a/two_box_parent_a.mp4"         "$SIM/two_box_ft_a/two_box_ft_a.mp4"
pair ft-boxes-7    "$SIM/two_box_parent_b/two_box_parent_b.mp4"         "$SIM/two_box_ft_b/two_box_ft_b.mp4"

echo "simulation: terrain showcase"
clip sim-four-box   "$SIM/four_box_sweep_steered/four_box_sweep_steered.mp4"     0 31.8
clip sim-flat       "$SIM/flat_locomotion/flat_locomotion.mp4"                    0 28.5
clip sim-tall-stairs "$SIM/tall_stairs_up/tall_stairs_up.mp4"                     0 20.76
clip sim-entrance   "$SIM/entry_stairs_down/entry_stairs_down.mp4"                0 14.7

echo "method animations"
clip anim-finetune  "$ANIM/S4FineTuneLoopFast.mp4"   0 44.4 1280 22


du -sh "$OUT/video" "$OUT/poster"
