# Pachinko Descent: Godot 4.7 (GDScript) + a Cloudflare Worker in web/.
# `make help` lists targets. GODOT must be the standard (non-.NET) build: the web
# export cannot run C#, and the .NET editor looks for .NET export templates.

GODOT ?= godot
XVFB  := xvfb-run -a -s "-screen 0 1920x1080x24"

.PHONY: help import test selfplay shots shots-wide export sounds dev deploy

help: ## Show this help
	@grep -E '^[a-z-]+:.*##' $(MAKEFILE_LIST) | awk -F ':.*## ' '{printf "  %-12s %s\n", $$1, $$2}'

import: ## Import assets and build the class cache (needed once after a fresh clone)
	@$(GODOT) --headless --import >/dev/null 2>&1 || true

test: import ## Sim, board and telemetry checks, headless, plus the Worker's tests
	$(GODOT) --headless --script tests/run_tests.gd
	cd web && npm test --silent

selfplay: import ## Autopilot runs at three skill levels: busts, payouts per cash-out wave (ARGS="48 12")
	lowprio $(GODOT) --headless --script tests/selfplay.gd -- $(ARGS)

shots: import ## Screenshots of every screen at phone size into /tmp/pachinko/shots (virtual display)
	$(XVFB) $(GODOT) --rendering-driver opengl3 --resolution 390x844 res://tests/shot.tscn -- /tmp/pachinko/shots

shots-wide: import ## Same at desktop size into /tmp/pachinko/shots-wide
	$(XVFB) $(GODOT) --rendering-driver opengl3 --resolution 1440x900 res://tests/shot.tscn -- /tmp/pachinko/shots-wide

export: import ## Web export into build/web
	mkdir -p build/web
	find build/web -mindepth 1 -delete
	@# The editor can crash while shutting down after a successful export, so
	@# judge the result by the files rather than the exit code.
	-$(GODOT) --headless --export-release "Web" build/web/index.html >/dev/null 2>&1
	@test -s build/web/index.wasm && test -s build/web/index.pck && echo "exported build/web"

sounds: ## Re-render assets/audio from tools/make-sounds.py
	python3 tools/make-sounds.py

dev: export ## Serve the web build through the Worker locally on :8787
	cd web && npm run dev

deploy: test export ## Ship to pachinko.twinspear.com
	cd web && broker exec --request --reason "deploy pachinko.twinspear.com" CLOUDFLARE_API_TOKEN CLOUDFLARE_ACCOUNT_ID -- npm run deploy
