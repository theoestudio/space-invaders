class_name GameUI
extends CanvasLayer
## Every screen-space panel: title menu, pause, the cash-out choice between waves,
## the result and the rules pages. Pure presentation: buttons raise signals and
## Main does the work. The in-board HUD is drawn by Stage.

signal daily_pressed
signal arcade_pressed
signal menu_pressed
signal again_pressed
signal share_pressed
signal cash_pressed
signal ride_pressed
signal resume_pressed
signal rules_closed

const RULE_PAGES := [
	["The House descends", "A formation of living casino chips, dice and cards marches down toward your launcher. Break them all before any reach the red line.\n\nMove with the arrow keys or A and D, fire with Space. On a phone or with a mouse, hold anywhere and drag: the launcher follows and fires on its own."],
	["Balls are everything", "Your tray of balls is your ammunition and your score. Every shot costs one ball, and a hit from the House spills twelve.\n\nRun the tray dry with nothing left in play and you are bust."],
	["Wrecks fall through the pins", "Every invader you break drops a ball through the pin field. Dice drop two. Gold invaders drop gold balls that pay triple.\n\nPockets pay into your tray: side +2, tulip +5, and the green start chucker +3. Catch a ball in the cup on your launcher for +1. A bolt through a shut tulip springs it open."],
	["Spin the reels", "Each ball in the start chucker banks a spin, up to four. Three of a kind pays:\n\nSevens: FEVER. Free rapid fire, the gold attacker opens (+10) and balls shower down.\nCherries: spread shot  ·  Bars: piercing bolts\nBells: a shield  ·  Stars: a wide catch cup  ·  Chips: +20 balls\n\nShoot the croupier's saucer for a free spin and five balls."],
	["Cash out or let it ride", "After each wave the House offers a choice. Cash out and your tray is your score. Let it ride and the next wave pays a bigger clear bonus, but marches faster, starts lower and shoots more.\n\nBust and the House keeps everything."],
	["The daily run", "One run a day, the same for everyone: the same board, the same formations and the same reel draws in the same order. Your first finished run counts; replays are practice.\n\nArcade deals a fresh board every time and keeps your best payout."],
]

var _root := Control.new()
var _menu := Control.new()
var _pause := Control.new()
var _between := Control.new()
var _end := Control.new()
var _rules := Control.new()

var _daily_title: Label
var _daily_status: Label
var _daily_button: Button
var _arcade_status: Label
var _toggles := {}

var _banner: Label
var _banner_sub: Label
var _banner_box: VBoxContainer
var _banner_tween: Tween
var _toast: Label

var _between_title: Label
var _between_lines: Label
var _cash: Button
var _ride: Button

var _end_title: Label
var _end_sub: Label
var _end_stats: Label
var _end_grid: HBoxContainer
var _end_share: Button
var _end_again: Button

var _rules_page := 0
var _rules_title: Label
var _rules_text: Label
var _rules_art: RulesArt
var _rules_next: Button
var _rules_prev: Button
var _panels: Array[Control] = []


func _ready() -> void:
	Style.init()
	_root.theme = Style.theme
	_root.set_anchors_preset(Control.PRESET_FULL_RECT)
	_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_root)
	for c in [_menu, _pause, _between, _end, _rules]:
		c.set_anchors_preset(Control.PRESET_FULL_RECT)
		c.mouse_filter = Control.MOUSE_FILTER_STOP
		c.visible = false
		_root.add_child(c)
	_build_menu()
	_build_pause()
	_build_between()
	_build_end()
	_build_rules()
	_build_banner()
	_toast = Style.label("", 22, Style.INK, Look.sans_bold)
	_toast.set_anchors_and_offsets_preset(Control.PRESET_CENTER_BOTTOM)
	_toast.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_toast.grow_horizontal = Control.GROW_DIRECTION_BOTH
	_toast.offset_top = -150
	_toast.modulate.a = 0.0
	_root.add_child(_toast)
	get_viewport().size_changed.connect(_on_resized)
	_on_resized()


