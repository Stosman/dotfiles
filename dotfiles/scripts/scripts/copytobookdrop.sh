#!/bin/bash

SRC="/pool1/Downloads/MYM/ToSort/Ebooks Collection From 256 Authors"
DEST="/pool1/Media/Ebooks/bookdrop"

mkdir -p "$DEST"

find "$SRC" -type f -iname '*.epub' -print0 | while IFS= read -r -d '' f; do
    base=$(basename "$f")
    target="$DEST/$base"

    if [ -e "$target" ]; then
        n=1
        stem="${base%.epub}"
        while [ -e "$DEST/$stem ($n).epub" ]; do
            n=$((n + 1))
        done
        target="$DEST/$stem ($n).epub"
    fi

    cp -v "$f" "$target"
done

echo "Done. Files now in bookdrop: $(find "$DEST" -maxdepth 1 -iname '*.epub' | wc -l)"
