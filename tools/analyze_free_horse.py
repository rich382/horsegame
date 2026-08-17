"""Print bounds, facing, and hoof clusters for the free horse mesh."""
from __future__ import annotations

from pathlib import Path

import bpy
from mathutils import Vector

ROOT = Path(r"c:\Users\rich\Projects\Horse Game")
SRC = ROOT / "assets" / "models" / "horse" / "free_horse.glb"


def main() -> None:
    bpy.ops.object.select_all(action="SELECT")
    bpy.ops.object.delete(use_global=False)
    bpy.ops.import_scene.gltf(filepath=str(SRC))
    meshes = [o for o in bpy.context.scene.objects if o.type == "MESH"]
    if not meshes:
        raise SystemExit("no mesh")
    obj = meshes[0]
    print("object", obj.name, "matrix", obj.matrix_world)
    print("dims", obj.dimensions)
    coords = [obj.matrix_world @ v.co for v in obj.data.vertices]
    xs = [p.x for p in coords]
    ys = [p.y for p in coords]
    zs = [p.z for p in coords]
    print("x %.3f .. %.3f" % (min(xs), max(xs)))
    print("y %.3f .. %.3f" % (min(ys), max(ys)))
    print("z %.3f .. %.3f" % (min(zs), max(zs)))
    # Hooves: lowest 2% of vertices by Z
    zs_sorted = sorted(zs)
    cut = zs_sorted[max(1, int(len(zs_sorted) * 0.02))]
    hooves = [p for p in coords if p.z <= cut]
    print("hoof verts", len(hooves), "cut", cut)
    # 4-means-ish by XY quadrant around centroid of hoof verts
    cx = sum(p.x for p in hooves) / len(hooves)
    cy = sum(p.y for p in hooves) / len(hooves)
    buckets = {"+x+y": [], "+x-y": [], "-x+y": [], "-x-y": []}
    for p in hooves:
        key = ("%s%s" % ("+x" if p.x >= cx else "-x", "+y" if p.y >= cy else "-y"))
        buckets[key].append(p)
    for k, pts in buckets.items():
        if not pts:
            print(k, "empty")
            continue
        avg = Vector((
            sum(p.x for p in pts) / len(pts),
            sum(p.y for p in pts) / len(pts),
            sum(p.z for p in pts) / len(pts),
        ))
        print(k, "n", len(pts), "avg", tuple(round(c, 3) for c in avg))
    # Head: highest 1% verts
    z_hi = zs_sorted[int(len(zs_sorted) * 0.99)]
    heads = [p for p in coords if p.z >= z_hi]
    hx = sum(p.x for p in heads) / len(heads)
    hy = sum(p.y for p in heads) / len(heads)
    hz = sum(p.z for p in heads) / len(heads)
    print("head cluster n", len(heads), "avg", (round(hx, 3), round(hy, 3), round(hz, 3)))
    # Nose: verts farthest along the long horizontal axis from the body center
    # Prefer the axis with larger span among X/Y
    print("span x", max(xs) - min(xs), "span y", max(ys) - min(ys))


if __name__ == "__main__":
    main()
