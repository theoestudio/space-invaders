#!/usr/bin/env python3
"""Render the 2.5D tactile miniature sprite suite for Pachinko Descent using Blender Cycles.

Run via:
    LOWPRIO_MEM=24G lowprio blender --background --python tools/render-art.py
"""

from __future__ import annotations

import math
import os
import subprocess

import bmesh
import bpy

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
SRC_DIR = os.path.join(ROOT, "tools", "art_src")
OUT_DIR = os.path.join(ROOT, "assets", "art")
os.makedirs(OUT_DIR, exist_ok=True)


def clear_scene() -> None:
    bpy.ops.wm.read_factory_settings(use_empty=True)


def setup_cycles(samples: int = 64) -> bpy.types.Scene:
    scene = bpy.context.scene
    scene.render.engine = "CYCLES"
    scene.cycles.samples = samples
    scene.cycles.use_adaptive_sampling = True
    scene.cycles.adaptive_threshold = 0.015
    scene.cycles.use_denoising = True
    scene.cycles.max_bounces = 8
    scene.cycles.diffuse_bounces = 3
    scene.cycles.glossy_bounces = 4
    scene.cycles.transmission_bounces = 8
    scene.cycles.transparent_max_bounces = 8

    prefs = bpy.context.preferences.addons["cycles"].preferences
    prefs.refresh_devices()
    chosen = None
    for backend in ("OPTIX", "CUDA"):
        for dev in prefs.devices:
            if dev.type == backend:
                chosen = backend
                break
        if chosen:
            break
    if chosen:
        prefs.compute_device_type = chosen
        for dev in prefs.devices:
            dev.use = dev.type == chosen
        scene.cycles.device = "GPU"
        print(f"[render-art] Cycles using GPU ({chosen})", flush=True)
    else:
        scene.cycles.device = "CPU"
        print("[render-art] Cycles using CPU", flush=True)

    scene.render.film_transparent = True
    scene.render.image_settings.file_format = "PNG"
    scene.render.image_settings.color_mode = "RGBA"
    scene.render.image_settings.color_depth = "8"
    scene.view_settings.view_transform = "AgX"
    for look_name in ("AgX - Medium High Contrast", "AgX - Punchy", "None"):
        try:
            scene.view_settings.look = look_name
            break
        except TypeError:
            continue
    scene.view_settings.exposure = 0.1
    return scene


def setup_studio_world(scene: bpy.types.Scene) -> None:
    world = bpy.data.worlds.new("StudioWorld")
    scene.world = world
    nt = world.node_tree
    nt.nodes.clear()

    out = nt.nodes.new("ShaderNodeOutputWorld")
    bg = nt.nodes.new("ShaderNodeBackground")
    bg.inputs["Strength"].default_value = 0.42

    # Dark midnight studio dome with sharp high-altitude reflection band for chrome & brass
    tex_coord = nt.nodes.new("ShaderNodeTexCoord")
    sep = nt.nodes.new("ShaderNodeSeparateXYZ")
    nt.links.new(tex_coord.outputs["Generated"], sep.inputs["Vector"])

    ramp = nt.nodes.new("ShaderNodeValToRGB")
    cr = ramp.color_ramp
    cr.elements[0].position = 0.0
    cr.elements[0].color = (0.015, 0.012, 0.045, 1.0)
    e1 = cr.elements.new(0.55)
    e1.color = (0.05, 0.045, 0.12, 1.0)
    e2 = cr.elements.new(0.84)
    e2.color = (0.28, 0.30, 0.42, 1.0)
    cr.elements[-1].position = 0.94
    cr.elements[-1].color = (1.65, 1.62, 1.75, 1.0)
    nt.links.new(sep.outputs["Z"], ramp.inputs["Fac"])

    ramp_x = nt.nodes.new("ShaderNodeValToRGB")
    cx = ramp_x.color_ramp
    cx.elements[0].position = 0.0
    cx.elements[0].color = (0.04, 0.32, 0.48, 1.0)
    em = cx.elements.new(0.5)
    em.color = (0.0, 0.0, 0.0, 1.0)
    cx.elements[-1].position = 1.0
    cx.elements[-1].color = (0.45, 0.06, 0.28, 1.0)
    nt.links.new(sep.outputs["X"], ramp_x.inputs["Fac"])

    add = nt.nodes.new("ShaderNodeMix")
    add.data_type = "RGBA"
    add.blend_type = "ADD"
    add.inputs["Factor"].default_value = 0.45
    nt.links.new(ramp.outputs["Color"], add.inputs[6])
    nt.links.new(ramp_x.outputs["Color"], add.inputs[7])
    nt.links.new(add.outputs[2], bg.inputs["Color"])
    nt.links.new(bg.outputs["Background"], out.inputs["Surface"])


def add_studio_lights(collection: bpy.types.Collection, key_energy: float = 68.0) -> None:
    def area(name: str, loc: tuple[float, float, float], rot_deg: tuple[float, float, float],
             energy: float, size: float, color: tuple[float, float, float]) -> None:
        ld = bpy.data.lights.new(name, type="AREA")
        ld.energy = energy
        ld.size = size
        ld.color = color
        lo = bpy.data.objects.new(name, ld)
        lo.location = loc
        lo.rotation_euler = tuple(math.radians(a) for a in rot_deg)
        collection.objects.link(lo)

    area("KeySoftbox", (-3.0, 2.6, 6.2), (-22, -24, 0), key_energy, 2.8, (1.0, 0.97, 0.93))
    area("TopFill", (0.4, 1.5, 6.5), (-12, 4, 0), key_energy * 0.28, 4.5, (0.92, 0.95, 1.0))
    area("CyanRim", (-4.2, -0.4, 2.4), (8, -60, 0), key_energy * 0.48, 2.2, (0.20, 0.88, 1.0))
    area("PinkRim", (4.2, -0.6, 2.2), (10, 60, 0), key_energy * 0.44, 2.2, (1.0, 0.28, 0.65))


def setup_camera(scene: bpy.types.Scene, ortho_width: float, px_w: int, px_h: int) -> bpy.types.Object:
    cam_data = bpy.data.cameras.new("OrthoCam")
    cam_data.type = "ORTHO"
    cam_data.sensor_fit = "HORIZONTAL"
    cam_data.ortho_scale = ortho_width
    cam_data.clip_start = 0.05
    cam_data.clip_end = 50.0
    cam_obj = bpy.data.objects.new("OrthoCam", cam_data)
    cam_obj.location = (0.0, 0.0, 8.0)
    cam_obj.rotation_euler = (0.0, 0.0, 0.0)
    scene.collection.objects.link(cam_obj)
    scene.camera = cam_obj
    scene.render.resolution_x = px_w
    scene.render.resolution_y = px_h
    scene.render.resolution_percentage = 100
    return cam_obj


def reset_prop_stage(ortho_width: float, px_w: int, px_h: int, shadow_plane: bool = True,
                     shadow_z: float = -0.22, key_energy: float = 68.0) -> bpy.types.Collection:
    scene = bpy.context.scene
    if "PropStage" in bpy.data.collections:
        col = bpy.data.collections["PropStage"]
        for obj in list(col.objects):
            bpy.data.objects.remove(obj, do_unlink=True)
    else:
        col = bpy.data.collections.new("PropStage")
        scene.collection.children.link(col)

    for obj in list(scene.collection.objects):
        if obj.type == "CAMERA":
            bpy.data.objects.remove(obj, do_unlink=True)

    setup_camera(scene, ortho_width, px_w, px_h)
    add_studio_lights(col, key_energy=key_energy)

    if shadow_plane:
        bpy.ops.mesh.primitive_plane_add(size=max(ortho_width * 2.5, 10.0), location=(0.0, 0.0, shadow_z))
        plane = bpy.context.active_object
        for c in list(plane.users_collection):
            c.objects.unlink(plane)
        col.objects.link(plane)
        plane.is_shadow_catcher = True
    return col


