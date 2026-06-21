extends Node

# ═══════════════════════════════════════════════════════════════════════════════
# GAME DATA — central state, no logic beyond pure helpers
# ═══════════════════════════════════════════════════════════════════════════════

# ── Player ─────────────────────────────────────────────────────────────────────
var player_first_name : String = ""
var player_last_name  : String = ""
var player_party      : String = ""

# ── Time ───────────────────────────────────────────────────────────────────────
var current_year          : int = 2025
var current_month         : int = 1
var months_until_election : int = 48
var terms_served          : int = 0
var month_history         : Array = []   # Array of snapshots for graphs

# ── Core Resources ─────────────────────────────────────────────────────────────
var approval_rating   : float = 50.0
var political_capital : int   = 20
var legitimacy        : float = 60.0   # 0–100; low = constitutional instability
var prestige          : int   = 0      # cumulative legacy score

# ── Economy ────────────────────────────────────────────────────────────────────
var gdp_growth       : float = 2.0
var unemployment     : float = 6.0
var budget_deficit   : float = 3.0
var inflation        : float = 2.0
var gdp_absolute     : float = 1200.0  # in billions

# ── Social Strata (Pops) ───────────────────────────────────────────────────────
# satisfaction 0–100, size = relative population share
var pops : Dictionary = {
	"Working Class":  { "satisfaction": 50.0, "size": 38, "radicalisation": 0.0 },
	"Middle Class":   { "satisfaction": 50.0, "size": 30, "radicalisation": 0.0 },
	"Business Elite": { "satisfaction": 50.0, "size": 12, "radicalisation": 0.0 },
	"Youth":          { "satisfaction": 50.0, "size": 14, "radicalisation": 0.0 },
	"Pensioners":     { "satisfaction": 50.0, "size": 22, "radicalisation": 0.0 },
	"Rural":          { "satisfaction": 50.0, "size": 16, "radicalisation": 0.0 },
}

# ── Parliament ─────────────────────────────────────────────────────────────────
const TOTAL_SEATS : int = 300

var seats : Dictionary = {
	"Green Alliance Party":   42,
	"Centre Compass Party":   78,
	"Fair Nationalism Party":  65,
	"Rose Democracy Party":    55,
	"Liberal Society Party":   60,
}

var party_colors : Dictionary = {
	"Green Alliance Party":   Color(0.13, 0.70, 0.30),
	"Centre Compass Party":   Color(1.00, 0.80, 0.00),
	"Fair Nationalism Party":  Color(0.20, 0.30, 0.80),
	"Rose Democracy Party":    Color(0.85, 0.15, 0.25),
	"Liberal Society Party":   Color(0.90, 0.50, 0.10),
}

# Ideology: -10 (far left) to +10 (far right)
var party_ideology : Dictionary = {
	"Green Alliance Party":   -6.0,
	"Centre Compass Party":    0.0,
	"Fair Nationalism Party":   7.0,
	"Rose Democracy Party":    -3.0,
	"Liberal Society Party":    3.0,
}

var party_leaders : Dictionary = {
	"Green Alliance Party":   "Elena Marsh",
	"Centre Compass Party":   "Victor Hale",
	"Fair Nationalism Party":  "Conrad Steele",
	"Rose Democracy Party":    "Sofia Ramos",
	"Liberal Society Party":   "James Finch",
}

# coalition_stance: -1 hostile, 0 neutral, 1 allied
var coalition_stance : Dictionary = {
	"Green Alliance Party":   0,
	"Centre Compass Party":   0,
	"Fair Nationalism Party":  0,
	"Rose Democracy Party":    0,
	"Liberal Society Party":   0,
}

var polling : Dictionary = {
	"Green Alliance Party":   14.0,
	"Centre Compass Party":   26.0,
	"Fair Nationalism Party":  21.5,
	"Rose Democracy Party":    18.5,
	"Liberal Society Party":   20.0,
}

