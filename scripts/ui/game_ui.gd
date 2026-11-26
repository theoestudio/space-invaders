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
## The cashier: buy offer `index`, sell a fixture, reroll the offers.
signal buy_pressed(index: int)
signal sell_pressed(id: StringName)
signal reroll_pressed
signal resume_pressed
signal rules_closed
## A "More from Twinspear" game tapped: `where` is "menu" (the list) or "end" (the
## suggestion under a result). Main counts it and opens the link.
signal promo_pressed(game: Dictionary, where: String)

const RULE_PAGES := [
	["The House descends", "A formation of living casino chips, dice and cards marches down toward your launcher. Break them all before any reach the red line.\n\nMove with the arrow keys or A and D, fire with Space. On a phone or with a mouse, hold anywhere and drag: the launcher follows and fires on its own."],
	["Balls are everything", "Your tray of balls is your ammunition and your score. Every shot costs one ball, and a hit from the House spills twelve, or a fiftieth of the tray when that is more.\n\nRun the tray dry with nothing left in play and you are bust."],
	["Wrecks fall through the pins", "Every invader you break drops a ball through the pin field. Dice drop two. Gold invaders drop gold balls that pay triple.\n\nPockets pay into your tray: side +2, tulip +5, and the green start chucker +3. Catch a ball in the cup on your launcher for +1. A bolt through a shut tulip springs it open."],
	["Spin the reels", "Each ball in the start chucker banks a spin, up to four. Three of a kind pays:\n\nSevens: FEVER. Free rapid fire, the gold attacker opens (+10) and balls shower down.\nCherries: spread shot  ·  Bars: piercing bolts\nBells: a shield  ·  Stars: a wide catch cup  ·  Chips: +20 balls\n\nShoot the croupier's saucer for a free spin and five balls."],
	["Cash out or ride down", "After each wave the cashier sells fixtures for the rest of the run, paid from your tray. Then choose. Cash out and your tray is your score. Let it ride and the next wave pays a bigger clear bonus, but marches faster, starts lower and shoots more.\n\nFive floors of four waves each, the last a guard worth double. Break the Vault's guard and the tray doubles. Bust and the House keeps everything."],
	["The daily run", "One run a day, the same for everyone: the same board, the same formations and the same reel draws in the same order. Your first finished run counts; replays are practice. The daily ends at the Vault.\n\nArcade deals a fresh board every time and keeps your best payout."],
]

var _root := Control.new()
var _menu := Control.new()
var _pause := Control.new()
var _between := Control.new()
var _end := Control.new()
var _rules := Control.new()
var _more := Control.new()
var _records := Control.new()

## The other Twinspear games, best fit first (MoreGames). Starts with the bundled copy and
## is replaced by the blog's feed when it arrives.
var games: Array[Dictionary] = MoreGames.ranked(MoreGames.bundled())
var _more_list: VBoxContainer
var _more_scroll: ScrollContainer
var _end_more: Button

var _daily_title: Label
var _daily_status: Label
var _daily_button: Button
var _arcade_status: Label
## The last 14 dailies as lamps on the Daily card, and the Records button.
var _daily_strip: HBoxContainer
var _records_button: Button
var _records_list: VBoxContainer
var _records_scroll: ScrollContainer
var _records_head: Label
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
var _cashier: VBoxContainer
var _offer_buttons: Array[Button] = []
var _offer_frames: Array[PanelContainer] = []
var _offer_icons: Array[TextureRect] = []
var _offer_names: Array[Label] = []
var _offer_texts: Array[Label] = []
var _offer_prices: Array[Label] = []
var _offer_balls: Array[TextureRect] = []
var _owned_label: Label
var _owned: HFlowContainer
var _reroll: Button

