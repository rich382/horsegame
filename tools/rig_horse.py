"""
Blender 5.2: turn the Imagine horse PNG into a skinned card with idle + walk.

This is a 2D cutout puppet, not a 3D Warmblood. Bones warp one painted plane.

Run:
  blender --background --python tools/rig_horse.py
"""
from __future__ import annotations

import math
import sys
from pathlib import Path

import bpy
from mathutils import Vector

ROOT = Path(r"c:\Users\rich\Projects\Horse Game")
TEX = ROOT / "assets" / "sprites" / "horse_bay.png"
OUT = ROOT / "assets" / "models" / "horse" / "horse_rigged.glb"

HEIGHT_M = 2.15
COLS, ROWS = 18, 22


def clear_scene() -> None:
    bpy.ops.object.select_all(action="SELECT")
    bpy.ops.object.delete(use_global=False)
    for block in list(bpy.data.meshes) + list(bpy.data.armatures) + list(bpy.data.materials) + list(bpy.data.images):
        bpy.data.batch_remove([block])


def make_card(aspect: float) -> bpy.types.Object:
    width = HEIGHT_M * aspect
    bpy.ops.mesh.primitive_grid_add(
        x_subdivisions=COLS,
        y_subdivisions=ROWS,
        size=1.0,
        location=(0.0, HEIGHT_M * 0.5, 0.0),
    )
    card = bpy.context.active_object
    card.name = "HorseCard"
    card.scale = (width, HEIGHT_M, 1.0)
    bpy.ops.object.transform_apply(location=False, rotation=False, scale=True)
    # Face +Z so Godot/glTF sees the painting
    card.rotation_euler = (math.radians(90.0), 0.0, 0.0)
    bpy.ops.object.transform_apply(location=False, rotation=True, scale=False)
    return card


def assign_material(card: bpy.types.Object, tex_path: Path) -> None:
    img = bpy.data.images.load(str(tex_path))
    img.alpha_mode = "STRAIGHT"
    mat = bpy.data.materials.new("HorsePaint")
    mat.use_nodes = True
    mat.blend_method = "CLIP"
    nt = mat.node_tree
    nt.nodes.clear()
    out = nt.nodes.new("ShaderNodeOutputMaterial")
    bsdf = nt.nodes.new("ShaderNodeBsdfPrincipled")
    tex = nt.nodes.new("ShaderNodeTexImage")
    tex.image = img
    tex.interpolation = "Closest"
    nt.links.new(tex.outputs["Color"], bsdf.inputs["Base Color"])
    nt.links.new(tex.outputs["Alpha"], bsdf.inputs["Alpha"])
    nt.links.new(bsdf.outputs["BSDF"], out.inputs["Surface"])
    card.data.materials.append(mat)


def add_bone(arm, name: str, head: Vector, tail: Vector, parent: str | None = None):
    bone = arm.edit_bones.new(name)
    bone.head = head
    bone.tail = tail
    bone.use_deform = name != "Root"
    if parent:
        bone.parent = arm.edit_bones[parent]
        bone.use_connect = False
    return bone


def make_armature() -> bpy.types.Object:
    bpy.ops.object.armature_add(enter_editmode=True, location=(0.0, 0.0, 0.0))
    obj = bpy.context.active_object
    obj.name = "HorseRig"
    arm = obj.data
    arm.name = "HorseRigData"
    # Drop the default bone
    for b in list(arm.edit_bones):
        arm.edit_bones.remove(b)

    # Image: head on -X, tail on +X, hooves at Y=0, withers ~1.3
    add_bone(arm, "Root", Vector((0.05, 0.0, 0.0)), Vector((0.05, 0.15, 0.0)))
    add_bone(arm, "Spine", Vector((0.08, 0.95, 0.0)), Vector((-0.05, 1.25, 0.0)), "Root")
    add_bone(arm, "Neck", Vector((-0.18, 1.35, 0.0)), Vector((-0.38, 1.58, 0.0)), "Spine")
    add_bone(arm, "Head", Vector((-0.40, 1.60, 0.0)), Vector((-0.58, 1.78, 0.0)), "Neck")
    add_bone(arm, "Shoulder", Vector((-0.18, 1.18, 0.0)), Vector((-0.20, 0.78, 0.0)), "Spine")
    add_bone(arm, "FrontLeg", Vector((-0.20, 0.76, 0.0)), Vector((-0.18, 0.08, 0.0)), "Shoulder")
    add_bone(arm, "Hip", Vector((0.22, 1.12, 0.0)), Vector((0.24, 0.74, 0.0)), "Spine")
    add_bone(arm, "BackLeg", Vector((0.24, 0.72, 0.0)), Vector((0.22, 0.08, 0.0)), "Hip")
    add_bone(arm, "Tail", Vector((0.38, 1.18, 0.0)), Vector((0.52, 0.72, 0.0)), "Spine")

    bpy.ops.object.mode_set(mode="OBJECT")
    return obj