def link_to(obj: bpy.types.Object, col: bpy.types.Collection) -> bpy.types.Object:
    for c in list(obj.users_collection):
        c.objects.unlink(obj)
    col.objects.link(obj)
    return obj


def make_pbr(name: str, color: tuple[float, float, float], metallic: float = 0.0,
             roughness: float = 0.3, specular: float = 0.5, coat: float = 0.0,
             coat_rough: float = 0.1, emission: tuple[float, float, float] | None = None,
             emit_str: float = 0.0) -> bpy.types.Material:
    mat = bpy.data.materials.get(name) or bpy.data.materials.new(name)
    nt = mat.node_tree
    nt.nodes.clear()
    out = nt.nodes.new("ShaderNodeOutputMaterial")
    bsdf = nt.nodes.new("ShaderNodeBsdfPrincipled")
    bsdf.inputs["Base Color"].default_value = (*color, 1.0)
    bsdf.inputs["Metallic"].default_value = metallic
    bsdf.inputs["Roughness"].default_value = roughness
    bsdf.inputs["Specular IOR Level"].default_value = specular
    bsdf.inputs["Coat Weight"].default_value = coat
    bsdf.inputs["Coat Roughness"].default_value = coat_rough
    if emission is not None and emit_str > 0.0:
        bsdf.inputs["Emission Color"].default_value = (*emission, 1.0)
        bsdf.inputs["Emission Strength"].default_value = emit_str
    nt.links.new(bsdf.outputs["BSDF"], out.inputs["Surface"])
    return mat


def make_image_mat(name: str, image_path: str, roughness: float = 0.26,
                   coat: float = 0.55, metallic: float = 0.0, specular: float = 0.45,
                   emit_str: float = 0.0) -> bpy.types.Material:
    mat = bpy.data.materials.get(name) or bpy.data.materials.new(name)
    nt = mat.node_tree
    nt.nodes.clear()
    out = nt.nodes.new("ShaderNodeOutputMaterial")
    bsdf = nt.nodes.new("ShaderNodeBsdfPrincipled")
    bsdf.inputs["Metallic"].default_value = metallic
    bsdf.inputs["Roughness"].default_value = roughness
    bsdf.inputs["Specular IOR Level"].default_value = specular
    bsdf.inputs["Coat Weight"].default_value = coat
    bsdf.inputs["Coat Roughness"].default_value = 0.10

    tex = nt.nodes.new("ShaderNodeTexImage")
    tex.image = bpy.data.images.load(image_path, check_existing=True)
    tex.extension = "EXTEND"
    nt.links.new(tex.outputs["Color"], bsdf.inputs["Base Color"])
    if emit_str > 0.0:
        nt.links.new(tex.outputs["Color"], bsdf.inputs["Emission Color"])
        bsdf.inputs["Emission Strength"].default_value = emit_str
    nt.links.new(bsdf.outputs["BSDF"], out.inputs["Surface"])
    return mat


def make_acrylic_mat(name: str, color: tuple[float, float, float],
                     center_opacity: float = 0.42, body_emit: float = 1.45,
                     edge_emit: float = 3.2) -> bpy.types.Material:
    """Translucent glowing neon acrylic: vivid colored tint, clear center for pocketed balls, bright Fresnel rim."""
    mat = bpy.data.materials.get(name) or bpy.data.materials.new(name)
    nt = mat.node_tree
    nt.nodes.clear()

    out = nt.nodes.new("ShaderNodeOutputMaterial")
    lw = nt.nodes.new("ShaderNodeLayerWeight")
    lw.inputs["Blend"].default_value = 0.45

    trans = nt.nodes.new("ShaderNodeBsdfTransparent")
    trans.inputs["Color"].default_value = (
        0.55 + color[0] * 0.45,
        0.55 + color[1] * 0.45,
        0.55 + color[2] * 0.45,
        1.0,
    )

    body_bsdf = nt.nodes.new("ShaderNodeBsdfPrincipled")
    body_bsdf.inputs["Base Color"].default_value = (*color, 1.0)
    body_bsdf.inputs["Roughness"].default_value = 0.18
    body_bsdf.inputs["Specular IOR Level"].default_value = 0.22
    body_bsdf.inputs["Coat Weight"].default_value = 0.0
    body_bsdf.inputs["Emission Color"].default_value = (*color, 1.0)
    body_bsdf.inputs["Emission Strength"].default_value = body_emit

    mix_center = nt.nodes.new("ShaderNodeMixShader")
    mix_center.inputs["Fac"].default_value = center_opacity
    nt.links.new(trans.outputs["BSDF"], mix_center.inputs[1])
    nt.links.new(body_bsdf.outputs["BSDF"], mix_center.inputs[2])

    rim_bsdf = nt.nodes.new("ShaderNodeBsdfPrincipled")
    rim_bsdf.inputs["Base Color"].default_value = (*color, 1.0)
    rim_bsdf.inputs["Roughness"].default_value = 0.08
    rim_bsdf.inputs["Emission Color"].default_value = (*color, 1.0)
    rim_bsdf.inputs["Emission Strength"].default_value = edge_emit

    ramp = nt.nodes.new("ShaderNodeValToRGB")
    ramp.color_ramp.elements[0].position = 0.18
    ramp.color_ramp.elements[0].color = (0.0, 0.0, 0.0, 1.0)
    ramp.color_ramp.elements[1].position = 0.72
    ramp.color_ramp.elements[1].color = (1.0, 1.0, 1.0, 1.0)
    nt.links.new(lw.outputs["Facing"], ramp.inputs["Fac"])

    mix_rim = nt.nodes.new("ShaderNodeMixShader")
    nt.links.new(ramp.outputs["Color"], mix_rim.inputs["Fac"])
    nt.links.new(mix_center.outputs["Shader"], mix_rim.inputs[1])
    nt.links.new(rim_bsdf.outputs["BSDF"], mix_rim.inputs[2])
    nt.links.new(mix_rim.outputs["Shader"], out.inputs["Surface"])
    return mat


def make_glass_sheen_mat(name: str, tint: tuple[float, float, float] = (0.85, 0.93, 1.0),
                         alpha: float = 0.14) -> bpy.types.Material:
    mat = bpy.data.materials.get(name) or bpy.data.materials.new(name)
    nt = mat.node_tree
    nt.nodes.clear()
    out = nt.nodes.new("ShaderNodeOutputMaterial")
    trans = nt.nodes.new("ShaderNodeBsdfTransparent")
    trans.inputs["Color"].default_value = (1.0, 1.0, 1.0, 1.0)
    gloss = nt.nodes.new("ShaderNodeBsdfPrincipled")
    gloss.inputs["Base Color"].default_value = (*tint, 1.0)
    gloss.inputs["Roughness"].default_value = 0.06
    gloss.inputs["Specular IOR Level"].default_value = 0.9
    gloss.inputs["Coat Weight"].default_value = 0.8
    mix = nt.nodes.new("ShaderNodeMixShader")
    mix.inputs["Fac"].default_value = alpha
    nt.links.new(trans.outputs["BSDF"], mix.inputs[1])
    nt.links.new(gloss.outputs["BSDF"], mix.inputs[2])
    nt.links.new(mix.outputs["Shader"], out.inputs["Surface"])
    return mat


def render_to(filename: str) -> str:
    path = os.path.join(OUT_DIR, filename)
    bpy.context.scene.render.filepath = path
    bpy.ops.render.render(write_still=True)
    return path


