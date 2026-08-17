"""Skin the free horse and author idle / walk / jump.

  blender --background --python tools/rig_free_horse.py
"""
from __future__ import annotations

import math
from pathlib import Path

import bpy
from mathutils import Vector

ROOT = Path(r"c:\Users\rich\Projects\Horse Game")
SRC = ROOT / "assets" / "models" / "horse" / "free_horse.glb"
OUT = ROOT / "assets" / "models" / "horse" / "free_horse.glb"


def clear_scene() -> None:
    bpy.ops.object.select_all(action="SELECT")
    bpy.ops.object.delete(use_global=False)


def mesh_obj() -> bpy.types.Object:
    meshes = [o for o in bpy.context.scene.objects if o.type == "MESH"]
    if not meshes:
        raise SystemExit("no mesh")
    return meshes[0]


def add_bone(arm, name: str, head: Vector, tail: Vector, parent: str | None = None, deform: bool = True):
    bone = arm.edit_bones.new(name)
    bone.head = head
    bone.tail = tail
    bone.use_deform = deform
    bone.roll = 0.0
    if parent:
        bone.parent = arm.edit_bones[parent]
        bone.use_connect = False
    return bone


def build_armature(ground_z: float) -> bpy.types.Object:
    bpy.ops.object.armature_add(enter_editmode=True, location=(0.0, 0.0, 0.0))
    arm_obj = bpy.context.active_object
    arm_obj.name = "HorseRig"
    arm = arm_obj.data
    arm.name = "HorseRig"
    for b in list(arm.edit_bones):
        arm.edit_bones.remove(b)

    # Horse faces -Y. Left = -X, right = +X. Ground ~ ground_z.
    hip_z = ground_z + 1.08
    sh_z = ground_z + 1.12
    mid_z = ground_z + 1.14
    knee_z = ground_z + 0.62
    hock_z = ground_z + 0.58
    hoof_z = ground_z + 0.02
    hip_y = 0.78
    sh_y = -0.02
    lx, rx = -0.13, 0.13

    add_bone(arm, "Root", Vector((0.0, 0.35, ground_z)), Vector((0.0, 0.35, ground_z + 0.2)), deform=False)
    add_bone(arm, "Pelvis", Vector((0.0, 0.70, hip_z)), Vector((0.0, 0.48, mid_z)), "Root")
    add_bone(arm, "Spine", Vector((0.0, 0.48, mid_z)), Vector((0.0, 0.18, mid_z + 0.02)), "Pelvis")
    add_bone(arm, "Chest", Vector((0.0, 0.18, mid_z + 0.02)), Vector((0.0, -0.04, sh_z)), "Spine")
    add_bone(arm, "Neck", Vector((0.0, -0.04, sh_z)), Vector((0.0, -0.42, ground_z + 1.42)), "Chest")
    add_bone(arm, "Head", Vector((0.0, -0.42, ground_z + 1.42)), Vector((0.0, -0.78, ground_z + 1.62)), "Neck")
    add_bone(arm, "Tail", Vector((0.0, 0.86, hip_z + 0.08)), Vector((0.0, 1.08, hip_z - 0.06)), "Pelvis")

    add_bone(arm, "Shoulder.L", Vector((lx, sh_y, sh_z)), Vector((lx, sh_y - 0.02, knee_z)), "Chest")
    add_bone(arm, "Forearm.L", Vector((lx, sh_y - 0.02, knee_z)), Vector((lx, sh_y, hoof_z + 0.32)), "Shoulder.L")
    add_bone(arm, "Cannon.L", Vector((lx, sh_y, hoof_z + 0.32)), Vector((lx, sh_y + 0.01, hoof_z)), "Forearm.L")
    add_bone(arm, "Shoulder.R", Vector((rx, sh_y, sh_z)), Vector((rx, sh_y - 0.02, knee_z)), "Chest")
    add_bone(arm, "Forearm.R", Vector((rx, sh_y - 0.02, knee_z)), Vector((rx, sh_y, hoof_z + 0.32)), "Shoulder.R")
    add_bone(arm, "Cannon.R", Vector((rx, sh_y, hoof_z + 0.32)), Vector((rx, sh_y + 0.01, hoof_z)), "Forearm.R")

    add_bone(arm, "Hip.L", Vector((lx, hip_y, hip_z)), Vector((lx, hip_y + 0.02, hock_z)), "Pelvis")
    add_bone(arm, "Hock.L", Vector((lx, hip_y + 0.02, hock_z)), Vector((lx, hip_y, hoof_z + 0.30)), "Hip.L")
    add_bone(arm, "HindCannon.L", Vector((lx, hip_y, hoof_z + 0.30)), Vector((lx, hip_y - 0.01, hoof_z)), "Hock.L")
    add_bone(arm, "Hip.R", Vector((rx, hip_y, hip_z)), Vector((rx, hip_y + 0.02, hock_z)), "Pelvis")
    add_bone(arm, "Hock.R", Vector((rx, hip_y + 0.02, hock_z)), Vector((rx, hip_y, hoof_z + 0.30)), "Hip.R")
    add_bone(arm, "HindCannon.R", Vector((rx, hip_y, hoof_z + 0.30)), Vector((rx, hip_y - 0.01, hoof_z)), "Hock.R")

    bpy.ops.object.mode_set(mode="OBJECT")
    return arm_obj


