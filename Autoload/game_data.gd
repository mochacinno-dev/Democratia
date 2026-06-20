extends Node

# ── Player Info ────────────────────────────────────────────────────────────────
var player_first_name : String = ""
var player_last_name  : String = ""
var player_party      : String = ""

# ── Time ───────────────────────────────────────────────────────────────────────
var current_year          : int = 2025
var current_month         : int = 1
var months_until_election : int = 48
var terms_served          : int = 0

# ── Core Stats ─────────────────────────────────────────────────────────────────
var approval_rating   : float = 50.0
var political_capital : int   = 20     # finite resource, max 40, regen 2/month

# ── Economy ────────────────────────────────────────────────────────────────────
var gdp_growth       : float = 2.0
var unemployment     : float = 6.0
var budget_deficit   : float = 3.0

# ── Public Opinion Groups (0–100) ──────────────────────────────────────────────
var public_groups : Dictionary = {
	"Workers":    50.0,
	"Business":   50.0,
	"Youth":      50.0,
	"Pensioners": 50.0,
}
# If a group drops below this threshold they actively campaign vs you
const GROUP_HOSTILE_THRESHOLD : float = 30.0

# ── Parliament ─────────────────────────────────────────────────────────────────
const TOTAL_SEATS : int = 300

var seats : Dictionary = {
	"Green Alliance Party":  42,
	"Centre Compass Party":  78,
	"Fair Nationalism Party": 65,
	"Rose Democracy Party":   55,
	"Liberal Society Party":  60,
}

var party_colors : Dictionary = {
	"Green Alliance Party":  Color(0.13, 0.70, 0.30),
	"Centre Compass Party":  Color(1.00, 0.80, 0.00),
	"Fair Nationalism Party": Color(0.20, 0.30, 0.80),
	"Rose Democracy Party":   Color(0.85, 0.15, 0.25),
	"Liberal Society Party":  Color(0.90, 0.50, 0.10),
}

var party_ideology : Dictionary = {
	"Green Alliance Party":  -6.0,
	"Centre Compass Party":   0.0,
	"Fair Nationalism Party":  7.0,
	"Rose Democracy Party":   -3.0,
	"Liberal Society Party":   3.0,
}

var party_leaders : Dictionary = {
	"Green Alliance Party":  "Elena Marsh",
	"Centre Compass Party":  "Victor Hale",
	"Fair Nationalism Party": "Conrad Steele",
	"Rose Democracy Party":   "Sofia Ramos",
	"Liberal Society Party":  "James Finch",
}

var coalition_stance : Dictionary = {
	"Green Alliance Party":  0,
	"Centre Compass Party":  0,
	"Fair Nationalism Party": 0,
	"Rose Democracy Party":   0,
	"Liberal Society Party":  0,
}

var polling : Dictionary = {
	"Green Alliance Party":  14.0,
	"Centre Compass Party":  26.0,
	"Fair Nationalism Party": 21.5,
	"Rose Democracy Party":   18.5,
	"Liberal Society Party":  20.0,
}

# ── Cabinet ────────────────────────────────────────────────────────────────────
# slot -> { name, competence(1-10), scandal_risk(0-100), months_served, party }
var cabinet : Dictionary = {
	"Economy":        {},
	"Health":         {},
	"Foreign Affairs":{},
	"Home Affairs":   {},
	"Education":      {},
	"Defence":        {},
}
var cabinet_scandal_meter : float = 0.0   # global hidden meter 0–100

# ── Media ──────────────────────────────────────────────────────────────────────
var media_hostility    : float = 0.0    # 0 = neutral, 100 = hostile press
var last_headline      : String = ""
var press_spun_this_month : bool = false

# ── Foreign Policy ─────────────────────────────────────────────────────────────
# trade_deals: list of { nation, gdp_bonus, expires_in_months }
var trade_deals : Array = []
# alliances: list of { nation, approval_bonus, capital_cost_paid }
var alliances   : Array = []
# active_crisis: {} or { title, desc, deadline_months, severity, resolved }
var active_crisis : Dictionary = {}

# ── Legislation ────────────────────────────────────────────────────────────────
var pending_bill  : Dictionary = {}
var bills_passed  : int = 0
var bills_failed  : int = 0

# ── Term Goals ─────────────────────────────────────────────────────────────────
# Each goal: { desc, type, target, achieved, failed }
var term_goals   : Array = []
var legacy_score : int   = 0    # carries across terms

# ── Scandal ────────────────────────────────────────────────────────────────────
var scandal_meter       : float = 0.0   # 0–100, hidden from player
var whip_count_this_term: int   = 0

