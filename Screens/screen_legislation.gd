extends Control

@onready var lbl_bill_name    : Label  = $Margin/HBox/Left/BillName
@onready var lbl_bill_desc    : Label  = $Margin/HBox/Left/BillDesc
@onready var lbl_bill_effects : Label  = $Margin/HBox/Left/BillEffects
@onready var lbl_groups_effect: Label  = $Margin/HBox/Left/GroupsEffect
@onready var lbl_vote_tally   : Label  = $Margin/HBox/Left/VoteTally
@onready var btn_whip         : Button = $Margin/HBox/Left/HBoxActions/BtnWhip
@onready var btn_coalition    : Button = $Margin/HBox/Left/HBoxActions/BtnCoalition
@onready var btn_pass         : Button = $Margin/HBox/Left/HBoxVote/BtnPass
@onready var btn_drop         : Button = $Margin/HBox/Left/HBoxVote/BtnDrop
@onready var btn_new_bill     : Button = $Margin/HBox/Left/HBoxVote/BtnNew
@onready var lbl_result       : Label  = $Margin/HBox/Left/Result
@onready var lbl_capital      : Label  = $Margin/HBox/Right/VBox/Capital
@onready var lbl_record       : Label  = $Margin/HBox/Right/VBox/Record
@onready var lbl_queue        : Label  = $Margin/HBox/Right/VBox/Queue

var whipped          : bool = false
var coalition_sought : bool = false

const BILL_POOL : Array = [
	{ "name": "Universal Healthcare Act",     "desc": "Expand public healthcare to all citizens.",         "seats_needed": 151, "gdp_effect": -0.3, "unemployment_effect": -0.2, "deficit_effect": 0.8,  "approval_effect":  9.0, "ideology_lean": -4.0, "pop_effects": { "Working Class": 12.0, "Pensioners": 10.0, "Business Elite": -6.0 } },
	{ "name": "Corporate Tax Cut",            "desc": "Reduce corporate tax rate by 5 points.",            "seats_needed": 151, "gdp_effect":  0.6, "unemployment_effect": -0.3, "deficit_effect": 1.2,  "approval_effect": -3.0, "ideology_lean":  5.0, "pop_effects": { "Business Elite": 14.0, "Working Class": -8.0 } },
	{ "name": "Green Energy Fund",            "desc": "£50bn investment in renewable infrastructure.",     "seats_needed": 151, "gdp_effect":  0.2, "unemployment_effect": -0.4, "deficit_effect": 0.6,  "approval_effect":  6.0, "ideology_lean": -5.0, "pop_effects": { "Youth": 15.0, "Rural": 8.0, "Business Elite": -4.0 } },
	{ "name": "Border Security Bill",         "desc": "Increase enforcement and tighten immigration.",     "seats_needed": 151, "gdp_effect": -0.1, "unemployment_effect":  0.1, "deficit_effect": 0.4,  "approval_effect":  2.0, "ideology_lean":  6.0, "pop_effects": { "Rural": 10.0, "Youth": -8.0 } },
	{ "name": "Austerity Budget",             "desc": "Cut public spending by 8% to reduce deficit.",     "seats_needed": 151, "gdp_effect": -0.5, "unemployment_effect":  0.5, "deficit_effect":-1.5,  "approval_effect": -8.0, "ideology_lean":  4.0, "pop_effects": { "Business Elite": 10.0, "Working Class": -14.0, "Pensioners": -10.0 } },
	{ "name": "Workers Rights Expansion",     "desc": "4-day week and strengthened union rights.",         "seats_needed": 151, "gdp_effect": -0.2, "unemployment_effect":  0.3, "deficit_effect": 0.1,  "approval_effect":  7.0, "ideology_lean": -6.0, "pop_effects": { "Working Class": 18.0, "Middle Class": 8.0, "Business Elite": -10.0 } },
	{ "name": "Free University Tuition",      "desc": "Abolish tuition fees; fund via taxation.",         "seats_needed": 151, "gdp_effect":  0.1, "unemployment_effect": -0.1, "deficit_effect": 0.7,  "approval_effect":  8.0, "ideology_lean": -4.0, "pop_effects": { "Youth": 20.0, "Middle Class": 8.0, "Business Elite": -5.0 } },
	{ "name": "National Infrastructure Plan", "desc": "£80bn investment in roads, rail, broadband.",      "seats_needed": 151, "gdp_effect":  0.7, "unemployment_effect": -0.6, "deficit_effect": 1.0,  "approval_effect":  5.0, "ideology_lean":  0.0, "pop_effects": { "Working Class": 8.0, "Rural": 12.0 } },
	{ "name": "Rail Privatisation",           "desc": "Sell state-owned rail assets to private ops.",     "seats_needed": 151, "gdp_effect":  0.3, "unemployment_effect":  0.2, "deficit_effect":-0.5,  "approval_effect": -6.0, "ideology_lean":  7.0, "pop_effects": { "Business Elite": 12.0, "Working Class": -12.0 } },
	{ "name": "Emergency Housing Bill",       "desc": "200,000 social homes over 3 years.",               "seats_needed": 151, "gdp_effect":  0.4, "unemployment_effect": -0.5, "deficit_effect": 0.9,  "approval_effect": 10.0, "ideology_lean": -3.0, "pop_effects": { "Working Class": 14.0, "Youth": 12.0 } },
	{ "name": "National Security Act",        "desc": "Expands surveillance powers. Controversial.",      "seats_needed": 151, "gdp_effect":  0.0, "unemployment_effect":  0.0, "deficit_effect": 0.3,  "approval_effect": -4.0, "ideology_lean":  5.0, "pop_effects": { "Rural": 6.0, "Youth": -12.0 } },
	{ "name": "Wealth Redistribution Tax",   "desc": "Progressive wealth tax on top 1%.",                "seats_needed": 151, "gdp_effect": -0.2, "unemployment_effect":  0.1, "deficit_effect":-0.8,  "approval_effect":  6.0, "ideology_lean": -7.0, "pop_effects": { "Working Class": 14.0, "Middle Class": 6.0, "Business Elite": -20.0 } },
]

