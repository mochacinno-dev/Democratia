extends Node

const TRADE_PARTNERS : Array = [
	{ "nation": "Valdoria",   "gdp_bonus": 0.4, "cost": 4, "duration": 24 },
	{ "nation": "Kestmark",   "gdp_bonus": 0.6, "cost": 5, "duration": 18 },
	{ "nation": "Aurencia",   "gdp_bonus": 0.3, "cost": 3, "duration": 30 },
	{ "nation": "Threnmoor",  "gdp_bonus": 0.5, "cost": 4, "duration": 20 },
	{ "nation": "Solveig",    "gdp_bonus": 0.7, "cost": 6, "duration": 12 },
]

const ALLIANCE_PARTNERS : Array = [
	{ "nation": "Valdorian Union",  "approval_bonus": 3.0, "cost": 6 },
	{ "nation": "Northern Pact",    "approval_bonus": 2.0, "cost": 4 },
	{ "nation": "Eastern Accord",   "approval_bonus": 4.0, "cost": 7 },
	{ "nation": "Maritime League",  "approval_bonus": 2.5, "cost": 5 },
]

const CRISIS_POOL : Array = [
	{
		"title": "Economic Recession",
		"desc":  "A global downturn is hitting the economy hard. Emergency stimulus may be needed.",
		"deadline_months": 3, "severity": 3,
		"resolve_cost": 6,
		"resolve_gdp": 1.0, "resolve_approval": 5.0,
		"ignore_gdp": -1.5, "ignore_approval": -12.0,
	},
	{
		"title": "Natural Disaster",
		"desc":  "A major flood has devastated the northern regions. Disaster relief is urgently needed.",
		"deadline_months": 2, "severity": 2,
		"resolve_cost": 5,
		"resolve_gdp": 0.0, "resolve_approval": 10.0,
		"ignore_gdp": -0.5, "ignore_approval": -15.0,
	},
	{
		"title": "Constitutional Crisis",
		"desc":  "A legal challenge to recent legislation has paralysed Parliament.",
		"deadline_months": 4, "severity": 2,
		"resolve_cost": 7,
		"resolve_gdp": 0.2, "resolve_approval": 6.0,
		"ignore_gdp": -0.3, "ignore_approval": -10.0,
	},
	{
		"title": "Energy Crisis",
		"desc":  "Fuel shortages are causing public unrest and rising inflation.",
		"deadline_months": 3, "severity": 2,
		"resolve_cost": 5,
		"resolve_gdp": -0.5, "resolve_approval": 4.0,
		"ignore_gdp": -1.0, "ignore_approval": -8.0,
	},
	{
		"title": "Border Tensions",
		"desc":  "A neighbouring state has increased military presence at the border.",
		"deadline_months": 5, "severity": 1,
		"resolve_cost": 4,
		"resolve_gdp": 0.1, "resolve_approval": 5.0,
		"ignore_gdp": -0.2, "ignore_approval": -5.0,
	},
]

func available_trade_partners() -> Array:
	var active_nations = []
	for d in GameData.trade_deals:
		active_nations.append(d["nation"])
	var out = []
	for p in TRADE_PARTNERS:
		if not active_nations.has(p["nation"]):
			out.append(p)
	return out

func sign_trade_deal(partner: Dictionary) -> String:
	var cost = partner.get("cost", 4)
	if not GameData.spend_capital(cost):
		return "Not enough political capital (need %d)." % cost
	var deal = partner.duplicate()
	deal["expires_in_months"] = deal.get("duration", 24)
	GameData.trade_deals.append(deal)
	return "Trade deal signed with %s. GDP +%.1f%% monthly. (Cost: %d capital)" % [
		partner["nation"], partner["gdp_bonus"], cost
	]

func available_alliances() -> Array:
	var active = []
	for a in GameData.alliances:
		active.append(a["nation"])
	var out = []
	for a in ALLIANCE_PARTNERS:
		if not active.has(a["nation"]):
			out.append(a)
	return out

func join_alliance(alliance: Dictionary) -> String:
	var cost = alliance.get("cost", 5)
	if not GameData.spend_capital(cost):
		return "Not enough political capital (need %d)." % cost
	var a = alliance.duplicate()
	GameData.alliances.append(a)
	GameData.approval_rating = clampf(GameData.approval_rating + 3.0, 0.0, 100.0)
	return "Joined the %s. (+3 approval, ongoing bonus of +%.1f/month). (Cost: %d capital)" % [
		alliance["nation"], alliance["approval_bonus"], cost
	]

func maybe_trigger_crisis() -> bool:
	if not GameData.active_crisis.is_empty() and not GameData.active_crisis.get("resolved", true):
		return false
	# ~12% chance per month
	if randf() > 0.12:
		return false
	var crisis = CRISIS_POOL[randi() % CRISIS_POOL.size()].duplicate()
	crisis["resolved"] = false
	GameData.active_crisis = crisis
	return true

func resolve_crisis() -> String:
	if GameData.active_crisis.is_empty():
		return "No active crisis."
	if GameData.active_crisis.get("resolved", false):
		return "Crisis already resolved."
	var c    = GameData.active_crisis
	var cost = c.get("resolve_cost", 5)
	if not GameData.spend_capital(cost):
		return "Not enough political capital (need %d)." % cost
	GameData.gdp_growth      = clampf(GameData.gdp_growth      + c.get("resolve_gdp", 0.0),      -5.0, 10.0)
	GameData.approval_rating = clampf(GameData.approval_rating + c.get("resolve_approval", 0.0), 0.0, 100.0)
	GameData.active_crisis["resolved"] = true
	return "Crisis resolved: %s\nGDP %+.1f%%  |  Approval %+.1f" % [
		c["title"], c.get("resolve_gdp", 0.0), c.get("resolve_approval", 0.0)
	]

func ignore_crisis() -> String:
	if GameData.active_crisis.is_empty() or GameData.active_crisis.get("resolved", false):
		return "No active crisis to ignore."
	var c = GameData.active_crisis
	GameData.gdp_growth      = clampf(GameData.gdp_growth      + c.get("ignore_gdp", -1.0),      -5.0, 10.0)
	GameData.approval_rating = clampf(GameData.approval_rating + c.get("ignore_approval", -10.0), 0.0, 100.0)
	GameData.scandal_meter   = clampf(GameData.scandal_meter   + 10.0, 0.0, 100.0)
	GameData.active_crisis["resolved"] = true
	return "Crisis ignored. Consequences felt.\nGDP %+.1f%%  |  Approval %+.1f" % [
		c.get("ignore_gdp", -1.0), c.get("ignore_approval", -10.0)
	]