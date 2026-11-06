class_name Look
extends RefCounted
## Palette and shared drawing resources for the neon parlour.

const BG := Color(0.035, 0.03, 0.07)
const FACE_TOP := Color(0.075, 0.06, 0.16)
const FACE_BOTTOM := Color(0.045, 0.035, 0.1)
const PINK := Color(1.0, 0.31, 0.64)
const CYAN := Color(0.21, 0.89, 1.0)
const GREEN := Color(0.36, 1.0, 0.6)
const GOLD := Color(1.0, 0.8, 0.3)
const BRASS := Color(0.85, 0.64, 0.25)
const RED := Color(1.0, 0.27, 0.27)
const VIOLET := Color(0.62, 0.42, 1.0)
const CHROME := Color(0.8, 0.83, 0.9)
const INK := Color(0.93, 0.92, 0.98)
const MUTED := Color(0.93, 0.92, 0.98, 0.6)

const DISPLAY_FILE := preload("res://fonts/Bungee-Regular.ttf")
const SANS_FILE := preload("res://fonts/Outfit.ttf")

static var _glow: GradientTexture2D
static var _soft: GradientTexture2D
static var display: Font
static var sans: FontVariation
static var sans_bold: FontVariation


static func init() -> void:
	if _glow:
		return
	_glow = _radial([Color(1, 1, 1, 1), Color(1, 1, 1, 0.35), Color(1, 1, 1, 0)], [0.0, 0.25, 1.0])
	_soft = _radial([Color(1, 1, 1, 0.9), Color(1, 1, 1, 0)], [0.0, 1.0])
	display = DISPLAY_FILE
	sans = _weight(SANS_FILE, 400)
	sans_bold = _weight(SANS_FILE, 640)


static func _radial(colors: Array, offsets: Array) -> GradientTexture2D:
	var g := Gradient.new()
	g.colors = PackedColorArray(colors)
	g.offsets = PackedFloat32Array(offsets)
	var t := GradientTexture2D.new()
	t.gradient = g
	t.fill = GradientTexture2D.FILL_RADIAL
	t.fill_from = Vector2(0.5, 0.5)
	t.fill_to = Vector2(1.0, 0.5)
	t.width = 64
	t.height = 64
	return t


static func _weight(file: FontFile, wght: int) -> FontVariation:
	var f := FontVariation.new()
	f.base_font = file
	f.variation_opentype = {TextServerManager.get_primary_interface().name_to_tag("wght"): wght}
	return f


## An additive glow blob (call from a CanvasItem whose material blends ADD).
static func glow(ci: CanvasItem, pos: Vector2, radius: float, color: Color) -> void:
	ci.draw_texture_rect(_glow, Rect2(pos - Vector2(radius, radius), Vector2(radius, radius) * 2.0), false, color)


static func glow_rect(ci: CanvasItem, rect: Rect2, color: Color) -> void:
	ci.draw_texture_rect(_soft, rect, false, color)


static func additive() -> CanvasItemMaterial:
	var m := CanvasItemMaterial.new()
	m.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	return m


static func text(ci: CanvasItem, pos: Vector2, s: String, size: int, color: Color, font: Font = null, align := HORIZONTAL_ALIGNMENT_CENTER, width := -1.0) -> void:
	var f := font if font else display
	var w := width
	var p := pos
	if align == HORIZONTAL_ALIGNMENT_CENTER and width < 0.0:
		w = 600.0
		p.x -= 300.0
	ci.draw_string(f, p, s, align, w, size, color)


static func rounded(ci: CanvasItem, rect: Rect2, radius: float, color: Color, filled := true, width := 2.0) -> void:
	var sb := StyleBoxFlat.new()
	sb.set_corner_radius_all(int(radius))
	sb.anti_aliasing = true
	if filled:
		sb.bg_color = color
	else:
		sb.draw_center = false
		sb.border_color = color
		sb.set_border_width_all(int(width))
	sb.draw(ci.get_canvas_item(), rect)