func _ready() -> void:
	btn_whip.pressed.connect(_on_whip)
	btn_coalition.pressed.connect(_on_coalition)
	btn_pass.pressed.connect(_on_pass)
	btn_drop.pressed.connect(_on_drop)
	btn_new_bill.pressed.connect(_on_new_bill)
	if GameData.pending_bill.is_empty():
		_new_bill()
	refresh()

func refresh() -> void:
	lbl_capital.text = "Political Capital:  %d / 40" % GameData.political_capital
	lbl_record.text  = "This Term:  %d passed  /  %d failed" % [GameData.bills_passed, GameData.bills_failed]

	if GameData.pending_bill.is_empty():
		_new_bill()
	var b = GameData.pending_bill
	lbl_bill_name.text = "📜  " + b["name"]
	lbl_bill_desc.text = b["desc"]

	lbl_bill_effects.text = (
		"If passed:\n"
		+ "  GDP:           %+.1f%%\n" % b["gdp_effect"]
		+ "  Unemployment:  %+.1f%%\n" % b["unemployment_effect"]
		+ "  Deficit:       %+.1f%% GDP\n" % b["deficit_effect"]
		+ "  Approval:      %+.1f\n" % b["approval_effect"]
		+ "  Ideology lean: %+.1f" % b["ideology_lean"]
	)

	var pop_txt = "Population effects:\n"
	for pop_name in b.get("pop_effects", {}):
		var delta = b["pop_effects"][pop_name]
		pop_txt += "  %-14s  %+.0f\n" % [pop_name, delta]
	lbl_groups_effect.text = pop_txt

	_refresh_tally()

	lbl_queue.text = "Seats needed: %d\nSupermajority: %d\nYour coalition: %d" % [
		b.get("seats_needed", 151), GameData.supermajority_threshold(), GameData.coalition_seats()
	]

func _refresh_tally() -> void:
	var your  = GameData.player_seat_count()
	var allied = 0
	for party in GameData.coalition_stance:
		if GameData.coalition_stance[party] == 1 and party != GameData.player_party:
			allied += GameData.seats.get(party, 0)
	var whip_bonus = 10 if whipped else 0
	var total      = your + allied + whip_bonus
	var needed     = GameData.pending_bill.get("seats_needed", 151)
	lbl_vote_tally.text = (
		"Vote projection:\n"
		+ "  Your seats:     %d\n" % your
		+ "  Allied seats:   %d\n" % allied
		+ ("  Whip bonus:     +%d\n" % whip_bonus if whipped else "")
		+ "  ─────────────────\n"
		+ "  Total:          %d / %d\n" % [total, needed]
		+ ("  ✔ PASS likely" if total >= needed else "  ✘ FAIL likely")
	)