var _end_title: Label
var _end_sub: Label
var _end_stats: Label
var _end_grid: HBoxContainer
var _end_share: Button
var _end_again: Button
var _end_board: VBoxContainer

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
	for c in [_menu, _pause, _between, _end, _rules, _more, _records]:
		c.set_anchors_preset(Control.PRESET_FULL_RECT)
		c.mouse_filter = Control.MOUSE_FILTER_STOP
		c.visible = false
		_root.add_child(c)
	_build_menu()
	_build_pause()
	_build_between()
	_build_end()
	_build_rules()
	_build_more()
	_build_records()
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
	_daily_strip = HBoxContainer.new()
	_daily_strip.alignment = BoxContainer.ALIGNMENT_CENTER
	_daily_strip.add_theme_constant_override(&"separation", 5)
	daily.add_child(_daily_strip)
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
	_records_button = Style.button("Challenges and records")
	_records_button.pressed.connect(show_records)
	col.add_child(_records_button)
	var more := Style.button("More free games from Twinspear")
	more.pressed.connect(show_more)
	col.add_child(more)


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
	_fill_strip(n)
	var met := Profile.challenges.size()
	_records_button.text = "Challenges %d/%d · %d comps" % [met, Challenges.ORDER.size(), Profile.comps] if met > 0 else "Challenges and records"
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
	for c in [_menu, _pause, _between, _end, _rules, _more, _records]:
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


func hide_banner() -> void:
	if _banner_tween:
		_banner_tween.kill()
	_banner_box.modulate.a = 0.0


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
	_between_lines = _centered(Style.label("", 20, Style.INK))
	v.add_child(_between_lines)
	_build_cashier(v)
	v.add_child(_spacer(2))
	_cash = Style.button("", Look.GOLD, true)
	_cash.pressed.connect(func() -> void: cash_pressed.emit())
	v.add_child(_cash)
	_ride = Style.button("", Look.PINK)
	_ride.pressed.connect(func() -> void: ride_pressed.emit())
	v.add_child(_ride)
	v.add_child(_centered(Style.label("Bust and the House keeps everything.", 18, Style.FAINT)))


func _build_cashier(parent: Control) -> void:
	_cashier = VBoxContainer.new()
	_cashier.add_theme_constant_override(&"separation", 8)
	parent.add_child(_cashier)
	_cashier.add_child(_centered(Style.label("THE CASHIER · fixtures for the rest of the run", 16, Look.CYAN, Look.sans_bold)))
	for i in Fixtures.OFFERS:
		var b := Style.button("", Look.CYAN)
		b.custom_minimum_size = Vector2(0, 70)
		b.pressed.connect(func() -> void: buy_pressed.emit(i))
		var row := HBoxContainer.new()
		row.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		row.offset_left = 14
		row.offset_right = -16
		row.add_theme_constant_override(&"separation", 12)
		row.mouse_filter = Control.MOUSE_FILTER_IGNORE
		b.add_child(row)
		var frame := PanelContainer.new()
		var fbox := StyleBoxFlat.new()
		fbox.bg_color = Color(0.04, 0.03, 0.09, 0.92)
		fbox.border_color = Color(Look.CYAN, 0.65)
		fbox.set_border_width_all(2)
		fbox.set_corner_radius_all(10)
		fbox.set_content_margin_all(3)
		frame.add_theme_stylebox_override(&"panel", fbox)
		frame.custom_minimum_size = Vector2(48, 48)
		frame.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		frame.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var ico := TextureRect.new()
		ico.custom_minimum_size = Vector2(40, 40)
		ico.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		ico.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		ico.mouse_filter = Control.MOUSE_FILTER_IGNORE
		frame.add_child(ico)
		row.add_child(frame)
		var words := VBoxContainer.new()
		words.add_theme_constant_override(&"separation", 0)
		words.alignment = BoxContainer.ALIGNMENT_CENTER
		words.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		words.mouse_filter = Control.MOUSE_FILTER_IGNORE
		row.add_child(words)
		var n := Style.label("", 18, Style.INK, Look.display)
		words.add_child(n)
		var t := Style.label("", 15, Style.MUTED)
		words.add_child(t)
		var cost_box := HBoxContainer.new()
		cost_box.add_theme_constant_override(&"separation", 6)
		cost_box.alignment = BoxContainer.ALIGNMENT_END
		cost_box.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		cost_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
		row.add_child(cost_box)
		var pr := Style.label("", 20, Look.GOLD, Look.display)
		cost_box.add_child(pr)
		var ball_ico := TextureRect.new()
		ball_ico.texture = Art.tex(&"ball_chrome")
		ball_ico.custom_minimum_size = Vector2(18, 18)
		ball_ico.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		ball_ico.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		ball_ico.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		ball_ico.mouse_filter = Control.MOUSE_FILTER_IGNORE
		cost_box.add_child(ball_ico)
		_cashier.add_child(b)
		_offer_buttons.append(b)
		_offer_frames.append(frame)
		_offer_icons.append(ico)
		_offer_names.append(n)
		_offer_texts.append(t)
		_offer_prices.append(pr)
		_offer_balls.append(ball_ico)
	var row2 := _row(_cashier)
	_owned_label = Style.label("", 15, Style.MUTED)
	_owned_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row2.add_child(_owned_label)
	_reroll = _small_button("", Look.CYAN)
	_reroll.pressed.connect(func() -> void: reroll_pressed.emit())
	row2.add_child(_reroll)
	_owned = HFlowContainer.new()
	_owned.add_theme_constant_override(&"h_separation", 6)
	_owned.add_theme_constant_override(&"v_separation", 6)
	_cashier.add_child(_owned)


