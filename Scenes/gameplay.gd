extends Control

# ── Tab indices ────────────────────────────────────────────────────────────────
const TAB_OVERVIEW    = 0
const TAB_PARLIAMENT  = 1
const TAB_LEGISLATION = 2
const TAB_CABINET     = 3
const TAB_PRESS       = 4
const TAB_FOREIGN     = 5
const TAB_ELECTION    = 6
const TAB_ECONOMY     = 7
const TAB_GOALS       = 8

@onready var tab_container : TabContainer = $TabContainer

# ── Overview ───────────────────────────────────────────────────────────────────
@onready var lbl_name       : Label  = $TabContainer/Overview/Margin/VBox/PlayerName
@onready var lbl_party      : Label  = $TabContainer/Overview/Margin/VBox/Party
@onready var lbl_date       : Label  = $TabContainer/Overview/Margin/VBox/Date
@onready var lbl_capital    : Label  = $TabContainer/Overview/Margin/VBox/Capital
@onready var lbl_election   : Label  = $TabContainer/Overview/Margin/VBox/ElectionCountdown
@onready var lbl_approval   : Label  = $TabContainer/Overview/Margin/VBox/Approval
@onready var lbl_majority   : Label  = $TabContainer/Overview/Margin/VBox/MajorityStatus
@onready var lbl_economy_ov : Label  = $TabContainer/Overview/Margin/VBox/Economy
@onready var lbl_record     : Label  = $TabContainer/Overview/Margin/VBox/LegRecord
@onready var lbl_headline   : Label  = $TabContainer/Overview/Margin/VBox/Headline
@onready var lbl_opp_msg    : Label  = $TabContainer/Overview/Margin/VBox/OppMsg
@onready var lbl_crisis_ov  : Label  = $TabContainer/Overview/Margin/VBox/CrisisAlert
@onready var btn_next_month : Button = $TabContainer/Overview/Margin/VBox/NextMonthBtn

# ── Parliament ─────────────────────────────────────────────────────────────────
@onready var parliament_chart : Control       = $TabContainer/Parliament/Margin/VBox/Chart
@onready var legend_container : VBoxContainer = $TabContainer/Parliament/Margin/VBox/Legend
@onready var lbl_seats_header : Label         = $TabContainer/Parliament/Margin/VBox/SeatsHeader
@onready var coalition_info   : Label         = $TabContainer/Parliament/Margin/VBox/CoalitionInfo

# ── Legislation ────────────────────────────────────────────────────────────────
@onready var lbl_bill_name    : Label  = $TabContainer/Legislation/Margin/VBox/BillName
@onready var lbl_bill_desc    : Label  = $TabContainer/Legislation/Margin/VBox/BillDesc
@onready var lbl_bill_effects : Label  = $TabContainer/Legislation/Margin/VBox/BillEffects
@onready var lbl_vote_tally   : Label  = $TabContainer/Legislation/Margin/VBox/VoteTally
@onready var lbl_groups_effect: Label  = $TabContainer/Legislation/Margin/VBox/GroupsEffect
@onready var btn_whip         : Button = $TabContainer/Legislation/Margin/VBox/HBoxActions/BtnWhip
@onready var btn_coalition    : Button = $TabContainer/Legislation/Margin/VBox/HBoxActions/BtnCoalition
@onready var btn_pass_bill    : Button = $TabContainer/Legislation/Margin/VBox/HBoxVote/BtnPassBill
@onready var btn_drop_bill    : Button = $TabContainer/Legislation/Margin/VBox/HBoxVote/BtnDropBill
@onready var lbl_bill_result  : Label  = $TabContainer/Legislation/Margin/VBox/BillResult

# ── Cabinet ────────────────────────────────────────────────────────────────────
@onready var lbl_cabinet_slots   : Label        = $TabContainer/Cabinet/Margin/VBox/CabinetSlots
@onready var lbl_capital_cab     : Label        = $TabContainer/Cabinet/Margin/VBox/CapitalLabel
@onready var lbl_candidates      : Label        = $TabContainer/Cabinet/Margin/VBox/Candidates
@onready var option_slot         : OptionButton = $TabContainer/Cabinet/Margin/VBox/HBoxAppoint/SlotOption
@onready var option_candidate    : OptionButton = $TabContainer/Cabinet/Margin/VBox/HBoxAppoint/CandidateOption
@onready var btn_appoint         : Button       = $TabContainer/Cabinet/Margin/VBox/HBoxAppoint/BtnAppoint
@onready var btn_dismiss         : Button       = $TabContainer/Cabinet/Margin/VBox/HBoxAppoint/BtnDismiss
@onready var lbl_cabinet_result  : Label        = $TabContainer/Cabinet/Margin/VBox/CabinetResult