def _seg_dist(p: Vector, a: Vector, b: Vector) -> float:
    ab = b - a
    denom = ab.length_squared
    if denom < 1e-8:
        return (p - a).length
    t = max(0.0, min(1.0, (p - a).dot(ab) / denom))
    return (p - (a + ab * t)).length


def bind(mesh: bpy.types.Object, arm: bpy.types.Object) -> None:
    ## Heat weights fail on this decimated mesh. Bind with named groups
    ## and distance-to-bone weights so the export actually has a skin.
    bpy.ops.object.select_all(action="DESELECT")
    mesh.select_set(True)
    arm.select_set(True)
    bpy.context.view_layer.objects.active = arm
    bpy.ops.object.parent_set(type="ARMATURE_NAME")

    bpy.context.view_layer.objects.active = arm
    bpy.ops.object.mode_set(mode="EDIT")
    bones: list[tuple[str, Vector, Vector, float]] = []
    for eb in arm.data.edit_bones:
        if not eb.use_deform:
            continue
        radius = 0.12
        if eb.name in {"Pelvis", "Spine", "Chest"}:
            radius = 0.30
        elif eb.name in {"Neck", "Head"}:
            radius = 0.18
        elif eb.name == "Tail":
            radius = 0.11
        elif eb.name.startswith("Shoulder") or eb.name.startswith("Hip"):
            radius = 0.15
        elif eb.name.startswith("Forearm") or eb.name.startswith("Hock"):
            radius = 0.11
        elif "Cannon" in eb.name:
            radius = 0.08
        bones.append((eb.name, eb.head.copy(), eb.tail.copy(), radius))
    bpy.ops.object.mode_set(mode="OBJECT")

    for name, _h, _t, _r in bones:
        if name not in mesh.vertex_groups:
            mesh.vertex_groups.new(name=name)
        mesh.vertex_groups[name].remove(range(len(mesh.data.vertices)))

    assigned = 0
    for v in mesh.data.vertices:
        p = mesh.matrix_world @ v.co
        weights: list[tuple[str, float]] = []
        for name, head, tail, radius in bones:
            if name.endswith(".L") and p.x > 0.04:
                continue
            if name.endswith(".R") and p.x < -0.04:
                continue
            d = _seg_dist(p, head, tail)
            if d >= radius:
                continue
            w = (1.0 - d / radius) ** 2
            if w > 0.002:
                weights.append((name, w))
        if not weights:
            nearest = min(bones, key=lambda b: _seg_dist(p, b[1], b[2]))
            mesh.vertex_groups[nearest[0]].add([v.index], 1.0, "REPLACE")
            assigned += 1
            continue
        total = sum(w for _n, w in weights)
        for name, w in weights:
            mesh.vertex_groups[name].add([v.index], w / total, "REPLACE")
        assigned += 1
    print("weighted verts", assigned, "of", len(mesh.data.vertices), "groups", len(mesh.vertex_groups))
    _side_cleanup(mesh)


