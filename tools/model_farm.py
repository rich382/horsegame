"""
Blender 5.2 — real 3D farm kit (Z-up). Exports Godot-ready glTF (Y-up).

  blender --background --python tools/model_farm.py
"""
from __future__ import annotations

import math
import sys
from pathlib import Path

import bpy

ROOT = Path(r"c:\Users\rich\Projects\Horse Game")
OUT = ROOT / "assets" / "models" / "farm"
TEX_WOOD = ROOT / "assets" / "textures" / "tex_barn_wood.jpg"
TEX_ROOF = ROOT / "assets" / "textures" / "tex_barn_roof.jpg"


def clear_scene() -> None:
    bpy.ops.object.select_all(action="SELECT")
    bpy.ops.object.delete(use_global=False)
    for coll in (bpy.data.meshes, bpy.data.materials, bpy.data.images, bpy.data.textures):
        for block in list(coll):
            coll.remove(block)


def make_mat(name: str, color=(0.6, 0.5, 0.4, 1.0), tex: Path | None = None, uv_scale=2.0, rough=0.9):
    mat = bpy.data.materials.new(name)
    mat.use_nodes = True
    nt = mat.node_tree
    bsdf = next(n for n in nt.nodes if n.type == "BSDF_PRINCIPLED")
    bsdf.inputs["Roughness"].default_value = rough
    bsdf.inputs["Base Color"].default_value = color
    if tex and tex.exists():
        img = bpy.data.images.load(str(tex))
        tex_node = nt.nodes.new("ShaderNodeTexImage")
        tex_node.image = img
        tex_node.interpolation = "Smart"
        mapn = nt.nodes.new("ShaderNodeMapping")
        mapn.inputs["Scale"].default_value = (uv_scale, uv_scale, uv_scale)
        coord = nt.nodes.new("ShaderNodeTexCoord")
        nt.links.new(coord.outputs["UV"], mapn.inputs["Vector"])
        nt.links.new(mapn.outputs["Vector"], tex_node.inputs["Vector"])
        nt.links.new(tex_node.outputs["Color"], bsdf.inputs["Base Color"])
    return mat


def box(name: str, sx: float, sy: float, sz: float, x: float, y: float, z: float, mat) -> bpy.types.Object:
    """sx,sy,sz = full size. z is HEIGHT. Bottom sits at z - sz/2."""
    bpy.ops.mesh.primitive_cube_add(size=1.0, location=(x, y, z))
    ob = bpy.context.active_object
    ob.name = name
    ob.scale = (sx, sy, sz)
    bpy.ops.object.transform_apply(location=False, rotation=False, scale=True)
    if mat:
        if ob.data.materials:
            ob.data.materials[0] = mat
        else:
            ob.data.materials.append(mat)
    bpy.ops.object.mode_set(mode="EDIT")
    bpy.ops.mesh.select_all(action="SELECT")
    bpy.ops.uv.cube_project(cube_size=1.0, correct_aspect=True, scale_to_bounds=False)
    bpy.ops.object.mode_set(mode="OBJECT")
    return ob


def join_named(names: list[str], result: str) -> bpy.types.Object:
    bpy.ops.object.select_all(action="DESELECT")
    first = None
    for n in names:
        ob = bpy.data.objects.get(n)
        if ob is None:
            continue
        ob.select_set(True)
        if first is None:
            first = ob
    if first is None:
        raise RuntimeError(f"nothing to join for {result}")
    bpy.context.view_layer.objects.active = first
    if len([o for o in bpy.context.selected_objects]) > 1:
        bpy.ops.object.join()
    first.name = result
    return first


def export_glb(path: Path) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    bpy.ops.export_scene.gltf(
        filepath=str(path),
        export_format="GLB",
        use_selection=False,
        export_apply=True,
        export_yup=True,
        export_texcoords=True,
        export_normals=True,
        export_materials="EXPORT",
        export_image_format="AUTO",
        export_animations=False,
    )
    print(f"Wrote {path} ({path.stat().st_size} bytes)")


