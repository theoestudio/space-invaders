extends Node2D
## Game flow: the attract demo behind the menu, arcade and daily runs, the cash-out
## choice between waves and the result. Owns the Sim; Stage draws it and GameUI
## frames it.

enum Mode { MENU, ARCADE, DAILY }

const SITE := "pachinko.twinspear.com"

var stage := Stage.new()
var ui := GameUI.new()
var sky := ColorRect.new()

var mode := Mode.MENU
var sim: Sim
var daily_number := 0
var practice := false
var paused := false
var _demo_bot: Autopilot
var _rng := RandomNumberGenerator.new()
var _finished := false
## This run's challenge watcher, and the challenges it met for the first time ever.
var _tracker := Challenges.Tracker.new()
var _met_run: Array[StringName] = []
## The finished run was a daily replay, which does not place.
var _board_practice := false
var _fever_on := false
var _sky_nebula: Color = Look.FLOOR_THEMES[0].nebula
var _sky_mist: Color = Look.FLOOR_THEMES[0].mist
## When set (screenshot harness), plays the run instead of the keyboard and pointer.
var autopilot: Autopilot = null


func _ready() -> void:
	_rng.randomize()
	var back := CanvasLayer.new()
	back.layer = -1
	add_child(back)
	var sm := ShaderMaterial.new()
	sm.shader = preload("res://shaders/starfield.gdshader")
	sky.material = sm
	sky.set_anchors_preset(Control.PRESET_FULL_RECT)
	sky.mouse_filter = Control.MOUSE_FILTER_IGNORE
	back.add_child(sky)
	add_child(stage)
	add_child(ui)
	ui.daily_pressed.connect(start_daily)
	ui.arcade_pressed.connect(start_arcade)
	ui.menu_pressed.connect(show_menu)
	ui.again_pressed.connect(_again)
	ui.share_pressed.connect(_share)
	ui.cash_pressed.connect(_cash_out)
	ui.ride_pressed.connect(_ride)
	ui.buy_pressed.connect(_buy)
	ui.sell_pressed.connect(_sell)
	ui.reroll_pressed.connect(_reroll)
	ui.resume_pressed.connect(func() -> void: set_paused(false))
	ui.rules_closed.connect(_on_rules_closed)
	ui.promo_pressed.connect(_promo)
	ui.fetch_games()
	Telemetry.board_received.connect(_on_board)
	stage.pause_pressed.connect(func() -> void: set_paused(true))
	get_viewport().size_changed.connect(_on_resized)
	_on_resized()
	show_menu()


func _on_resized() -> void:
	var size := get_viewport().get_visible_rect().size
	(sky.material as ShaderMaterial).set_shader_parameter(&"aspect", size.x / maxf(size.y, 1.0))


func show_menu() -> void:
	mode = Mode.MENU
	paused = false
	_finished = false
	_new_demo()
	ui.show_menu()
	Sfx.set_fever(false)
	Sfx.music_for(&"lounge")


func _apply_sky(floor_num: int, instant: bool, delta := 0.0) -> void:
	var th := Look.floor_theme(floor_num)
	if instant:
		_sky_nebula = th.nebula
		_sky_mist = th.mist
	else:
		var k := clampf(delta * 7.0, 0.0, 1.0)
		_sky_nebula = _sky_nebula.lerp(th.nebula, k)
		_sky_mist = _sky_mist.lerp(th.mist, k)
	var sm := sky.material as ShaderMaterial
	sm.set_shader_parameter(&"nebula_col", Vector3(_sky_nebula.r, _sky_nebula.g, _sky_nebula.b))
	sm.set_shader_parameter(&"mist_col", Vector3(_sky_mist.r, _sky_mist.g, _sky_mist.b))


func _new_demo() -> void:
	sim = Sim.create(_rng.randi())
	_demo_bot = Autopilot.new(0.85, _rng.randi())
	stage.show_sim(sim, true)
	_apply_sky(sim.floor_number(), true)


func start_arcade() -> void:
	mode = Mode.ARCADE
	practice = false
	_begin(Sim.create(_rng.randi()))


