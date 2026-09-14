#!/bin/bash
#
# rebrand-assets.sh
#
# Regenerates every derivative branding asset from three masters:
#   stosduck.png      square duck                    (required)
#   stosducktext.png  duck with wordmark              (required)
#   duckbanner.png    seven-panel wide banner         (optional -
#                                                       only needed for
#                                                       duckbanner-login.png)
#
# Run after changing any master, or after an OMV/Jellyfin update changes
# the dimensions of the assets these get matched against.
#
# Outputs and who consumes them:
#   duck.ico            jf, bt, ebook, tna     favicon.ico
#   duck32.png          bt                     images/qbittorrent32.png
#   duck48.png          books                  /audiobookshelf/icon48.png
#   duck64.png          books                  /audiobookshelf/icon64.png
#   duck180.png         tna                    favicon_180x180.png
#   duck192.png         books                  /audiobookshelf/icon192.png
#   duck.svg            books, ebook, npm      generic square wrapper
#   ducktext.svg        npm, ebook             generic wide wrapper
#   duck-omv.svg        tna                    openmediavault_logo_only.svg
#   duck-omv-simple.svg tna                    openmediavault_logo_simple.svg
#   ducktext-omv.svg    tna                    openmediavault_logo.svg
#   favicon-32.png      quack landing page     index.html <link icon>
#   apple-touch-icon.png quack landing page    index.html <link apple-touch>
#   favicon.ico          quack landing page    duplicate of duck.ico, in
#                                               case anything references
#                                               this name literally
#   stosduck-128.png     quack landing page    128x128 raster, purpose
#                                               unconfirmed - check what
#                                               actually references it
#   stosduck.svg          quack landing page    same wrap as duck.svg,
#                                               purpose unconfirmed
#   og-card.jpg          quack landing page     index.html og:image,
#                                               1200x630 (skipped if
#                                               duckbanner.png master
#                                               is absent)
#   ducktext-jf.png     jf                     web/banner-(light|dark).*.png
#                                               (nginx location NEEDS the
#                                               /web/ prefix - jf serves
#                                               favicon at root but this
#                                               under /web/, checked by curl)
#   duckbanner-login.png tna                   assets/images/login.jpg
#                                               (OMV login background;
#                                               skipped if duckbanner.png
#                                               master is absent)
#   custom.css           ebook, docker (npm)   injected via sub_filter on
#                                               login SVG / sidebar logo
#
# Nothing here touches nginx. The proxy blocks alias these paths, so a
# regenerated file is served on the next request. Browser cache is the
# only thing between you and seeing the change.
#
# custom.css is injected into Grimmory and Portainer via sub_filter
# '</head>' on each host's Advanced tab, pointing at
# /branding/custom.css. If a future app's build renames its logo class
# (Angular/React builds do this on version bumps), the selector below
# needs updating by hand - this script only re-writes the file, it
# can't discover the new class name for you.

set -euo pipefail

DIR="/pool1/composedata/www-customlanding"
OMV="/var/www/openmediavault/assets/images"

SQUARE="$DIR/stosduck.png"
WIDE="$DIR/stosducktext.png"
BANNER="$DIR/duckbanner.png"

VOID='#170C2E'

# ---------------------------------------------------------------- checks

for cmd in convert base64 identify; do
    command -v "$cmd" >/dev/null || { echo "missing: $cmd"; exit 1; }
done

for f in "$SQUARE" "$WIDE"; do
    [ -r "$f" ] || { echo "missing master: $f"; exit 1; }
done

HAVE_BANNER=1
[ -r "$BANNER" ] || { HAVE_BANNER=0; echo "note: $BANNER not found, skipping duckbanner-login.png"; }

cd "$DIR"

# ---------------------------------------------------------------- helpers