def extrude_2d_poly(name: str, pts: list[tuple[float, float]], z0: float, z1: float,
                    bevel: float = 0.01) -> bpy.types.Object:
    bm = bmesh.new()
    vb = [bm.verts.new((x, y, z0)) for x, y in pts]
    vt = [bm.verts.new((x, y, z1)) for x, y in pts]
    bm.faces.new(list(reversed(vb)))
    bm.faces.new(vt)
    n = len(pts)
    for i in range(n):
        j = (i + 1) % n
        bm.faces.new([vb[i], vb[j], vt[j], vt[i]])
    bmesh.ops.recalc_face_normals(bm, faces=bm.faces)
    mesh = bpy.data.meshes.new(name)
    bm.to_mesh(mesh)
    bm.free()
    obj = bpy.data.objects.new(name, mesh)
    if bevel > 0.0:
        b = obj.modifiers.new("Bevel", "BEVEL")
        b.width = bevel
        b.segments = 3
        b.limit_method = "ANGLE"
    for p in obj.data.polygons:
        p.use_smooth = True
    return obj


def add_rounded_rect_mesh(name: str, w: float, h: float, r: float, depth: float,
                          bevel: float = 0.02, segs: int = 8) -> bpy.types.Object:
    bm = bmesh.new()
    hw, hh = w * 0.5, h * 0.5
    rr = min(r, hw - 0.005, hh - 0.005)
    pts = []
    corners = [
        (hw - rr, hh - rr, 0.0),
        (-hw + rr, hh - rr, math.pi * 0.5),
        (-hw + rr, -hh + rr, math.pi),
        (hw - rr, -hh + rr, math.pi * 1.5),
    ]
    for cx, cy, start_a in corners:
        for i in range(segs + 1):
            a = start_a + (math.pi * 0.5) * (i / segs)
            pts.append((cx + math.cos(a) * rr, cy + math.sin(a) * rr))

    verts_bot = [bm.verts.new((x, y, -depth * 0.5)) for x, y in pts]
    verts_top = [bm.verts.new((x, y, depth * 0.5)) for x, y in pts]
    bm.faces.new(list(reversed(verts_bot)))
    bm.faces.new(verts_top)
    n = len(pts)
    for i in range(n):
        j = (i + 1) % n
        bm.faces.new([verts_bot[i], verts_bot[j], verts_top[j], verts_top[i]])
    bmesh.ops.recalc_face_normals(bm, faces=bm.faces)

    uv_layer = bm.loops.layers.uv.new("UVMap")
    for f in bm.faces:
        for loop in f.loops:
            v = loop.vert.co
            loop[uv_layer].uv = ((v.x + hw) / w, (v.y + hh) / h)

    mesh = bpy.data.meshes.new(name)
    bm.to_mesh(mesh)
    bm.free()

    obj = bpy.data.objects.new(name, mesh)
    bpy.context.scene.collection.objects.link(obj)
    if bevel > 0.0:
        b = obj.modifiers.new("Bevel", "BEVEL")
        b.width = bevel
        b.segments = 3
        b.limit_method = "ANGLE"
    for p in obj.data.polygons:
        p.use_smooth = True
    return obj


# ---------------------------------------------------------------------------
# Individual asset builders
# ---------------------------------------------------------------------------

def render_cabinet() -> None:
    # Covers x: 0..720 (7.20 BU), y: 90..1290 (12.00 BU); stage draws at (0, 90)
    col = reset_prop_stage(7.20, 720, 1200, shadow_plane=False, key_energy=36.0)
    cy = 0.06  # Rect2(6, 96, 708, 1176) center is (360, 684) -> +0.06 BU above (360, 690)

    # Matte-satin dark lacquered backplate (no huge mirror glare!)
    back = add_rounded_rect_mesh("CabBack", 7.02, 11.70, 0.24, 0.06, bevel=0.015)
    link_to(back, col)
    back.location = (0.0, cy, -0.18)
    back_mat = make_image_mat("CabBackMat", os.path.join(SRC_DIR, "backglass.png"),
                              roughness=0.78, coat=0.0, specular=0.10, emit_str=1.20)
    back.data.materials.append(back_mat)

    def make_ring_tube(name: str, hw: float, hh: float, rr: float, tube_r: float,
                       z: float, mat: bpy.types.Material) -> None:
        curve = bpy.data.curves.new(name, "CURVE")
        curve.dimensions = "3D"
        curve.bevel_depth = tube_r
        curve.bevel_resolution = 4
        sp = curve.splines.new("POLY")
        segs = 8
        pts = []
        for cx, cy_c, sa in [
            (hw - rr, hh - rr, 0.0),
            (-hw + rr, hh - rr, math.pi * 0.5),
            (-hw + rr, -hh + rr, math.pi),
            (hw - rr, -hh + rr, math.pi * 1.5),
        ]:
            for i in range(segs + 1):
                a = sa + (math.pi * 0.5) * (i / segs)
                pts.append((cx + math.cos(a) * rr, cy_c + math.sin(a) * rr))
        sp.points.add(len(pts) - 1)
        for i, (px, py) in enumerate(pts):
            sp.points[i].co = (px, py, 0.0, 1.0)
        sp.use_cyclic_u = True
        obj = bpy.data.objects.new(name, curve)
        link_to(obj, col)
        obj.location = (0.0, cy, z)
        obj.data.materials.append(mat)

    # Outer dark gunmetal frame + warm brass bezel edge + crisp pink/cyan neon inner pipes
    make_ring_tube("CabOuterBezel", 3.49, 5.83, 0.26, 0.075, -0.02,
                   make_pbr("GunmetalBezel", (0.20, 0.22, 0.34), metallic=0.90, roughness=0.22, coat=0.45))
    make_ring_tube("CabBrassTrim", 3.44, 5.78, 0.24, 0.015, 0.02,
                   make_pbr("CabBrassTrimMat", (0.88, 0.66, 0.24), metallic=0.95, roughness=0.20))
    make_ring_tube("CabNeonPink", 3.38, 5.72, 0.22, 0.020, -0.04,
                   make_pbr("CabNeonMat", (1.0, 0.16, 0.56), roughness=0.2,
                            emission=(1.0, 0.16, 0.56), emit_str=2.6))
    make_ring_tube("CabNeonCyan", 3.31, 5.65, 0.20, 0.014, -0.07,
                   make_pbr("CabCyanMat", (0.08, 0.86, 1.0), roughness=0.2,
                            emission=(0.08, 0.86, 1.0), emit_str=1.8))

    render_to("cabinet.png")


def render_balls_and_pins() -> None:
    # Chrome ball uses extra wrap-around studio rim bounce so the whole sphere reads gleaming steel.
    for fname, color, metal, rough, emit, extra_rim in [
        ("ball_chrome.png", (0.94, 0.96, 1.0), 0.96, 0.08, ((0.62, 0.70, 0.84), 0.28), True),
        ("ball_gold.png", (1.0, 0.78, 0.22), 0.96, 0.08, ((1.0, 0.72, 0.16), 0.22), False),
    ]:
        col = reset_prop_stage(0.24, 48, 48, shadow_plane=False, key_energy=82.0 if extra_rim else 68.0)
        if extra_rim:
            # Lower-hemisphere silver fill card so the bottom half of the chrome sphere stays bright steel.
            ld = bpy.data.lights.new("LowerBounce", type="AREA")
            ld.energy = 28.0
            ld.size = 3.2
            ld.color = (0.78, 0.86, 1.0)
            lo = bpy.data.objects.new("LowerBounce", ld)
            lo.location = (0.0, -2.4, 2.2)
            lo.rotation_euler = (math.radians(48.0), 0.0, 0.0)
            col.objects.link(lo)
        bpy.ops.mesh.primitive_uv_sphere_add(segments=48, ring_count=32, radius=0.070, location=(0, 0, 0))
        sp = link_to(bpy.context.active_object, col)
        for p in sp.data.polygons:
            p.use_smooth = True
        sp.data.materials.append(make_pbr(fname, color, metallic=metal, roughness=rough,
                                          coat=0.5, emission=emit[0], emit_str=emit[1]))
        render_to(fname)

    col = reset_prop_stage(0.24, 48, 48, shadow_plane=True, shadow_z=-0.09)
    bpy.ops.mesh.primitive_uv_sphere_add(segments=32, ring_count=20, radius=0.068, location=(0, 0, 0.02))
    sp = link_to(bpy.context.active_object, col)
    sp.visible_camera = False
    sp.data.materials.append(make_pbr("ShadowSphere", (0.5, 0.5, 0.5)))
    render_to("ball_shadow.png")

    col = reset_prop_stage(0.18, 36, 36, shadow_plane=True, shadow_z=-0.06)
    bpy.ops.mesh.primitive_uv_sphere_add(segments=36, ring_count=20, radius=0.044, location=(0, 0, 0))
    head = link_to(bpy.context.active_object, col)
    head.scale = (1.0, 1.0, 0.65)
    for p in head.data.polygons:
        p.use_smooth = True
    head.data.materials.append(make_pbr("BrassPin", (0.98, 0.76, 0.28), metallic=0.94, roughness=0.18,
                                        coat=0.35, emission=(0.95, 0.72, 0.24), emit_str=0.08))
    bpy.ops.mesh.primitive_cylinder_add(vertices=24, radius=0.018, depth=0.06, location=(0, 0, -0.03))
    stem = link_to(bpy.context.active_object, col)
    stem.data.materials.append(make_pbr("BrassStem", (0.60, 0.40, 0.12), metallic=0.92, roughness=0.35))
    render_to("pin_brass.png")