func start_daily() -> void:
	mode = Mode.DAILY
	daily_number = Daily.today_number()
	practice = Profile.has_daily(daily_number)
	_begin(Daily.create(daily_number))


func _again() -> void:
	if mode == Mode.DAILY:
		start_daily()
	else:
		start_arcade()


func _begin(s: Sim) -> void:
	Sfx.music_for(&"run")
	sim = s
	_finished = false
	_tracker = Challenges.Tracker.new()
	_met_run.clear()
	stage.show_sim(sim, false)
	_apply_sky(sim.floor_number(), true)
	stage.release_pointer()
	ui.show_game()
	if not Profile.seen_rules:
		paused = true
		ui.show_rules()
	else:
		paused = false
		_wave_banner()


func _on_rules_closed() -> void:
	if mode == Mode.MENU:
		return
	if ui.is_paused_shown():
		return
	if paused and not _finished and not ui.is_between_shown():
		paused = false
		_wave_banner()


func _wave_banner() -> void:
	var label := "Daily #%d" % daily_number if mode == Mode.DAILY else "Arcade"
	if mode == Mode.DAILY and practice:
		label += " · practice"
	var f := sim.floor_number()
	if f > Tune.FLOORS:
		if sim.wave == Tune.VAULT_WAVE + 1:
			ui.banner("AFTER HOURS", "endless, mixed floors · %s" % label, 1.3, Look.PINK)
		else:
			ui.banner("WAVE %d" % sim.wave, "After Hours · %s" % label, 0.9)
	elif sim.wave_in_floor() == 1:
		ui.banner(Floors.floor_name(f).to_upper(), "floor %d of %d · %s" % [f, Tune.FLOORS, label], 1.3, Look.CYAN)
	elif Floors.is_guard(sim.wave):
		ui.banner("FLOOR GUARD", "double clear bonus · %s" % label, 1.1, Look.PINK)
	else:
		ui.banner("WAVE %d" % sim.wave_in_floor(), "%s · %s" % [Floors.floor_name(f), label], 0.9)


func set_paused(on: bool) -> void:
	if mode == Mode.MENU or _finished or ui.is_between_shown():
		return
	paused = on
	stage.release_pointer()
	ui.show_pause(on)


func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_FOCUS_OUT and mode != Mode.MENU and not paused:
		set_paused(true)


func _unhandled_input(event: InputEvent) -> void:
	if not (event is InputEventKey and event.pressed and not event.echo):
		return
	var key: Key = event.keycode
	if mode == Mode.MENU:
		return
	if ui.is_between_shown():
		if key == KEY_C:
			_cash_out()
		elif key == KEY_R or key == KEY_ENTER:
			_ride()
		elif key >= KEY_1 and key < KEY_1 + Fixtures.OFFERS:
			_buy(key - KEY_1)
		elif key == KEY_X:
			_reroll()
		return
	if key == KEY_ESCAPE or key == KEY_P:
		if ui.is_rules_shown():
			ui.hide_rules()
		else:
			set_paused(not paused)


func _input_state() -> Dictionary:
	var move := 0.0
	if Input.is_key_pressed(KEY_LEFT) or Input.is_key_pressed(KEY_A):
		move -= 1.0
	if Input.is_key_pressed(KEY_RIGHT) or Input.is_key_pressed(KEY_D):
		move += 1.0
	var jx := Input.get_joy_axis(0, JOY_AXIS_LEFT_X)
	if absf(jx) > 0.25:
		move += jx
	if Input.is_joy_button_pressed(0, JOY_BUTTON_DPAD_LEFT):
		move -= 1.0
	if Input.is_joy_button_pressed(0, JOY_BUTTON_DPAD_RIGHT):
		move += 1.0
	var fire := Input.is_key_pressed(KEY_SPACE) or Input.is_key_pressed(KEY_UP) or Input.is_key_pressed(KEY_W) \
		or Input.is_key_pressed(KEY_Z) or Input.is_joy_button_pressed(0, JOY_BUTTON_A) or Input.is_joy_button_pressed(0, JOY_BUTTON_RIGHT_SHOULDER)
	var target := NAN
	if stage.pointer_down and move == 0.0:
		target = stage.pointer_x
		fire = true
	return {move = clampf(move, -1.0, 1.0), target = target, fire = fire}


