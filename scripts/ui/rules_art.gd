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
			Sprites.ball(self, c + Vector2(sin(_t * 5.0) * 18.0, y), int(_t / 1.55) % 3 == 0)
			for i in 3:
				var col: Color = [Look.CYAN, Look.GREEN, Look.PINK][i]
				var p := c + Vector2(-140 + i * 140, 62)
				draw_rect(Rect2(p + Vector2(-16, 0), Vector2(32, 10)), Color(0, 0, 0, 0.6))
				draw_rect(Rect2(p + Vector2(-20, 8), Vector2(40, 5)), col)
				Look.text(self, p + Vector2(0, 34), ["+2", "+3 SPIN", "+5"][i], 16, col)
		3:
			var r := Rect2(c - Vector2(110, 46), Vector2(220, 92))
			draw_rect(r.grow(5), Color(0.55, 0.58, 0.68))
			draw_rect(r, Color(0.015, 0.01, 0.03))
			for i in 3:
				var sym := Reels.Sym.SEVEN if fmod(_t, 3.0) > 1.0 + i * 0.5 else (int(_t * 10.0) + i) % Reels.COUNT
				Sprites.symbol(self, c + Vector2(-72 + i * 72, 0), sym, 1.0)
		4:
			Look.text(self, c + Vector2(-130, -10), "CASH OUT", 28, Look.GOLD)
			Look.text(self, c + Vector2(-130, 26), "keep the tray", 16, Look.MUTED, Look.sans)
			Look.text(self, c + Vector2(130, -10), "RIDE", 28, Look.PINK)
			Look.text(self, c + Vector2(130, 26), "bigger bonus, faster House", 16, Look.MUTED, Look.sans)
			for i in 6:
				var col := GameUI.wave_color([40, 25, 60, 12, 38, 0][i], i == 5)
				draw_rect(Rect2(c + Vector2(-100 + i * 34, 50), Vector2(26, 26)), col)
		5:
			for i in 7:
				var col := GameUI.wave_color([40, 25, 60, -12, 38, 50, 20][i], false)
				var on := int(_t * 2.0) % 7 >= i
				draw_rect(Rect2(c + Vector2(-118 + i * 34, -20), Vector2(26, 26)), col if on else Color(col, 0.2))
			Look.text(self, c + Vector2(0, 50), "same run for everyone, every day", 18, Look.MUTED, Look.sans)
