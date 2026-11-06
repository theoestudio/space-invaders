extends Node
## One coarse row per finished run to the site's own Worker (web/), shown on the
## studio dashboard. The row has no identifier, timestamp or seed: two rows can never
## be tied to the same person. Only the production web build sends anything.

const ENDPOINT := "https://pachinko.twinspear.com/api/run"
const HOST := "pachinko.twinspear.com"

var _enabled := false


func _ready() -> void:
	if OS.has_feature("web") and not OS.is_debug_build():
		_enabled = str(JavaScriptBridge.eval("location.hostname", true)) == HOST


## Builds the row for a finished Sim. Public so the tests can check its shape.
static func row(mode: String, s: Sim, official: bool) -> Dictionary:
	var cleared: int = s.stats.waves.size() - (1 if s.phase == Sim.Phase.BUST else 0)
	return {
		mode = mode,
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


func run_finished(mode: String, s: Sim, official: bool) -> void:
	if not _enabled:
		return
	var req := HTTPRequest.new()
	add_child(req)
	req.request_completed.connect(func(_r: int, _c: int, _h: PackedStringArray, _b: PackedByteArray) -> void: req.queue_free())
	var err := req.request(ENDPOINT, ["Content-Type: application/json"], HTTPClient.METHOD_POST, JSON.stringify(row(mode, s, official)))
	if err != OK:
		push_warning("telemetry request failed to start: %s" % error_string(err))
		req.queue_free()