def _side_cleanup(mesh: bpy.types.Object) -> None:
    left = [vg.name for vg in mesh.vertex_groups if vg.name.endswith(".L")]
    right = [vg.name for vg in mesh.vertex_groups if vg.name.endswith(".R")]
    for v in mesh.data.vertices:
        p = mesh.matrix_world @ v.co
        if abs(p.x) < 0.035:
            continue
        kill = right if p.x < 0.0 else left
        for name in kill:
            mesh.vertex_groups[name].remove([v.index])


def key_euler(pb, frame: int, xyz: tuple[float, float, float]) -> None:
    pb.rotation_mode = "XYZ"
    pb.rotation_euler = xyz
    pb.keyframe_insert(data_path="rotation_euler", frame=frame)


def key_loc(pb, frame: int, loc: tuple[float, float, float]) -> None:
    pb.location = loc
    pb.keyframe_insert(data_path="location", frame=frame)


def new_action(arm: bpy.types.Object, name: str) -> bpy.types.Action:
    if arm.animation_data is None:
        arm.animation_data_create()
    old = bpy.data.actions.get(name)
    if old:
        bpy.data.actions.remove(old)
    action = bpy.data.actions.new(name)
    action.use_fake_user = True
    arm.animation_data.action = action
    slot = action.slots.new("OBJECT", arm.name)
    arm.animation_data.action_slot = slot
    return action


def pose(arm: bpy.types.Object, name: str) -> bpy.types.PoseBone:
    return arm.pose.bones[name]


def make_idle(arm: bpy.types.Object) -> None:
    new_action(arm, "Idle")
    n = pose(arm, "Neck")
    h = pose(arm, "Head")
    s = pose(arm, "Spine")
    t = pose(arm, "Tail")
    for fr, neck, head, spine, tail in (
        (1, (0.04, 0.0, 0.0), (0.02, 0.0, 0.03), (0.0, 0.0, 0.02), (0.1, 0.0, 0.05)),
        (16, (-0.03, 0.0, 0.02), (-0.04, 0.0, -0.02), (0.015, 0.0, -0.02), (-0.08, 0.0, -0.04)),
        (32, (0.05, 0.0, -0.02), (0.03, 0.0, 0.04), (-0.01, 0.0, 0.015), (0.12, 0.0, 0.06)),
        (48, (0.04, 0.0, 0.0), (0.02, 0.0, 0.03), (0.0, 0.0, 0.02), (0.1, 0.0, 0.05)),
    ):
        key_euler(n, fr, neck)
        key_euler(h, fr, head)
        key_euler(s, fr, spine)
        key_euler(t, fr, tail)
        key_loc(pose(arm, "Root"), fr, (0.0, 0.0, 0.008 * math.sin((fr - 1) / 48.0 * math.tau)))