# ── Press ──────────────────────────────────────────────────────────────────────
@onready var lbl_headline_press  : Label  = $TabContainer/Press/Margin/VBox/HeadlinePress
@onready var lbl_media_hostility : Label  = $TabContainer/Press/Margin/VBox/MediaHostility
@onready var lbl_groups_press    : Label  = $TabContainer/Press/Margin/VBox/GroupsPress
@onready var btn_press_conf      : Button = $TabContainer/Press/Margin/VBox/HBoxPress/BtnPressConf
@onready var btn_buy_media       : Button = $TabContainer/Press/Margin/VBox/HBoxPress/BtnBuyMedia
@onready var lbl_press_result    : Label  = $TabContainer/Press/Margin/VBox/PressResult

# ── Foreign ────────────────────────────────────────────────────────────────────
@onready var lbl_trade_deals     : Label        = $TabContainer/Foreign/Margin/VBox/TradeDeals
@onready var lbl_alliances       : Label        = $TabContainer/Foreign/Margin/VBox/Alliances
@onready var lbl_crisis_foreign  : Label        = $TabContainer/Foreign/Margin/VBox/CrisisLabel
@onready var option_trade        : OptionButton = $TabContainer/Foreign/Margin/VBox/HBoxTrade/TradeOption
@onready var btn_sign_trade      : Button       = $TabContainer/Foreign/Margin/VBox/HBoxTrade/BtnSignTrade
@onready var option_alliance     : OptionButton = $TabContainer/Foreign/Margin/VBox/HBoxAlliance/AllianceOption
@onready var btn_join_alliance   : Button       = $TabContainer/Foreign/Margin/VBox/HBoxAlliance/BtnJoinAlliance
@onready var btn_resolve_crisis  : Button       = $TabContainer/Foreign/Margin/VBox/HBoxCrisis/BtnResolveCrisis
@onready var btn_ignore_crisis   : Button       = $TabContainer/Foreign/Margin/VBox/HBoxCrisis/BtnIgnoreCrisis
@onready var lbl_foreign_result  : Label        = $TabContainer/Foreign/Margin/VBox/ForeignResult

# ── Election ───────────────────────────────────────────────────────────────────
@onready var lbl_polling         : Label  = $TabContainer/Election/Margin/VBox/Polling
@onready var lbl_funds           : Label  = $TabContainer/Election/Margin/VBox/Funds
@onready var btn_campaign_ads    : Button = $TabContainer/Election/Margin/VBox/HBoxCampaign/BtnAds
@onready var btn_rally           : Button = $TabContainer/Election/Margin/VBox/HBoxCampaign/BtnRally
@onready var btn_attack          : Button = $TabContainer/Election/Margin/VBox/HBoxCampaign/BtnAttack
@onready var btn_hold_election   : Button = $TabContainer/Election/Margin/VBox/BtnHoldElection
@onready var lbl_election_result : Label  = $TabContainer/Election/Margin/VBox/ElectionResult

# ── Economy ────────────────────────────────────────────────────────────────────
@onready var lbl_gdp             : Label  = $TabContainer/Economy/Margin/VBox/GDP
@onready var lbl_unemployment    : Label  = $TabContainer/Economy/Margin/VBox/Unemployment
@onready var lbl_deficit         : Label  = $TabContainer/Economy/Margin/VBox/Deficit
@onready var lbl_econ_groups     : Label  = $TabContainer/Economy/Margin/VBox/EconGroups
@onready var btn_stimulus        : Button = $TabContainer/Economy/Margin/VBox/HBoxEcon/BtnStimulus
@onready var btn_austerity       : Button = $TabContainer/Economy/Margin/VBox/HBoxEcon/BtnAusterity
@onready var btn_rate_cut        : Button = $TabContainer/Economy/Margin/VBox/HBoxEcon/BtnRateCut
@onready var lbl_econ_result     : Label  = $TabContainer/Economy/Margin/VBox/EconResult

# ── Goals ──────────────────────────────────────────────────────────────────────
@onready var lbl_goals           : Label  = $TabContainer/Goals/Margin/VBox/GoalsText
@onready var lbl_legacy          : Label  = $TabContainer/Goals/Margin/VBox/LegacyScore
@onready var btn_set_goals       : Button = $TabContainer/Goals/Margin/VBox/BtnSetGoals
@onready var lbl_goals_result    : Label  = $TabContainer/Goals/Margin/VBox/GoalsResult

# ── Managers ───────────────────────────────────────────────────────────────────
var cabinet_mgr    : Node = null
var media_mgr      : Node = null
var foreign_mgr    : Node = null
var opposition_ai  : Node = null
var goals_mgr      : Node = null
var bill_gen       : Node = null