def render_windmills_and_rails() -> None:
    col = reset_prop_stage(0.40, 80, 80, shadow_plane=False)
    blade_mat = make_acrylic_mat("VioletBlade", (0.52, 0.14, 1.0), center_opacity=0.78,
                                 body_emit=0.55, edge_emit=1.4)
    for i in range(4):
        ang = i * math.pi * 0.5
        b = add_rounded_rect_mesh(f"Blade{i}", 0.064, 0.142, 0.024, 0.024, bevel=0.008, segs=5)
        link_to(b, col)
        b.location = (math.cos(ang) * 0.088, math.sin(ang) * 0.088, 0.0)
        b.rotation_euler = (0.0, 0.18, ang - math.pi * 0.5)
        b.data.materials.append(blade_mat)
    render_to("windmill_blades.png")

    col = reset_prop_stage(0.16, 32, 32, shadow_plane=True, shadow_z=-0.05)
    bpy.ops.mesh.primitive_uv_sphere_add(segments=32, ring_count=16, radius=0.052, location=(0, 0, 0))
    hub = link_to(bpy.context.active_object, col)
    hub.scale = (1.0, 1.0, 0.55)
    for p in hub.data.polygons:
        p.use_smooth = True
    hub.data.materials.append(make_pbr("HubBrass", (0.94, 0.72, 0.26), metallic=0.96, roughness=0.18))
    render_to("windmill_hub.png")

    col = reset_prop_stage(0.64, 64, 32, shadow_plane=True, shadow_z=-0.06)
    bpy.ops.mesh.primitive_cylinder_add(vertices=28, radius=0.035, depth=0.80, location=(0, 0, 0),
                                        rotation=(0, math.pi * 0.5, 0))
    rod = link_to(bpy.context.active_object, col)
    for p in rod.data.polygons:
        p.use_smooth = True
    rod.data.materials.append(make_pbr("RailBrass", (0.88, 0.65, 0.22), metallic=0.95, roughness=0.22, coat=0.3))
    render_to("rail_brass_seg.png")

    col = reset_prop_stage(0.32, 32, 32, shadow_plane=True, shadow_z=-0.06)
    bpy.ops.mesh.primitive_uv_sphere_add(segments=28, ring_count=16, radius=0.036, location=(0, 0, 0))
    cap = link_to(bpy.context.active_object, col)
    for p in cap.data.polygons:
        p.use_smooth = True
    cap.data.materials.append(make_pbr("RailCapBrass", (0.88, 0.65, 0.22), metallic=0.95, roughness=0.22, coat=0.3))
    render_to("rail_brass_cap.png")


def render_cards() -> None:
    for tag, src_name in [("red", "card_red.png"), ("gold", "card_gold.png")]:
        col = reset_prop_stage(0.48, 96, 120, shadow_plane=True, shadow_z=-0.09)
        card = add_rounded_rect_mesh(f"Card_{tag}", 0.28, 0.373, 0.028, 0.032, bevel=0.008, segs=6)
        link_to(card, col)
        card.rotation_euler = (math.radians(8.0), 0.0, 0.0)
        tex_mat = make_image_mat(f"CardTex_{tag}", os.path.join(SRC_DIR, src_name),
                                 roughness=0.26, coat=0.45,
                                 metallic=0.35 if tag == "gold" else 0.0,
                                 emit_str=0.22 if tag == "gold" else 0.36)
        edge_mat = make_pbr(f"CardEdge_{tag}",
                            (0.95, 0.74, 0.24) if tag == "gold" else (0.86, 0.14, 0.22),
                            metallic=0.6 if tag == "gold" else 0.1, roughness=0.25, coat=0.5)
        card.data.materials.append(edge_mat)
        card.data.materials.append(tex_mat)
        for poly in card.data.polygons:
            poly.material_index = 1 if poly.normal.z > 0.7 else 0
        render_to(f"card_{tag}.png")

        col = reset_prop_stage(0.18, 36, 36, shadow_plane=True, shadow_z=-0.05)
        bpy.ops.mesh.primitive_cylinder_add(vertices=20, radius=0.014, depth=0.064, location=(0.024, 0, 0),
                                            rotation=(0, math.pi * 0.5, 0))
        arm = link_to(bpy.context.active_object, col)
        b = arm.modifiers.new("Bevel", "BEVEL")
        b.width = 0.008
        b.segments = 3
        for p in arm.data.polygons:
            p.use_smooth = True
        arm.data.materials.append(edge_mat)
        bpy.ops.mesh.primitive_uv_sphere_add(segments=16, ring_count=12, radius=0.018, location=(0.056, 0, 0))
        hand = link_to(bpy.context.active_object, col)
        for p in hand.data.polygons:
            p.use_smooth = True
        hand.data.materials.append(edge_mat)
        render_to(f"card_arm_{tag}.png")


