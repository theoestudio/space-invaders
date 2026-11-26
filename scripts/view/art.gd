class_name Art
extends RefCounted
## Loads and draws the pre-rendered 2.5D miniature textures from res://assets/art/.

const NAMES := [
	&"cabinet",
	&"ball_chrome", &"ball_gold", &"ball_shadow", &"pin_brass",
	&"windmill_blades", &"windmill_hub", &"rail_brass_seg", &"rail_brass_cap",
	&"card_red", &"card_arm_red", &"card_gold", &"card_arm_gold",
	&"die_ivory", &"die_ivory_cracked", &"die_foot_ivory",
	&"die_gold", &"die_gold_cracked", &"die_foot_gold",
	&"chip_red", &"chip_blue", &"chip_green", &"chip_gold",
	&"chip_eye_white", &"chip_foot",
	&"shard_red", &"shard_blue", &"shard_green", &"shard_ivory", &"shard_gold",
	&"pocket_side_back", &"pocket_side_front",
	&"pocket_start_back", &"pocket_start_front",
	&"pocket_tulip_back", &"pocket_tulip_front",
	&"tulip_petal_left", &"tulip_petal_right",
	&"attacker_shut", &"attacker_open_back", &"attacker_open_front",
	&"reel_roof", &"reel_drums", &"reel_frame",
	&"sym_seven", &"sym_bar", &"sym_cherry", &"sym_bell", &"sym_star", &"sym_chip",
	&"ship_hull", &"ship_barrel", &"ship_cup_back", &"ship_cup_front",
	&"saucer",
]

static var _loaded := false
static var _tex: Dictionary = {}


static func init() -> void:
	if _loaded:
		return
	_loaded = true
	for name: StringName in NAMES:
		var path := "res://assets/art/%s.png" % String(name)
		if ResourceLoader.exists(path):
			var res := ResourceLoader.load(path)
			if res is Texture2D:
				_tex[name] = res


static func tex(name: StringName) -> Texture2D:
	if not _loaded:
		init()
	return _tex.get(name, null)


static func has(name: StringName) -> bool:
	return tex(name) != null


static func draw(ci: CanvasItem, name: StringName, center: Vector2, size: Vector2,
		rot := 0.0, scl := Vector2.ONE, modulate := Color.WHITE) -> bool:
	var t := tex(name)
	if t == null:
		return false
	ci.draw_set_transform(center, rot, scl)
	ci.draw_texture_rect(t, Rect2(-size * 0.5, size), false, modulate)
	ci.draw_set_transform(Vector2.ZERO)
	return true


## Draws a horizontally 3-sliced texture centered at `center` so curved side rims
## do not stretch when `size.x` widens (used for the expanding gold catch cup).
static func draw_3slice_h(ci: CanvasItem, name: StringName, center: Vector2, size: Vector2,
		cap_frac := 0.24, modulate := Color.WHITE) -> bool:
	var t := tex(name)
	if t == null:
		return false
	var tw := float(t.get_width())
	var th := float(t.get_height())
	var src_cap := tw * cap_frac
	var dest_cap := minf(size.x * 0.45, src_cap * (size.y / th))
	var left := center.x - size.x * 0.5
	var top := center.y - size.y * 0.5
	var mid_w := maxf(size.x - dest_cap * 2.0, 0.0)
	ci.draw_texture_rect_region(t, Rect2(left, top, dest_cap, size.y),
		Rect2(0.0, 0.0, src_cap, th), modulate)
	if mid_w > 0.1:
		ci.draw_texture_rect_region(t, Rect2(left + dest_cap, top, mid_w, size.y),
			Rect2(src_cap, 0.0, tw - src_cap * 2.0, th), modulate)
	ci.draw_texture_rect_region(t, Rect2(left + size.x - dest_cap, top, dest_cap, size.y),
		Rect2(tw - src_cap, 0.0, src_cap, th), modulate)
	return true