func _small_button(text: String, tone: Color) -> Button:
	var b := Style.button(text, tone)
	b.add_theme_font_size_override(&"font_size", 14)
	for state in [&"normal", &"hover", &"pressed", &"disabled"]:
		var box: StyleBoxFlat = b.get_theme_stylebox(state).duplicate()
		box.content_margin_left = 10
		box.content_margin_right = 10
		box.content_margin_top = 6
		box.content_margin_bottom = 6
		b.add_theme_stylebox_override(state, box)
	return b


func _show_cashier(s: Sim) -> void:
	_cashier.visible = s.can_ride() and not s.offers.is_empty()
	if not _cashier.visible:
		return
	for i in Fixtures.OFFERS:
		var b := _offer_buttons[i]
		var id: StringName = s.offers[i] if i < s.offers.size() else &""
		b.visible = i < s.offers.size()
		if id == &"":
			_offer_icons[i].modulate = Color(1, 1, 1, 0.25)
			(_offer_frames[i].get_theme_stylebox(&"panel") as StyleBoxFlat).border_color = Color(Look.CYAN, 0.22)
			_offer_names[i].text = "Sold"
			_offer_texts[i].text = ""
			_offer_prices[i].text = ""
			_offer_balls[i].visible = false
			b.disabled = true
			continue
		var f: Dictionary = Fixtures.ALL[id]
		var can := s.can_buy(i)
		_offer_icons[i].texture = Art.fixture(id)
		_offer_icons[i].modulate = Color.WHITE if can else Color(1, 1, 1, 0.55)
		(_offer_frames[i].get_theme_stylebox(&"panel") as StyleBoxFlat).border_color = Color(Look.group_color(f.group), 0.85 if can else 0.40)
		_offer_balls[i].visible = true
		var stacks := ""
		if f.stacks > 1:
			stacks = "  %d/%d" % [s.level(id) + 1, f.stacks]
		_offer_names[i].text = f.name + stacks
		_offer_texts[i].text = "%s · %s" % [f.group, f.text]
		_offer_prices[i].text = str(s.price(id))
		b.disabled = not can
	_owned_label.text = "Yours %d/%d%s" % [s.fixtures.size(), Fixtures.SLOTS, "" if s.fixtures.is_empty() else " · sells for half"]
	for c in _owned.get_children():
		c.queue_free()
	for id: StringName in s.fixtures:
		var lv := s.level(id)
		var label: String = Fixtures.name_of(id) + (" x%d" % lv if lv > 1 else "")
		var b := _small_button("%s · sell %d" % [label, s.sell_price(id)], Look.PINK)
		b.icon = Art.fixture(id)
		b.add_theme_constant_override(&"icon_max_width", 22)
		b.pressed.connect(func() -> void: sell_pressed.emit(id))
		_owned.add_child(b)
	_reroll.text = "Reroll %d" % s.reroll_price()
	_reroll.disabled = s.reroll_price() > s.tray


