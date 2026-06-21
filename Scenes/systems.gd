extends Node
# ═══════════════════════════════════════════════════════════════════════════════
# SYSTEMS — all monthly simulation logic, kept out of game_data and UI
# ═══════════════════════════════════════════════════════════════════════════════

signal month_processed(events: Array)   # emits list of narrative strings

func process_month() -> Array:
	var events : Array = []

	_tick_economy(events)
	_tick_factions(events)
	_tick_pops(events)
	_tick_diplomacy(events)
	_tick_cabinet(events)
	_tick_media(events)
	_tick_crisis(events)
	_tick_scandal(events)
	_tick_polling(events)
	_tick_legitimacy(events)
	_regen_capital(events)
	_check_goals(events)
	_opposition_ai(events)

	emit_signal("month_processed", events)
	return events

# ── Economy ────────────────────────────────────────────────────────────────────
func _tick_economy(ev: Array) -> void:
	# Cabinet economy minister passive bonus
	var econ_comp = GameData.cabinet_competence("Economy")
	GameData.gdp_growth = clampf(GameData.gdp_growth + econ_comp * 0.02, -5.0, 10.0)

	# Unemployment reacts to GDP
	if GameData.gdp_growth > 3.0:
		GameData.unemployment = max(3.0, GameData.unemployment - 0.15)
	elif GameData.gdp_growth < 0.5:
		GameData.unemployment = min(18.0, GameData.unemployment + 0.25)
	else:
		GameData.unemployment += (5.0 - GameData.unemployment) * 0.04

	# Inflation reacts to deficit and growth
	GameData.inflation = clampf(
		GameData.inflation + (GameData.budget_deficit * 0.05) + (GameData.gdp_growth * 0.02) - 0.1,
		-1.0, 15.0
	)

	# GDP absolute grows
	GameData.gdp_absolute *= (1.0 + GameData.gdp_growth / 100.0 / 12.0)

	# Approval pressure from economy
	var pressure = 0.0
	if GameData.gdp_growth > 3.0:   pressure += 0.6
	elif GameData.gdp_growth < 0.0: pressure -= 1.5
	if GameData.unemployment > 10.0: pressure -= 1.2
	elif GameData.unemployment < 4.0: pressure += 0.6
	if GameData.inflation > 6.0:    pressure -= 0.8
	GameData.approval_rating = clampf(GameData.approval_rating + pressure, 0.0, 100.0)

	if GameData.gdp_growth < -1.0:
		ev.append("📉 The economy is contracting. GDP growth at %.1f%%." % GameData.gdp_growth)
	elif GameData.unemployment > 11.0:
		ev.append("📉 Unemployment surges to %.1f%%. Public anger rising." % GameData.unemployment)

# ── Party Factions ─────────────────────────────────────────────────────────────
func _tick_factions(ev: Array) -> void:
	for party in GameData.party_factions:
		var factions = GameData.party_factions[party]
		var total    = 0.0
		for f in factions: total += factions[f]

		# Dominant faction slowly consolidates power (by 1–2 pts/month)
		var dom = GameData.dominant_faction(party)
		if dom != "":
			factions[dom] = clampf(factions[dom] + randf_range(0.5, 1.5), 5.0, 80.0)

		# Renormalise
		total = 0.0
		for f in factions: total += factions[f]
		for f in factions: factions[f] = factions[f] / total * 100.0

		# If dominant faction shifts ideology, adjust party ideology slightly
		var dom_ideology_pull = 0.0
		if "Radical" in dom or "Populist" in dom or "Left" in dom:
			dom_ideology_pull = -0.1
		elif "Conservative" in dom or "Traditional" in dom or "Market" in dom:
			dom_ideology_pull = 0.1
		GameData.party_ideology[party] = clampf(
			GameData.party_ideology.get(party, 0.0) + dom_ideology_pull, -10.0, 10.0
		)

		# Rare faction revolt
		if randf() < 0.02:
			var weakest = ""
			var weakest_power = 999.0
			for f in factions:
				if factions[f] < weakest_power and f != dom:
					weakest_power = factions[f]
					weakest = f
			if weakest != "":
				var boost = randf_range(5.0, 15.0)
				factions[weakest] = clampf(factions[weakest] + boost, 5.0, 80.0)
				if party == GameData.player_party:
					ev.append("⚠ Internal revolt: the %s faction in %s surges in power!" % [weakest, party])

