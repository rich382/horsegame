"""Decimate the free horse GLB to a farm-ready polycount. Run:

  blender --background --python tools/decimate_free_horse.py
"""
from __future__ import annotations

from pathlib import Path

import bpy

ROOT = Path(r"c:\Users\rich\Projects\Horse Game")
SRC = ROOT / "assets" / "models" / "horse" / "free_horse_source.glb"
OUT = ROOT / "assets" / "models" / "horse" / "free_horse.glb"
TARGET_FACES = 28000


def clear_scene() -> None:
    bpy.ops.object.select_all(action="SELECT")
    bpy.ops.object.delete(use_global=False)


def mesh_objects():
    return [o for o in bpy.context.scene.objects if o.type == "MESH"]


def main() -> None:
    clear_scene()
    bpy.ops.import_scene.gltf(filepath=str(SRC))
    meshes = mesh_objects()
    if not meshes:
        raise SystemExit("no mesh in %s" % SRC)
    for obj in meshes:
        bpy.context.view_layer.objects.active = obj
        obj.select_set(True)
        faces = len(obj.data.polygons)
        ratio = min(1.0, float(TARGET_FACES) / float(max(faces, 1)))
        print("decimate %s faces=%d ratio=%.4f" % (obj.name, faces, ratio))
        mod = obj.modifiers.new(name="Decimate", type="DECIMATE")
        mod.decimate_type = "COLLAPSE"
        mod.ratio = ratio
        bpy.ops.object.modifier_apply(modifier=mod.name)
        print("  now faces=%d verts=%d" % (len(obj.data.polygons), len(obj.data.vertices)))
        # Kill the glowing emissive that THREE.GLTFExporter baked in.
        for slot in obj.material_slots:
            mat = slot.material
            if mat and mat.use_nodes:
                for node in mat.node_tree.nodes:
                    if node.type == "EMISSION":
                        if "Color" in node.inputs:
                            node.inputs["Color"].default_value = (0, 0, 0, 1)
                        if "Strength" in node.inputs:
                            node.inputs["Strength"].default_value = 0.0
                    if node.type == "BSDF_PRINCIPLED":
                        if "Emission Color" in node.inputs:
                            node.inputs["Emission Color"].default_value = (0, 0, 0, 1)
                        if "Emission Strength" in node.inputs:
                            node.inputs["Emission Strength"].default_value = 0.0
    bpy.ops.export_scene.gltf(
        filepath=str(OUT),
        export_format="GLB",
        export_texcoords=True,
        export_normals=True,
        export_materials="EXPORT",
        export_animations=False,
        export_apply=True,
    )
    print("wrote", OUT)


if __name__ == "__main__":
    main()