# ── Legislation state ──────────────────────────────────────────────────────────
var bill_active       : bool = false
var whipped           : bool = false
var coalition_sought  : bool = false
var candidates_cache  : Array = []

func _ready() -> void:
	_init_managers()
	_connect_signals()
	goals_mgr.generate_term_goals()
	_load_new_bill()
	_refresh_all()

func _init_managers() -> void:
	cabinet_mgr   = _make_child("res://Scenes/cabinet_manager.gd")
	media_mgr     = _make_child("res://Scenes/media_manager.gd")
	foreign_mgr   = _make_child("res://Scenes/foreign_manager.gd")
	opposition_ai = _make_child("res://Scenes/opposition_ai.gd")
	goals_mgr     = _make_child("res://Scenes/goals_manager.gd")
	bill_gen      = _make_child("res://Scenes/bill_generator.gd")

func _make_child(script_path: String) -> Node:
	var n = Node.new()
	n.set_script(load(script_path))
	add_child(n)
	return n

func _connect_signals() -> void:
	btn_next_month.pressed.connect(_on_next_month)
	# Legislation
	btn_whip.pressed.connect(_on_whip)
	btn_coalition.pressed.connect(_on_seek_coalition)
	btn_pass_bill.pressed.connect(_on_pass_bill)
	btn_drop_bill.pressed.connect(_on_drop_bill)
	# Cabinet
	btn_appoint.pressed.connect(_on_appoint)
	btn_dismiss.pressed.connect(_on_dismiss)
	# Press
	btn_press_conf.pressed.connect(_on_press_conference)
	btn_buy_media.pressed.connect(_on_buy_media)
	# Foreign
	btn_sign_trade.pressed.connect(_on_sign_trade)
	btn_join_alliance.pressed.connect(_on_join_alliance)
	btn_resolve_crisis.pressed.connect(_on_resolve_crisis)
	btn_ignore_crisis.pressed.connect(_on_ignore_crisis)
	# Election
	btn_campaign_ads.pressed.connect(func(): _spend_campaign(2, 4.0, "Ad blitz! +4 polling."))
	btn_rally.pressed.connect(func(): _spend_campaign(1, 2.0, "Rally energises base. +2 polling."))
	btn_attack.pressed.connect(_attack_largest_rival)
	btn_hold_election.pressed.connect(_on_hold_election)
	# Economy
	btn_stimulus.pressed.connect(func(): _economy_action("stimulus"))
	btn_austerity.pressed.connect(func(): _economy_action("austerity"))
	btn_rate_cut.pressed.connect(func(): _economy_action("rate_cut"))
	# Goals
	btn_set_goals.pressed.connect(_on_set_goals)

# ── Master refresh ─────────────────────────────────────────────────────────────
func _refresh_all() -> void:
	_refresh_overview()
	_refresh_parliament()
	_refresh_legislation()
	_refresh_cabinet()
	_refresh_press()
	_refresh_foreign()
	_refresh_election()
	_refresh_economy()
	_refresh_goals()

# ── Next Month ─────────────────────────────────────────────────────────────────
func _on_next_month() -> void:
	GameData.advance_month()
	cabinet_mgr.tick_ministers()
	foreign_mgr.maybe_trigger_crisis()

	var headline = media_mgr.generate_headline()
	var opp_msg  = opposition_ai.tick()

	lbl_headline.text = "📰 " + headline
	lbl_opp_msg.text  = opp_msg if opp_msg != "" else ""

	if not GameData.active_crisis.is_empty() and not GameData.active_crisis.get("resolved", true):
		lbl_crisis_ov.text    = "⚠ CRISIS: " + GameData.active_crisis.get("title", "") + " — go to Foreign Policy!"
		lbl_crisis_ov.visible = true
	else:
		lbl_crisis_ov.visible = false

	_load_new_bill()
	_refresh_all()

	if GameData.election_active:
		tab_container.current_tab = TAB_ELECTION
		lbl_election_result.text = "⚠ An election has been called! Campaign before holding the vote."