# ── Pops ───────────────────────────────────────────────────────────────────────
func _tick_pops(ev: Array) -> void:
	for pop_name in GameData.pops:
		var pop = GameData.pops[pop_name]

		# Economy effects per stratum
		var delta = 0.0
		match pop_name:
			"Working Class":
				delta += (GameData.gdp_growth - 1.0) * 0.3
				delta -= GameData.unemployment * 0.15
				delta -= GameData.inflation * 0.2
			"Middle Class":
				delta += (GameData.gdp_growth - 1.5) * 0.25
				delta -= GameData.inflation * 0.15
			"Business Elite":
				delta += GameData.gdp_growth * 0.4
				delta -= GameData.budget_deficit * 0.1
			"Youth":
				delta += (GameData.gdp_growth - 1.0) * 0.2
				delta -= GameData.unemployment * 0.25
			"Pensioners":
				delta -= GameData.inflation * 0.3
				delta += GameData.cabinet_competence("Health") * 0.05
			"Rural":
				delta += (GameData.gdp_growth - 1.0) * 0.15
				delta -= GameData.unemployment * 0.1

		pop["satisfaction"] = clampf(pop["satisfaction"] + delta * 0.3, 0.0, 100.0)

		# Radicalisation rises when satisfaction < 25
		if pop["satisfaction"] < 25.0:
			pop["radicalisation"] = clampf(pop["radicalisation"] + 1.5, 0.0, 100.0)
			if pop["radicalisation"] > 60.0 and randf() < 0.1:
				GameData.approval_rating = clampf(GameData.approval_rating - 5.0, 0.0, 100.0)
				GameData.legitimacy      = clampf(GameData.legitimacy - 3.0, 0.0, 100.0)
				ev.append("🔥 Radicalised %s take to the streets. (-5 approval, -3 legitimacy)" % pop_name)
		else:
			pop["radicalisation"] = clampf(pop["radicalisation"] - 0.5, 0.0, 100.0)

	# Sync overall approval to weighted pop satisfaction (soft pull)
	var weighted = GameData.weighted_approval()
	GameData.approval_rating = clampf(
		GameData.approval_rating + (weighted - GameData.approval_rating) * 0.08, 0.0, 100.0
	)

# ── Diplomacy ─────────────────────────────────────────────────────────────────
func _tick_diplomacy(ev: Array) -> void:
	for nation in GameData.foreign_relations:
		var rel = GameData.foreign_relations[nation]

		# Trade deal GDP bonus
		if rel["trade_deal"]:
			GameData.gdp_growth = clampf(GameData.gdp_growth + rel.get("gdp_bonus", 0.3) * 0.05, -5.0, 10.0)

		# Alliance approval bonus
		if rel["alliance"]:
			GameData.approval_rating = clampf(GameData.approval_rating + 0.1, 0.0, 100.0)
			GameData.legitimacy       = clampf(GameData.legitimacy + 0.05, 0.0, 100.0)

		# Sanctions hurt economy
		if rel["sanctions"]:
			GameData.gdp_growth = clampf(GameData.gdp_growth - 0.15, -5.0, 10.0)
			if randf() < 0.1:
				ev.append("🚫 Sanctions from %s continue to drag on GDP." % nation)

		# Relations drift toward 0 (neutral) slowly if no active policy
		if not rel["alliance"] and not rel["trade_deal"]:
			rel["relation"] += (0 - rel["relation"]) * 0.02

# ── Cabinet ────────────────────────────────────────────────────────────────────
func _tick_cabinet(_ev: Array) -> void:
	for slot in GameData.cabinet:
		var m = GameData.cabinet[slot]
		if m.is_empty(): continue
		m["months_served"] = m.get("months_served", 0) + 1
		if m["months_served"] % 6 == 0 and m.get("competence", 5) < 10:
			m["competence"] = min(10, m["competence"] + 1)

# ── Media ──────────────────────────────────────────────────────────────────────
func _tick_media(_ev: Array) -> void:
	# Hostile media amplifies bad news
	if GameData.media_hostility > 50.0 and GameData.approval_rating < 50.0:
		GameData.approval_rating = clampf(GameData.approval_rating - 0.5, 0.0, 100.0)
	# Media hostility drifts toward 20 (baseline) slowly
	GameData.media_hostility += (20.0 - GameData.media_hostility) * 0.03

# ── Crisis ─────────────────────────────────────────────────────────────────────
func _tick_crisis(ev: Array) -> void:
	if GameData.active_crisis.is_empty() or GameData.active_crisis.get("resolved", true):
		# Random new crisis: ~10% monthly
		if randf() < 0.10:
			_trigger_random_crisis(ev)
		return

	GameData.active_crisis["deadline_months"] -= 1
	var sev = GameData.active_crisis.get("severity", 1)
	GameData.approval_rating = clampf(GameData.approval_rating - sev * 1.2, 0.0, 100.0)
	GameData.legitimacy      = clampf(GameData.legitimacy - sev * 0.5, 0.0, 100.0)
	ev.append("⚠ CRISIS ongoing: %s (%d months left)" % [
		GameData.active_crisis["title"], GameData.active_crisis["deadline_months"]
	])
	if GameData.active_crisis["deadline_months"] <= 0:
		GameData.approval_rating = clampf(GameData.approval_rating - sev * 10.0, 0.0, 100.0)
		GameData.legitimacy      = clampf(GameData.legitimacy - sev * 5.0, 0.0, 100.0)
		GameData.active_crisis["resolved"] = true
		ev.append("💀 Crisis unresolved: %s — major consequences." % GameData.active_crisis["title"])