func _physics_process(_delta: float) -> void:
	if sim == null:
		return
	if mode == Mode.MENU:
		_demo_step()
		return
	if paused or _finished:
		return
	var i := autopilot.decide(sim) if autopilot else _input_state()
	sim.step(i.move, i.target, i.fire)
	stage.consume(sim.events)
	_meet(_tracker.feed(sim))
	var fever := sim.fever_t > 0.0
	if fever != _fever_on:
		_fever_on = fever
		Sfx.set_fever(fever)
	(sky.material as ShaderMaterial).set_shader_parameter(&"fever", 1.0 if fever else 0.0)
	_apply_sky(sim.floor_number(), false, _delta)
	for e in sim.events:
		match e.kind:
			&"clear":
				if Floors.is_guard(sim.wave):
					ui.banner("FLOOR %d CLEARED" % sim.floor_number(), "clear bonus +%d" % e.bonus, 1.2, Look.GREEN)
				else:
					ui.banner("WAVE CLEARED", "clear bonus +%d" % e.bonus, 1.0, Look.GREEN)
			&"broke_house":
				ui.banner("YOU BROKE THE HOUSE", "the tray doubles", 1.8, Look.GOLD)
			&"settled":
				stage.release_pointer()
				ui.show_between(sim)
			&"prize":
				if e.prize == "fever":
					ui.banner("FEVER", "free rapid fire · the attacker is open", 1.3, Look.PINK)
			&"bust":
				_finish()


func _demo_step() -> void:
	var d := _demo_bot.decide(sim)
	sim.step(d.move, d.target, d.fire)
	stage.consume(sim.events)
	if sim.phase == Sim.Phase.SETTLED:
		if sim.wave >= 4:
			_new_demo()
		else:
			sim.next_wave()
	elif sim.is_over():
		_new_demo()


func _ride() -> void:
	if sim.phase != Sim.Phase.SETTLED:
		return
	Sfx.play(&"start")
	ui.hide_between()
	var prev_f := sim.floor_number()
	sim.next_wave()
	if sim.floor_number() != prev_f:
		stage.play_elevator(prev_f, sim.floor_number())
	_wave_banner()


func _buy(i: int) -> void:
	if sim.buy(i):
		Sfx.play(&"select", 0.8)
		_meet(_tracker.shopped(sim))
		ui.show_between(sim)


func _sell(id: StringName) -> void:
	if sim.sell(id):
		Sfx.play(&"select", 0.6)
		ui.show_between(sim)


func _reroll() -> void:
	if sim.reroll():
		Sfx.play(&"select", 1.2)
		ui.show_between(sim)


func _cash_out() -> void:
	if sim.phase != Sim.Phase.SETTLED:
		return
	ui.hide_between()
	sim.cash_out()
	Sfx.play(&"cashout")
	_finish()


## Challenges the tracker reports: the ones never met before pay comps, show a toast
## and are listed on the result.
func _meet(ids: Array[StringName]) -> void:
	if ids.is_empty():
		return
	for id in Profile.record_challenges(ids, Daily.today_number()):
		_met_run.append(id)
		ui.toast("Challenge met: %s · +%d comps" % [Challenges.name_of(id), Challenges.comps_of(id)])


func _cleared() -> int:
	return sim.stats.waves.size() - (1 if sim.phase == Sim.Phase.BUST else 0)