def make_walk(arm: bpy.types.Object) -> None:
    new_action(arm, "Walk")
    # 24-frame 4-beat walk. Positive X rotation swings a down-bone toward +Y (hind).
    # Horse faces -Y, so negative X on a front shoulder is a forward reach.
    sl, sr = pose(arm, "Shoulder.L"), pose(arm, "Shoulder.R")
    fl, frb = pose(arm, "Forearm.L"), pose(arm, "Forearm.R")
    hl, hr = pose(arm, "Hip.L"), pose(arm, "Hip.R")
    kl, kr = pose(arm, "Hock.L"), pose(arm, "Hock.R")
    chest, neck, head = pose(arm, "Chest"), pose(arm, "Neck"), pose(arm, "Head")
    keys = (
        # fr, shL, shR, faL, faR, hipL, hipR, hockL, hockR
        (1, -0.38, 0.32, 0.55, 0.12, 0.32, -0.34, 0.15, 0.50),
        (7, -0.05, -0.05, 0.20, 0.22, -0.05, -0.05, 0.22, 0.22),
        (13, 0.32, -0.38, 0.12, 0.55, -0.34, 0.32, 0.50, 0.15),
        (19, -0.05, -0.05, 0.22, 0.20, -0.05, -0.05, 0.22, 0.22),
        (25, -0.38, 0.32, 0.55, 0.12, 0.32, -0.34, 0.15, 0.50),
    )
    for fr, a, b, c, d, e, f, g, h in keys:
        key_euler(sl, fr, (a, 0.0, 0.0))
        key_euler(sr, fr, (b, 0.0, 0.0))
        key_euler(fl, fr, (c, 0.0, 0.0))
        key_euler(frb, fr, (d, 0.0, 0.0))
        key_euler(hl, fr, (e, 0.0, 0.0))
        key_euler(hr, fr, (f, 0.0, 0.0))
        key_euler(kl, fr, (g, 0.0, 0.0))
        key_euler(kr, fr, (h, 0.0, 0.0))
        bob = 0.02 * math.sin((fr - 1) / 24.0 * math.tau * 2.0)
        key_loc(pose(arm, "Root"), fr, (0.0, 0.0, bob))
        key_euler(chest, fr, (0.0, 0.0, 0.04 * math.sin((fr - 1) / 24.0 * math.tau)))
        key_euler(neck, fr, (0.06 * math.sin((fr - 1) / 24.0 * math.tau), 0.0, 0.0))
        key_euler(head, fr, (-0.05 * math.sin((fr - 1) / 24.0 * math.tau), 0.0, 0.0))


def make_jump(arm: bpy.types.Object) -> None:
    new_action(arm, "Jump")
    bones = {
        "Neck": pose(arm, "Neck"),
        "Head": pose(arm, "Head"),
        "Spine": pose(arm, "Spine"),
        "Chest": pose(arm, "Chest"),
        "Pelvis": pose(arm, "Pelvis"),
        "Shoulder.L": pose(arm, "Shoulder.L"),
        "Shoulder.R": pose(arm, "Shoulder.R"),
        "Forearm.L": pose(arm, "Forearm.L"),
        "Forearm.R": pose(arm, "Forearm.R"),
        "Hip.L": pose(arm, "Hip.L"),
        "Hip.R": pose(arm, "Hip.R"),
        "Hock.L": pose(arm, "Hock.L"),
        "Hock.R": pose(arm, "Hock.R"),
    }

    def set_pose(fr: int, data: dict[str, tuple[float, float, float]]) -> None:
        for name, xyz in data.items():
            key_euler(bones[name], fr, xyz)

    rest = {k: (0.0, 0.0, 0.0) for k in bones}
    collect = {
        **rest,
        "Neck": (0.22, 0.0, 0.0),
        "Head": (0.12, 0.0, 0.0),
        "Spine": (0.08, 0.0, 0.0),
        "Pelvis": (-0.10, 0.0, 0.0),
        "Hip.L": (0.28, 0.0, 0.0),
        "Hip.R": (0.28, 0.0, 0.0),
        "Hock.L": (0.55, 0.0, 0.0),
        "Hock.R": (0.55, 0.0, 0.0),
        "Shoulder.L": (0.10, 0.0, 0.0),
        "Shoulder.R": (0.10, 0.0, 0.0),
        "Forearm.L": (0.20, 0.0, 0.0),
        "Forearm.R": (0.20, 0.0, 0.0),
    }
    takeoff = {
        **rest,
        "Neck": (-0.25, 0.0, 0.0),
        "Head": (-0.10, 0.0, 0.0),
        "Chest": (-0.12, 0.0, 0.0),
        "Pelvis": (0.18, 0.0, 0.0),
        "Shoulder.L": (-0.45, 0.0, 0.0),
        "Shoulder.R": (-0.45, 0.0, 0.0),
        "Forearm.L": (0.15, 0.0, 0.0),
        "Forearm.R": (0.15, 0.0, 0.0),
        "Hip.L": (-0.40, 0.0, 0.0),
        "Hip.R": (-0.40, 0.0, 0.0),
        "Hock.L": (0.10, 0.0, 0.0),
        "Hock.R": (0.10, 0.0, 0.0),
    }
    tuck = {
        **rest,
        "Neck": (-0.05, 0.0, 0.0),
        "Spine": (-0.12, 0.0, 0.0),
        "Shoulder.L": (0.15, 0.0, 0.0),
        "Shoulder.R": (0.15, 0.0, 0.0),
        "Forearm.L": (0.85, 0.0, 0.0),
        "Forearm.R": (0.85, 0.0, 0.0),
        "Hip.L": (0.35, 0.0, 0.0),
        "Hip.R": (0.35, 0.0, 0.0),
        "Hock.L": (0.90, 0.0, 0.0),
        "Hock.R": (0.90, 0.0, 0.0),
    }
    land = {
        **rest,
        "Neck": (0.18, 0.0, 0.0),
        "Head": (0.08, 0.0, 0.0),
        "Shoulder.L": (0.20, 0.0, 0.0),
        "Shoulder.R": (0.20, 0.0, 0.0),
        "Forearm.L": (0.35, 0.0, 0.0),
        "Forearm.R": (0.35, 0.0, 0.0),
        "Hip.L": (0.15, 0.0, 0.0),
        "Hip.R": (0.15, 0.0, 0.0),
        "Hock.L": (0.40, 0.0, 0.0),
        "Hock.R": (0.40, 0.0, 0.0),
    }
    set_pose(1, rest)
    set_pose(6, collect)
    set_pose(12, takeoff)
    set_pose(18, tuck)
    set_pose(24, land)
    set_pose(28, rest)