const CRISIS_POOL : Array = [
	{ "title": "Economic Recession",    "desc": "Global downturn hits domestic growth hard.", "deadline_months": 3, "severity": 3, "resolve_cost": 6, "resolve_gdp": 1.2, "resolve_approval": 6.0,  "ignore_gdp": -2.0, "ignore_approval": -14.0 },
	{ "title": "Natural Disaster",      "desc": "Severe flooding devastates northern regions.", "deadline_months": 2, "severity": 2, "resolve_cost": 4, "resolve_gdp": 0.0, "resolve_approval": 10.0, "ignore_gdp": -0.5, "ignore_approval": -16.0 },
	{ "title": "Constitutional Crisis", "desc": "Supreme Court challenges executive authority.", "deadline_months": 4, "severity": 2, "resolve_cost": 7, "resolve_gdp": 0.1, "resolve_approval": 5.0,  "ignore_gdp": -0.3, "ignore_approval": -10.0, "ignore_legitimacy": -15.0 },
	{ "title": "Energy Shortage",       "desc": "Fuel shortages cause public unrest.", "deadline_months": 3, "severity": 2, "resolve_cost": 5, "resolve_gdp": -0.3, "resolve_approval": 4.0, "ignore_gdp": -1.2, "ignore_approval": -9.0 },
	{ "title": "Border Dispute",        "desc": "Neighbouring state escalates border tensions.", "deadline_months": 5, "severity": 1, "resolve_cost": 4, "resolve_gdp": 0.1, "resolve_approval": 4.0, "ignore_gdp": -0.2, "ignore_approval": -5.0, "ignore_legitimacy": -5.0 },
	{ "title": "Labour Strike",         "desc": "National strike action paralyses key industries.", "deadline_months": 2, "severity": 2, "resolve_cost": 3, "resolve_gdp": 0.3, "resolve_approval": 7.0, "ignore_gdp": -0.8, "ignore_approval": -8.0 },
	{ "title": "Corruption Scandal",    "desc": "A leaked dossier implicates senior officials.", "deadline_months": 3, "severity": 3, "resolve_cost": 8, "resolve_gdp": 0.0, "resolve_approval": 5.0, "ignore_gdp": 0.0, "ignore_approval": -18.0, "ignore_legitimacy": -12.0 },
]

func _trigger_random_crisis(ev: Array) -> void:
	var c = CRISIS_POOL[randi() % CRISIS_POOL.size()].duplicate()
	c["resolved"] = false
	GameData.active_crisis = c
	ev.append("🆘 NEW CRISIS: %s — go to Foreign Policy to respond!" % c["title"])

# ── Scandal ────────────────────────────────────────────────────────────────────
func _tick_scandal(ev: Array) -> void:
	GameData.scandal_meter = clampf(
		GameData.scandal_meter + (GameData.media_hostility * 0.04) + (GameData.whip_count_this_term * 0.3),
		0.0, 100.0
	)
	if GameData.scandal_meter > 65.0 and randf() < 0.12:
		var filled = []
		for slot in GameData.cabinet:
			if not GameData.cabinet[slot].is_empty(): filled.append(slot)
		if not filled.is_empty():
			var slot = filled[randi() % filled.size()]
			var minister_name = GameData.cabinet[slot].get("name", "Minister")
			GameData.cabinet[slot] = {}
			GameData.approval_rating = clampf(GameData.approval_rating - 10.0, 0.0, 100.0)
			GameData.legitimacy      = clampf(GameData.legitimacy - 5.0, 0.0, 100.0)
			GameData.scandal_meter   = clampf(GameData.scandal_meter - 30.0, 0.0, 100.0)
			ev.append("💥 SCANDAL: %s (%s) forced to resign! (-10 approval, -5 legitimacy)" % [minister_name, slot])
		else:
			GameData.approval_rating = clampf(GameData.approval_rating - 7.0, 0.0, 100.0)
			GameData.scandal_meter   = clampf(GameData.scandal_meter - 20.0, 0.0, 100.0)
			ev.append("💥 SCANDAL: Senior official implicated in misconduct. (-7 approval)")