# ── Party Internal Factions ───────────────────────────────────────────────────
# party -> { faction_name: power_score }  power sums to 100
var party_factions : Dictionary = {
	"Green Alliance Party": {
		"Radical Greens": 40.0, "Social Ecologists": 35.0, "Green Liberals": 25.0
	},
	"Centre Compass Party": {
		"Centrist Hawks": 30.0, "Liberal Centre": 45.0, "Conservative Wing": 25.0
	},
	"Fair Nationalism Party": {
		"National Populists": 55.0, "Traditionalists": 30.0, "Moderate Nationalists": 15.0
	},
	"Rose Democracy Party": {
		"Labour Left": 40.0, "Social Democrats": 45.0, "Progressive Centre": 15.0
	},
	"Liberal Society Party": {
		"Classical Liberals": 35.0, "Progressive Liberals": 40.0, "Market Liberals": 25.0
	},
}

# dominant faction shapes the party's effective ideology each month
func dominant_faction(party: String) -> String:
	var factions = party_factions.get(party, {})
	if factions.is_empty(): return ""
	var best = ""
	var best_power = -1.0
	for f in factions:
		if factions[f] > best_power:
			best_power = factions[f]
			best = f
	return best

# ── Laws & Constitution ───────────────────────────────────────────────────────
# Each law: { name, category, passed, repealed, requires_supermajority,
#             seats_needed_override, effects: {}, unlocks: [] }
var constitution_laws : Dictionary = {
	# Electoral
	"Universal Suffrage": {
		"category": "Electoral", "passed": true, "repealed": false,
		"requires_super": false, "seats_needed": 151,
		"desc": "All citizens over 18 may vote.",
		"effects": { "legitimacy": 5.0 }, "unlocks": ["Proportional Representation", "Voter ID Laws"]
	},
	"Proportional Representation": {
		"category": "Electoral", "passed": false, "repealed": false,
		"requires_super": false, "seats_needed": 151,
		"desc": "Seats allocated by vote share. Boosts smaller parties.",
		"effects": { "legitimacy": 8.0, "approval": 4.0 }, "unlocks": ["Coalition Government Act"]
	},
	"Voter ID Laws": {
		"category": "Electoral", "passed": false, "repealed": false,
		"requires_super": false, "seats_needed": 151,
		"desc": "Mandatory ID at polling stations. Controversial.",
		"effects": { "legitimacy": -3.0, "approval": -5.0 }, "unlocks": []
	},
	"Coalition Government Act": {
		"category": "Electoral", "passed": false, "repealed": false,
		"requires_super": true, "seats_needed": 201,
		"desc": "Formalises coalition rules. Stabilises minority governments.",
		"effects": { "legitimacy": 10.0, "approval": 3.0 }, "unlocks": []
	},
	# Economic
	"Free Market Framework": {
		"category": "Economic", "passed": true, "repealed": false,
		"requires_super": false, "seats_needed": 151,
		"desc": "Baseline market economy with limited regulation.",
		"effects": { "gdp_growth": 0.3 }, "unlocks": ["Deregulation Act", "Workers Protection Act"]
	},
	"Deregulation Act": {
		"category": "Economic", "passed": false, "repealed": false,
		"requires_super": false, "seats_needed": 151,
		"desc": "Removes industry regulations. Business booms, workers suffer.",
		"effects": { "gdp_growth": 0.8, "pop_business_elite": 15.0, "pop_working_class": -12.0 },
		"unlocks": ["Financial Liberalisation"]
	},
	"Workers Protection Act": {
		"category": "Economic", "passed": false, "repealed": false,
		"requires_super": false, "seats_needed": 151,
		"desc": "Minimum wage, union rights, redundancy protection.",
		"effects": { "gdp_growth": -0.2, "pop_working_class": 18.0, "pop_business_elite": -8.0 },
		"unlocks": ["Universal Basic Income"]
	},
	"Financial Liberalisation": {
		"category": "Economic", "passed": false, "repealed": false,
		"requires_super": false, "seats_needed": 151,
		"desc": "Open capital markets. High growth, high risk.",
		"effects": { "gdp_growth": 1.2, "inflation": 1.5, "pop_business_elite": 20.0 },
		"unlocks": []
	},
	"Universal Basic Income": {
		"category": "Economic", "passed": false, "repealed": false,
		"requires_super": true, "seats_needed": 201,
		"desc": "Every citizen receives a monthly stipend.",
		"effects": { "budget_deficit": 2.0, "pop_working_class": 20.0, "pop_youth": 15.0, "approval": 8.0 },
		"unlocks": []
	},
	# Social
	"Public Healthcare": {
		"category": "Social", "passed": true, "repealed": false,
		"requires_super": false, "seats_needed": 151,
		"desc": "State-funded healthcare for all citizens.",
		"effects": { "pop_working_class": 10.0, "pop_pensioners": 12.0, "budget_deficit": 0.5 },
		"unlocks": ["Universal Dental & Mental Health", "Healthcare Privatisation"]
	},
	"Universal Dental & Mental Health": {
		"category": "Social", "passed": false, "repealed": false,
		"requires_super": false, "seats_needed": 151,
		"desc": "Extends NHS to cover dental and mental health.",
		"effects": { "pop_youth": 12.0, "pop_working_class": 8.0, "budget_deficit": 0.4, "approval": 6.0 },
		"unlocks": []
	},
	"Healthcare Privatisation": {
		"category": "Social", "passed": false, "repealed": false,
		"requires_super": false, "seats_needed": 151,
		"desc": "Open healthcare to private providers.",
		"effects": { "pop_business_elite": 10.0, "pop_working_class": -15.0, "gdp_growth": 0.3 },
		"unlocks": []
	},
	# Civil
	"Freedom of Press": {
		"category": "Civil", "passed": true, "repealed": false,
		"requires_super": false, "seats_needed": 151,
		"desc": "Guarantees press freedom. Hostile media can operate freely.",
		"effects": { "legitimacy": 8.0 }, "unlocks": ["Media Ownership Transparency", "Press Restriction Act"]
	},
	"Media Ownership Transparency": {
		"category": "Civil", "passed": false, "repealed": false,
		"requires_super": false, "seats_needed": 151,
		"desc": "Owners must disclose political ties. Reduces media hostility.",
		"effects": { "legitimacy": 5.0, "media_hostility": -20.0 }, "unlocks": []
	},
	"Press Restriction Act": {
		"category": "Civil", "passed": false, "repealed": false,
		"requires_super": false, "seats_needed": 151,
		"desc": "Limits hostile coverage. Undermines legitimacy.",
		"effects": { "legitimacy": -15.0, "media_hostility": -30.0 }, "unlocks": []
	},
	"Emergency Powers Act": {
		"category": "Civil", "passed": false, "repealed": false,
		"requires_super": true, "seats_needed": 201,
		"desc": "Grants executive emergency authority. High risk to legitimacy.",
		"effects": { "legitimacy": -20.0, "political_capital": 10 }, "unlocks": []
	},
}