# ── Overview ───────────────────────────────────────────────────────────────────
func _refresh_overview() -> void:
	lbl_name.text       = "Politician:  "  + GameData.player_full_name()
	lbl_party.text      = "Party:  "       + GameData.player_party
	lbl_date.text       = "Date:  "        + GameData.month_name() + " " + str(GameData.current_year)
	lbl_capital.text    = "Political Capital:  %d / 40" % GameData.political_capital
	lbl_approval.text   = "Approval:  %.1f%%" % GameData.approval_rating
	lbl_economy_ov.text = GameData.economy_summary()
	lbl_record.text     = "Legislation:  %d passed  /  %d failed" % [GameData.bills_passed, GameData.bills_failed]

	var ml = GameData.months_until_election
	lbl_election.text = "Next Election:  %d months  (%dy %dm)" % [ml, ml / 12, ml % 12]

	if GameData.has_majority():
		lbl_majority.text = "✔ MAJORITY  —  %d / %d seats" % [GameData.player_seat_count(), GameData.TOTAL_SEATS]
		lbl_majority.add_theme_color_override("font_color", Color(0.2, 0.85, 0.2))
	elif GameData.has_coalition_majority():
		lbl_majority.text = "◈ COALITION MAJORITY  —  %d / %d seats" % [GameData.coalition_seats(), GameData.TOTAL_SEATS]
		lbl_majority.add_theme_color_override("font_color", Color(0.9, 0.75, 0.1))
	else:
		lbl_majority.text = "✘ OPPOSITION  —  %d / %d seats" % [GameData.player_seat_count(), GameData.TOTAL_SEATS]
		lbl_majority.add_theme_color_override("font_color", Color(0.9, 0.3, 0.3))

# ── Parliament ─────────────────────────────────────────────────────────────────
func _refresh_parliament() -> void:
	parliament_chart.refresh()
	for child in legend_container.get_children():
		child.queue_free()

	var sorted = GameData.seats.keys()
	sorted.sort_custom(func(a, b): return GameData.seats[a] > GameData.seats[b])

	for party in sorted:
		var count     = GameData.seats[party]
		var pct       = float(count) / float(GameData.TOTAL_SEATS) * 100.0
		var is_player = (party == GameData.player_party)
		var stance    = GameData.coalition_stance.get(party, 0)
		var stance_str = " [ALLIED]" if stance == 1 else (" [HOSTILE]" if stance == -1 else "")
		var leader    = GameData.party_leaders.get(party, "Unknown")

		var row = HBoxContainer.new()
		row.add_theme_constant_override("separation", 12)

		var dot = ColorRect.new()
		dot.custom_minimum_size = Vector2(18, 18)
		dot.color = GameData.party_colors.get(party, Color.GRAY)

		var lbl = Label.new()
		lbl.text = "%s%s%s  —  %d seats (%.1f%%)  |  Leader: %s" % [
			"★ " if is_player else "   ", party, stance_str, count, pct, leader
		]
		lbl.add_theme_font_size_override("font_size", 16)
		if is_player:
			lbl.add_theme_color_override("font_color", Color(1.0, 0.85, 0.1))
		elif stance == 1:
			lbl.add_theme_color_override("font_color", Color(0.4, 0.9, 0.4))
		elif stance == -1:
			lbl.add_theme_color_override("font_color", Color(0.9, 0.4, 0.4))

		row.add_child(dot)
		row.add_child(lbl)
		legend_container.add_child(row)

	lbl_seats_header.text = "Parliament  —  %d total seats  |  Majority: %d" % [GameData.TOTAL_SEATS, GameData.majority_threshold()]
	coalition_info.text   = "Your coalition controls %d seats." % GameData.coalition_seats()

# ── Legislation ────────────────────────────────────────────────────────────────
func _load_new_bill() -> void:
	GameData.pending_bill = bill_gen.get_random_bill()
	bill_active      = true
	whipped          = false
	coalition_sought = false
	lbl_bill_result.visible = false
	btn_whip.disabled      = false
	btn_coalition.disabled = false
	btn_pass_bill.disabled = false
	btn_drop_bill.disabled = false

func _refresh_legislation() -> void:
	if not bill_active or GameData.pending_bill.is_empty(): return
	var b = GameData.pending_bill
	lbl_bill_name.text    = "📜  " + b["name"]
	lbl_bill_desc.text    = b["desc"]
	lbl_bill_effects.text = (
		"Effects if passed:\n"
		+ "  GDP Growth:      %+.1f%%\n" % b["gdp_effect"]
		+ "  Unemployment:    %+.1f%%\n" % b["unemployment_effect"]
		+ "  Budget Deficit:  %+.1f%% GDP\n" % b["deficit_effect"]
		+ "  Approval:        %+.1f\n" % b["approval_effect"]
		+ "  Seats needed:    %d" % b["seats_needed"]
	)
	# Show which public groups are helped/hurt
	var group_lines = "Public group impact:"
	if b["ideology_lean"] < -2:
		group_lines += "\n  Workers ▲   Youth ▲   Business ▼"
	elif b["ideology_lean"] > 2:
		group_lines += "\n  Business ▲   Pensioners ▲   Workers ▼"
	else:
		group_lines += "\n  Balanced — minor effects across groups"
	lbl_groups_effect.text = group_lines
	_refresh_vote_tally()