def build_barn() -> None:
    wood = make_mat("BarnWood", tex=TEX_WOOD, uv_scale=3.5)
    roof = make_mat("BarnRoof", tex=TEX_ROOF, uv_scale=4.0)
    trim = make_mat("BarnTrim", color=(0.82, 0.78, 0.70, 1), rough=0.75)
    green = make_mat("StallGreen", color=(0.22, 0.38, 0.26, 1), rough=0.8)
    dark = make_mat("Interior", color=(0.18, 0.14, 0.10, 1), rough=0.95)

    W, D, WALL = 11.2, 5.4, 0.14
    EAVE = 3.05
    RIDGE = 4.35
    names = []

    def add(n, *a, **k):
        names.append(box(n, *a, **k).name)

    add("Floor", W, D, 0.10, 0, 0, 0.05, wood)
    add("Back", W, WALL, EAVE, 0, -D / 2 + WALL / 2, EAVE / 2, wood)
    add("Left", WALL, D, EAVE, -W / 2 + WALL / 2, 0, EAVE / 2, wood)
    add("Right", WALL, D, EAVE, W / 2 - WALL / 2, 0, EAVE / 2, wood)

    # 3 stall partitions + tack split
    for i, x in enumerate((-2.7, 0.0, 2.7)):
        add(f"Part{i}", WALL, D - 0.3, 2.4, x, -0.05, 1.2, wood)

    # Front kickboards under openings
    for i, x in enumerate((-4.05, -1.35, 1.35, 4.05)):
        add(f"Kick{i}", 2.4, WALL, 0.55, x, D / 2 - WALL / 2 - 0.15, 0.28, green)

    # Aisle posts + beam
    for i, x in enumerate((-5.5, -2.7, 0.0, 2.7, 5.5)):
        add(f"Post{i}", 0.16, 0.16, 2.7, x, D / 2 + 0.85, 1.35, trim)
    add("Beam", W - 0.2, 0.16, 0.18, 0, D / 2 + 0.85, 2.75, trim)

    # Tack-room front (rightmost bay mostly closed)
    add("TackFront", 2.5, WALL, 2.5, 4.15, D / 2 - WALL / 2, 1.45, green)
    add("TackDoor", 0.9, 0.06, 2.0, 4.15, D / 2 + 0.02, 1.1, wood)

    # Overhang roof slab
    add("Overhang", W + 0.4, 2.2, 0.10, 0, D / 2 + 0.7, 2.95, roof)

    # Main roof: two slabs meeting at ridge (pitch along Y)
    roof_len = D + 0.6
    pitch = math.atan2(RIDGE - EAVE, D / 2)
    # Blender rotate around X
    bpy.ops.mesh.primitive_cube_add(size=1, location=(0, -D / 4, (EAVE + RIDGE) / 2))
    rs = bpy.context.active_object
    rs.name = "RoofS"
    rs.scale = (W + 0.5, roof_len / 2 + 0.15, 0.10)
    rs.rotation_euler = (pitch, 0, 0)
    bpy.ops.object.transform_apply(location=False, rotation=True, scale=True)
    rs.data.materials.append(roof)
    names.append("RoofS")

    bpy.ops.mesh.primitive_cube_add(size=1, location=(0, D / 4, (EAVE + RIDGE) / 2))
    rn = bpy.context.active_object
    rn.name = "RoofN"
    rn.scale = (W + 0.5, roof_len / 2 + 0.15, 0.10)
    rn.rotation_euler = (-pitch, 0, 0)
    bpy.ops.object.transform_apply(location=False, rotation=True, scale=True)
    rn.data.materials.append(roof)
    names.append("RoofN")

    # Cupola
    add("Cupola", 0.85, 0.7, 0.7, 0, 0, RIDGE + 0.35, trim)
    add("CupolaRoof", 1.05, 0.9, 0.12, 0, 0, RIDGE + 0.75, roof)

    # Interior hint (dark back boards)
    add("Loft", W - 0.4, D - 0.4, 0.08, 0, 0, 2.85, dark)

    join_named(names, "Barn")


def build_jump() -> None:
    cream = make_mat("Standard", color=(0.86, 0.78, 0.62, 1), rough=0.7)
    pole = make_mat("Pole", color=(0.55, 0.40, 0.24, 1), rough=0.85)
    boxc = make_mat("Planter", color=(0.45, 0.55, 0.38, 1), rough=0.8)
    leaf = make_mat("Leaf", color=(0.25, 0.48, 0.22, 1), rough=0.7)
    bloom = make_mat("Bloom", color=(0.92, 0.90, 0.82, 1), rough=0.55)
    names = []

    def add(n, *a, mat=None):
        names.append(box(n, *a, mat).name)

    span = 3.2
    add("StdL", 0.14, 0.22, 1.35, -span / 2, 0, 0.675, mat=cream)
    add("StdR", 0.14, 0.22, 1.35, span / 2, 0, 0.675, mat=cream)
    add("FootL", 0.42, 0.42, 0.10, -span / 2, 0, 0.05, mat=cream)
    add("FootR", 0.42, 0.42, 0.10, span / 2, 0, 0.05, mat=cream)
    add("RailLo", span - 0.15, 0.11, 0.11, 0, 0, 0.72, mat=pole)
    add("RailHi", span - 0.15, 0.11, 0.11, 0, 0, 1.05, mat=pole)
    add("Planter", 2.4, 0.42, 0.38, 0, 0.28, 0.19, mat=boxc)

    for i, x in enumerate((-0.7, -0.2, 0.3, 0.75)):
        bpy.ops.mesh.primitive_ico_sphere_add(subdivisions=1, radius=0.11, location=(x, 0.28, 0.46))
        fl = bpy.context.active_object
        fl.name = f"Flower{i}"
        fl.data.materials.append(leaf if i % 2 == 0 else bloom)
        names.append(fl.name)

    join_named(names, "Jump")


def build_fence() -> None:
    white = make_mat("FenceWhite", color=(0.90, 0.88, 0.82, 1), rough=0.72)
    names = []

    def add(n, *a):
        names.append(box(n, *a, white).name)

    add("PostL", 0.12, 0.12, 1.22, -1.45, 0, 0.61)
    add("PostR", 0.12, 0.12, 1.22, 1.45, 0, 0.61)
    add("Rail1", 2.9, 0.07, 0.08, 0, 0, 0.38)
    add("Rail2", 2.9, 0.07, 0.08, 0, 0, 0.70)
    add("Rail3", 2.9, 0.07, 0.08, 0, 0, 1.02)
    join_named(names, "Fence")


def main() -> None:
    if not TEX_WOOD.exists() or not TEX_ROOF.exists():
        print("Missing barn textures", file=sys.stderr)
        sys.exit(1)
    OUT.mkdir(parents=True, exist_ok=True)

    clear_scene()
    build_barn()
    export_glb(OUT / "barn.glb")

    clear_scene()
    build_jump()
    export_glb(OUT / "jump.glb")

    clear_scene()
    build_fence()
    export_glb(OUT / "fence.glb")


if __name__ == "__main__":
    main()