func _finish() -> void:
	if _finished:
		return
	_finished = true
	_fever_on = false
	Sfx.set_fever(false)
	Sfx.music_for(&"lounge")
	stage.release_pointer()
	var cashed := sim.phase == Sim.Phase.CASHED
	var payout := sim.payout()
	var cleared := _cleared()
	_meet(_tracker.finish(sim))
	var title := ("BROKE THE HOUSE" if sim.broke_house() else "CASHED OUT") if cashed else "BUST"
	var color := Look.GOLD if cashed else Look.RED
	var sub: String
	var where := _where()
	if cashed:
		sub = "%d balls after %d wave%s, %s" % [payout, cleared, "" if cleared == 1 else "s", where]
	elif sim.bust_reason == "invaded":
		sub = "The House reached your rail %s.\nIt keeps the tray." % where
	else:
		sub = "Out of balls %s." % where
	var st := sim.stats
	var acc: float = 100.0 * st.kills / maxf(st.shots, 1.0)
	var stats := "%d broken · %d%% accuracy · peak tray %d\n%d pocketed · %d caught · %d spins · %d fever%s" % [
		st.kills, roundi(acc), st.peak, st.pocketed, st.caught, st.spins, st.fevers, "" if st.fevers == 1 else "s"]
	if not _met_run.is_empty():
		stats += "\n\nChallenges: %s" % ", ".join(_met_run.map(func(id: StringName) -> String:
			return "%s +%d" % [Challenges.name_of(id), Challenges.comps_of(id)]))
	var nets: Array = st.waves
	if mode == Mode.DAILY:
		var official := not practice and Profile.record_daily(daily_number, {
			payout = payout, waves = cleared, outcome = "cashed" if cashed else sim.bust_reason, nets = nets.duplicate(),
			floor = sim.floor_number()})
		var totals := Profile.daily_totals()
		var streak := Profile.daily_streak(daily_number)
		stats += "\n\nDaily runs cashed: %d of %d · best %d" % [totals.cashed, totals.played, totals.best]
		if streak > 1:
			stats += " · streak %d" % streak
		if not official:
			stats += "\nPractice run: your first result today stands."
		ui.show_end(title, color, sub, stats, nets, not cashed, true, "Replay")
		_board_practice = not official
		Telemetry.run_finished("daily", sim, official, daily_number)
	else:
		var best := Profile.record_arcade(payout, cleared, cashed)
		if best and payout > 0:
			stats += "\n\nNew best payout!"
		else:
			stats += "\n\nBest payout %d" % int(Profile.arcade.best)
		ui.show_end(title, color, sub, stats, nets, not cashed, false, "Play again")
		_board_practice = false
		Telemetry.run_finished("arcade", sim, true)


## Where the run ended, for the result: "in the Dice Pit, wave 2".
func _where() -> String:
	var f := sim.floor_number()
	if f > Tune.FLOORS:
		return "After Hours, wave %d" % sim.wave
	if sim.broke_house():
		return "with the Vault broken"
	return "in %s, %s" % [Floors.in_sentence(f), "its guard" if Floors.is_guard(sim.wave) else "wave %d" % sim.wave_in_floor()]


## The site's reply to the finished run: the leaderboard, under the result.
func _on_board(board: Dictionary) -> void:
	if _finished and sim:
		ui.show_board(board, sim.payout(), _cleared(), _board_practice)


## The spoiler-free daily result: the official run if there is one, else this one.
## A "More from Twinspear" game tapped: count it, then open it. On the web the link opens
## in a new tab, so the run here is still waiting when the player comes back.
func _promo(game: Dictionary, where: String) -> void:
	Telemetry.promo(game.id, where)
	OS.shell_open(MoreGames.link(game, where))


func _share() -> void:
	var r: Dictionary = Profile.daily.get(daily_number, {})
	var nets: Array = r.get("nets", sim.stats.waves)
	var payout: int = r.get("payout", sim.payout())
	var outcome: String = r.get("outcome", "cashed" if sim.phase == Sim.Phase.CASHED else sim.bust_reason)
	var cells := ""
	for i in nets.size():
		var bust := outcome != "cashed" and i == nets.size() - 1
		var net := int(nets[i])
		cells += "💥" if bust else ("🟩" if net >= 30 else ("🟨" if net > 0 else "🟪"))
	var tail := "💰 %d" % payout if outcome == "cashed" else "bust"
	var text := "Pachinko Descent #%d\n%s %s\n%s" % [daily_number, cells, tail, SITE]
	DisplayServer.clipboard_set(text)
	ui.toast("Result copied")