func _refresh_vote_tally() -> void:
	var your_seats   = GameData.player_seat_count()
	var allied_seats = 0
	for party in GameData.coalition_stance:
		if GameData.coalition_stance[party] == 1 and party != GameData.player_party:
			allied_seats += GameData.seats.get(party, 0)
	var whip_bonus  = 8 if whipped else 0
	var total_votes = your_seats + allied_seats + whip_bonus
	var needed      = GameData.pending_bill.get("seats_needed", 151)
	lbl_vote_tally.text = (
		"Vote projection:\n"
		+ "  Your seats:      %d\n" % your_seats
		+ "  Allied seats:    %d\n" % allied_seats
		+ ("  Whip bonus:      +%d\n" % whip_bonus if whipped else "")
		+ "  ─────────────────────\n"
		+ "  Total:           %d / %d needed\n" % [total_votes, needed]
		+ ("  ✔ Likely to PASS" if total_votes >= needed else "  ✘ Likely to FAIL")
	)

func _on_whip() -> void:
	if whipped: return
	if not GameData.spend_capital(2):
		lbl_bill_result.text    = "Not enough political capital to whip (need 2)."
		lbl_bill_result.visible = true
		return
	whipped = true
	btn_whip.disabled = true
	GameData.whip_count_this_term += 1
	GameData.scandal_meter = clampf(GameData.scandal_meter + 3.0, 0.0, 100.0)
	GameData.approval_rating = clampf(GameData.approval_rating - 2.0, 0.0, 100.0)
	lbl_bill_result.text    = "Party whip applied. (-2 approval, +scandal risk, Cost: 2 capital)"
	lbl_bill_result.visible = true
	_refresh_vote_tally()

func _on_seek_coalition() -> void:
	if coalition_sought: return
	if not GameData.spend_capital(3):
		lbl_bill_result.text    = "Not enough political capital to court allies (need 3)."
		lbl_bill_result.visible = true
		return
	coalition_sought = true
	btn_coalition.disabled = true

	var best_party = ""
	var best_dist  = 999.0
	for party in GameData.coalition_stance:
		if party == GameData.player_party: continue
		if GameData.coalition_stance[party] != 0: continue
		var dist = GameData.ideology_distance(party)
		if dist < best_dist:
			best_dist  = dist
			best_party = party

	if best_party == "":
		lbl_bill_result.text = "No neutral parties available. (Cost: 3 capital)"
		lbl_bill_result.visible = true
		return

	var chance = clampf(1.0 - (best_dist / 14.0), 0.15, 0.85)
	if randf() < chance:
		GameData.coalition_stance[best_party] = 1
		lbl_bill_result.text = "✔ %s agreed to support the bill! (Cost: 3 capital)" % best_party
	else:
		lbl_bill_result.text = "✘ %s declined. (Cost: 3 capital)" % best_party
	lbl_bill_result.visible = true
	_refresh_vote_tally()
	_refresh_parliament()

func _on_pass_bill() -> void:
	var b          = GameData.pending_bill
	var your_seats = GameData.player_seat_count()
	var allied     = 0
	for party in GameData.coalition_stance:
		if GameData.coalition_stance[party] == 1 and party != GameData.player_party:
			allied += GameData.seats.get(party, 0)
	var total  = your_seats + allied + (8 if whipped else 0)
	var needed = b.get("seats_needed", 151)

	btn_pass_bill.disabled = true
	btn_drop_bill.disabled = true
	bill_active = false

	if total >= needed:
		GameData.gdp_growth      = clampf(GameData.gdp_growth      + b["gdp_effect"],         -5.0, 10.0)
		GameData.unemployment    = clampf(GameData.unemployment     + b["unemployment_effect"],  0.5, 20.0)
		GameData.budget_deficit  = clampf(GameData.budget_deficit   + b["deficit_effect"],      -5.0, 20.0)
		GameData.approval_rating = clampf(GameData.approval_rating  + b["approval_effect"],     0.0, 100.0)
		GameData.bills_passed   += 1
		_apply_group_effects(b, true)
		lbl_bill_result.text = "✔ PASSED: %s" % b["name"]
	else:
		GameData.approval_rating = clampf(GameData.approval_rating - 5.0, 0.0, 100.0)
		GameData.bills_failed   += 1
		lbl_bill_result.text = "✘ FAILED: %s — not enough votes. (-5 approval)" % b["name"]

	lbl_bill_result.visible = true
	_refresh_overview()
	_refresh_economy()
	_refresh_goals()

