extends SceneTree
## What each fixture is worth: the autopilot plays runs with one fixture given free
## from wave 1 and always rides; prints mean waves cleared and the mean tray after
## waves 4, 8 and 12 (a bust counts 0), against a run with none. Guides the
## autopilot's buy policy (Autopilot.WORTH) and spots a fixture every run wants.
##   godot --headless --script tests/fixture_value.gd -- runs skill [ids...]

func _init() -> void:
	var args := OS.get_cmdline_user_args()
	var runs := int(args[0])
	var skill := float(args[1])
	var ids: Array = args.slice(2) if args.size() > 2 else ["none"] + Fixtures.ORDER.map(func(i: StringName) -> String: return str(i))
	for id: String in ids:
		var at := {4: 0.0, 8: 0.0, 12: 0.0}
		var cleared := 0.0
		for r in runs:
			var s := Sim.create(5000 + r)
			if id != "none":
				s.fixtures[StringName(id)] = 1
				s.start_wave(1)
			var bot := Autopilot.new(skill, 300 + r)
			while not s.is_over() and s.wave <= 16:
				var d := bot.decide(s)
				s.step(d.move, d.target, d.fire)
				if s.phase == Sim.Phase.SETTLED:
					if at.has(s.wave):
						at[s.wave] += s.tray
					if s.wave >= 16:
						s.cash_out()
					else:
						s.next_wave()
			cleared += s.stats.waves.size() - (1 if s.phase == Sim.Phase.BUST else 0)
		print("%-14s skill %.2f  cleared %5.2f  tray@4 %6.1f  @8 %6.1f  @12 %6.1f" % [
			id, skill, cleared / runs, at[4] / runs, at[8] / runs, at[12] / runs])
	quit()
