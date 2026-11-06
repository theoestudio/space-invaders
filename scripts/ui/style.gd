class_name Style
extends RefCounted
## The shared Theme for every Control: neon parlour signage.

const INK := Look.INK
const MUTED := Look.MUTED
const FAINT := Color(0.93, 0.92, 0.98, 0.38)
const PANEL := Color(0.05, 0.04, 0.11, 0.94)
const BUTTON := Color(0.11, 0.09, 0.22)
const BUTTON_HOVER := Color(0.16, 0.13, 0.32)
const BUTTON_PRESSED := Color(0.08, 0.06, 0.16)

static var theme: Theme


static func init() -> void:
	if theme:
		return
	Look.init()
	theme = Theme.new()
	theme.default_font = Look.sans
	theme.default_font_size = 22
	theme.set_color(&"font_color", &"Label", INK)
	for state in [&"normal", &"hover", &"pressed", &"disabled", &"focus"]:
		theme.set_stylebox(state, &"Button", _button_box(state, Look.CYAN))
	theme.set_color(&"font_color", &"Button", INK)
	theme.set_color(&"font_hover_color", &"Button", Color.WHITE)
	theme.set_color(&"font_pressed_color", &"Button", Look.CYAN)
	theme.set_color(&"font_disabled_color", &"Button", FAINT)
	theme.set_color(&"font_focus_color", &"Button", INK)
	theme.set_font(&"font", &"Button", Look.display)
	theme.set_font_size(&"font_size", &"Button", 20)
	theme.set_stylebox(&"panel", &"PanelContainer", panel_box())
	theme.set_constant(&"separation", &"VBoxContainer", 12)
	theme.set_constant(&"separation", &"HBoxContainer", 12)


static func panel_box(edge := Look.PINK, radius := 20) -> StyleBoxFlat:
	var b := StyleBoxFlat.new()
	b.bg_color = PANEL
	b.border_color = Color(edge, 0.7)
	b.set_border_width_all(2)
	b.set_corner_radius_all(radius)
	b.set_content_margin_all(28)
	b.shadow_color = Color(edge, 0.25)
	b.shadow_size = 22
	return b


static func _button_box(state: StringName, edge: Color) -> StyleBoxFlat:
	var b := StyleBoxFlat.new()
	b.bg_color = {&"hover": BUTTON_HOVER, &"pressed": BUTTON_PRESSED, &"disabled": Color(BUTTON, 0.5)}.get(state, BUTTON)
	b.border_color = Color(edge, 0.9 if state == &"hover" else 0.5)
	b.set_border_width_all(2)
	b.set_corner_radius_all(12)
	b.content_margin_left = 22
	b.content_margin_right = 22
	b.content_margin_top = 14
	b.content_margin_bottom = 14
	if state == &"hover":
		b.shadow_color = Color(edge, 0.35)
		b.shadow_size = 10
	if state == &"focus":
		b.bg_color = Color(0, 0, 0, 0)
	return b


static func label(text: String, size := 22, color := INK, font: Font = null) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_font_size_override(&"font_size", size)
	l.add_theme_color_override(&"font_color", color)
	if font:
		l.add_theme_font_override(&"font", font)
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return l


## `tone` picks the neon: CYAN for ordinary buttons, GOLD for the main action,
## PINK for risk.
static func button(text: String, tone := Look.CYAN, filled := false) -> Button:
	var b := Button.new()
	b.text = text
	b.focus_mode = Control.FOCUS_NONE
	for state in [&"normal", &"hover", &"pressed", &"disabled"]:
		var box := _button_box(state, tone)
		if filled:
			box.bg_color = tone.darkened(0.15 if state == &"hover" else (0.45 if state == &"pressed" else 0.3))
		b.add_theme_stylebox_override(state, box)
	if filled:
		b.add_theme_color_override(&"font_color", Color(0.04, 0.02, 0.08))
		b.add_theme_color_override(&"font_hover_color", Color(0.02, 0.01, 0.05))
		b.add_theme_color_override(&"font_pressed_color", Color(0.02, 0.01, 0.05))
	b.mouse_entered.connect(func() -> void: Sfx.play(&"select", 1.4, -14.0))
	return b