func _shade(parent: Control, alpha := 0.6) -> void:
	var shade := ColorRect.new()
	shade.color = Color(0.02, 0.015, 0.05, alpha)
	shade.set_anchors_preset(Control.PRESET_FULL_RECT)
	shade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(shade)


func _center(parent: Control) -> CenterContainer:
	var c := CenterContainer.new()
	c.set_anchors_preset(Control.PRESET_FULL_RECT)
	c.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(c)
	return c


func _panel(parent: Control, edge := Look.PINK) -> VBoxContainer:
	var p := PanelContainer.new()
	p.add_theme_stylebox_override(&"panel", Style.panel_box(edge))
	_center(parent).add_child(p)
	_panels.append(p)
	var v := VBoxContainer.new()
	v.add_theme_constant_override(&"separation", 14)
	p.add_child(v)
	return v


func _centered(l: Label) -> Label:
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	return l


func _spacer(h: float) -> Control:
	var c := Control.new()
	c.custom_minimum_size = Vector2(0, h)
	c.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return c


func _row(parent: Control) -> HBoxContainer:
	var h := HBoxContainer.new()
	h.alignment = BoxContainer.ALIGNMENT_CENTER
	parent.add_child(h)
	return h


# --- menu ----------------------------------------------------------------------

func _build_menu() -> void:
	_shade(_menu, 0.72)
	var col := VBoxContainer.new()
	col.add_theme_constant_override(&"separation", 16)
	_center(_menu).add_child(col)
	_panels.append(col)

	var title := _centered(Style.label("PACHINKO", 76, Look.PINK, Look.display))
	title.add_theme_color_override(&"font_shadow_color", Color(Look.PINK, 0.55))
	title.add_theme_constant_override(&"shadow_outline_size", 18)
	col.add_child(title)
	var title2 := _centered(Style.label("DESCENT", 48, Look.CYAN, Look.display))
	title2.add_theme_color_override(&"font_shadow_color", Color(Look.CYAN, 0.5))
	title2.add_theme_constant_override(&"shadow_outline_size", 14)
	title2.add_theme_constant_override(&"line_spacing", -10)
	col.add_child(title2)
	col.add_child(_centered(Style.label("Shoot the House. Every wreck drops a ball through the pins.", 20, Style.MUTED)))
	col.add_child(_spacer(10))

	var daily := _card(col, Look.GOLD)
	_daily_title = Style.label("Daily run", 30, Look.GOLD, Look.display)
	daily.add_child(_daily_title)
	_daily_status = Style.label("", 19, Style.MUTED)
	_daily_status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	daily.add_child(_daily_status)
	_daily_button = Style.button("Play today's run", Look.GOLD, true)
	_daily_button.pressed.connect(func() -> void: daily_pressed.emit())
	daily.add_child(_daily_button)

	var arcade := _card(col, Look.CYAN)
	arcade.add_child(Style.label("Arcade", 30, Look.CYAN, Look.display))
	_arcade_status = Style.label("", 19, Style.MUTED)
	_arcade_status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	arcade.add_child(_arcade_status)
	var ab := Style.button("Play arcade", Look.CYAN, true)
	ab.pressed.connect(func() -> void: arcade_pressed.emit())
	arcade.add_child(ab)

	var row := _row(col)
	var how := Style.button("How to play")
	how.pressed.connect(show_rules)
	row.add_child(how)
	for key in ["sound", "music"]:
		var t := Style.button("")
		t.pressed.connect(func() -> void:
			Profile.set(key, not Profile.get(key))
			Profile.save()
			_sync_toggles())
		_toggles[key] = t
		row.add_child(t)
	_sync_toggles()


func _card(parent: Control, edge: Color) -> VBoxContainer:
	var p := PanelContainer.new()
	var box := Style.panel_box(edge, 16)
	box.set_content_margin_all(20)
	box.shadow_size = 10
	p.add_theme_stylebox_override(&"panel", box)
	parent.add_child(p)
	var v := VBoxContainer.new()
	v.add_theme_constant_override(&"separation", 8)
	p.add_child(v)
	return v