func _apply_group_effects(b: Dictionary, passed: bool) -> void:
	var lean = b.get("ideology_lean", 0.0)
	var mult = 1.0 if passed else -0.5
	if lean < -2:
		GameData.public_groups["Workers"]    = clampf(GameData.public_groups["Workers"]    + 8.0  * mult, 0.0, 100.0)
		GameData.public_groups["Youth"]      = clampf(GameData.public_groups["Youth"]      + 5.0  * mult, 0.0, 100.0)
		GameData.public_groups["Business"]   = clampf(GameData.public_groups["Business"]   - 6.0  * mult, 0.0, 100.0)
	elif lean > 2:
		GameData.public_groups["Business"]   = clampf(GameData.public_groups["Business"]   + 8.0  * mult, 0.0, 100.0)
		GameData.public_groups["Pensioners"] = clampf(GameData.public_groups["Pensioners"] + 5.0  * mult, 0.0, 100.0)
		GameData.public_groups["Workers"]    = clampf(GameData.public_groups["Workers"]    - 6.0  * mult, 0.0, 100.0)
	else:
		for g in GameData.public_groups:
			GameData.public_groups[g] = clampf(GameData.public_groups[g] + 2.0 * mult, 0.0, 100.0)

func _on_drop_bill() -> void:
	GameData.bills_failed += 1
	GameData.approval_rating = clampf(GameData.approval_rating - 2.0, 0.0, 100.0)
	bill_active = false
	btn_pass_bill.disabled = true
	btn_drop_bill.disabled = true
	lbl_bill_result.text    = "Bill withdrawn. (-2 approval)"
	lbl_bill_result.visible = true
	_refresh_overview()

# ── Cabinet ────────────────────────────────────────────────────────────────────
func _refresh_cabinet() -> void:
	lbl_capital_cab.text = "Political Capital:  %d / 40  (Appoint costs 3)" % GameData.political_capital

	var slots_text = "Current Cabinet:\n"
	for slot in GameData.cabinet:
		var m = GameData.cabinet[slot]
		if m.is_empty():
			slots_text += "  %-18s  [VACANT]\n" % slot
		else:
			slots_text += "  %-18s  %s  (Competence: %d/10)\n" % [slot, m["name"], m["competence"]]
	lbl_cabinet_slots.text = slots_text

	# Populate slot dropdown
	option_slot.clear()
	for slot in GameData.cabinet:
		option_slot.add_item(slot)

	# Populate candidate dropdown
	candidates_cache = cabinet_mgr.get_candidates(6)
	option_candidate.clear()
	for c in candidates_cache:
		option_candidate.add_item("%s  (Comp: %d, %s)" % [c["name"], c["competence"], c["party"]])

	lbl_candidates.text = "Available Candidates:"

func _on_appoint() -> void:
	var slot_idx = option_slot.selected
	var cand_idx = option_candidate.selected
	if slot_idx < 0 or cand_idx < 0 or cand_idx >= candidates_cache.size():
		lbl_cabinet_result.text    = "Select a slot and a candidate."
		lbl_cabinet_result.visible = true
		return
	var slot      = option_slot.get_item_text(slot_idx)
	var candidate = candidates_cache[cand_idx]
	var msg = cabinet_mgr.appoint(slot, candidate)
	lbl_cabinet_result.text    = msg
	lbl_cabinet_result.visible = true
	_refresh_cabinet()
	_refresh_overview()

func _on_dismiss() -> void:
	var slot_idx = option_slot.selected
	if slot_idx < 0:
		return
	var slot = option_slot.get_item_text(slot_idx)
	var msg  = cabinet_mgr.dismiss(slot)
	lbl_cabinet_result.text    = msg
	lbl_cabinet_result.visible = true
	_refresh_cabinet()
	_refresh_overview()

# ── Press ──────────────────────────────────────────────────────────────────────
func _refresh_press() -> void:
	lbl_headline_press.text  = "Latest Headline:\n" + GameData.last_headline
	lbl_media_hostility.text = "Media Hostility:  %.0f / 100  %s" % [
		GameData.media_hostility,
		"(HOSTILE — amplifying bad news!)" if GameData.media_hostility > 50 else "(Manageable)"
	]
	var groups_text = "Public Group Satisfaction:\n"
	for g in GameData.public_groups:
		var val  = GameData.public_groups[g]
		var icon = "⚠ HOSTILE" if val < GameData.GROUP_HOSTILE_THRESHOLD else ("✔" if val >= 60 else "~")
		groups_text += "  %-12s  %.0f%%  %s\n" % [g, val, icon]
	lbl_groups_press.text = groups_text

func _on_press_conference() -> void:
	var result = media_mgr.press_conference()
	lbl_press_result.text    = result["msg"]
	lbl_press_result.visible = true
	_refresh_press()
	_refresh_overview()

func _on_buy_media() -> void:
	var msg = media_mgr.buy_media_outlet()
	lbl_press_result.text    = msg
	lbl_press_result.visible = true
	_refresh_press()