def render_dice() -> None:
    for tag, base_col, metal in [("ivory", (0.82, 0.76, 0.64), 0.0), ("gold", (0.96, 0.74, 0.22), 0.78)]:
        for cracked in (False, True):
            col = reset_prop_stage(0.48, 96, 96, shadow_plane=True, shadow_z=-0.16)
            die = add_rounded_rect_mesh(f"Die_{tag}", 0.30, 0.29, 0.045, 0.26, bevel=0.026, segs=6)
            link_to(die, col)
            body_mat = make_pbr(f"DieMat_{tag}", base_col, metallic=metal, roughness=0.28, coat=0.55)
            die.data.materials.append(body_mat)

            ink_mat = make_pbr("DieInk", (0.04, 0.03, 0.10), roughness=0.18, coat=0.6)
            white_mat = make_pbr("DieEyeWhite", (1.0, 1.0, 1.0), roughness=0.14, coat=0.6,
                                 emission=(1.0, 1.0, 1.0), emit_str=0.45)

            parent_empty = bpy.data.objects.new("DieRoot", None)
            link_to(parent_empty, col)
            parent_empty.rotation_euler = (math.radians(10.0), 0.0, 0.0)
            die.parent = parent_empty

            for sx in (-0.068, 0.068):
                # Dark socket ring so eyes stand out sharply against warm ivory/gold
                bpy.ops.mesh.primitive_uv_sphere_add(segments=24, ring_count=16, radius=0.042,
                                                     location=(sx, 0.036, 0.132))
                ring = link_to(bpy.context.active_object, col)
                ring.scale = (1.0, 1.0, 0.35)
                for p in ring.data.polygons:
                    p.use_smooth = True
                ring.data.materials.append(ink_mat)
                ring.parent = parent_empty

                bpy.ops.mesh.primitive_uv_sphere_add(segments=24, ring_count=16, radius=0.034,
                                                     location=(sx, 0.036, 0.140))
                eyeball = link_to(bpy.context.active_object, col)
                eyeball.scale = (1.0, 1.0, 0.45)
                for p in eyeball.data.polygons:
                    p.use_smooth = True
                eyeball.data.materials.append(white_mat)
                eyeball.parent = parent_empty

                bpy.ops.mesh.primitive_uv_sphere_add(segments=20, ring_count=14, radius=0.020,
                                                     location=(sx, 0.026, 0.150))
                pupil = link_to(bpy.context.active_object, col)
                pupil.scale = (1.0, 1.0, 0.5)
                for p in pupil.data.polygons:
                    p.use_smooth = True
                pupil.data.materials.append(ink_mat)
                pupil.parent = parent_empty

            for i in range(3):
                px = -0.062 + i * 0.062
                py = -0.066 - (0.015 if i == 1 else 0.0)
                bpy.ops.mesh.primitive_uv_sphere_add(segments=20, ring_count=12, radius=0.021,
                                                     location=(px, py, 0.140))
                pip = link_to(bpy.context.active_object, col)
                pip.scale = (1.0, 1.0, 0.35)
                for p in pip.data.polygons:
                    p.use_smooth = True
                pip.data.materials.append(ink_mat)
                pip.parent = parent_empty

            if cracked:
                crack_curve = bpy.data.curves.new("Crack", "CURVE")
                crack_curve.dimensions = "3D"
                crack_curve.bevel_depth = 0.010
                crack_curve.bevel_resolution = 2
                csp = crack_curve.splines.new("POLY")
                cpts = [
                    (0.118, 0.145, 0.145),
                    (0.088, 0.085, 0.154),
                    (0.122, 0.032, 0.154),
                    (0.082, -0.028, 0.150),
                ]
                csp.points.add(len(cpts) - 1)
                for i, pt in enumerate(cpts):
                    csp.points[i].co = (*pt, 1.0)
                crack_obj = bpy.data.objects.new("CrackObj", crack_curve)
                link_to(crack_obj, col)
                crack_obj.data.materials.append(ink_mat)
                crack_obj.parent = parent_empty

            suffix = "_cracked" if cracked else ""
            render_to(f"die_{tag}{suffix}.png")

        col = reset_prop_stage(0.16, 32, 32, shadow_plane=True, shadow_z=-0.05)
        foot = add_rounded_rect_mesh(f"DieFoot_{tag}", 0.072, 0.052, 0.016, 0.048, bevel=0.012, segs=4)
        link_to(foot, col)
        foot.data.materials.append(make_pbr(f"DieFootMat_{tag}",
                                            tuple(c * 0.58 for c in base_col),
                                            metallic=metal, roughness=0.35))
        render_to(f"die_foot_{tag}.png")


def render_chips() -> None:
    chip_defs = [
        ("red", (0.78, 0.08, 0.16), 0.0),
        ("blue", (0.08, 0.36, 0.88), 0.0),
        ("green", (0.06, 0.56, 0.28), 0.0),
        ("gold", (0.94, 0.68, 0.14), 0.85),
    ]
    for tag, col_rgb, metal in chip_defs:
        col = reset_prop_stage(0.48, 96, 96, shadow_plane=True, shadow_z=-0.09)
        root = bpy.data.objects.new("ChipRoot", None)
        link_to(root, col)
        root.rotation_euler = (math.radians(12.0), 0.0, 0.0)

        chip_mat = make_pbr(f"ChipMat_{tag}", col_rgb, metallic=metal, roughness=0.32, coat=0.4)
        dish_mat = make_pbr(f"ChipDish_{tag}", tuple(c * 0.62 for c in col_rgb), metallic=metal, roughness=0.40, coat=0.3)
        cream_mat = make_pbr("ChipCream", (0.92, 0.88, 0.82), roughness=0.28, coat=0.4)

        bpy.ops.mesh.primitive_cylinder_add(vertices=48, radius=0.162, depth=0.056, location=(0, 0, 0))
        disc = link_to(bpy.context.active_object, col)
        b = disc.modifiers.new("Bevel", "BEVEL")
        b.width = 0.012
        b.segments = 3
        for p in disc.data.polygons:
            p.use_smooth = True
        disc.data.materials.append(chip_mat)
        disc.parent = root

        bpy.ops.mesh.primitive_cylinder_add(vertices=40, radius=0.102, depth=0.014, location=(0, 0, 0.025))
        dish = link_to(bpy.context.active_object, col)
        for p in dish.data.polygons:
            p.use_smooth = True
        dish.data.materials.append(dish_mat)
        dish.parent = root

        bpy.ops.mesh.primitive_torus_add(major_segments=48, minor_segments=12,
                                         major_radius=0.103, minor_radius=0.008, location=(0, 0, 0.030))
        ring = link_to(bpy.context.active_object, col)
        for p in ring.data.polygons:
            p.use_smooth = True
        ring.data.materials.append(cream_mat)
        ring.parent = root

        for i in range(8):
            ang = i * math.tau / 8.0
            stripe = add_rounded_rect_mesh(f"Stripe_{i}", 0.034, 0.044, 0.006, 0.060, bevel=0.004, segs=3)
            link_to(stripe, col)
            stripe.location = (math.cos(ang) * 0.136, math.sin(ang) * 0.136, 0.002)
            stripe.rotation_euler = (0.0, 0.0, ang - math.pi * 0.5)
            stripe.data.materials.append(cream_mat)
            stripe.parent = root

        render_to(f"chip_{tag}.png")

    col = reset_prop_stage(0.14, 28, 28, shadow_plane=False)
    bpy.ops.mesh.primitive_uv_sphere_add(segments=24, ring_count=16, radius=0.034, location=(0, 0, 0))
    eye = link_to(bpy.context.active_object, col)
    eye.scale = (1.0, 1.0, 0.6)
    for p in eye.data.polygons:
        p.use_smooth = True
    eye.data.materials.append(make_pbr("ChipEyeW", (1.0, 1.0, 1.0), roughness=0.14, coat=0.6,
                                       emission=(1.0, 1.0, 1.0), emit_str=0.45))
    render_to("chip_eye_white.png")

    col = reset_prop_stage(0.14, 28, 28, shadow_plane=True, shadow_z=-0.04)
    bpy.ops.mesh.primitive_uv_sphere_add(segments=20, ring_count=12, radius=0.028, location=(0, 0, 0))
    cfoot = link_to(bpy.context.active_object, col)
    cfoot.scale = (0.85, 1.25, 0.55)
    for p in cfoot.data.polygons:
        p.use_smooth = True
    cfoot.data.materials.append(make_pbr("ChipFoot", (0.12, 0.10, 0.20), roughness=0.38, coat=0.3))
    render_to("chip_foot.png")


def render_shards() -> None:
    shard_defs = [
        ("red", (0.82, 0.08, 0.16), 0.0),
        ("blue", (0.08, 0.36, 0.90), 0.0),
        ("green", (0.06, 0.60, 0.30), 0.0),
        ("ivory", (0.84, 0.78, 0.66), 0.0),
        ("gold", (0.96, 0.72, 0.18), 0.85),
    ]
    for tag, rgb, metal in shard_defs:
        col = reset_prop_stage(0.24, 48, 48, shadow_plane=False)
        obj = extrude_2d_poly(f"Shard_{tag}",
                              [(-0.055, -0.02), (0.04, -0.05), (0.06, 0.025), (-0.015, 0.055)],
                              -0.016, 0.016, bevel=0.006)
        link_to(obj, col)
        obj.rotation_euler = (math.radians(32), math.radians(-24), math.radians(15))
        obj.data.materials.append(make_pbr(f"ShardMat_{tag}", rgb, metallic=metal, roughness=0.28, coat=0.45))
        render_to(f"shard_{tag}.png")


