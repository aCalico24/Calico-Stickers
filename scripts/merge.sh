#! /usr/bin/env bash

set -euo pipefail

if command -v magick >/dev/null 2>&1; then
	IM_CMD=(magick)
elif command -v convert >/dev/null 2>&1; then
	IM_CMD=(convert)
else
	echo "Please install ImageMagick first (requires 'magick' or 'convert' command)." >&2
	exit 1
fi

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
IMAGE_DIR="$REPO_ROOT/三花"
OUTPUT_FORMAT="png"
OUTPUT_FILE="$REPO_ROOT/合集预览.$OUTPUT_FORMAT"

THUMB_SIZE=200
COLS=6

TILE_BORDER_WIDTH=4
TILE_BORDER_COLOR="#ffffff"
BG_COLOR="#ffffff"

EXTENSIONS=(jpg jpeg png)

shopt -s nullglob nocaseglob
files=()
for ext in "${EXTENSIONS[@]}"; do
	files+=("$IMAGE_DIR"/*."$ext")
done
shopt -u nullglob nocaseglob

TMP_DIR="$(mktemp -d)"
trap 'rm -rf "$TMP_DIR"' EXIT

for i in "${!files[@]}"; do
	"${IM_CMD[@]}" "${files[$i]}" \
		-auto-orient \
		-thumbnail "${THUMB_SIZE}x${THUMB_SIZE}" \
		-gravity center \
		-background "$BG_COLOR" \
		-extent "${THUMB_SIZE}x${THUMB_SIZE}" \
		-bordercolor "$TILE_BORDER_COLOR" \
		-border "$TILE_BORDER_WIDTH" \
		"$TMP_DIR/thumb_$(printf '%05d' "$i").$OUTPUT_FORMAT"
done

blank_tile="$TMP_DIR/blank.$OUTPUT_FORMAT"
"${IM_CMD[@]}" \
	-size "${THUMB_SIZE}x${THUMB_SIZE}" "xc:${BG_COLOR}" \
	-bordercolor "$TILE_BORDER_COLOR" \
	-border "$TILE_BORDER_WIDTH" \
	"$blank_tile"

total="${#files[@]}"
rows=$(((total + COLS - 1) / COLS))

for ((r = 0; r < rows; r++)); do
	row_imgs=()
	for ((c = 0; c < COLS; c++)); do
		idx=$((r * COLS + c))
		if [ "$idx" -lt "$total" ]; then
			row_imgs+=("$TMP_DIR/thumb_$(printf '%05d' "$idx").$OUTPUT_FORMAT")
		else
			row_imgs+=("$blank_tile")
		fi
	done
	"${IM_CMD[@]}" "${row_imgs[@]}" +append "$TMP_DIR/row_$(printf '%03d' "$r").$OUTPUT_FORMAT"
done

row_files=("$TMP_DIR"/row_*$OUTPUT_FORMAT)
"${IM_CMD[@]}" "${row_files[@]}" -append \
	-bordercolor "#e0e0e0" \
	-border 2 \
	"$OUTPUT_FILE"
