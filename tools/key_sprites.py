"""Chroma-key magenta/pink Imagine backgrounds to cropped RGBA PNGs."""
from pathlib import Path

from PIL import Image
import numpy as np

ROOT = Path(r"c:\Users\rich\Projects\Horse Game")
RAW = ROOT / "assets" / "sprites" / "_raw"
OUT = ROOT / "assets" / "sprites"

JOBS = {
    "5.jpg": "fence.png",
    "6.jpg": "horse_bay.png",
    "7.jpg": "barn.png",
    "8.jpg": "jump.png",
    "9.jpg": "tree_oak.png",
    "10.jpg": "horse_black.png",
    "11.jpg": "horse_grey.png",
    "12.jpg": "horse_chestnut.png",
}


def key_image(src: Path, dest: Path) -> None:
    im = Image.open(src).convert("RGBA")
    arr = np.asarray(im).astype(np.float32)
    r, g, b, a = arr[..., 0], arr[..., 1], arr[..., 2], arr[..., 3]
    mx = np.maximum(np.maximum(r, g), b)
    mn = np.minimum(np.minimum(r, g), b)
    sat = np.where(mx > 1.0, (mx - mn) / mx, 0.0)
    # Imagine used a mid-magenta, not #FF00FF. Key high-sat pinks.
    pink = (r > 140) & (b > 90) & (g < r * 0.85) & (g < b * 1.15) & (sat > 0.22)
    # Also catch flatter magenta fills
    magenta = (r > 170) & (b > 140) & (g < 130) & ((r + b) > g * 2.4)
    mask = pink | magenta
    alpha = np.where(mask, 0.0, a)
    # Soft edge: pull alpha down near keyed pixels
    from numpy.lib.stride_tricks import sliding_window_view

    bin_mask = mask.astype(np.uint8)
    # simple 3x3 dilate for fringe
    pad = np.pad(bin_mask, 1, mode="edge")
    neigh = (
        pad[0:-2, 0:-2]
        + pad[0:-2, 1:-1]
        + pad[0:-2, 2:]
        + pad[1:-1, 0:-2]
        + pad[1:-1, 1:-1]
        + pad[1:-1, 2:]
        + pad[2:, 0:-2]
        + pad[2:, 1:-1]
        + pad[2:, 2:]
    )
    fringe = (neigh > 0) & (~mask)
    alpha = np.where(fringe, alpha * 0.35, alpha)
    arr[..., 3] = alpha
    out = Image.fromarray(arr.astype(np.uint8), "RGBA")
    bbox = out.getbbox()
    if bbox:
        # pad a few pixels so hooves/roofs aren't clipped
        x0, y0, x1, y1 = bbox
        x0 = max(0, x0 - 4)
        y0 = max(0, y0 - 4)
        x1 = min(out.width, x1 + 4)
        y1 = min(out.height, y1 + 4)
        out = out.crop((x0, y0, x1, y1))
    dest.parent.mkdir(parents=True, exist_ok=True)
    out.save(dest)
    print(f"{src.name} -> {dest.name} {out.size} keyed={int(mask.mean()*100)}%")


def main() -> None:
    for src_name, dest_name in JOBS.items():
        key_image(RAW / src_name, OUT / dest_name)


if __name__ == "__main__":
    main()