# Which laws are currently available to be passed (unlocked by prerequisites)
func available_laws() -> Array:
	var out = []
	for law_name in constitution_laws:
		var law = constitution_laws[law_name]
		if law["passed"] or law["repealed"]:
			continue
		# Check if any passed law unlocks this one
		var unlocked = false
		for other_name in constitution_laws:
			var other = constitution_laws[other_name]
			if other["passed"] and other["unlocks"].has(law_name):
				unlocked = true
				break
		if unlocked:
			out.append(law_name)
	return out

# ── Diplomatic Relations ──────────────────────────────────────────────────────
# nation -> { relation(-100 to 100), envoy_sent, trade_deal, alliance, sanctions }
var foreign_relations : Dictionary = {
	"Valdoria":  { "relation": 20,  "envoy_sent": false, "trade_deal": false, "alliance": false, "sanctions": false, "gdp_bonus": 0.4 },
	"Kestmark":  { "relation": -10, "envoy_sent": false, "trade_deal": false, "alliance": false, "sanctions": false, "gdp_bonus": 0.6 },
	"Aurencia":  { "relation": 40,  "envoy_sent": false, "trade_deal": false, "alliance": false, "sanctions": false, "gdp_bonus": 0.3 },
	"Threnmoor": { "relation": 5,   "envoy_sent": false, "trade_deal": false, "alliance": false, "sanctions": false, "gdp_bonus": 0.5 },
	"Solveig":   { "relation": 60,  "envoy_sent": false, "trade_deal": false, "alliance": false, "sanctions": false, "gdp_bonus": 0.7 },
}

# ── Cabinet ────────────────────────────────────────────────────────────────────
var cabinet : Dictionary = {
	"Economy":         {},
	"Health":          {},
	"Foreign Affairs": {},
	"Home Affairs":    {},
	"Education":       {},
	"Defence":         {},
}