func show_between(s: Sim) -> void:
	hide_banner()
	var f := s.floor_number()
	if s.broke_house():
		_between_title.text = "YOU BROKE THE HOUSE"
	elif s.floor_cleared():
		_between_title.text = "FLOOR %d CLEARED" % f
	elif f > Tune.FLOORS:
		_between_title.text = "WAVE %d CLEARED" % s.wave
	else:
		_between_title.text = "WAVE %d CLEARED" % s.wave_in_floor()
	var net: int = s.stats.waves[-1]
	var lines := "Clear bonus +%d   ·   this wave %s%d\nTray: %d balls" % [s.clear_bonus, "+" if net >= 0 else "", net, s.tray]
	var next := s.wave + 1
	if not s.can_ride():
		lines += "\n\nThe daily ends at the Vault. Cash out your winnings." if s.broke_house() else "\n\nThe House is closing. Cash out."
	elif s.broke_house():
		lines += "\n\nAfter Hours: endless waves on mixed floors.\nWave %d's clear bonus is +%d." % [next, s.clear_bonus_at(next)]
	elif s.floor_cleared():
		lines += "\n\nNext: %s, floor %d of %d.\nThe House starts back near the top. Clear bonus +%d." % [
			Floors.in_sentence(f + 1), f + 1, Tune.FLOORS, s.clear_bonus_at(next)]
	elif Floors.is_guard(next):
		lines += "\n\nNext: the floor's guard, with extra gold.\nIts clear bonus is doubled: +%d." % s.clear_bonus_at(next)
	else:
		lines += "\n\nWave %d marches faster and starts lower.\nIts clear bonus is +%d." % [Floors.wave_in_floor(next), s.clear_bonus_at(next)]
	_between_lines.text = lines
	_cash.text = "Cash out %d" % s.tray
	if s.floor_cleared() and not s.broke_house():
		_ride.text = "Ride down to %s" % Floors.floor_name(f + 1).to_lower()
	elif s.broke_house():
		_ride.text = "Stay for After Hours"
	else:
		_ride.text = "Let it ride: wave %d" % Floors.wave_in_floor(next) if f <= Tune.FLOORS else "Let it ride: wave %d" % next
	_ride.visible = s.can_ride()
	_show_cashier(s)
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
	_end_board = VBoxContainer.new()
	_end_board.add_theme_constant_override(&"separation", 2)
	_end_board.visible = false
	v.add_child(_end_board)
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
	# The best-fitting other game, one tap away from every result.
	_end_more = Style.button("")
	_end_more.pressed.connect(func() -> void:
		if not games.is_empty():
			promo_pressed.emit(games[0], "end"))
	v.add_child(_end_more)


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
	_end_board.visible = false
	_end_more.visible = not games.is_empty()
	if not games.is_empty():
		var g := games[0]
		_end_more.text = ("Try %s on Steam  ›" if g.platform == "steam" else "Play %s free  ›") % g.title
	_end.visible = true


## The leaderboard under the result, once the site has replied (see Telemetry). `payout`
## and `waves` are this run's, for its own line when it places below the top.
func show_board(board: Dictionary, payout: int, waves: int, practice: bool) -> void:
	for c in _end_board.get_children():
		c.queue_free()
	var daily := str(board.get("mode")) == "daily"
	var head := ("DAILY #%d · TODAY'S TOP CASH-OUTS" % int(board.get("daily", 0))) if daily else "ALL-TIME TOP CASH-OUTS"
	_end_board.add_child(_spacer(6))
	_end_board.add_child(_centered(Style.label(head, 16, Look.CYAN, Look.sans_bold)))
	for r in Telemetry.board_rows(board, payout, waves):
		if r.gap:
			_end_board.add_child(_centered(Style.label("···", 16, Style.MUTED)))
		_end_board.add_child(_board_line(r))
	var total := int(board.get("total", 0))
	var rank: Variant = board.get("rank")
	var foot: String
	if rank != null:
		foot = "You placed #%d of %d" % [int(rank), total]
	elif practice:
		foot = "Practice runs don't place."
	elif payout == 0:
		foot = "Busts don't place."
	else:
		foot = ""
	if total == 0:
		foot = "No cash-outs yet. " + foot
	if foot != "":
		_end_board.add_child(_centered(Style.label(foot.strip_edges(), 16, Style.MUTED)))
	_end_board.visible = true


