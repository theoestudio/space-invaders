extends Node
## Screenshot harness for visual review, run under a virtual display:
##   xvfb-run -a godot --rendering-driver opengl3 res://tests/shot.tscn -- OUT_DIR
## (a scene, not --script, so the autoloads exist)
## Drives the real main scene through the menu, rules, an arcade run played by the
## autopilot (with a forced spin, fever, wave clear and cash-out) and a daily bust,
## saving a PNG at each stop. Opens nothing on the real desktop.

var main: Node
var out := "/tmp/pachinko/shots"


func _ready() -> void:
	var args := OS.get_cmdline_user_args()
	if args.size() > 0:
		out = args[0]
	DirAccess.make_dir_recursive_absolute(out)
	Profile.sound = false
	Profile.music = false
	main = load("res://scenes/main.tscn").instantiate()
	get_tree().root.add_child.call_deferred(main)
	_run.call_deferred()


func _frames(n: int) -> void:
	for i in n:
		await get_tree().process_frame


func _wait(t: float) -> void:
	await get_tree().create_timer(t).timeout


func _shot(name: String) -> void:
	await _frames(3)
	var img := get_tree().root.get_texture().get_image()
	img.save_png("%s/%s.png" % [out, name])
	print("shot ", name)


func _run() -> void:
	await _wait(3.0)
	await _shot("01-menu")
	main.ui.show_more()
	await _wait(0.3)
	await _shot("01b-more-games")
	main.ui.show_menu_panel()
	main.ui.show_rules()
	await _shot("02-rules")
	main.ui._rules_show(2)
	await _wait(0.6)
	await _shot("03-rules-pins")
	main.ui._rules_show(3)
	await _wait(1.6)
	await _shot("04-rules-reels")
	main.ui._rules_show(4)
	await _wait(0.8)
	await _shot("04b-rules-cashier")
	main.ui._rules_show(5)
	await _wait(0.4)
	await _shot("04c-rules-pieces")
	main.ui.hide_rules()

	Profile.seen_rules = true
	main.autopilot = Autopilot.new(0.8, 5)
	main.start_arcade()
	var s: Sim = main.sim
	Engine.time_scale = 3.0
	await _wait(14.0)
	Engine.time_scale = 1.0
	await _shot("05-play")
	s.holds = 3
	await _wait(1.0)
	await _shot("06-spin")
	s.spin = {}
	s.holds = 0
	s.last_symbols = PackedInt32Array([Reels.Sym.SEVEN, Reels.Sym.SEVEN, Reels.Sym.SEVEN])
	s._award(Reels.Sym.SEVEN)
	main.ui.banner("FEVER", "free rapid fire · the attacker is open", 1.3, Look.PINK)
	await _wait(1.4)
	await _shot("07-fever")
	Engine.time_scale = 3.0
	while s.phase == Sim.Phase.PLAYING:
		await get_tree().process_frame
	while not main.ui.is_between_shown() and not s.is_over():
		await get_tree().process_frame
	Engine.time_scale = 1.0
	await _wait(0.3)
	await _shot("08-between")
	if main.ui.is_between_shown():
		s.tray += 300
		main._buy(0)
		main._buy(1)
		await _wait(0.3)
		await _shot("08b-bought")
	if main.ui.is_between_shown():
		main._cash_out()
		await _wait(0.5)
	await _shot("09-cashed")
	# The site's reply (only the production build gets one): this run placed below the top.
	main._on_board({mode = "arcade", daily = 0, total = 57, rank = 23.0, top = [
		{payout = 512.0, waves = 9.0}, {payout = 430.0, waves = 8.0}, {payout = 430.0, waves = 7.0},
		{payout = 388.0, waves = 7.0}, {payout = 301.0, waves = 6.0}, {payout = 260.0, waves = 6.0},
		{payout = 244.0, waves = 5.0}, {payout = 230.0, waves = 5.0}, {payout = 199.0, waves = 4.0},
		{payout = 187.0, waves = 4.0}]})
	await _wait(0.3)
	await _shot("09b-cashed-board")

	# Live 6-slot fixture hardware showcase (bent nail x2, deep cup, twin barrel, piercing glint, padded rail, insurance).
	main.start_arcade()
	s = main.sim
	s.fixtures = {&"bent_nail": 2, &"deep_cup": 1, &"twin_barrel": 1, &"piercing_tips": 1, &"padded_rail": 1, &"insurance": 1}
	s._volleys = Fixtures.PIERCE_EVERY - 1
	await _wait(0.5)
	await _shot("08c-fixtures-play")

	# Floor themes, floor guards, elevator dial and the Vault broken.
	for w in [4, 5, 9, 13, Tune.VAULT_WAVE, Tune.VAULT_WAVE + 1]:
		main.start_arcade()
		s = main.sim
		s.start_wave(w)
		if w == 5:
			main.stage.play_elevator(1, 2)
			main._wave_banner()
			await _wait(0.28)
			await _shot("12-elevator-2")
			await _wait(0.65)
		else:
			main._wave_banner()
		await _wait(0.6)
		await _shot("12-floor-%d" % w)
		if w in [4, Tune.VAULT_WAVE]:
			for inv in s.invaders:
				inv.alive = false
			s.boss = null
			while not main.ui.is_between_shown():
				await get_tree().process_frame
			await _wait(0.3)
			await _shot("13-cleared-%d" % w)
			main._cash_out()
			await _wait(0.5)
			await _shot("14-cashed-%d" % w)

	# Each boss a few seconds in.
	for f in Tune.FLOORS:
		main.start_arcade()
		s = main.sim
		s.start_wave((f + 1) * Tune.WAVES_PER_FLOOR)
		main._wave_banner()
		await _wait(2.2)
		await _shot("19-boss-%d" % (f + 1))

	# The new pieces at work: the Wheel Room and the Vault.
	for w in [14, 19]:
		main.start_arcade()
		s = main.sim
		s.start_wave(w)
		await _wait(2.5)
		await _shot("18-pieces-%d" % w)

	# Every formation shape, a moment into the wave.
	for shape in Formations.ALL:
		main.start_arcade()
		s = main.sim
		s.form(shape, Floors.PLANS[3][2])
		await _wait(1.5)
		await _shot("15-shape-%s" % shape)

	main.start_daily()
	s = main.sim
	await _wait(1.0)
	s.origin.y = Tune.INVADED_Y - 4 * Tune.CELL.y - Tune.INVADER_HALF.y - 2.0
	await _wait(1.5)
	await _shot("10-bust")
	main._on_board({mode = "daily", daily = 4, total = 3, rank = null, top = [
		{payout = 212.0, waves = 4.0}, {payout = 96.0, waves = 3.0}, {payout = 36.0, waves = 1.0}]})
	await _wait(0.3)
	await _shot("10b-bust-board")
	main.show_menu()
	await _wait(0.5)
	await _shot("11-menu-after")
	# A player some weeks in: a history strip and a few challenges (not saved).
	var today := Daily.today_number()
	for back in [1, 2, 3, 5, 6, 9, 10, 12]:
		Profile.daily[today - back] = {payout = 0 if back in [3, 9] else 150 + back * 37, waves = 10 - back % 4,
			outcome = "invaded" if back in [3, 9] else "cashed", floor = 1 + back % 4}
	Profile.challenges = {&"card_shark": today - 5, &"hot_streak": today - 2, &"untouchable": today - 1}
	Profile.comps = 140
	main.show_menu()
	await _wait(0.3)
	await _shot("16-menu-history")
	main.ui.show_records()
	await _wait(0.3)
	await _shot("17-records")
	get_tree().quit()