def _build_u_cup(name: str, half_w: float, depth_h: float, wall_t: float, z_ext: float,
                 front_only: bool) -> bpy.types.Object:
    bm = bmesh.new()
    segs = 20
    outer_pts = []
    inner_pts = []
    for i in range(segs + 1):
        t = i / segs
        ang = math.pi + t * math.pi
        ox = math.cos(ang) * (half_w + wall_t)
        oy = math.sin(ang) * depth_h
        ix = math.cos(ang) * half_w
        iy = math.sin(ang) * max(depth_h - wall_t, 0.04)
        outer_pts.append((ox, oy))
        inner_pts.append((ix, iy))

    if not front_only:
        vf_o = [bm.verts.new((x, y, 0.0)) for x, y in outer_pts]
        vb_o = [bm.verts.new((x, y, -z_ext)) for x, y in outer_pts]
        chute_f = [bm.verts.new((x, y, -0.02)) for x, y in inner_pts]
        bm.faces.new(chute_f)
        for i in range(len(outer_pts) - 1):
            bm.faces.new([vb_o[i], vb_o[i + 1], vf_o[i + 1], vf_o[i]])
    else:
        vi0 = [bm.verts.new((x, y, 0.0)) for x, y in inner_pts]
        vo0 = [bm.verts.new((x, y, 0.0)) for x, y in outer_pts]
        vi1 = [bm.verts.new((x, y, z_ext)) for x, y in inner_pts]
        vo1 = [bm.verts.new((x, y, z_ext)) for x, y in outer_pts]
        for i in range(len(outer_pts) - 1):
            bm.faces.new([vi1[i], vo1[i], vo1[i + 1], vi1[i + 1]])
            bm.faces.new([vi0[i], vi1[i], vi1[i + 1], vi0[i + 1]])
            bm.faces.new([vo0[i], vo0[i + 1], vo1[i + 1], vo1[i]])
        bm.faces.new([vi0[0], vo0[0], vo1[0], vi1[0]])
        bm.faces.new([vi1[-1], vo1[-1], vo0[-1], vi0[-1]])

    bmesh.ops.recalc_face_normals(bm, faces=bm.faces)
    mesh = bpy.data.meshes.new(name)
    bm.to_mesh(mesh)
    bm.free()
    obj = bpy.data.objects.new(name, mesh)
    b = obj.modifiers.new("Bevel", "BEVEL")
    b.width = 0.012
    b.segments = 3
    for p in obj.data.polygons:
        p.use_smooth = True
    return obj


def _u_cavity_mesh(name: str, half_w: float, depth_h: float, z0: float, z1: float) -> bpy.types.Object:
    """Solid U-shaped pocket cavity (for dark back recess or translucent front acrylic shield)."""
    segs = 20
    pts = []
    for i in range(segs + 1):
        ang = math.pi + (i / segs) * math.pi
        pts.append((math.cos(ang) * half_w, math.sin(ang) * depth_h))
    return extrude_2d_poly(name, pts, z0, z1, bevel=0.008)


def render_pockets() -> None:
    for tag, half_bu, rgb in [
        ("side", 0.145, (0.04, 0.85, 1.0)),
        ("start", 0.125, (0.10, 0.98, 0.45)),
    ]:
        # Back: dark recessed cavity + glowing rim so falling balls stay high-contrast inside
        col = reset_prop_stage(0.64, 128, 112, shadow_plane=True, shadow_z=-0.16)
        root = bpy.data.objects.new("PkRoot", None)
        link_to(root, col)
        root.rotation_euler = (math.radians(12.0), 0.0, 0.0)

        chute = _u_cavity_mesh(f"{tag}_chute", half_bu + 0.015, 0.21, -0.09, -0.02)
        link_to(chute, col)
        chute.data.materials.append(make_pbr(f"{tag}_dark", (0.012, 0.010, 0.025), roughness=0.65,
                                             emission=tuple(c * 0.12 for c in rgb), emit_str=0.25))
        chute.parent = root

        back_rim = _build_u_cup(f"{tag}_back", half_bu, 0.21, 0.048, 0.08, False)
        link_to(back_rim, col)
        back_rim.data.materials.append(make_pbr(f"{tag}_back_mat", tuple(c * 0.35 for c in rgb),
                                                metallic=0.35, roughness=0.25, emission=rgb, emit_str=0.55))
        back_rim.parent = root
        render_to(f"pocket_{tag}_back.png")

        # Front: translucent colored acrylic shield + bright U-rim lip drawn OVER falling balls
        col = reset_prop_stage(0.64, 128, 112, shadow_plane=False)
        root = bpy.data.objects.new("PkFrontRoot", None)
        link_to(root, col)
        root.rotation_euler = (math.radians(12.0), 0.0, 0.0)

        shield = _u_cavity_mesh(f"{tag}_shield", half_bu + 0.005, 0.20, 0.01, 0.04)
        link_to(shield, col)
        shield.data.materials.append(make_acrylic_mat(f"{tag}_shield_mat", rgb, center_opacity=0.26,
                                                      body_emit=0.45, edge_emit=1.2))
        shield.parent = root

        front_cup = _build_u_cup(f"{tag}_front", half_bu, 0.215, 0.056, 0.12, True)
        link_to(front_cup, col)
        front_cup.data.materials.append(make_acrylic_mat(f"{tag}_acrylic", rgb, center_opacity=0.68,
                                                         body_emit=0.85, edge_emit=2.2))
        front_cup.parent = root
        render_to(f"pocket_{tag}_front.png")

    pink = (1.0, 0.14, 0.56)
    col = reset_prop_stage(0.72, 144, 112, shadow_plane=True, shadow_z=-0.16)
    root = bpy.data.objects.new("TulipRoot", None)
    link_to(root, col)
    root.rotation_euler = (math.radians(12.0), 0.0, 0.0)
    chute = _u_cavity_mesh("tulip_chute", 0.155, 0.185, -0.09, -0.02)
    link_to(chute, col)
    chute.data.materials.append(make_pbr("tulip_dark", (0.015, 0.008, 0.03), roughness=0.6,
                                         emission=(0.24, 0.03, 0.12), emit_str=0.25))
    chute.parent = root
    back_rim = _build_u_cup("tulip_back", 0.14, 0.18, 0.048, 0.08, False)
    link_to(back_rim, col)
    back_rim.data.materials.append(make_pbr("tulip_back_mat", (0.40, 0.08, 0.26), roughness=0.25,
                                            emission=pink, emit_str=0.55))
    back_rim.parent = root
    render_to("pocket_tulip_back.png")

    col = reset_prop_stage(0.72, 144, 112, shadow_plane=False)
    root = bpy.data.objects.new("TulipFrontRoot", None)
    link_to(root, col)
    root.rotation_euler = (math.radians(12.0), 0.0, 0.0)
    t_shield = _u_cavity_mesh("tulip_shield", 0.145, 0.18, 0.01, 0.04)
    link_to(t_shield, col)
    t_shield.data.materials.append(make_acrylic_mat("tulip_shield_mat", pink, center_opacity=0.26,
                                                    body_emit=0.45, edge_emit=1.2))
    t_shield.parent = root
    front_cup = _build_u_cup("tulip_front", 0.14, 0.185, 0.056, 0.12, True)
    link_to(front_cup, col)
    front_cup.data.materials.append(make_acrylic_mat("tulip_acrylic", pink, center_opacity=0.68,
                                                     body_emit=0.85, edge_emit=2.2))
    front_cup.parent = root
    render_to("pocket_tulip_front.png")

    for side in (-1, 1):
        col = reset_prop_stage(0.48, 96, 96, shadow_plane=False)
        pts = [
            (0.0, -0.015),
            (side * 0.048, 0.025),
            (side * 0.078, 0.145),
            (side * 0.036, 0.215),
            (-side * 0.014, 0.145),
            (-side * 0.020, 0.015),
        ]
        petal = extrude_2d_poly(f"Petal_{side}", pts, -0.02, 0.04, bevel=0.010)
        link_to(petal, col)
        petal.data.materials.append(make_acrylic_mat(f"PetalAcrylic_{side}", pink, center_opacity=0.78,
                                                     body_emit=0.62, edge_emit=1.6))
        render_to("tulip_petal_left.png" if side < 0 else "tulip_petal_right.png")

    gold = (1.0, 0.72, 0.14)
    col = reset_prop_stage(1.80, 360, 88, shadow_plane=True, shadow_z=-0.10)
    bar = add_rounded_rect_mesh("AttackerShut", 1.48, 0.20, 0.04, 0.08, bevel=0.018, segs=4)
    link_to(bar, col)
    bar.rotation_euler = (math.radians(8.0), 0.0, 0.0)
    bar.data.materials.append(make_pbr("AttackerGold", (0.78, 0.56, 0.16), metallic=0.92, roughness=0.25, coat=0.4))
    lid = add_rounded_rect_mesh("AttackerLid", 1.42, 0.05, 0.02, 0.05, bevel=0.01, segs=3)
    link_to(lid, col)
    lid.location = (0.0, 0.075, 0.04)
    lid.data.materials.append(make_pbr("AttackerLidMat", (0.24, 0.16, 0.05), metallic=0.85, roughness=0.35))
    render_to("attacker_shut.png")

    col = reset_prop_stage(1.80, 360, 104, shadow_plane=True, shadow_z=-0.14)
    trough_b = add_rounded_rect_mesh("AttackerBack", 1.52, 0.24, 0.04, 0.08, bevel=0.015, segs=4)
    link_to(trough_b, col)
    trough_b.location = (0.0, -0.04, -0.06)
    trough_b.data.materials.append(make_pbr("AttackerTroughDark", (0.03, 0.02, 0.01), roughness=0.5,
                                            emission=(0.45, 0.28, 0.04), emit_str=0.8))
    for s in (-1, 1):
        w = add_rounded_rect_mesh(f"AttWing_{s}", 0.055, 0.24, 0.018, 0.06, bevel=0.01, segs=3)
        link_to(w, col)
        w.location = (s * 0.77, 0.08, 0.02)
        w.rotation_euler = (0.0, 0.0, -s * math.radians(18.0))
        w.data.materials.append(make_pbr("AttWingGold", gold, metallic=0.94, roughness=0.20,
                                         emission=gold, emit_str=0.8))
    render_to("attacker_open_back.png")

    col = reset_prop_stage(1.80, 360, 104, shadow_plane=False)
    front_bar = add_rounded_rect_mesh("AttackerFrontLip", 1.48, 0.16, 0.035, 0.09, bevel=0.018, segs=4)
    link_to(front_bar, col)
    front_bar.location = (0.0, -0.07, 0.05)
    front_bar.rotation_euler = (math.radians(10.0), 0.0, 0.0)
    front_bar.data.materials.append(make_acrylic_mat("AttackerFrontAcrylic", gold, center_opacity=0.42,
                                                     body_emit=1.4, edge_emit=3.2))
    render_to("attacker_open_front.png")