func _board_line(r: Dictionary) -> HBoxContainer:
	var color: Color = Look.GOLD if r.you else Style.INK
	var h := HBoxContainer.new()
	h.alignment = BoxContainer.ALIGNMENT_CENTER
	h.add_theme_constant_override(&"separation", 14)
	var cells := [["#%d" % r.place, 52, HORIZONTAL_ALIGNMENT_RIGHT], ["%d" % r.payout, 72, HORIZONTAL_ALIGNMENT_RIGHT],
		["%d wave%s" % [r.waves, "" if r.waves == 1 else "s"], 92, HORIZONTAL_ALIGNMENT_LEFT],
		["◀ you" if r.you else "", 56, HORIZONTAL_ALIGNMENT_LEFT]]
	for c in cells:
		var l := Style.label(c[0], 18, color, Look.sans_bold if r.you else null)
		l.custom_minimum_size = Vector2(c[1], 0)
		l.horizontal_alignment = c[2]
		h.add_child(l)
	return h


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


# --- more from Twinspear ------------------------------------------------------------

func _build_more() -> void:
	_shade(_more, 0.78)
	var v := _panel(_more, Look.CYAN)
	v.add_child(_centered(Style.label("MORE FROM TWINSPEAR", 34, Look.CYAN, Look.display)))
	v.add_child(_centered(Style.label("Other games from the same small studio.", 19, Style.MUTED)))
	_more_scroll = ScrollContainer.new()
	_more_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	v.add_child(_more_scroll)
	_more_list = VBoxContainer.new()
	_more_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_more_list.add_theme_constant_override(&"separation", 12)
	_more_scroll.add_child(_more_list)
	var back := Style.button("Back", Look.CYAN, true)
	back.pressed.connect(show_menu_panel)
	v.add_child(back)


func show_more() -> void:
	for c in _more_list.get_children():
		c.queue_free()
	for g in games:
		var steam: bool = g.platform == "steam"
		var card := _card(_more_list, Look.GOLD if steam else Look.CYAN)
		card.add_child(Style.label(g.title, 28, Look.GOLD if steam else Look.CYAN, Look.display))
		var where := "On Steam" if steam else ("Free in your browser" if g.free else "In your browser")
		card.add_child(Style.label(where, 17, Style.FAINT, Look.sans_bold))
		var pitch := Style.label(g.pitch, 19, Style.MUTED)
		pitch.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		card.add_child(pitch)
		var go := Style.button(MoreGames.call_to_action(g), Look.GOLD if steam else Look.CYAN, true)
		go.pressed.connect(func() -> void: promo_pressed.emit(g, "menu"))
		card.add_child(go)
	_menu.visible = false
	_more.visible = true
	_more_scroll.scroll_vertical = 0


## Back from the list to the title menu.
func show_menu_panel() -> void:
	_more.visible = false
	_records.visible = false
	_menu.visible = true


# --- challenges and records ---------------------------------------------------------

## The lamp colour for one daily: gold for a cash-out, red for a bust, dim when
## unplayed.
static func daily_lamp(d: Dictionary) -> Color:
	if not d.played:
		return Color(Style.FAINT, 0.18)
	return Look.GOLD if d.payout > 0 else Look.RED


func _fill_strip(today: int) -> void:
	for c in _daily_strip.get_children():
		c.queue_free()
	var history := Profile.daily_history(today)
	_daily_strip.visible = history.any(func(d: Dictionary) -> bool: return d.played)
	for d in history:
		var lamp := Panel.new()
		lamp.custom_minimum_size = Vector2(16, 16)
		var box := StyleBoxFlat.new()
		box.bg_color = daily_lamp(d)
		box.set_corner_radius_all(8)
		if d.number == today:
			box.border_color = Style.INK
			box.set_border_width_all(2)
		lamp.add_theme_stylebox_override(&"panel", box)
		lamp.tooltip_text = _history_line(d)
		_daily_strip.add_child(lamp)


## "#21 · cashed out 812 · the Dice Pit".
static func _history_line(d: Dictionary) -> String:
	if not d.played:
		return "#%d · not played" % d.number
	var res := "cashed out %d" % d.payout if d.payout > 0 else ("bust" if d.outcome != "empty" else "ran dry")
	var where := ""
	if d.floor > 0:
		where = " · %s" % ("broke the Vault" if d.payout > 0 and d.waves >= Tune.VAULT_WAVE else Floors.in_sentence(d.floor))
	return "#%d · %s%s" % [d.number, res, where]


