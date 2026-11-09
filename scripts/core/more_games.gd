class_name MoreGames
extends RefCounted
## The other TwinSpear games, for the "More from TwinSpear" panel and the suggestion under
## a result. The list lives on the blog (data/games.yaml in ~/Sites/blog, published as
## FEED with an open CORS header), so a new game shows up in every older game without a
## redeploy. BUNDLED is a copy that works offline and until the fetch lands.
##
## Written to be copied into the other browser games: change SELF and TAGS, keep the rest.

const FEED := "https://nathanielinman.com/games/index.json"
const BUNDLED := "res://data/more_games.json"
## This game's id in the feed (never listed), and the audience tags its players share.
const SELF := "pachinko"
const TAGS := ["arcade", "shooter"]
const PLATFORMS := ["web", "steam"]


## The feed's games, keeping only well-formed entries. Empty if the text isn't the feed.
static func parse(text: String) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	var json := JSON.new()
	var d: Variant = json.data if json.parse(text) == OK else null
	if not d is Dictionary or int(d.get("version", 0)) != 1 or not d.get("games") is Array:
		return out
	for g: Variant in d.games:
		if not g is Dictionary:
			continue
		var ok: bool = g.get("id") is String and g.get("title") is String and g.get("pitch") is String \
			and g.get("url") is String and str(g.url).begins_with("https://") \
			and g.get("platform") in PLATFORMS and g.get("free") is bool and g.get("audience") is Array
		if ok:
			out.append(g)
	return out


static func bundled() -> Array[Dictionary]:
	return parse(FileAccess.get_file_as_string(BUNDLED))


## The other games, best fit first: shared audience tags, then the paid games (the
## bigger ones these free games are here to point at), then the feed's own order.
static func ranked(games: Array[Dictionary], self_id := SELF, tags: Array = TAGS) -> Array[Dictionary]:
	var scored := []
	for i in games.size():
		var g := games[i]
		if g.id == self_id:
			continue
		var fit := 0
		for t: Variant in g.audience:
			if t in tags:
				fit += 1
		scored.append([fit * 10 + (0 if g.free else 5), -i, g])
	scored.sort_custom(func(a: Array, b: Array) -> bool: return a[0] > b[0] or a[0] == b[0] and a[1] > b[1])
	var out: Array[Dictionary] = []
	for s: Array in scored:
		out.append(s[2])
	return out


## Where a tap goes. Steam links carry UTM tags so Steamworks shows the visits from here:
## utm_source is this game, utm_medium where it was played (played_on), utm_campaign the
## button ("menu" or "end"). `medium` is for tests; empty means look it up.
static func link(game: Dictionary, where: String, self_id := SELF, medium := "") -> String:
	var url: String = game.url
	if game.platform != "steam":
		return url
	var sep := "&" if "?" in url else "?"
	var on := medium if medium != "" else played_on()
	return "%s%sutm_source=%s&utm_medium=%s&utm_campaign=%s" % [url, sep, self_id, on, where]


## Where this copy of the game is running (host_label), or "app" outside a browser.
static func played_on() -> String:
	if not OS.has_feature("web"):
		return "app"
	return host_label(str(JavaScriptBridge.eval("location.hostname", true)))


## A page's hostname as a short UTM label: "site" for our own twinspear.com pages, "itch"
## inside itch.io's player (its game frames are served from itch.zone, older uploads from
## hwcdn.net), "dev" for a local build, and any other host as itself, so a new portal
## shows up in Steamworks without a code change.
static func host_label(hostname: String) -> String:
	var h := hostname.strip_edges().to_lower()
	if h == "twinspear.com" or h.ends_with(".twinspear.com"):
		return "site"
	for itch: String in ["itch.io", "itch.zone", "hwcdn.net"]:
		if h == itch or h.ends_with("." + itch):
			return "itch"
	if h in ["", "localhost", "127.0.0.1", "[::1]"]:
		return "dev"
	var re := RegEx.create_from_string("[^a-z0-9.-]")
	return re.sub(h, "", true).left(48)


## The button text for a game.
static func call_to_action(game: Dictionary) -> String:
	if game.platform == "steam":
		return "View on Steam"
	return "Play free" if game.free else "Play"