# ── Foreign ────────────────────────────────────────────────────────────────────
func _refresh_foreign() -> void:
	# Trade deals
	if GameData.trade_deals.is_empty():
		lbl_trade_deals.text = "Active Trade Deals:  None"
	else:
		var t = "Active Trade Deals:\n"
		for d in GameData.trade_deals:
			t += "  %s  —  GDP +%.1f%%  (%d months left)\n" % [d["nation"], d["gdp_bonus"], d["expires_in_months"]]
		lbl_trade_deals.text = t

	# Alliances
	if GameData.alliances.is_empty():
		lbl_alliances.text = "Alliances:  None"
	else:
		var a = "Alliances:\n"
		for al in GameData.alliances:
			a += "  %s  —  +%.1f approval/month\n" % [al["nation"], al["approval_bonus"]]
		lbl_alliances.text = a

	# Crisis
	var c = GameData.active_crisis
	if c.is_empty() or c.get("resolved", true):
		lbl_crisis_foreign.text = "Active Crisis:  None"
		btn_resolve_crisis.disabled = true
		btn_ignore_crisis.disabled  = true
	else:
		lbl_crisis_foreign.text = (
			"⚠ CRISIS: %s\n%s\nDeadline: %d months  |  Severity: %d/3  |  Resolve cost: %d capital" % [
				c["title"], c["desc"], c["deadline_months"], c["severity"], c["resolve_cost"]
			]
		)
		btn_resolve_crisis.disabled = false
		btn_ignore_crisis.disabled  = false

	# Trade option
	option_trade.clear()
	for p in foreign_mgr.available_trade_partners():
		option_trade.add_item("%s  (GDP +%.1f%%, %d months, Cost: %d cap)" % [
			p["nation"], p["gdp_bonus"], p["duration"], p["cost"]
		])

	# Alliance option
	option_alliance.clear()
	for a in foreign_mgr.available_alliances():
		option_alliance.add_item("%s  (+%.1f approval/mo, Cost: %d cap)" % [
			a["nation"], a["approval_bonus"], a["cost"]
		])

func _on_sign_trade() -> void:
	var idx = option_trade.selected
	var partners = foreign_mgr.available_trade_partners()
	if idx < 0 or idx >= partners.size():
		lbl_foreign_result.text = "Select a trade partner first."
		lbl_foreign_result.visible = true
		return
	var msg = foreign_mgr.sign_trade_deal(partners[idx])
	lbl_foreign_result.text    = msg
	lbl_foreign_result.visible = true
	_refresh_foreign()
	_refresh_overview()

func _on_join_alliance() -> void:
	var idx = option_alliance.selected
	var alliances = foreign_mgr.available_alliances()
	if idx < 0 or idx >= alliances.size():
		lbl_foreign_result.text = "Select an alliance first."
		lbl_foreign_result.visible = true
		return
	var msg = foreign_mgr.join_alliance(alliances[idx])
	lbl_foreign_result.text    = msg
	lbl_foreign_result.visible = true
	_refresh_foreign()
	_refresh_overview()

func _on_resolve_crisis() -> void:
	var msg = foreign_mgr.resolve_crisis()
	lbl_foreign_result.text    = msg
	lbl_foreign_result.visible = true
	lbl_crisis_ov.visible      = false
	_refresh_foreign()
	_refresh_overview()

func _on_ignore_crisis() -> void:
	var msg = foreign_mgr.ignore_crisis()
	lbl_foreign_result.text    = msg
	lbl_foreign_result.visible = true
	lbl_crisis_ov.visible      = false
	_refresh_foreign()
	_refresh_overview()

# ── Election ───────────────────────────────────────────────────────────────────
func _refresh_election() -> void:
	var sorted = GameData.polling.keys()
	sorted.sort_custom(func(a, b): return GameData.polling[a] > GameData.polling[b])
	var poll_text = "Current Polling:\n"
	for party in sorted:
		poll_text += "  %s%s:  %.1f%%\n" % [
			"★ " if party == GameData.player_party else "  ", party, GameData.polling[party]
		]
	lbl_polling.text = poll_text
	lbl_funds.text   = "Campaign Funds:  %d points" % GameData.campaign_funds

	var active = GameData.election_active
	btn_campaign_ads.disabled  = not active or GameData.campaign_funds < 2
	btn_rally.disabled         = not active or GameData.campaign_funds < 1
	btn_attack.disabled        = not active or GameData.campaign_funds < 1
	btn_hold_election.disabled = not active
	if not active:
		lbl_election_result.text = "No election scheduled.\nElections are called every 4 years."

func _spend_campaign(cost: int, poll_boost: float, msg: String) -> void:
	if GameData.campaign_funds < cost: return
	GameData.campaign_funds -= cost
	GameData.polling[GameData.player_party] = clampf(
		GameData.polling.get(GameData.player_party, 20.0) + poll_boost, 1.0, 70.0
	)
	GameData._normalise_polling()
	lbl_election_result.text = msg
	_refresh_election()

