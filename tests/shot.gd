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
	main.ui.show_rules()
	await _shot("02-rules")
	main.ui._rules_show(2)
	await _wait(0.6)
	await _shot("03-rules-pins")
	main.ui._rules_show(3)
	await _wait(1.6)
	await _shot("04-rules-reels")
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
	get_tree().quit()
