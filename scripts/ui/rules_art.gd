class_name RulesArt
extends Control
## The small picture above each How to Play page, drawn with the game's own sprites.

var page := 0
var _t := 0.0


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func _process(delta: float) -> void:
	if is_visible_in_tree():
		_t += delta
		queue_redraw()


func _draw() -> void:
	var c := size / 2.0
	var frame := int(_t * 2.0) % 2
	match page:
		0:
			for i in 5:
				var kind: int = [Sim.Kind.CARD, Sim.Kind.DIE, Sim.Kind.CHIP, Sim.Kind.DIE, Sim.Kind.CARD][i]
				Sprites.invader(self, c + Vector2(-120 + i * 60, -40), kind, i == 2, frame, 9.0, 2, i)
			draw_line(c + Vector2(-200, 26), c + Vector2(200, 26), Color(Look.RED, 0.5), 2.0)
			var x := sin(_t * 1.5) * 90.0
			draw_line(c + Vector2(x, 34), c + Vector2(x, -10), Look.CYAN, 4.0, true)
			Sprites.ship(self, c.x + x, c.y + 62, cos(_t * 1.5), Tune.TRAY_HALF, false, false, false)
		1:
			Sprites.ball(self, c + Vector2(-60, -10), false)
			Look.text(self, c + Vector2(30, 6), "= 1 SHOT", 26, Look.INK)
			Sprites.ship(self, c.x - 60, c.y + 60, 0.0, Tune.TRAY_HALF, false, int(_t * 6.0) % 2 == 0, false)
			Look.text(self, c + Vector2(40, 72), "HIT  -12", 26, Look.RED)
		2:
			for row in 3:
				for col in 7:
					Sprites.pin(self, c + Vector2(-150 + col * 50 + (25 if row % 2 else 0), -50 + row * 34))
			var y := fmod(_t * 90.0, 140.0) - 70.0
			var kinds := [Board.Pocket.SIDE, Board.Pocket.START, Board.Pocket.TULIP]
			var cols: Array[Color] = [Look.CYAN, Look.GREEN, Look.PINK]
			for i in 3:
				var pk := {kind = kinds[i], pos = c + Vector2(-140 + i * 140, 50), half = 14.0, open = i == 2}
				Sprites.pocket_back(self, pk, 1.0 if i == 2 else 0.0)
			Sprites.ball(self, c + Vector2(sin(_t * 5.0) * 18.0, y), int(_t / 1.55) % 3 == 0)
			for i in 3:
				var p := c + Vector2(-140 + i * 140, 50)
				var pk := {kind = kinds[i], pos = p, half = 14.0, open = i == 2}
				Sprites.pocket_front(self, pk, 1.0 if i == 2 else 0.0, _t, 0.2)
				Look.text(self, p + Vector2(0, 34), ["+2", "+3 SPIN", "+5"][i], 16, cols[i])
		3:
			if not Art.draw(self, &"reel_drums", c, Vector2(220, 96)):
				var r := Rect2(c - Vector2(110, 46), Vector2(220, 92))
				draw_rect(r.grow(5), Color(0.55, 0.58, 0.68))
				draw_rect(r, Color(0.015, 0.01, 0.03))
			for i in 3:
				var sym := Reels.Sym.SEVEN if fmod(_t, 3.0) > 1.0 + i * 0.5 else (int(_t * 10.0) + i) % Reels.COUNT
				Sprites.symbol(self, c + Vector2(-72 + i * 72, 0), sym, 1.0)
			Art.draw(self, &"reel_frame", c, Vector2(256, 128))
		4:
			var icons := [&"fix_bent_nail", &"fix_twin_barrel", &"fix_deep_cup", &"fix_insurance"]
			var cols := [Look.GREEN, Look.CYAN, Look.GOLD, Look.PINK]
			var sel := int(_t * 1.4) % icons.size()
			for i in icons.size():
				var pos := c + Vector2(-132.0 + i * 88.0, -48.0)
				var r := Rect2(pos - Vector2(26, 26), Vector2(52, 52))
				var active := i == sel
				Look.rounded(self, r, 10, Color(0.06, 0.05, 0.14, 0.92))
				Look.rounded(self, r, 10, Color(cols[i], 0.95 if active else 0.42), false, 2.2 if active else 1.5)
				Art.draw(self, icons[i], pos, Vector2(40, 40) * (1.08 if active else 1.0))
			for i in Tune.FLOORS:
				var th := Look.floor_theme(i + 1)
				var fr := Rect2(c + Vector2(-120.0 + i * 50.0, -4.0), Vector2(40, 22))
				var pulse := int(_t * 1.6) % Tune.FLOORS == i
				Look.rounded(self, fr, 6, Color(th.edge, 0.30 if pulse else 0.14))
				Look.rounded(self, fr, 6, Color(th.edge, 0.95 if pulse else 0.55), false, 1.5)
				Look.text(self, fr.position + Vector2(0, 16), str(i + 1), 13, Look.GOLD if i == Tune.FLOORS - 1 else Look.INK, Look.display, HORIZONTAL_ALIGNMENT_CENTER, 40.0)
			Look.text(self, c + Vector2(-120, 48), "CASH OUT", 24, Look.GOLD)
			Look.text(self, c + Vector2(-120, 70), "keep the tray", 14, Look.MUTED, Look.sans)
			Look.text(self, c + Vector2(120, 48), "RIDE DOWN", 24, Look.PINK)
			Look.text(self, c + Vector2(120, 70), "buy fixtures · 5 floors", 14, Look.MUTED, Look.sans)
		5:
			for i in 7:
				var col := GameUI.wave_color([40, 25, 60, -12, 38, 50, 20][i], false)
				var on := int(_t * 2.0) % 7 >= i
				draw_rect(Rect2(c + Vector2(-118 + i * 34, -20), Vector2(26, 26)), col if on else Color(col, 0.2))
			Look.text(self, c + Vector2(0, 50), "same run for everyone, every day", 18, Look.MUTED, Look.sans)
