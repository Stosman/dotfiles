#!/bin/bash

SRC="/pool1/Downloads/MYM/ToSort/Ebooks Collection From 256 Authors"
DEST="/pool1/Downloads/MYM/ToSort/MobiOnly"

mkdir -p "$DEST"

copied=0

find "$SRC" -type f -iname '*.mobi' -print0 | while IFS= read -r -d '' f; do
    dir=$(dirname "$f")
    base=$(basename "$f")
    stem="${base%.*}"

    # Skip if an epub with the same stem exists alongside
    if find "$dir" -maxdepth 1 -iname "$stem.epub" -print -quit | grep -q .; then
        continue
    fi

    target="$DEST/$base"

    if [ -e "$target" ]; then
        n=1
        ext="${base##*.}"
        while [ -e "$DEST/$stem ($n).$ext" ]; do
            n=$((n + 1))
        done
        target="$DEST/$stem ($n).$ext"
    fi

    cp -v "$f" "$target"
done

echo "Done. Files in $DEST: $(ls -1 "$DEST" | wc -l)"