def render_reels() -> None:
    col = reset_prop_stage(2.60, 520, 128, shadow_plane=True, shadow_z=-0.10)
    pts = [(-1.14, -0.18), (0.0, 0.22), (1.14, -0.18), (1.06, -0.25), (0.0, 0.11), (-1.06, -0.25)]
    roof = extrude_2d_poly("ReelRoof", pts, -0.05, 0.06, bevel=0.018)
    link_to(roof, col)
    roof.data.materials.append(make_pbr("RoofBrass", (0.86, 0.64, 0.22), metallic=0.92, roughness=0.22, coat=0.35))
    render_to("reel_roof.png")

    # Three curved 3D cylindrical drums with clear vertical curvature shading
    col = reset_prop_stage(2.20, 440, 192, shadow_plane=False, key_energy=54.0)
    drum_mat = make_pbr("DrumIvory", (0.76, 0.74, 0.71), roughness=0.42, coat=0.35)
    for i in range(3):
        x = (i - 1) * 0.72
        bpy.ops.mesh.primitive_cylinder_add(vertices=48, radius=0.46, depth=0.66,
                                            location=(x, 0.0, -0.10), rotation=(0.0, math.pi * 0.5, 0.0))
        d = link_to(bpy.context.active_object, col)
        for p in d.data.polygons:
            p.use_smooth = True
        d.data.materials.append(drum_mat)
    render_to("reel_drums.png")

    col = reset_prop_stage(2.56, 512, 256, shadow_plane=False)
    bm = bmesh.new()
    iw, ih = 2.14 * 0.5, 0.90 * 0.5
    ow, oh = 2.34 * 0.5, 1.08 * 0.5
    outer_ring = [(-ow, -oh), (ow, -oh), (ow, oh), (-ow, oh)]
    inner_ring = [(-iw, -ih), (iw, -ih), (iw, ih), (-iw, ih)]
    vo0 = [bm.verts.new((x, y, -0.05)) for x, y in outer_ring]
    vi0 = [bm.verts.new((x, y, -0.05)) for x, y in inner_ring]
    vo1 = [bm.verts.new((x, y, 0.07)) for x, y in outer_ring]
    vi1 = [bm.verts.new((x, y, 0.07)) for x, y in inner_ring]
    for i in range(4):
        j = (i + 1) % 4
        bm.faces.new([vi1[i], vo1[i], vo1[j], vi1[j]])
        bm.faces.new([vi0[i], vi1[i], vi1[j], vi0[j]])
        bm.faces.new([vo0[i], vo0[j], vo1[j], vo1[i]])
        bm.faces.new([vo0[i], vi0[i], vi0[j], vo0[j]])
    bmesh.ops.recalc_face_normals(bm, faces=bm.faces)
    mesh = bpy.data.meshes.new("ReelBezel")
    bm.to_mesh(mesh)
    bm.free()
    bezel = bpy.data.objects.new("ReelBezel", mesh)
    link_to(bezel, col)
    b = bezel.modifiers.new("Bevel", "BEVEL")
    b.width = 0.024
    b.segments = 4
    for p in bezel.data.polygons:
        p.use_smooth = True
    bezel.data.materials.append(make_pbr("BezelChrome", (0.58, 0.62, 0.72), metallic=0.92, roughness=0.22, coat=0.4))

    for dx in (-0.36, 0.36):
        div = add_rounded_rect_mesh(f"Div_{dx}", 0.022, 0.90, 0.005, 0.06, bevel=0.004, segs=2)
        link_to(div, col)
        div.location = (dx, 0.0, 0.03)
        div.data.materials.append(make_pbr("DivMat", (0.28, 0.30, 0.38), metallic=0.88, roughness=0.25))

    glass = add_rounded_rect_mesh("ReelGlass", 2.12, 0.88, 0.02, 0.008, bevel=0.0, segs=3)
    link_to(glass, col)
    glass.location = (0.0, 0.0, 0.05)
    glass.data.materials.append(make_glass_sheen_mat("ReelGlassMat", (0.85, 0.92, 1.0), alpha=0.06))

    arrow_mat = make_pbr("PayArrow", (1.0, 0.22, 0.56), metallic=0.2, roughness=0.18,
                         emission=(1.0, 0.22, 0.56), emit_str=2.0)
    for side in (-1, 1):
        ao = extrude_2d_poly(f"Arrow_{side}",
                             [(side * 1.07, 0.0), (side * 1.21, 0.075), (side * 1.21, -0.075)],
                             0.0, 0.08, bevel=0.008)
        link_to(ao, col)
        ao.data.materials.append(arrow_mat)

    render_to("reel_frame.png")