func _on_whip() -> void:
	if whipped: return
	if not GameData.spend_capital(2):
		_show("Need 2 capital to whip."); return
	whipped = true
	btn_whip.disabled = true
	GameData.whip_count_this_term += 1
	GameData.scandal_meter    = clampf(GameData.scandal_meter    + 4.0, 0.0, 100.0)
	GameData.approval_rating  = clampf(GameData.approval_rating  - 2.0, 0.0, 100.0)
	GameData.legitimacy       = clampf(GameData.legitimacy        - 1.0, 0.0, 100.0)
	_show("Whip applied. Party discipline enforced. (-2 approval, -1 legitimacy, cost: 2 cap)")
	_refresh_tally()

func _on_coalition() -> void:
	if coalition_sought: return
	if not GameData.spend_capital(3):
		_show("Need 3 capital."); return
	coalition_sought = true
	btn_coalition.disabled = true
	var best = ""; var best_dist = 999.0
	for party in GameData.coalition_stance:
		if party == GameData.player_party or GameData.coalition_stance[party] != 0: continue
		var d = GameData.ideology_distance(party)
		if d < best_dist: best_dist = d; best = party
	if best == "": _show("No neutral parties to court."); return
	var chance = clampf(1.0 - best_dist / 14.0, 0.1, 0.85)
	if randf() < chance:
		GameData.coalition_stance[best] = 1
		_show("✔ %s agreed to back this bill!" % best)
	else:
		_show("✘ %s declined coalition talks." % best)
	_refresh_tally()

func _on_pass() -> void:
	var b    = GameData.pending_bill
	var your = GameData.player_seat_count()
	var allied = 0
	for party in GameData.coalition_stance:
		if GameData.coalition_stance[party] == 1 and party != GameData.player_party:
			allied += GameData.seats.get(party, 0)
	var total  = your + allied + (10 if whipped else 0)
	var needed = b.get("seats_needed", 151)
	btn_pass.disabled = true; btn_drop.disabled = true

	if total >= needed:
		GameData.gdp_growth      = clampf(GameData.gdp_growth      + b["gdp_effect"],         -5.0, 10.0)
		GameData.unemployment    = clampf(GameData.unemployment     + b["unemployment_effect"],  0.5, 18.0)
		GameData.budget_deficit  = clampf(GameData.budget_deficit   + b["deficit_effect"],      -5.0, 20.0)
		GameData.approval_rating = clampf(GameData.approval_rating  + b["approval_effect"],      0.0, 100.0)
		GameData.bills_passed   += 1
		for pop_name in b.get("pop_effects", {}):
			if GameData.pops.has(pop_name):
				GameData.pops[pop_name]["satisfaction"] = clampf(
					GameData.pops[pop_name]["satisfaction"] + b["pop_effects"][pop_name], 0.0, 100.0
				)
		_show("✔ PASSED: %s" % b["name"])
	else:
		GameData.approval_rating = clampf(GameData.approval_rating - 6.0, 0.0, 100.0)
		GameData.legitimacy      = clampf(GameData.legitimacy - 3.0, 0.0, 100.0)
		GameData.bills_failed   += 1
		_show("✘ FAILED: %s — not enough votes. (-6 approval, -3 legitimacy)" % b["name"])

	GameData.pending_bill = {}
	refresh()

func _on_drop() -> void:
	GameData.bills_failed   += 1
	GameData.approval_rating = clampf(GameData.approval_rating - 2.0, 0.0, 100.0)
	GameData.pending_bill    = {}
	btn_pass.disabled = true; btn_drop.disabled = true
	_show("Bill withdrawn. (-2 approval)")
	refresh()

func _on_new_bill() -> void:
	_new_bill(); refresh()

func _new_bill() -> void:
	GameData.pending_bill = BILL_POOL[randi() % BILL_POOL.size()].duplicate()
	whipped          = false
	coalition_sought = false
	btn_whip.disabled      = false
	btn_coalition.disabled = false
	btn_pass.disabled      = false
	btn_drop.disabled      = false
	lbl_result.visible     = false

func _show(msg: String) -> void:
	lbl_result.text    = msg
	lbl_result.visible = true