func _sync_toggles() -> void:
	for key: String in _toggles:
		_toggles[key].text = "%s %s" % [key.capitalize(), "on" if Profile.get(key) else "off"]


func show_menu() -> void:
	_hide_all()
	var n := Daily.today_number()
	_daily_title.text = "Daily run #%d" % n
	var totals := Profile.daily_totals()
	var streak := Profile.daily_streak(n)
	if Profile.has_daily(n):
		var r: Dictionary = Profile.daily[n]
		var res := "cashed out %d" % int(r.payout) if int(r.payout) > 0 else "bust on wave %d" % (int(r.waves) + 1)
		_daily_status.text = "Today: %s. Next run in %s." % [res, _hm(Daily.seconds_until_next())]
		_daily_button.text = "Practice today's run"
	else:
		_daily_status.text = "The same board and waves for everyone today. Your first run counts."
		_daily_button.text = "Play today's run"
	if totals.played > 0:
		_daily_status.text += "\nPlayed %d · cashed out %d · best %d" % [totals.played, totals.cashed, totals.best]
		if streak > 1:
			_daily_status.text += " · streak %d" % streak
	var a := Profile.arcade
	if int(a.runs) > 0:
		_arcade_status.text = "A fresh board every time. Best payout %d · furthest wave %d · %d runs" % [int(a.best), int(a.best_wave), int(a.runs)]
	else:
		_arcade_status.text = "A fresh board every time. Ride as far as you dare."
	_sync_toggles()
	_menu.visible = true


static func _hm(secs: int) -> String:
	return "%dh %02dm" % [secs / 3600, (secs % 3600) / 60]


# --- in game ---------------------------------------------------------------------

func show_game() -> void:
	_hide_all()


func _hide_all() -> void:
	for c in [_menu, _pause, _between, _end, _rules]:
		c.visible = false


func _build_banner() -> void:
	_banner_box = VBoxContainer.new()
	_banner_box.set_anchors_and_offsets_preset(Control.PRESET_HCENTER_WIDE)
	_banner_box.anchor_top = 0.42
	_banner_box.anchor_bottom = 0.42
	_banner_box.grow_vertical = Control.GROW_DIRECTION_BOTH
	_banner_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_banner_box.modulate.a = 0.0
	_banner = _centered(Style.label("", 54, Look.GOLD, Look.display))
	_banner.add_theme_color_override(&"font_shadow_color", Color(0, 0, 0, 0.85))
	_banner.add_theme_constant_override(&"shadow_outline_size", 22)
	_banner_sub = _centered(Style.label("", 22, Style.INK, Look.sans_bold))
	_banner_sub.add_theme_color_override(&"font_shadow_color", Color(0, 0, 0, 0.9))
	_banner_sub.add_theme_constant_override(&"shadow_outline_size", 12)
	_banner_box.add_child(_banner)
	_banner_box.add_child(_banner_sub)
	_root.add_child(_banner_box)


func banner(text: String, sub := "", hold := 1.1, color := Look.GOLD) -> void:
	_banner.text = text
	_banner.add_theme_color_override(&"font_color", color)
	_banner_sub.text = sub
	_banner_sub.visible = sub != ""
	if _banner_tween:
		_banner_tween.kill()
	_banner_box.modulate.a = 0.0
	_banner_box.scale = Vector2(0.9, 0.9)
	_banner_box.pivot_offset = _banner_box.size / 2.0
	_banner_tween = create_tween()
	_banner_tween.tween_property(_banner_box, "modulate:a", 1.0, 0.18)
	_banner_tween.parallel().tween_property(_banner_box, "scale", Vector2.ONE, 0.25).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	_banner_tween.tween_interval(hold)
	_banner_tween.tween_property(_banner_box, "modulate:a", 0.0, 0.35)