def render_ship_and_saucer() -> None:
    col = reset_prop_stage(0.90, 180, 104, shadow_plane=True, shadow_z=-0.10)
    root = bpy.data.objects.new("ShipRoot", None)
    link_to(root, col)
    root.rotation_euler = (math.radians(10.0), 0.0, 0.0)

    hull_mat = make_pbr("ShipHull", (0.20, 0.24, 0.38), metallic=0.88, roughness=0.24, coat=0.4)
    trim_mat = make_pbr("ShipCyan", (0.12, 0.86, 1.0), metallic=0.25, roughness=0.15,
                        emission=(0.12, 0.86, 1.0), emit_str=2.2)

    hull = extrude_2d_poly("ShipHull",
                           [(-0.34, -0.10), (-0.26, 0.05), (0.26, 0.05), (0.34, -0.10), (0.18, -0.15), (-0.18, -0.15)],
                           -0.05, 0.05, bevel=0.015)
    link_to(hull, col)
    hull.data.materials.append(hull_mat)
    hull.parent = root

    for s in (-1, 1):
        pod = add_rounded_rect_mesh(f"Pod_{s}", 0.09, 0.16, 0.03, 0.08, bevel=0.012, segs=4)
        link_to(pod, col)
        pod.location = (s * 0.29, -0.04, 0.02)
        pod.data.materials.append(trim_mat)
        pod.parent = root

        bpy.ops.mesh.primitive_uv_sphere_add(segments=16, ring_count=12, radius=0.024,
                                             location=(s * 0.18, -0.06, 0.055))
        lamp = link_to(bpy.context.active_object, col)
        lamp.data.materials.append(trim_mat)
        lamp.parent = root

    render_to("ship_hull.png")

    col = reset_prop_stage(0.20, 40, 72, shadow_plane=False)
    bpy.ops.mesh.primitive_cylinder_add(vertices=28, radius=0.036, depth=0.22, location=(0, 0, 0),
                                        rotation=(math.pi * 0.5, 0, 0))
    barrel = link_to(bpy.context.active_object, col)
    for p in barrel.data.polygons:
        p.use_smooth = True
    barrel.data.materials.append(make_pbr("BarrelSilver", (0.72, 0.76, 0.85), metallic=0.95, roughness=0.20))
    bpy.ops.mesh.primitive_cylinder_add(vertices=28, radius=0.040, depth=0.042, location=(0, 0.095, 0),
                                        rotation=(math.pi * 0.5, 0, 0))
    tip = link_to(bpy.context.active_object, col)
    tip.data.materials.append(make_pbr("BarrelTip", (0.12, 0.88, 1.0), metallic=0.4, roughness=0.15,
                                       emission=(0.12, 0.88, 1.0), emit_str=2.4))
    render_to("ship_barrel.png")

    gold_rgb = (1.0, 0.74, 0.18)
    col = reset_prop_stage(0.80, 160, 64, shadow_plane=True, shadow_z=-0.09)
    root = bpy.data.objects.new("CupBackRoot", None)
    link_to(root, col)
    root.rotation_euler = (math.radians(14.0), 0.0, 0.0)
    cup_dark = add_rounded_rect_mesh("CupDark", 0.60, 0.11, 0.03, 0.05, bevel=0.008, segs=4)
    link_to(cup_dark, col)
    cup_dark.location = (0, -0.02, -0.03)
    cup_dark.data.materials.append(make_pbr("CupDarkGold", (0.22, 0.14, 0.03), metallic=0.88, roughness=0.38))
    cup_dark.parent = root
    cup_back = _build_u_cup("CupBackWall", 0.30, 0.12, 0.028, 0.06, False)
    link_to(cup_back, col)
    cup_back.location = (0, 0.04, 0.0)
    cup_back.data.materials.append(make_pbr("CupGoldRim", gold_rgb, metallic=0.95, roughness=0.18, coat=0.3))
    cup_back.parent = root
    render_to("ship_cup_back.png")

    col = reset_prop_stage(0.80, 160, 64, shadow_plane=False)
    root = bpy.data.objects.new("CupFrontRoot", None)
    link_to(root, col)
    root.rotation_euler = (math.radians(14.0), 0.0, 0.0)
    cup_front = _build_u_cup("CupFrontWall", 0.30, 0.125, 0.030, 0.08, True)
    link_to(cup_front, col)
    cup_front.location = (0, 0.04, 0.0)
    cup_front.data.materials.append(make_pbr("CupGoldFront", gold_rgb, metallic=0.95, roughness=0.18, coat=0.4,
                                             emission=(0.95, 0.65, 0.12), emit_str=0.45))
    cup_front.parent = root
    render_to("ship_cup_front.png")

    col = reset_prop_stage(0.80, 160, 88, shadow_plane=True, shadow_z=-0.12)
    root = bpy.data.objects.new("SaucerRoot", None)
    link_to(root, col)
    root.rotation_euler = (math.radians(18.0), 0.0, 0.0)

    bpy.ops.mesh.primitive_uv_sphere_add(segments=48, ring_count=20, radius=0.31, location=(0, 0, 0))
    body = link_to(bpy.context.active_object, col)
    body.scale = (1.0, 0.48, 0.30)
    for p in body.data.polygons:
        p.use_smooth = True
    body.data.materials.append(make_pbr("SaucerViolet", (0.38, 0.14, 0.68), metallic=0.75, roughness=0.22, coat=0.5))
    body.parent = root

    bpy.ops.mesh.primitive_torus_add(major_segments=48, minor_segments=12,
                                     major_radius=0.31, minor_radius=0.016, location=(0, 0, 0.0))
    rim = link_to(bpy.context.active_object, col)
    rim.scale = (1.0, 0.48, 1.0)
    for p in rim.data.polygons:
        p.use_smooth = True
    rim.data.materials.append(make_pbr("SaucerGold", gold_rgb, metallic=0.95, roughness=0.18))
    rim.parent = root

    visor = add_rounded_rect_mesh("Visor", 0.24, 0.08, 0.02, 0.08, bevel=0.012, segs=4)
    link_to(visor, col)
    visor.location = (0.0, 0.02, 0.05)
    visor.data.materials.append(make_acrylic_mat("CroupierVisor", (0.14, 0.96, 0.44), center_opacity=0.72,
                                                 body_emit=1.6, edge_emit=2.8))
    visor.parent = root

    bpy.ops.mesh.primitive_uv_sphere_add(segments=36, ring_count=20, radius=0.15, location=(0, 0.03, 0.04))
    dome = link_to(bpy.context.active_object, col)
    dome.scale = (1.0, 0.72, 0.85)
    for p in dome.data.polygons:
        p.use_smooth = True
    dome.data.materials.append(make_glass_sheen_mat("SaucerDome", (0.55, 0.88, 1.0), alpha=0.24))
    dome.parent = root
    render_to("saucer.png")


def optimize_pngs() -> None:
    pngs = sorted(os.path.join(OUT_DIR, f) for f in os.listdir(OUT_DIR) if f.endswith(".png"))
    if not pngs:
        return
    try:
        subprocess.run(["oxipng", "-o", "3", "--strip", "safe", *pngs], check=False)
    except FileNotFoundError:
        pass


def main() -> None:
    clear_scene()
    scene = setup_cycles(samples=64)
    setup_studio_world(scene)

    render_cabinet()
    render_balls_and_pins()
    render_windmills_and_rails()
    render_cards()
    render_dice()
    render_chips()
    render_shards()
    render_pockets()
    render_reels()
    render_ship_and_saucer()
    optimize_pngs()

    total_kb = sum(os.path.getsize(os.path.join(OUT_DIR, f)) for f in os.listdir(OUT_DIR) if f.endswith(".png")) / 1024.0
    print(f"[render-art] Done! Total assets/art size: {total_kb:.1f} KB", flush=True)


if __name__ == "__main__":
    main()