# ── Media ──────────────────────────────────────────────────────────────────────
var media_hostility    : float  = 0.0
var last_headline      : String = ""

# ── Crisis ─────────────────────────────────────────────────────────────────────
var active_crisis : Dictionary = {}

# ── Legislation ────────────────────────────────────────────────────────────────
var pending_bill  : Dictionary = {}
var bills_passed  : int = 0
var bills_failed  : int = 0

# ── Scandal ────────────────────────────────────────────────────────────────────
var scandal_meter        : float = 0.0
var whip_count_this_term : int   = 0

# ── Election ───────────────────────────────────────────────────────────────────
var election_active : bool = false
var campaign_funds  : int  = 10

# ── Term Goals ─────────────────────────────────────────────────────────────────
var term_goals   : Array = []
var legacy_score : int   = 0

# ═══════════════════════════════════════════════════════════════════════════════
# HELPERS
# ═══════════════════════════════════════════════════════════════════════════════
func player_full_name() -> String:
	return player_first_name + " " + player_last_name

func player_seat_count() -> int:
	return seats.get(player_party, 0)

func majority_threshold() -> int:
	return int(float(TOTAL_SEATS) / 2.0) + 1

func supermajority_threshold() -> int:
	return int(float(TOTAL_SEATS) * 2.0 / 3.0) + 1

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

func has_supermajority() -> bool:
	return coalition_seats() >= supermajority_threshold()

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
	if m.is_empty(): return 0.0
	return float(m.get("competence", 5))

func filled_cabinet_slots() -> int:
	var n = 0
	for slot in cabinet:
		if not cabinet[slot].is_empty(): n += 1
	return n

func weighted_approval() -> float:
	# Weighted average of pop satisfaction by size
	var total_size = 0.0
	var weighted   = 0.0
	for pop_name in pops:
		var p = pops[pop_name]
		total_size += p["size"]
		weighted   += p["satisfaction"] * p["size"]
	if total_size == 0: return approval_rating
	return weighted / total_size

func month_name() -> String:
	var names = ["January","February","March","April","May","June",
				 "July","August","September","October","November","December"]
	return names[current_month - 1]

func economy_summary() -> String:
	return "GDP: %+.1f%%  |  Unemployment: %.1f%%  |  Deficit: %.1f%%  |  Inflation: %.1f%%" % [
		gdp_growth, unemployment, budget_deficit, inflation
	]

func snapshot() -> Dictionary:
	return {
		"month":       current_month,
		"year":        current_year,
		"approval":    approval_rating,
		"gdp":         gdp_growth,
		"unemployment":unemployment,
		"legitimacy":  legitimacy,
	}

func record_snapshot() -> void:
	month_history.append(snapshot())
	if month_history.size() > 24:
		month_history.pop_front()

func advance_month() -> void:
	record_snapshot()
	current_month += 1
	if current_month > 12:
		current_month = 1
		current_year += 1
	months_until_election -= 1
	if months_until_election <= 0:
		election_active = true
		months_until_election = 48
		terms_served += 1

func normalise_polling() -> void:
	var total = 0.0
	for p in polling: total += polling[p]
	if total <= 0: return
	for p in polling: polling[p] = polling[p] / total * 100.0

func run_election() -> void:
	for goal in term_goals:
		if not goal.get("achieved", false):
			goal["failed"] = true
			approval_rating = clampf(approval_rating - 8.0, 0.0, 100.0)
	var total_poll = 0.0
	for p in polling: total_poll += polling[p]
	for p in seats:
		seats[p] = int((polling.get(p, 0.0) / total_poll) * TOTAL_SEATS)
	var assigned = 0
	for p in seats: assigned += seats[p]
	var biggest = seats.keys()[0]
	for p in seats:
		if seats[p] > seats[biggest]: biggest = p
	seats[biggest] += TOTAL_SEATS - assigned
	for p in coalition_stance: coalition_stance[p] = 0
	election_active   = false
	campaign_funds    = 10
	whip_count_this_term = 0
	term_goals        = []
	legitimacy        = clampf(legitimacy + 5.0, 0.0, 100.0)