# ── Election ───────────────────────────────────────────────────────────────────
var election_active : bool = false
var campaign_funds  : int  = 10

# ── Helpers ────────────────────────────────────────────────────────────────────
func player_full_name() -> String:
	return player_first_name + " " + player_last_name

func player_seat_count() -> int:
	return seats.get(player_party, 0)

func majority_threshold() -> int:
	return int(float(TOTAL_SEATS) / 2.0) + 1

func has_majority() -> bool:
	return player_seat_count() >= majority_threshold()

func coalition_seats() -> int:
	var total = player_seat_count()
	for party in coalition_stance:
		if coalition_stance[party] == 1 and party != player_party:
			total += seats.get(party, 0)
	return total

func has_coalition_majority() -> bool:
	return coalition_seats() >= majority_threshold()

func player_ideology() -> float:
	return party_ideology.get(player_party, 0.0)

func ideology_distance(other_party: String) -> float:
	return abs(player_ideology() - party_ideology.get(other_party, 0.0))

func spend_capital(amount: int) -> bool:
	if political_capital < amount:
		return false
	political_capital -= amount
	return true

func gain_capital(amount: int) -> void:
	political_capital = min(40, political_capital + amount)

func cabinet_competence(slot: String) -> float:
	var m = cabinet.get(slot, {})
	if m.is_empty():
		return 0.0
	return float(m.get("competence", 5))

func filled_cabinet_slots() -> int:
	var n = 0
	for slot in cabinet:
		if not cabinet[slot].is_empty():
			n += 1
	return n

func hostile_groups() -> Array:
	var out = []
	for g in public_groups:
		if public_groups[g] < GROUP_HOSTILE_THRESHOLD:
			out.append(g)
	return out

func advance_month() -> void:
	current_month += 1
	if current_month > 12:
		current_month = 1
		current_year += 1
	months_until_election -= 1
	if months_until_election <= 0:
		election_active = true
		months_until_election = 48
		terms_served += 1
	_regen_capital()
	_tick_economy()
	_drift_polling()
	_tick_trade_deals()
	_tick_alliances()
	_tick_crisis()
	_tick_cabinet_scandal()
	_check_term_goals()
	_tick_public_groups()
	press_spun_this_month = false

func _regen_capital() -> void:
	# Base regen + bonus from full cabinet
	var regen = 2 + int(filled_cabinet_slots() / 3)
	gain_capital(regen)

func _tick_economy() -> void:
	# Cabinet economy minister passively helps
	var econ_comp = cabinet_competence("Economy")
	var gdp_boost = econ_comp * 0.03
	gdp_growth = clampf(gdp_growth + gdp_boost * 0.1, -5.0, 10.0)

	if gdp_growth > 2.5:
		unemployment = max(3.0, unemployment - 0.1)
	elif gdp_growth < 1.0:
		unemployment = min(15.0, unemployment + 0.2)
	else:
		unemployment += (5.0 - unemployment) * 0.05

	var econ_pressure = 0.0
	if gdp_growth > 3.0:   econ_pressure += 0.5
	elif gdp_growth < 0.5: econ_pressure -= 1.0
	if unemployment > 9.0: econ_pressure -= 1.0
	elif unemployment < 4.5: econ_pressure += 0.5

	# Hostile groups amplify negative pressure
	econ_pressure -= hostile_groups().size() * 0.3

	approval_rating = clampf(approval_rating + econ_pressure, 0.0, 100.0)

func _drift_polling() -> void:
	var player_poll = polling.get(player_party, 20.0)
	var target = 15.0 + (approval_rating - 50.0) * 0.4
	polling[player_party] = clampf(player_poll + (target - player_poll) * 0.1, 5.0, 60.0)
	_normalise_polling()

func _normalise_polling() -> void:
	var total = 0.0
	for p in polling: total += polling[p]
	if total <= 0: return
	for p in polling: polling[p] = polling[p] / total * 100.0

func _tick_trade_deals() -> void:
	var expired = []
	for deal in trade_deals:
		deal["expires_in_months"] -= 1
		gdp_growth = clampf(gdp_growth + deal.get("gdp_bonus", 0.0) * 0.1, -5.0, 10.0)
		if deal["expires_in_months"] <= 0:
			expired.append(deal)
	for d in expired:
		trade_deals.erase(d)

func _tick_alliances() -> void:
	for alliance in alliances:
		approval_rating = clampf(approval_rating + alliance.get("approval_bonus", 0.0) * 0.05, 0.0, 100.0)