func _attack_largest_rival() -> void:
	if GameData.campaign_funds < 1: return
	GameData.campaign_funds -= 1
	var rival = ""
	var best  = 0.0
	for party in GameData.polling:
		if party == GameData.player_party: continue
		if GameData.polling[party] > best:
			best  = GameData.polling[party]
			rival = party
	if rival == "":
		return
	GameData.polling[rival] = clampf(GameData.polling[rival] - 3.0, 1.0, 70.0)
	GameData._normalise_polling()
	lbl_election_result.text = "Attack ads against %s. Their polling drops." % rival
	_refresh_election()

func _on_hold_election() -> void:
	GameData.run_election()
	goals_mgr.generate_term_goals()
	lbl_election_result.text = (
		"Election held!\n"
		+ "Your party (%s):  %d seats\n" % [GameData.player_party, GameData.player_seat_count()]
		+ ("✔ Majority!" if GameData.has_majority() else "✘ No majority — seek coalition partners.")
	)
	_load_new_bill()
	_refresh_all()

# ── Economy ────────────────────────────────────────────────────────────────────
func _refresh_economy() -> void:
	lbl_gdp.text          = "GDP Growth:      %+.1f%%  %s" % [GameData.gdp_growth,    _tri(GameData.gdp_growth,    2.0)]
	lbl_unemployment.text = "Unemployment:    %.1f%%   %s" % [GameData.unemployment,   _tri(4.5, GameData.unemployment)]
	lbl_deficit.text      = "Budget Deficit:  %.1f%% GDP  %s" % [GameData.budget_deficit, _tri(0.0, GameData.budget_deficit)]

	var g_text = "Public Group Satisfaction:\n"
	for g in GameData.public_groups:
		var val = GameData.public_groups[g]
		g_text += "  %-12s  %.0f%%\n" % [g, val]
	lbl_econ_groups.text = g_text

func _tri(good_high: float, value: float) -> String:
	return "▲" if value >= good_high else "▼"

func _economy_action(action: String) -> void:
	lbl_econ_result.visible = true
	match action:
		"stimulus":
			GameData.gdp_growth      = clampf(GameData.gdp_growth      + 0.8,  -5.0, 10.0)
			GameData.budget_deficit  = clampf(GameData.budget_deficit   + 1.0,  -5.0, 20.0)
			GameData.approval_rating = clampf(GameData.approval_rating  + 3.0,   0.0, 100.0)
			GameData.public_groups["Workers"] = clampf(GameData.public_groups["Workers"] + 5.0, 0.0, 100.0)
			lbl_econ_result.text = "Stimulus deployed. GDP ▲, deficit ▲, workers pleased. (+3 approval)"
		"austerity":
			GameData.gdp_growth      = clampf(GameData.gdp_growth      - 0.5,  -5.0, 10.0)
			GameData.budget_deficit  = clampf(GameData.budget_deficit   - 1.2,  -5.0, 20.0)
			GameData.approval_rating = clampf(GameData.approval_rating  - 5.0,   0.0, 100.0)
			GameData.public_groups["Business"]  = clampf(GameData.public_groups["Business"]  + 6.0, 0.0, 100.0)
			GameData.public_groups["Workers"]   = clampf(GameData.public_groups["Workers"]   - 8.0, 0.0, 100.0)
			lbl_econ_result.text = "Austerity cuts. Deficit ▼, growth hit. Workers angry. (-5 approval)"
		"rate_cut":
			GameData.gdp_growth      = clampf(GameData.gdp_growth      + 0.4,  -5.0, 10.0)
			GameData.unemployment    = clampf(GameData.unemployment     - 0.3,   0.5, 20.0)
			GameData.approval_rating = clampf(GameData.approval_rating  + 1.0,   0.0, 100.0)
			GameData.public_groups["Youth"] = clampf(GameData.public_groups["Youth"] + 4.0, 0.0, 100.0)
			lbl_econ_result.text = "Rate cut. GDP ▲, jobs ▲, youth benefit. (+1 approval)"
	_refresh_economy()
	_refresh_overview()

# ── Goals ──────────────────────────────────────────────────────────────────────
func _refresh_goals() -> void:
	lbl_goals.text  = goals_mgr.goals_summary()
	lbl_legacy.text = "Legacy Score:  %d  (carries across terms)" % GameData.legacy_score

func _on_set_goals() -> void:
	if not GameData.term_goals.is_empty():
		lbl_goals_result.text    = "Goals already set for this term."
		lbl_goals_result.visible = true
		return
	goals_mgr.generate_term_goals()
	lbl_goals_result.text    = "New term goals generated."
	lbl_goals_result.visible = true
	_refresh_goals()