def auto_weights(card: bpy.types.Object, rig: bpy.types.Object) -> None:
    # Vertex groups from bone proximity in object space (Y up after apply).
    mesh = card.data
    groups = {name: card.vertex_groups.new(name=name) for name in
              ["Spine", "Neck", "Head", "Shoulder", "FrontLeg", "Hip", "BackLeg", "Tail"]}
    # Bone rest heads in world
    bpy.context.view_layer.update()
    heads = {}
    for pb in rig.pose.bones:
        if pb.name == "Root":
            continue
        heads[pb.name] = rig.matrix_world @ pb.head

    for vi, v in enumerate(mesh.vertices):
        p = card.matrix_world @ v.co
        weights = {}
        for name, h in heads.items():
            d = (Vector((p.x, p.y, 0.0)) - Vector((h.x, h.y, 0.0))).length
            weights[name] = 1.0 / max(d * d, 0.012)
        total = sum(weights.values())
        for name, w in weights.items():
            groups[name].add([vi], w / total, "REPLACE")

    mod = card.modifiers.new("Armature", "ARMATURE")
    mod.object = rig
    card.parent = rig


def key(pb, frame: int, rot_z: float) -> None:
    pb.rotation_mode = "XYZ"
    pb.rotation_euler = (0.0, 0.0, math.radians(rot_z))
    pb.keyframe_insert(data_path="rotation_euler", frame=frame)


def make_actions(rig: bpy.types.Object) -> None:
    bpy.context.view_layer.objects.active = rig
    bpy.ops.object.mode_set(mode="POSE")
    bones = rig.pose.bones
    fps = 24
    bpy.context.scene.render.fps = fps
    bpy.context.scene.frame_start = 1

    def action(name: str, length: int, keys: dict) -> None:
        act = bpy.data.actions.new(name)
        if not rig.animation_data:
            rig.animation_data_create()
        rig.animation_data.action = act
        for bname, frames in keys.items():
            pb = bones[bname]
            for fr, ang in frames:
                key(pb, fr, ang)
        act.use_fake_user = True
        bpy.context.scene.frame_end = length

    # Idle: 48 frames, head nod + weight shift
    action("idle", 48, {
        "Head": [(1, 0), (13, 6), (25, 0), (37, -4), (48, 0)],
        "Neck": [(1, 0), (25, 3), (48, 0)],
        "Spine": [(1, 0), (25, -1.5), (48, 0)],
        "FrontLeg": [(1, 0), (25, 2), (48, 0)],
        "BackLeg": [(1, 0), (25, -2), (48, 0)],
        "Tail": [(1, 4), (25, -6), (48, 4)],
    })

    # Walk: 24 frames, opposite legs. Small angles so the painting does not melt.
    action("walk", 24, {
        "FrontLeg": [(1, 12), (7, 0), (13, -12), (19, 0), (24, 12)],
        "BackLeg": [(1, -10), (7, 0), (13, 10), (19, 0), (24, -10)],
        "Shoulder": [(1, 4), (13, -4), (24, 4)],
        "Hip": [(1, -3), (13, 3), (24, -3)],
        "Head": [(1, 2), (13, -2), (24, 2)],
        "Neck": [(1, -2), (13, 2), (24, -2)],
        "Spine": [(1, 1.5), (13, -1.5), (24, 1.5)],
        "Tail": [(1, 8), (13, -8), (24, 8)],
    })

    # Leave idle as the active NLA / action for export default
    rig.animation_data.action = bpy.data.actions["idle"]
    bpy.ops.object.mode_set(mode="OBJECT")


def export_glb(path: Path) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    if path.exists():
        path.unlink()
    bpy.ops.export_scene.gltf(
        filepath=str(path),
        export_format="GLB",
        use_selection=False,
        export_animations=True,
        export_nla_strips=False,
        export_skins=True,
        export_morph=False,
        export_apply=False,
        export_yup=True,
        export_texcoords=True,
        export_normals=True,
        export_materials="EXPORT",
        export_image_format="AUTO",
    )


def main() -> None:
    if not TEX.exists():
        print(f"Missing texture: {TEX}", file=sys.stderr)
        sys.exit(1)
    img = bpy.data.images.load(str(TEX))
    aspect = img.size[0] / float(img.size[1])
    bpy.data.images.remove(img)

    clear_scene()
    card = make_card(aspect)
    assign_material(card, TEX)
    rig = make_armature()
    auto_weights(card, rig)
    make_actions(rig)
    export_glb(OUT)
    print(f"Wrote {OUT} ({OUT.stat().st_size} bytes)")


if __name__ == "__main__":
    main()