# ── Polling ────────────────────────────────────────────────────────────────────
func _tick_polling(_ev: Array) -> void:
	var target = 15.0 + (GameData.approval_rating - 50.0) * 0.4
	var pp     = GameData.polling.get(GameData.player_party, 20.0)
	GameData.polling[GameData.player_party] = clampf(pp + (target - pp) * 0.08, 5.0, 60.0)
	# Faction volatility adds small random noise to all parties
	for party in GameData.polling:
		GameData.polling[party] = clampf(GameData.polling[party] + randf_range(-0.5, 0.5), 2.0, 65.0)
	GameData.normalise_polling()

# ── Legitimacy ─────────────────────────────────────────────────────────────────
func _tick_legitimacy(ev: Array) -> void:
	# Legitimacy drifts toward 50 slowly
	GameData.legitimacy += (50.0 - GameData.legitimacy) * 0.01
	if GameData.legitimacy < 20.0:
		GameData.approval_rating = clampf(GameData.approval_rating - 2.0, 0.0, 100.0)
		if randf() < 0.05:
			ev.append("⚠ Legitimacy crisis deepening. Parliament questions executive authority.")

# ── Capital Regen ──────────────────────────────────────────────────────────────
func _regen_capital(_ev: Array) -> void:
	var regen = 2 + int(float(GameData.filled_cabinet_slots()) / 3.0)
	if GameData.legitimacy > 70.0: regen += 1
	GameData.gain_capital(regen)

# ── Goal Checking ──────────────────────────────────────────────────────────────
func _check_goals(ev: Array) -> void:
	for goal in GameData.term_goals:
		if goal.get("achieved", false) or goal.get("failed", false): continue
		var achieved = false
		match goal.get("type", ""):
			"unemployment": achieved = GameData.unemployment <= goal.get("target", 4.0)
			"bills_passed": achieved = GameData.bills_passed >= goal.get("target", 3)
			"approval":     achieved = GameData.approval_rating >= goal.get("target", 60.0)
			"legitimacy":   achieved = GameData.legitimacy >= goal.get("target", 70.0)
			"trade_deals":
				var count = 0
				for n in GameData.foreign_relations:
					if GameData.foreign_relations[n]["trade_deal"]: count += 1
				achieved = count >= goal.get("target", 2)
		if achieved:
			goal["achieved"] = true
			GameData.gain_capital(6)
			GameData.legacy_score += 15
			GameData.legitimacy   = clampf(GameData.legitimacy + 5.0, 0.0, 100.0)
			ev.append("✅ GOAL ACHIEVED: %s (+6 capital, +15 prestige)" % goal["desc"])

# ── Opposition AI ──────────────────────────────────────────────────────────────
func _opposition_ai(ev: Array) -> void:
	var rival = ""
	var best  = 0
	for party in GameData.seats:
		if party == GameData.player_party: continue
		if GameData.seats[party] > best:
			best  = GameData.seats[party]
			rival = party
	if rival == "": return

	var leader = GameData.party_leaders.get(rival, "Opposition")

	# No-confidence if approval < 32
	if GameData.approval_rating < 32.0 and randf() < 0.25:
		var against = 0
		for party in GameData.seats:
			if party == GameData.player_party: continue
			if GameData.coalition_stance.get(party, 0) != 1:
				against += GameData.seats.get(party, 0)
		if against > GameData.coalition_seats():
			GameData.approval_rating = clampf(GameData.approval_rating - 15.0, 0.0, 100.0)
			GameData.legitimacy      = clampf(GameData.legitimacy - 8.0, 0.0, 100.0)
			ev.append("⚠ NO-CONFIDENCE PASSED: %s (%s) wins the vote. (-15 approval, -8 legitimacy)" % [leader, rival])
		else:
			GameData.approval_rating = clampf(GameData.approval_rating + 3.0, 0.0, 100.0)
			ev.append("✔ No-confidence by %s (%s) FAILED. (+3 approval)" % [leader, rival])
		return

	# Campaign blitz near election
	if GameData.months_until_election <= 6 and randf() < 0.45:
		GameData.polling[rival] = clampf(GameData.polling.get(rival, 20.0) + 2.5, 2.0, 65.0)
		GameData.normalise_polling()
		ev.append("📣 %s (%s) launches election campaign blitz." % [leader, rival])
		return

	# Routine pressure
	if randf() < 0.3:
		GameData.approval_rating = clampf(GameData.approval_rating - 1.0, 0.0, 100.0)
		var attacks = [
			"%s (%s) calls for a parliamentary inquiry into government conduct." % [leader, rival],
			"%s (%s) attacks the economic record in a major speech." % [leader, rival],
			"%s (%s) releases damaging polling analysis." % [leader, rival],
		]
		ev.append(attacks[randi() % attacks.size()])