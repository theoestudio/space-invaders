extends Node
## One coarse row per finished run to the site's own Worker (web/), shown on the
## studio dashboard. The row has no identifier, timestamp or seed: two rows can never
## be tied to the same person. Only the production web build sends anything.
## The reply is that run's leaderboard (web/src/board.ts): the top cash-outs and, for a
## counted cash-out, its rank. It arrives as `board_received`.

## The leaderboard for the latest finished run: {mode, daily, top: [{payout, waves}],
## total, rank (or null)}.
signal board_received(board: Dictionary)

const ENDPOINT := "https://pachinko.twinspear.com/api/run"
const HOST := "pachinko.twinspear.com"
const PROMO_ENDPOINT := "https://pachinko.twinspear.com/api/promo"

var _enabled := false
## Counts finished runs, so a slow reply for an earlier run is dropped.
var _serial := 0


func _ready() -> void:
	if OS.has_feature("web") and not OS.is_debug_build():
		_enabled = str(JavaScriptBridge.eval("location.hostname", true)) == HOST


## Builds the row for a finished Sim. Public so the tests can check its shape.
static func row(mode: String, s: Sim, official: bool, daily := 0) -> Dictionary:
	var cleared: int = s.stats.waves.size() - (1 if s.phase == Sim.Phase.BUST else 0)
	return {
		mode = mode,
		daily = daily if mode == "daily" else 0,
		outcome = "cashed" if s.phase == Sim.Phase.CASHED else s.bust_reason,
		waves = clampi(cleared, 0, Tune.MAX_WAVE),
		payout = clampi(s.payout(), 0, 99999),
		peak = clampi(int(s.stats.peak), 0, 99999),
		shots = clampi(int(s.stats.shots), 0, 99999),
		kills = clampi(int(s.stats.kills), 0, 9999),
		hits = clampi(int(s.stats.hits), 0, 999),
		spins = clampi(int(s.stats.spins), 0, 999),
		fevers = clampi(int(s.stats.fevers), 0, 99),
		pocketed = clampi(int(s.stats.pocketed), 0, 9999),
		caught = clampi(int(s.stats.caught), 0, 9999),
		official = official,
	}


func run_finished(mode: String, s: Sim, official: bool, daily := 0) -> void:
	_serial += 1
	if not _enabled:
		return
	var serial := _serial
	var req := HTTPRequest.new()
	add_child(req)
	req.request_completed.connect(func(result: int, code: int, _h: PackedStringArray, body: PackedByteArray) -> void:
		req.queue_free()
		if result != HTTPRequest.RESULT_SUCCESS or code != 200 or serial != _serial:
			return
		var board: Variant = JSON.parse_string(body.get_string_from_utf8())
		if board is Dictionary and board.get("top") is Array:
			board_received.emit(board))
	var err := req.request(ENDPOINT, ["Content-Type: application/json"], HTTPClient.METHOD_POST, JSON.stringify(row(mode, s, official, daily)))
	if err != OK:
		push_warning("telemetry request failed to start: %s" % error_string(err))
		req.queue_free()


## The "More from Twinspear" click row: the tapped game's id and where it was shown
## ("menu" or "end"). Nothing else, so taps can't be tied to a player or a run.
## Must match web/src/promo.ts.
static func promo_row(to: String, where: String) -> Dictionary:
	return {to = to, where = where}


func promo(to: String, where: String) -> void:
	if not _enabled:
		return
	var req := HTTPRequest.new()
	add_child(req)
	req.request_completed.connect(func(_r: int, _c: int, _h: PackedStringArray, _b: PackedByteArray) -> void: req.queue_free())
	if req.request(PROMO_ENDPOINT, ["Content-Type: application/json"], HTTPClient.METHOD_POST, JSON.stringify(promo_row(to, where))) != OK:
		req.queue_free()


## The board's lines: {place, payout, waves, you, gap}. Ties share a place. This run is
## marked where its rank lands in the top; below it, its own line follows a gap.
static func board_rows(board: Dictionary, payout: int, waves: int) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	var rank: int = int(board.rank) if board.get("rank") != null else 0
	var marked := false
	var place := 0
	var prev := -1
	var i := 0
	for e: Variant in board.get("top", []):
		if not e is Dictionary:
			continue
		var p := int(e.get("payout", 0))
		i += 1
		if p != prev:
			place = i
			prev = p
		var you := not marked and rank > 0 and place == rank
		marked = marked or you
		out.append({place = place, payout = p, waves = int(e.get("waves", 0)), you = you, gap = false})
	if rank > 0 and not marked:
		out.append({place = rank, payout = payout, waves = waves, you = true, gap = true})
	return out
