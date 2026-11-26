extends SceneTree
## Balance check: the autopilot plays whole runs headless, always letting it ride,
## and this prints how far each skill level gets, how the tray moves per wave and
## what each cash-out policy would have paid. With "shop" the autopilot buys at
## each cashier (Autopilot.shop), and a second pass plays the same runs cashing out
## when the autopilot would (Autopilot.ride) to show where its runs end.
##   godot --headless --script tests/selfplay.gd -- [runs] [max_wave] [shop|none] [skill,skill]

const SKILLS := [0.4, 0.7, 0.95]


func _init() -> void:
	var args := OS.get_cmdline_user_args()
	var runs := int(args[0]) if args.size() > 0 else 24
	var max_wave := int(args[1]) if args.size() > 1 else 10
	var shop := args.size() > 2 and args[2] == "shop"
	var skills: Array = Array(args[3].split(",")).map(func(x: String) -> float: return float(x)) if args.size() > 3 else SKILLS
	for skill: float in skills:
		_report(skill, runs, max_wave, shop)
	quit()


func _report(skill: float, runs: int, max_wave: int, shop: bool) -> void:
	var t0 := Time.get_ticks_msec()
	## trays[k] = tray after wave k+1 settled, per run (0 when it never got there).
	var trays := []
	trays.resize(max_wave)
	for k in max_wave:
		trays[k] = []
	var reached := PackedInt32Array()
	var busts := {invaded = 0, empty = 0, survived = 0}
	var wave_secs := []
	var acc := Vector2()
	var spins := 0
	var fevers := 0
	var hits := 0
	var pocketed := 0
	var caught := 0
	var drained := 0
	var bought := {}
	for r in runs:
		var s := Sim.create(1000 + r)
		var bot := Autopilot.new(skill, 77 + r)
		var wave_t := 0.0
		while not s.is_over():
			var d := bot.decide(s)
			s.step(d.move, d.target, d.fire)
			wave_t += Tune.STEP
			if s.phase == Sim.Phase.SETTLED:
				trays[s.wave - 1].append(s.tray)
				wave_secs.append(wave_t)
				wave_t = 0.0
				if shop:
					for id in bot.shop(s):
						bought[id] = bought.get(id, 0) + 1
				if s.wave >= max_wave or not s.can_ride():
					s.cash_out()
				else:
					s.next_wave()
			if s.time > 3600.0:
				break
		var cleared: int = s.stats.waves.size() - (1 if s.phase == Sim.Phase.BUST else 0)
		for k in range(cleared, max_wave):
			trays[k].append(0)
		reached.append(cleared)
		if s.phase == Sim.Phase.BUST:
			busts[s.bust_reason] += 1
		else:
			busts.survived += 1
		acc += Vector2(s.stats.kills, s.stats.shots)
		spins += s.stats.spins
		fevers += s.stats.fevers
		hits += s.stats.hits
		pocketed += s.stats.pocketed
		caught += s.stats.caught
		drained += s.stats.drained
	var mean_reached := 0.0
	for n in reached:
		mean_reached += n
	mean_reached /= runs
	print("\n== skill %.2f: %d runs, %.1fs" % [skill, runs, (Time.get_ticks_msec() - t0) / 1000.0])
	print("waves cleared: mean %.2f  busts invaded %d, empty %d, survived to %d: %d" % [
		mean_reached, busts.invaded, busts.empty, max_wave, busts.survived])
	print("accuracy %.0f%%  hits/run %.1f  spins/run %.1f  fevers/run %.2f" % [
		100.0 * acc.x / maxf(acc.y, 1.0), float(hits) / runs, float(spins) / runs, float(fevers) / runs])
	var balls := float(pocketed + caught + drained)
	print("ball fates: pocketed %.0f%%  caught %.0f%%  drained %.0f%%" % [
		100.0 * pocketed / balls, 100.0 * caught / balls, 100.0 * drained / balls])
	var secs := 0.0
	for w: float in wave_secs:
		secs += w
	print("mean wave length %.0fs" % (secs / maxf(wave_secs.size(), 1)))
	if shop:
		var ids := bought.keys()
		ids.sort_custom(func(x: StringName, y: StringName) -> bool: return bought[x] > bought[y])
		print("bought per run: %s" % ", ".join(ids.map(func(id: StringName) -> String: return "%s %.1f" % [id, float(bought[id]) / runs])))
	print("cash out after wave k: survival, mean payout (bust pays 0)")
	for k in max_wave:
		var alive := 0
		var total := 0.0
		for v: int in trays[k]:
			if v > 0:
				alive += 1
			total += v
		print("  %2d  %3.0f%%  %6.1f" % [k + 1, 100.0 * alive / runs, total / runs])
	if shop:
		_policy(skill, runs)


## The same runs, cashing out when the autopilot would: where they end, by floor,
## and what they pay. Also how many runs that reached floor 3 bought each fixture.
func _policy(skill: float, runs: int) -> void:
	var ends := {}
	var paid := 0.0
	var deep := 0
	var owned := {}
	for r in runs:
		var s := Sim.create(1000 + r)
		var bot := Autopilot.new(skill, 77 + r)
		var had := {}
		while not s.is_over():
			var d := bot.decide(s)
			s.step(d.move, d.target, d.fire)
			if s.phase == Sim.Phase.SETTLED:
				for id in bot.shop(s):
					had[id] = true
				if bot.ride(s):
					s.next_wave()
				else:
					s.cash_out()
			if s.time > 3600.0:
				break
		var f := Floors.floor_of(s.wave)
		var key := "%s %s" % ["cashed" if s.phase == Sim.Phase.CASHED else "bust", Floors.floor_name(f)]
		ends[key] = ends.get(key, 0) + 1
		paid += s.payout()
		if f >= 3:
			deep += 1
			for id: StringName in had:
				owned[id] = owned.get(id, 0) + 1
	var keys := ends.keys()
	keys.sort()
	print("autopilot policy: mean payout %.0f; ends %s" % [paid / runs, ", ".join(keys.map(func(k: String) -> String: return "%s %d" % [k, ends[k]]))])
	var ids := owned.keys()
	ids.sort_custom(func(x: StringName, y: StringName) -> bool: return owned[x] > owned[y])
	print("runs reaching floor 3 (%d) that bought: %s" % [deep, ", ".join(ids.map(func(id: StringName) -> String: return "%s %d%%" % [id, 100 * owned[id] / maxi(deep, 1)]))])