func _build_records() -> void:
	_shade(_records, 0.78)
	var v := _panel(_records, Look.GOLD)
	v.add_child(_centered(Style.label("RECORDS", 34, Look.GOLD, Look.display)))
	_records_head = _centered(Style.label("", 19, Style.MUTED))
	v.add_child(_records_head)
	_records_scroll = ScrollContainer.new()
	_records_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	v.add_child(_records_scroll)
	_records_list = VBoxContainer.new()
	_records_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_records_list.add_theme_constant_override(&"separation", 8)
	_records_scroll.add_child(_records_list)
	var back := Style.button("Back", Look.GOLD, true)
	back.pressed.connect(show_menu_panel)
	v.add_child(back)


func show_records() -> void:
	for c in _records_list.get_children():
		c.queue_free()
	var today := Daily.today_number()
	_records_head.text = "%d comp points · %d of %d challenges" % [Profile.comps, Profile.challenges.size(), Challenges.ORDER.size()]
	var streak := Profile.daily_streak(today)
	if streak > 1:
		_records_head.text += " · daily streak %d" % streak
	_records_list.add_child(Style.label("CHALLENGES", 18, Look.CYAN, Look.sans_bold))
	for id in Challenges.ORDER:
		var done := Profile.challenges.has(id)
		var h := HBoxContainer.new()
		h.add_theme_constant_override(&"separation", 10)
		var mark := Style.label("✓" if done else "·", 22, Look.GREEN if done else Style.FAINT, Look.sans_bold)
		mark.custom_minimum_size = Vector2(22, 0)
		h.add_child(mark)
		var text := VBoxContainer.new()
		text.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		text.add_theme_constant_override(&"separation", 0)
		text.add_child(Style.label(Challenges.name_of(id), 19, Style.INK if done else Style.MUTED, Look.sans_bold))
		var what := Style.label(Challenges.ALL[id].text, 16, Style.MUTED)
		what.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		text.add_child(what)
		h.add_child(text)
		h.add_child(Style.label("+%d" % Challenges.comps_of(id), 18, Look.GOLD if not done else Style.FAINT, Look.sans_bold))
		_records_list.add_child(h)
	_records_list.add_child(_spacer(6))
	_records_list.add_child(Style.label("LAST 14 DAILIES", 18, Look.CYAN, Look.sans_bold))
	var history := Profile.daily_history(today)
	history.reverse()
	for d in history:
		var line := Style.label(_history_line(d), 17, daily_lamp(d) if d.played else Style.FAINT)
		_records_list.add_child(line)
	_menu.visible = false
	_records.visible = true
	_records_scroll.scroll_vertical = 0


func is_more_shown() -> bool:
	return _more.visible


## Fetches the blog's games list; the bundled copy stays if it fails.
func fetch_games() -> void:
	var req := HTTPRequest.new()
	req.timeout = 8.0
	add_child(req)
	req.request_completed.connect(func(result: int, code: int, _h: PackedStringArray, body: PackedByteArray) -> void:
		req.queue_free()
		if result != HTTPRequest.RESULT_SUCCESS or code != 200:
			return
		var fresh := MoreGames.parse(body.get_string_from_utf8())
		if not fresh.is_empty():
			games = MoreGames.ranked(fresh))
	if req.request(MoreGames.FEED) != OK:
		req.queue_free()


# --- sizing ----------------------------------------------------------------------

func _on_resized() -> void:
	var size := get_viewport().get_visible_rect().size
	var w := minf(size.x - 40.0, 640.0)
	for p in _panels:
		p.custom_minimum_size.x = w
	_rules_art.custom_minimum_size.x = w - 60.0
	_rules_text.custom_minimum_size.x = w - 60.0
	_more_scroll.custom_minimum_size = Vector2(w - 60.0, minf(size.y * 0.62, 900.0))
	_records_scroll.custom_minimum_size = Vector2(w - 60.0, minf(size.y * 0.62, 900.0))