func _tick_crisis() -> void:
	if active_crisis.is_empty(): return
	if active_crisis.get("resolved", false): return
	active_crisis["deadline_months"] -= 1
	var severity = active_crisis.get("severity", 1)
	# Unresolved crisis costs approval each month
	approval_rating = clampf(approval_rating - severity * 1.5, 0.0, 100.0)
	gdp_growth = clampf(gdp_growth - severity * 0.1, -5.0, 10.0)
	if active_crisis["deadline_months"] <= 0:
		# Crisis expires unresolved — major hit
		approval_rating = clampf(approval_rating - severity * 8.0, 0.0, 100.0)
		scandal_meter = clampf(scandal_meter + 15.0, 0.0, 100.0)
		active_crisis["resolved"] = true

func _tick_cabinet_scandal() -> void:
	# Scandal meter rises from whipping and hostile media
	scandal_meter = clampf(
		scandal_meter + (media_hostility * 0.05) + (whip_count_this_term * 0.5),
		0.0, 100.0
	)
	# Random scandal fires above 60
	if scandal_meter > 60.0 and randf() < 0.15:
		_fire_scandal()

func _fire_scandal() -> void:
	var filled = []
	for slot in cabinet:
		if not cabinet[slot].is_empty():
			filled.append(slot)
	if filled.is_empty():
		approval_rating = clampf(approval_rating - 8.0, 0.0, 100.0)
		scandal_meter = clampf(scandal_meter - 30.0, 0.0, 100.0)
		last_headline = "SCANDAL: A senior official implicated in misconduct. (-8 approval)"
		return
	var slot = filled[randi() % filled.size()]
	var minister = cabinet[slot]
	last_headline = "SCANDAL: %s (%s) caught in controversy — forced to resign! (-10 approval)" % [
		minister.get("name", "Minister"), slot
	]
	cabinet[slot] = {}
	approval_rating = clampf(approval_rating - 10.0, 0.0, 100.0)
	scandal_meter = clampf(scandal_meter - 30.0, 0.0, 100.0)

func _tick_public_groups() -> void:
	# Groups drift toward 50 slowly; hostile groups pressure polling
	for g in public_groups:
		public_groups[g] += (50.0 - public_groups[g]) * 0.02
		public_groups[g] = clampf(public_groups[g], 0.0, 100.0)
	# Hostile groups erode polling
	for g in hostile_groups():
		polling[player_party] = clampf(polling.get(player_party, 20.0) - 0.5, 5.0, 60.0)
	_normalise_polling()

func _check_term_goals() -> void:
	for goal in term_goals:
		if goal.get("achieved", false) or goal.get("failed", false):
			continue
		match goal.get("type", ""):
			"unemployment":
				if unemployment <= goal.get("target", 4.0):
					goal["achieved"] = true
					gain_capital(5)
					legacy_score += 10
			"bills_passed":
				if bills_passed >= goal.get("target", 3):
					goal["achieved"] = true
					gain_capital(5)
					legacy_score += 10
			"approval":
				if approval_rating >= goal.get("target", 60.0):
					goal["achieved"] = true
					gain_capital(5)
					legacy_score += 10

func run_election() -> void:
	# Check failed term goals — approval penalty
	for goal in term_goals:
		if not goal.get("achieved", false):
			goal["failed"] = true
			approval_rating = clampf(approval_rating - 8.0, 0.0, 100.0)
			polling[player_party] = clampf(polling.get(player_party, 20.0) - 3.0, 5.0, 60.0)

	var total_poll = 0.0
	for p in polling: total_poll += polling[p]
	for p in seats:
		var share = polling.get(p, 0.0) / total_poll
		seats[p] = int(share * TOTAL_SEATS)
	var assigned = 0
	for p in seats: assigned += seats[p]
	var remainder = TOTAL_SEATS - assigned
	if remainder > 0:
		var biggest = seats.keys()[0]
		for p in seats:
			if seats[p] > seats[biggest]: biggest = p
		seats[biggest] += remainder

	for p in coalition_stance: coalition_stance[p] = 0
	election_active = false
	campaign_funds = 10
	whip_count_this_term = 0
	term_goals = []

func economy_summary() -> String:
	return "GDP: %+.1f%%  |  Unemployment: %.1f%%  |  Deficit: %.1f%% GDP" % [
		gdp_growth, unemployment, budget_deficit
	]

func month_name() -> String:
	var names = ["January","February","March","April","May","June",
				 "July","August","September","October","November","December"]
	return names[current_month - 1]