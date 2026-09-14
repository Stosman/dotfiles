import re
import sys

ESC = chr(27)
CELL_PATTERN = re.compile(
    re.escape(ESC + "[0m" + ESC + "[38;2;") + r"(\d+);(\d+);(\d+)m(.)"
)

FG = lambda r, g, b: f"{ESC}[38;2;{r};{g};{b}m"
BG = lambda r, g, b: f"{ESC}[48;2;{r};{g};{b}m"
RESET = f"{ESC}[0m"

# all 16 quadrant fill combinations, keyed by (top_left, top_right, bottom_left, bottom_right)
QUAD_GLYPH = {
    (0, 0, 0, 0): " ",
    (1, 0, 0, 0): "\u2598",  # upper left
    (0, 1, 0, 0): "\u259d",  # upper right
    (0, 0, 1, 0): "\u2596",  # lower left
    (0, 0, 0, 1): "\u2597",  # lower right
    (1, 1, 0, 0): "\u2580",  # upper half
    (0, 0, 1, 1): "\u2584",  # lower half
    (1, 0, 1, 0): "\u258c",  # left half
    (0, 1, 0, 1): "\u2590",  # right half
    (1, 0, 0, 1): "\u259a",  # diagonal ul+lr
    (0, 1, 1, 0): "\u259e",  # diagonal ur+ll
    (1, 1, 1, 0): "\u259b",  # missing lr
    (1, 1, 0, 1): "\u259c",  # missing ll
    (1, 0, 1, 1): "\u2599",  # missing ur
    (0, 1, 1, 1): "\u259f",  # missing ul
    (1, 1, 1, 1): "\u2588",  # full block
}

# single-cell fill ramp, ordered by how much of the cell each glyph covers.
# no cells are merged here, every entry maps one original pixel to one glyph.
SHADE_RAMP = [
    (0, " "),
    (51, "\u2596"),  # quadrant lower-left, roughly 25%
    (102, "\u2584"),  # lower half, 50%
    (153, "\u2599"),  # three-quarter, missing upper-right, 75%
    (204, "\u2588"),  # full block, 100%
]


def parse_grid(path):
    with open(path, "r", encoding="utf-8") as f:
        data = f.read()
    grid = []
    width = 0
    for line in data.splitlines():
        row = [(int(r), int(g), int(b)) for r, g, b, _ch in CELL_PATTERN.findall(line)]
        if row:
            grid.append(row)
            width = max(width, len(row))
    # pad ragged rows to a common width by repeating the last colour
    for row in grid:
        while len(row) < width:
            row.append(row[-1] if row else (0, 0, 0))
    return grid


def luminance(rgb):
    r, g, b = rgb
    return 0.299 * r + 0.587 * g + 0.114 * b


def render_full(grid):
    out = []
    for row in grid:
        line = [RESET]
        for (r, g, b) in row:
            glyph = " " if (r, g, b) == (0, 0, 0) else "\u2588"
            line.append(FG(r, g, b) + glyph)
        line.append(RESET)
        out.append("".join(line))
    return out


def render_shade(grid):
    # same row and column count as the source, one glyph per original cell,
    # the glyph is just picked from a fuller-coverage ramp than the source used
    out = []
    for row in grid:
        line = [RESET]
        for (r, g, b) in row:
            lum = luminance((r, g, b))
            glyph = SHADE_RAMP[0][1]
            for threshold, ch in SHADE_RAMP:
                if lum >= threshold:
                    glyph = ch
            line.append(FG(r, g, b) + glyph)
        line.append(RESET)
        out.append("".join(line))
    return out


def render_half(grid):
    out = []
    rows = grid + ([grid[-1]] if len(grid) % 2 else [])
    for y in range(0, len(rows), 2):
        top, bottom = rows[y], rows[y + 1]
        line = [RESET]
        for x in range(len(top)):
            tr, tg, tb = top[x]
            br, bgc, bb = bottom[x]
            line.append(FG(tr, tg, tb) + BG(br, bgc, bb) + "\u2580")
        line.append(RESET)
        out.append("".join(line))
    return out


def quad_cell(tl, tr, bl, br):
    quad = [tl, tr, bl, br]
    mean = sum(luminance(c) for c in quad) / 4
    mask = tuple(1 if luminance(c) > mean else 0 for c in quad)
    glyph = QUAD_GLYPH[mask]

    fg_pixels = [c for c, m in zip(quad, mask) if m]
    bg_pixels = [c for c, m in zip(quad, mask) if not m]

    def avg(pixels, fallback):
        if not pixels:
            return fallback
        n = len(pixels)
        return (
            sum(p[0] for p in pixels) // n,
            sum(p[1] for p in pixels) // n,
            sum(p[2] for p in pixels) // n,
        )

    fg = avg(fg_pixels, (0, 0, 0))
    bg = avg(bg_pixels, fg)
    return glyph, fg, bg


def render_quarter(grid):
    out = []
    rows = grid + ([grid[-1]] if len(grid) % 2 else [])
    width = len(rows[0]) if rows else 0
    for y in range(0, len(rows), 2):
        top, bottom = rows[y], rows[y + 1]
        line = [RESET]
        x = 0
        while x < width:
            x2 = x + 1 if x + 1 < width else x
            glyph, fg, bg = quad_cell(top[x], top[x2], bottom[x], bottom[x2])
            line.append(FG(*fg) + BG(*bg) + glyph)
            x += 2
        line.append(RESET)
        out.append("".join(line))
    return out


def main():
    modes = {
        "full": render_full,
        "shade": render_shade,
        "half": render_half,
        "quarter": render_quarter,
    }
    if len(sys.argv) != 4 or sys.argv[3] not in modes:
        print("usage: block_render.py SRC DST full|shade|half|quarter", file=sys.stderr)
        print("  full    same size, solid block per pixel (old behaviour)", file=sys.stderr)
        print("  shade   same size, glyph picked from a fill-level ramp per pixel", file=sys.stderr)
        print("  half    half the rows, two colours per cell via a half-block glyph", file=sys.stderr)
        print("  quarter half the rows and columns, quadrant glyphs", file=sys.stderr)
        sys.exit(1)
    src, dst, mode = sys.argv[1], sys.argv[2], sys.argv[3]
    grid = parse_grid(src)
    lines = modes[mode](grid)
    with open(dst, "w", encoding="utf-8") as f:
        f.write("\n".join(lines) + "\n")


if __name__ == "__main__":
    main()