func toast(text: String) -> void:
	_toast.text = text
	var tw := create_tween()
	tw.tween_property(_toast, "modulate:a", 1.0, 0.15)
	tw.tween_interval(1.4)
	tw.tween_property(_toast, "modulate:a", 0.0, 0.4)


# --- pause -----------------------------------------------------------------------

func _build_pause() -> void:
	_shade(_pause, 0.65)
	var v := _panel(_pause, Look.CYAN)
	v.add_child(_centered(Style.label("PAUSED", 48, Look.CYAN, Look.display)))
	var resume := Style.button("Resume", Look.CYAN, true)
	resume.pressed.connect(func() -> void: resume_pressed.emit())
	v.add_child(resume)
	var how := Style.button("How to play")
	how.pressed.connect(show_rules)
	v.add_child(how)
	var row := _row(v)
	for key in ["sound", "music"]:
		var t := Style.button("")
		t.pressed.connect(func() -> void:
			Profile.set(key, not Profile.get(key))
			Profile.save()
			_sync_toggles())
		_toggles[key + "_p"] = t
		row.add_child(t)
	var quit := Style.button("Quit to menu", Look.PINK)
	quit.pressed.connect(func() -> void: menu_pressed.emit())
	v.add_child(quit)
	v.add_child(_centered(Style.label("Quitting a run forfeits it.", 17, Style.FAINT)))


func show_pause(on: bool) -> void:
	_sync_toggles()
	for key in ["sound", "music"]:
		_toggles[key + "_p"].text = "%s %s" % [key.capitalize(), "on" if Profile.get(key) else "off"]
	_pause.visible = on


func is_paused_shown() -> bool:
	return _pause.visible


# --- between waves -------------------------------------------------------------

func _build_between() -> void:
	_shade(_between, 0.45)
	var v := _panel(_between, Look.GOLD)
	_between_title = _centered(Style.label("", 42, Look.GOLD, Look.display))
	v.add_child(_between_title)
	_between_lines = _centered(Style.label("", 22, Style.INK))
	v.add_child(_between_lines)
	v.add_child(_spacer(4))
	_cash = Style.button("", Look.GOLD, true)
	_cash.pressed.connect(func() -> void: cash_pressed.emit())
	v.add_child(_cash)
	_ride = Style.button("", Look.PINK)
	_ride.pressed.connect(func() -> void: ride_pressed.emit())
	v.add_child(_ride)
	v.add_child(_centered(Style.label("Bust and the House keeps everything.", 18, Style.FAINT)))


func show_between(s: Sim) -> void:
	_between_title.text = "WAVE %d CLEARED" % s.wave
	var net: int = s.stats.waves[-1]
	var next_bonus := Tune.CLEAR_BONUS + Tune.CLEAR_BONUS_PER_WAVE * s.wave
	_between_lines.text = "Clear bonus +%d   ·   this wave %s%d\nTray: %d balls\n\nWave %d marches faster and starts lower.\nIts clear bonus is +%d." % [
		s.clear_bonus, "+" if net >= 0 else "", net, s.tray, s.wave + 1, next_bonus]
	_cash.text = "Cash out %d" % s.tray
	_ride.text = "Let it ride: wave %d" % (s.wave + 1)
	_ride.disabled = s.wave >= Tune.MAX_WAVE
	_between.visible = true


func hide_between() -> void:
	_between.visible = false


func is_between_shown() -> bool:
	return _between.visible


# --- result ----------------------------------------------------------------------

func _build_end() -> void:
	_shade(_end, 0.55)
	var v := _panel(_end, Look.PINK)
	_end_title = _centered(Style.label("", 50, Look.GOLD, Look.display))
	v.add_child(_end_title)
	_end_sub = _centered(Style.label("", 22, Style.INK, Look.sans_bold))
	v.add_child(_end_sub)
	_end_grid = HBoxContainer.new()
	_end_grid.alignment = BoxContainer.ALIGNMENT_CENTER
	_end_grid.add_theme_constant_override(&"separation", 6)
	v.add_child(_end_grid)
	_end_stats = _centered(Style.label("", 19, Style.MUTED))
	v.add_child(_end_stats)
	v.add_child(_spacer(4))
	_end_share = Style.button("Copy result", Look.GOLD, true)
	_end_share.pressed.connect(func() -> void: share_pressed.emit())
	v.add_child(_end_share)
	var row := _row(v)
	_end_again = Style.button("Play again", Look.CYAN, true)
	_end_again.pressed.connect(func() -> void: again_pressed.emit())
	row.add_child(_end_again)
	var menu := Style.button("Menu")
	menu.pressed.connect(func() -> void: menu_pressed.emit())
	row.add_child(menu)