# svg_wrap <source png> <width> <height> <viewbox w> <viewbox h> <align> <out>
# Wraps a PNG in an SVG shell with explicit intrinsic dimensions, so the
# browser sizes it from the attributes instead of the image's pixel size.
svg_wrap() {
    local src="$1" w="$2" h="$3" vbw="$4" vbh="$5" align="$6" out="$7"
    printf '<svg xmlns="http://www.w3.org/2000/svg" width="%s" height="%s" viewBox="0 0 %s %s"><image href="data:image/png;base64,%s" width="%s" height="%s" preserveAspectRatio="%s meet" style="image-rendering:pixelated"/></svg>' \
        "$w" "$h" "$vbw" "$vbh" "$(base64 -w0 "$src")" "$vbw" "$vbh" "$align" > "$out"
    echo "  $out"
}

# attr <file> <attribute> - first value of an attribute in an SVG header
attr() {
    head -c 800 "$1" | tr '\n' ' ' | grep -o "$2=\"[^\"]*\"" | head -1 | cut -d'"' -f2
}

# omv_wrap <omv svg> <source png> <align> <out>
# Reads dimensions off the OMV original so replacements scale correctly
# even if an update changes them. Falls back to known values if the
# original has gone missing.
omv_wrap() {
    local orig="$1" src="$2" align="$3" out="$4" fw="$5" fh="$6" fvw="$7" fvh="$8"
    local w h vb vbw vbh
    if [ -r "$orig" ]; then
        w=$(attr "$orig" width)
        h=$(attr "$orig" height)
        vb=$(attr "$orig" viewBox)
        vbw=$(echo "$vb" | awk '{print $3}')
        vbh=$(echo "$vb" | awk '{print $4}')
    fi
    w="${w:-$fw}"; h="${h:-$fh}"; vbw="${vbw:-$fvw}"; vbh="${vbh:-$fvh}"
    svg_wrap "$src" "$w" "$h" "$vbw" "$vbh" "$align" "$out"
}

# ---------------------------------------------------------------- raster

echo "raster:"
for s in 32 48 64 180 192; do
    convert "$SQUARE" -filter point -resize "${s}x${s}" "duck${s}.png"
    echo "  duck${s}.png"
done

convert "$SQUARE" -filter point -resize 48x48 \
    -define icon:auto-resize=48,32,16 duck.ico
echo "  duck.ico"

# ---------------------------------------------------------------- vector

echo "vector:"

# Generic wrappers. No intrinsic size on the square one by design: it is
# aliased into slots that size it themselves.
svg_wrap "$SQUARE" 298 298 298 298 xMidYMid duck.svg
svg_wrap "$WIDE"   400 80  400 80  xMinYMid ducktext.svg

# OMV variants, dimensions matched to the originals.
omv_wrap "$OMV/openmediavault_logo_only.svg"   "$SQUARE" xMidYMid \
    duck-omv.svg        10.240999mm 9.3493166mm 36.287006 33.127499

omv_wrap "$OMV/openmediavault_logo_simple.svg" "$SQUARE" xMidYMid \
    duck-omv-simple.svg 10.240999mm 9.3493166mm 36.287006 33.127499

omv_wrap "$OMV/openmediavault_logo.svg"        "$WIDE"   xMinYMid \
    ducktext-omv.svg    93.242828mm 11.853333mm 330.38798 42

# ---------------------------------------------------------------- landing page

# The Quack page itself (index.html, served by apache_landing_page) links
# these two by literal filename rather than through any nginx alias, so
# they need regenerating under their existing names, not duck-prefixed
# ones. Same master, same treatment, just named for their consumer.
#
#   favicon-32.png       index.html   <link rel="icon" ... sizes="32x32">
#   apple-touch-icon.png index.html   <link rel="apple-touch-icon">

echo "landing page:"
convert "$SQUARE" -filter point -resize 32x32 favicon-32.png
echo "  favicon-32.png"

convert "$SQUARE" -filter point -resize 180x180 apple-touch-icon.png
echo "  apple-touch-icon.png"

# Same bytes as duck.ico, second filename only. Some early hand-built
# config or bookmark may still reference favicon.ico literally rather
# than duck.ico, so keep both current rather than tracking down every
# reference.
convert "$SQUARE" -filter point -resize 48x48 \
    -define icon:auto-resize=48,32,16 favicon.ico
echo "  favicon.ico"

convert "$SQUARE" -filter point -resize 128x128 stosduck-128.png
echo "  stosduck-128.png"