def stash_nla(arm: bpy.types.Object) -> None:
    if arm.animation_data is None:
        return
    arm.animation_data.action = None
    # Drop leftover tracks from the imported file.
    while arm.animation_data.nla_tracks:
        arm.animation_data.nla_tracks.remove(arm.animation_data.nla_tracks[0])
    for name in ("Idle", "Walk", "Jump"):
        action = bpy.data.actions.get(name)
        if action is None:
            continue
        track = arm.animation_data.nla_tracks.new()
        track.name = name
        start = int(action.frame_range[0])
        strip = track.strips.new(name, start, action)
        strip.action = action
        if action.slots:
            strip.action_slot = action.slots[0]


def export() -> None:
    bpy.ops.object.select_all(action="SELECT")
    bpy.ops.export_scene.gltf(
        filepath=str(OUT),
        export_format="GLB",
        export_texcoords=True,
        export_normals=True,
        export_materials="EXPORT",
        export_skins=True,
        export_animations=True,
        export_nla_strips=True,
        export_anim_single_armature=True,
        export_apply=True,
    )


def main() -> None:
    clear_scene()
    bpy.context.scene.render.fps = 24
    for act in list(bpy.data.actions):
        bpy.data.actions.remove(act)
    bpy.ops.import_scene.gltf(filepath=str(SRC))
    for o in list(bpy.context.scene.objects):
        if o.type != "MESH":
            bpy.data.objects.remove(o, do_unlink=True)
    mesh = mesh_obj()
    bpy.ops.object.select_all(action="DESELECT")
    mesh.select_set(True)
    bpy.context.view_layer.objects.active = mesh
    bpy.ops.object.transform_apply(location=True, rotation=True, scale=True)
    zs = [(mesh.matrix_world @ v.co).z for v in mesh.data.vertices]
    ground = min(zs)
    print("mesh", mesh.name, "ground", ground, "dims", tuple(mesh.dimensions))
    arm = build_armature(ground)
    bind(mesh, arm)
    make_idle(arm)
    make_walk(arm)
    make_jump(arm)
    stash_nla(arm)
    export()
    print("actions", [a.name for a in bpy.data.actions])
    print("wrote", OUT, "bytes", OUT.stat().st_size)


if __name__ == "__main__":
    main()