## `nets` is the tray change per wave; `busted` marks the last as the bust wave.
func show_end(title: String, color: Color, sub: String, stats: String, nets: Array, busted: bool, share: bool, again_text: String) -> void:
	_hide_all()
	_end_title.text = title
	_end_title.add_theme_color_override(&"font_color", color)
	_end_sub.text = sub
	_end_stats.text = stats
	for c in _end_grid.get_children():
		c.queue_free()
	for i in nets.size():
		var last := i == nets.size() - 1
		var c := wave_color(int(nets[i]), busted and last)
		var sq := ColorRect.new()
		sq.color = c
		sq.custom_minimum_size = Vector2(26, 26)
		sq.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_end_grid.add_child(sq)
	_end_grid.visible = nets.size() > 0
	_end_share.visible = share
	_end_again.text = again_text
	_end.visible = true


static func wave_color(net: int, bust: bool) -> Color:
	if bust:
		return Look.RED
	if net >= 30:
		return Look.GREEN
	if net > 0:
		return Look.GOLD
	return Color(0.5, 0.45, 0.6)


# --- rules -------------------------------------------------------------------------

func _build_rules() -> void:
	_shade(_rules, 0.75)
	var v := _panel(_rules, Look.CYAN)
	_rules_title = _centered(Style.label("", 34, Look.CYAN, Look.display))
	v.add_child(_rules_title)
	_rules_art = RulesArt.new()
	_rules_art.custom_minimum_size = Vector2(560, 170)
	v.add_child(_rules_art)
	_rules_text = Style.label("", 21, Style.INK)
	_rules_text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_rules_text.custom_minimum_size = Vector2(560, 0)
	v.add_child(_rules_text)
	var row := _row(v)
	_rules_prev = Style.button("Back")
	_rules_prev.pressed.connect(func() -> void: _rules_show(_rules_page - 1))
	row.add_child(_rules_prev)
	_rules_next = Style.button("Next", Look.CYAN, true)
	_rules_next.pressed.connect(func() -> void:
		if _rules_page >= RULE_PAGES.size() - 1:
			hide_rules()
		else:
			_rules_show(_rules_page + 1))
	row.add_child(_rules_next)


func show_rules() -> void:
	_rules_show(0)
	_rules.visible = true


func hide_rules() -> void:
	_rules.visible = false
	Profile.seen_rules = true
	Profile.save()
	rules_closed.emit()


func is_rules_shown() -> bool:
	return _rules.visible


func _rules_show(page: int) -> void:
	_rules_page = clampi(page, 0, RULE_PAGES.size() - 1)
	_rules_title.text = RULE_PAGES[_rules_page][0]
	_rules_text.text = RULE_PAGES[_rules_page][1]
	_rules_art.page = _rules_page
	_rules_art.queue_redraw()
	_rules_prev.disabled = _rules_page == 0
	_rules_next.text = "Done" if _rules_page == RULE_PAGES.size() - 1 else "Next  %d/%d" % [_rules_page + 1, RULE_PAGES.size()]


# --- sizing ----------------------------------------------------------------------

func _on_resized() -> void:
	var size := get_viewport().get_visible_rect().size
	var w := minf(size.x - 40.0, 640.0)
	for p in _panels:
		p.custom_minimum_size.x = w
	_rules_art.custom_minimum_size.x = w - 60.0
	_rules_text.custom_minimum_size.x = w - 60.0