# Same wrapper as duck.svg (298x298), second filename. If this and
# duck.svg are ever confirmed to serve the exact same purpose, drop one.
svg_wrap "$SQUARE" 298 298 298 298 xMidYMid stosduck.svg

# Social preview image. Confirmed 1200x630 (2026-07-28), the standard
# Open Graph size, so hardcoded rather than measured at runtime like
# the OMV/JF login targets. Depends on the optional duckbanner.png
# master since the wide panel banner suits this ratio far better than
# the square duck or the wordmark would.
if [ "$HAVE_BANNER" = 1 ]; then
    convert "$BANNER" -filter point -resize 1200x630 \
        -background "$VOID" -gravity center -extent 1200x630 og-card.jpg
    echo "  og-card.jpg"
fi

# ---------------------------------------------------------------- banners

# Login backgrounds: composited onto a flat canvas at the exact
# dimensions of the asset being replaced, source centred at its own
# size rather than stretched. Confirm the target size with
# `identify` against the live original before trusting these numbers -
# both were measured once and will drift if the app rebuilds the asset
# at a different size on update.

echo "banners:"

# Jellyfin login banner. Target measured off banner-light...png at
# 1302x378 (2026-07-28). Uses the wordmark, not the panel banner - it
# fits this ratio far better than the seven-panel version does.
convert -size 1302x378 xc:"$VOID" "$WIDE" -gravity center -composite ducktext-jf.png
echo "  ducktext-jf.png"

# OMV login background. Target is login.jpg's rendered box, effectively
# full viewport under `cover`; 1920x1080 covers a normal desktop without
# cropping the panel banner the way the raw wide image did.
if [ "$HAVE_BANNER" = 1 ]; then
    convert -size 1920x1080 xc:"$VOID" "$BANNER" -gravity center -composite duckbanner-login.png
    echo "  duckbanner-login.png"
fi

# ---------------------------------------------------------------- css

echo "css:"

cat > custom.css << 'EOF'
/* Grimmory: login page wordmark and mark are inline SVGs, no fetch
   involved, so they're hidden and replaced with a background image
   rather than swapped at the source. */
.logo-icon path,
.logo-icon defs {
  display: none !important;
}
.logo-icon {
  background-image: url("/branding/duck.png");
  background-size: contain;
  background-repeat: no-repeat;
  background-position: center;
}

.sidebar-brand-wordmark > g,
.sidebar-brand-wordmark > defs {
  display: none !important;
}
.sidebar-brand-wordmark {
  background-image: url("/branding/ducktext.png");
  background-size: contain;
  background-repeat: no-repeat;
  background-position: center;
}

/* Portainer: sidebar logo is also inline SVG (base64 data URI), swapped
   with content: url() rather than hidden, since it's a plain <img> with
   no separate background layer to hide behind. Two class variants seen
   so far - default and the light-theme-only one. Check for
   th-dark / th-highcontrast variants if the mark disappears when the
   theme is switched. */
.app-react-sidebar-Header-module__logo,
.simple-box-logo {
  content: url("/branding/ducktext.svg");
  width: 200px;
  height: 40px;
}

/* Collapsed-sidebar state: Portainer adds a Tailwind arbitrary-value
   class (!max-h-[27px]) to the same element rather than using a
   separate one. This rule is UNVERIFIED as working - last check showed
   Portainer's own logo reappearing entirely, which points at custom.css
   not being served/matched at all rather than this selector being
   wrong. Confirm with:
     curl -s --resolve docker.stos.top:443:192.168.68.57 \
       https://docker.stos.top/branding/custom.css | grep -c max-h
   before trusting this is live. */
.app-react-sidebar-Header-module__logo[class*="max-h-[27px]"] {
  content: url("/branding/duck.svg");
  width: 27px;
  height: 27px;
}
EOF
echo "  custom.css"

# ---------------------------------------------------------------- perms

# Files only. Never recurse a file mode over directories: stripping the
# execute bit off a directory blocks traversal, which is what took the
# OMV workbench down.
find "$DIR" -maxdepth 1 -type f \( -name '*.png' -o -name '*.svg' -o -name '*.ico' \) \
    -exec chmod 644 {} +

echo
echo "done. clear browser cache to see changes."
