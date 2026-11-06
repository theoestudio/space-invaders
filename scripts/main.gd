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
var _fever_on := false
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
	ui.resume_pressed.connect(func() -> void: set_paused(false))
	ui.rules_closed.connect(_on_rules_closed)
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


func _new_demo() -> void:
	sim = Sim.create(_rng.randi())
	_demo_bot = Autopilot.new(0.85, _rng.randi())
	stage.show_sim(sim, true)


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
	sim = s
	_finished = false
	stage.show_sim(sim, false)
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
	ui.banner("WAVE %d" % sim.wave, label, 0.9)


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
	var fever := sim.fever_t > 0.0
	if fever != _fever_on:
		_fever_on = fever
		Sfx.set_fever(fever)
	(sky.material as ShaderMaterial).set_shader_parameter(&"fever", 1.0 if fever else 0.0)
	for e in sim.events:
		match e.kind:
			&"clear":
				ui.banner("WAVE %d CLEARED" % sim.wave, "clear bonus +%d" % e.bonus, 1.0, Look.GREEN)
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
	sim.next_wave()
	_wave_banner()


func _cash_out() -> void:
	if sim.phase != Sim.Phase.SETTLED:
		return
	ui.hide_between()
	sim.cash_out()
	Sfx.play(&"cashout")
	_finish()


func _cleared() -> int:
	return sim.stats.waves.size() - (1 if sim.phase == Sim.Phase.BUST else 0)


func _finish() -> void:
	if _finished:
		return
	_finished = true
	_fever_on = false
	Sfx.set_fever(false)
	stage.release_pointer()
	var cashed := sim.phase == Sim.Phase.CASHED
	var payout := sim.payout()
	var cleared := _cleared()
	var title := "CASHED OUT" if cashed else "BUST"
	var color := Look.GOLD if cashed else Look.RED
	var sub: String
	if cashed:
		sub = "%d balls after %d wave%s" % [payout, cleared, "" if cleared == 1 else "s"]
	elif sim.bust_reason == "invaded":
		sub = "The House reached your rail on wave %d.\nIt keeps the tray." % sim.wave
	else:
		sub = "Out of balls on wave %d." % sim.wave
	var st := sim.stats
	var acc: float = 100.0 * st.kills / maxf(st.shots, 1.0)
	var stats := "%d broken · %d%% accuracy · peak tray %d\n%d pocketed · %d caught · %d spins · %d fever%s" % [
		st.kills, roundi(acc), st.peak, st.pocketed, st.caught, st.spins, st.fevers, "" if st.fevers == 1 else "s"]
	var nets: Array = st.waves
	if mode == Mode.DAILY:
		var official := not practice and Profile.record_daily(daily_number, {
			payout = payout, waves = cleared, outcome = "cashed" if cashed else sim.bust_reason, nets = nets.duplicate()})
		var totals := Profile.daily_totals()
		var streak := Profile.daily_streak(daily_number)
		stats += "\n\nDaily runs cashed: %d of %d · best %d" % [totals.cashed, totals.played, totals.best]
		if streak > 1:
			stats += " · streak %d" % streak
		if not official:
			stats += "\nPractice run: your first result today stands."
		ui.show_end(title, color, sub, stats, nets, not cashed, true, "Replay")
		Telemetry.run_finished("daily", sim, official)
	else:
		var best := Profile.record_arcade(payout, cleared, cashed)
		if best and payout > 0:
			stats += "\n\nNew best payout!"
		else:
			stats += "\n\nBest payout %d" % int(Profile.arcade.best)
		ui.show_end(title, color, sub, stats, nets, not cashed, false, "Play again")
		Telemetry.run_finished("arcade", sim, true)


## The spoiler-free daily result: the official run if there is one, else this one.
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
