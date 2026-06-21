extends Node
# ═══════════════════════════════════════════════════════════════════════════════
# SYSTEMS — monthly simulation. Called once per month by gameplay.gd.
# Returns Array of narrative strings shown in the events overlay.
# ═══════════════════════════════════════════════════════════════════════════════

signal month_processed(events: Array)

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

# ── Economy ─────────────────────────────────────────────────────────────────
func _tick_economy(ev: Array) -> void:
	# Cabinet economy minister gives a small passive GDP nudge
	var econ_comp = GameData.cabinet_competence("Economy")
	if econ_comp > 0:
		GameData.gdp_growth = clampf(GameData.gdp_growth + econ_comp * 0.01, -5.0, 10.0)

	# Unemployment reacts to GDP with a lag
	var nat_rate = 5.0
	if GameData.gdp_growth > 3.0:
		GameData.unemployment = clampf(GameData.unemployment - 0.12, 2.5, 18.0)
	elif GameData.gdp_growth < 0.5:
		GameData.unemployment = clampf(GameData.unemployment + 0.18, 2.5, 18.0)
	else:
		GameData.unemployment = clampf(
			GameData.unemployment + (nat_rate - GameData.unemployment) * 0.04, 2.5, 18.0
		)

	# Inflation driven by deficit spending and growth overheating
	var inflation_pressure = (GameData.budget_deficit * 0.04) + (max(0.0, GameData.gdp_growth - 3.5) * 0.05)
	GameData.inflation = clampf(GameData.inflation + inflation_pressure - 0.08, -0.5, 12.0)

	# GDP absolute grows by monthly fraction of annual rate
	GameData.gdp_absolute *= (1.0 + GameData.gdp_growth / 1200.0)

	# Approval pressure — economy has a gradual effect, not instant
	var pressure = 0.0
	if   GameData.gdp_growth   >  3.0: pressure += 0.4
	elif GameData.gdp_growth   <  0.0: pressure -= 1.0
	if   GameData.unemployment > 10.0: pressure -= 0.8
	elif GameData.unemployment <  4.0: pressure += 0.4
	if   GameData.inflation    >  6.0: pressure -= 0.6
	GameData.approval_rating = clampf(GameData.approval_rating + pressure, 0.0, 100.0)

	if GameData.gdp_growth < -1.0:
		ev.append("📉 Recession deepening: GDP at %+.1f%%. Public patience wears thin." % GameData.gdp_growth)
	elif GameData.unemployment > 11.0:
		ev.append("📉 Unemployment at %.1f%%. Job centres overwhelmed." % GameData.unemployment)
	elif GameData.inflation > 7.0:
		ev.append("📈 Inflation running hot at %.1f%%. Cost-of-living anger rising." % GameData.inflation)

# ── Party Factions ──────────────────────────────────────────────────────────
func _tick_factions(ev: Array) -> void:
	for party in GameData.party_factions:
		var factions = GameData.party_factions[party]
		if factions.is_empty(): continue

		# Dominant faction consolidates power very slowly
		var dom = GameData.dominant_faction(party)
		if dom != "":
			factions[dom] = clampf(factions[dom] + randf_range(0.2, 0.8), 5.0, 85.0)

		# Renormalise to 100
		var total = 0.0
		for f in factions: total += factions[f]
		if total > 0:
			for f in factions: factions[f] = factions[f] / total * 100.0

		# Dominant faction pulls party ideology very slightly (0.05/month max)
		var pull = 0.0
		if "Radical" in dom or "Left" in dom or "Labour" in dom: pull = -0.05
		elif "Conservative" in dom or "Traditional" in dom or "Market" in dom or "Populist" in dom: pull = 0.05
		GameData.party_ideology[party] = clampf(
			GameData.party_ideology.get(party, 0.0) + pull, -10.0, 10.0
		)

		# Rare (2%) faction surge — a minority faction gains momentum
		if randf() < 0.02:
			var weakest = ""
			var weakest_power = 999.0
			for f in factions:
				if factions[f] < weakest_power and f != dom:
					weakest_power = factions[f]
					weakest = f
			if weakest != "":
				var boost = randf_range(4.0, 10.0)
				factions[weakest] = clampf(factions[weakest] + boost, 5.0, 60.0)
				# Renormalise again
				total = 0.0
				for f in factions: total += factions[f]
				for f in factions: factions[f] = factions[f] / total * 100.0
				if party == GameData.player_party:
					ev.append("⚡ Internal party shift: the '%s' faction in %s gains ground." % [weakest, party])

# ── Pops (Social Strata) ────────────────────────────────────────────────────
func _tick_pops(ev: Array) -> void:
	for pop_name in GameData.pops:
		var pop = GameData.pops[pop_name]
		var delta = 0.0

		match pop_name:
			"Working Class":
				# React to jobs and wages (GDP proxy) and inflation eating wages
				delta += clampf((GameData.gdp_growth - 1.5) * 0.25, -1.5, 1.5)
				delta -= clampf((GameData.unemployment - 5.0) * 0.15, 0.0, 2.0)
				delta -= clampf((GameData.inflation - 3.0) * 0.2, 0.0, 1.5)
			"Middle Class":
				# React to stability and inflation
				delta += clampf((GameData.gdp_growth - 1.5) * 0.2, -1.2, 1.2)
				delta -= clampf((GameData.inflation - 3.0) * 0.15, 0.0, 1.0)
			"Business Elite":
				# Loves GDP growth, hates deficits and regulation
				delta += clampf(GameData.gdp_growth * 0.3, -1.0, 2.0)
				delta -= clampf(GameData.budget_deficit * 0.08, 0.0, 1.0)
			"Youth":
				# Sensitive to unemployment and future prospects
				delta += clampf((GameData.gdp_growth - 1.0) * 0.2, -1.5, 1.5)
				delta -= clampf((GameData.unemployment - 4.5) * 0.2, 0.0, 2.5)
			"Pensioners":
				# Sensitive to inflation eroding savings; health minister helps
				delta -= clampf((GameData.inflation - 2.0) * 0.25, 0.0, 2.0)
				delta += GameData.cabinet_competence("Health") * 0.02
			"Rural":
				# React to overall economic conditions but more slowly
				delta += clampf((GameData.gdp_growth - 1.5) * 0.15, -1.0, 1.0)
				delta -= clampf((GameData.unemployment - 5.5) * 0.1, 0.0, 1.0)

		# Apply delta slowly — satisfaction is sticky
		pop["satisfaction"] = clampf(pop["satisfaction"] + delta * 0.4, 0.0, 100.0)

		# Radicalisation builds when deeply unhappy, fades when content
		if pop["satisfaction"] < 25.0:
			pop["radicalisation"] = clampf(pop["radicalisation"] + 1.0, 0.0, 100.0)
		elif pop["satisfaction"] > 55.0:
			pop["radicalisation"] = clampf(pop["radicalisation"] - 0.8, 0.0, 100.0)

		# Radicalised groups cause trouble above 70
		if pop["radicalisation"] > 70.0 and randf() < 0.08:
			var impact = randf_range(3.0, 7.0)
			GameData.approval_rating = clampf(GameData.approval_rating - impact, 0.0, 100.0)
			GameData.legitimacy      = clampf(GameData.legitimacy      - 2.0,   0.0, 100.0)
			ev.append("🔥 %s unrest boils over. Civil disorder reported. (-%.0f approval)" % [pop_name, impact])

	# Soft-pull overall approval toward weighted pop satisfaction (very gentle)
	var weighted = GameData.weighted_approval()
	GameData.approval_rating = clampf(
		GameData.approval_rating + (weighted - GameData.approval_rating) * 0.05, 0.0, 100.0
	)

# ── Diplomacy ────────────────────────────────────────────────────────────────
func _tick_diplomacy(_ev: Array) -> void:
	for nation in GameData.foreign_relations:
		var rel = GameData.foreign_relations[nation]

		if rel["trade_deal"]:
			# Trade deal gives GDP boost (monthly fraction)
			GameData.gdp_growth = clampf(
				GameData.gdp_growth + rel.get("gdp_bonus", 0.3) * 0.04, -5.0, 10.0
			)

		if rel["alliance"]:
			# Alliance gives small monthly approval and legitimacy
			GameData.approval_rating = clampf(GameData.approval_rating + 0.08, 0.0, 100.0)
			GameData.legitimacy      = clampf(GameData.legitimacy      + 0.04, 0.0, 100.0)

		if rel["sanctions"]:
			# Sanctions drag GDP; effect proportional to how trade-dependent we are
			GameData.gdp_growth = clampf(GameData.gdp_growth - 0.1, -5.0, 10.0)

		# Relations drift slowly toward neutral when no active engagement
		if not rel["alliance"] and not rel["envoy_sent"]:
			rel["relation"] = int(rel["relation"] + (0 - rel["relation"]) * 0.03)

# ── Cabinet ──────────────────────────────────────────────────────────────────
func _tick_cabinet(_ev: Array) -> void:
	for slot in GameData.cabinet:
		var m = GameData.cabinet[slot]
		if m.is_empty(): continue
		m["months_served"] = m.get("months_served", 0) + 1
		# Ministers gain experience every 6 months, capped at 10
		if m["months_served"] % 6 == 0 and m.get("competence", 5) < 10:
			m["competence"] = min(10, m["competence"] + 1)

# ── Media ────────────────────────────────────────────────────────────────────
func _tick_media(_ev: Array) -> void:
	# Hostile media amplifies bad news when approval is already low
	if GameData.media_hostility > 50.0 and GameData.approval_rating < 45.0:
		GameData.approval_rating = clampf(GameData.approval_rating - 0.3, 0.0, 100.0)
	# Media hostility naturally drifts toward a low baseline (15)
	GameData.media_hostility = clampf(
		GameData.media_hostility + (15.0 - GameData.media_hostility) * 0.03, 0.0, 100.0
	)

# ── Crisis ───────────────────────────────────────────────────────────────────
func _tick_crisis(ev: Array) -> void:
	var c = GameData.active_crisis
	if c.is_empty() or c.get("resolved", true):
		# ~8% monthly chance of a new crisis
		if randf() < 0.08:
			_trigger_random_crisis(ev)
		return

	c["deadline_months"] -= 1
	var sev = c.get("severity", 1)
	# Ongoing crisis drains approval and legitimacy each month it persists
	GameData.approval_rating = clampf(GameData.approval_rating - sev * 0.8, 0.0, 100.0)
	GameData.legitimacy      = clampf(GameData.legitimacy      - sev * 0.4, 0.0, 100.0)

	if c["deadline_months"] == 1:
		ev.append("⏰ CRISIS URGENT: '%s' — only 1 month left to respond!" % c["title"])
	elif c["deadline_months"] <= 0:
		# Crisis expires unresolved — heavy hit
		var approval_hit = sev * 8.0
		var legit_hit    = sev * 5.0
		GameData.approval_rating = clampf(GameData.approval_rating - approval_hit, 0.0, 100.0)
		GameData.legitimacy      = clampf(GameData.legitimacy      - legit_hit,    0.0, 100.0)
		GameData.scandal_meter   = clampf(GameData.scandal_meter   + 12.0,         0.0, 100.0)
		GameData.active_crisis["resolved"] = true
		ev.append("💀 CRISIS EXPIRED: '%s' unresolved. (-%.0f approval, -%.0f legitimacy)" % [
			c["title"], approval_hit, legit_hit
		])

const CRISIS_POOL : Array = [
	{ "title": "Economic Recession",    "desc": "Global downturn hitting domestic growth.",              "deadline_months": 4, "severity": 3, "resolve_cost": 6, "resolve_gdp":  1.0, "resolve_approval":  6.0, "ignore_gdp": -1.5, "ignore_approval": -12.0, "ignore_legitimacy": -4.0  },
	{ "title": "Natural Disaster",      "desc": "Major flooding in the north. Urgent relief needed.",   "deadline_months": 2, "severity": 2, "resolve_cost": 4, "resolve_gdp":  0.0, "resolve_approval": 10.0, "ignore_gdp": -0.3, "ignore_approval": -14.0, "ignore_legitimacy": -6.0  },
	{ "title": "Constitutional Crisis", "desc": "Court challenges executive authority.",                 "deadline_months": 5, "severity": 2, "resolve_cost": 7, "resolve_gdp":  0.1, "resolve_approval":  5.0, "ignore_gdp": -0.2, "ignore_approval":  -8.0, "ignore_legitimacy": -12.0 },
	{ "title": "Energy Shortage",       "desc": "Fuel shortages causing public unrest and inflation.",  "deadline_months": 3, "severity": 2, "resolve_cost": 5, "resolve_gdp": -0.2, "resolve_approval":  4.0, "ignore_gdp": -0.8, "ignore_approval":  -8.0, "ignore_legitimacy": -2.0  },
	{ "title": "Border Dispute",        "desc": "Neighbouring state escalates military presence.",      "deadline_months": 5, "severity": 1, "resolve_cost": 4, "resolve_gdp":  0.0, "resolve_approval":  4.0, "ignore_gdp": -0.1, "ignore_approval":  -4.0, "ignore_legitimacy": -4.0  },
	{ "title": "Labour Strike",         "desc": "National strike paralyses key industries.",            "deadline_months": 2, "severity": 2, "resolve_cost": 3, "resolve_gdp":  0.2, "resolve_approval":  7.0, "ignore_gdp": -0.6, "ignore_approval":  -7.0, "ignore_legitimacy": -2.0  },
	{ "title": "Corruption Scandal",    "desc": "Leaked dossier implicates senior officials.",          "deadline_months": 3, "severity": 3, "resolve_cost": 8, "resolve_gdp":  0.0, "resolve_approval":  5.0, "ignore_gdp":  0.0, "ignore_approval": -16.0, "ignore_legitimacy": -10.0 },
	{ "title": "Public Health Scare",   "desc": "Disease outbreak strains health services.",            "deadline_months": 3, "severity": 2, "resolve_cost": 5, "resolve_gdp": -0.3, "resolve_approval":  8.0, "ignore_gdp": -0.5, "ignore_approval": -10.0, "ignore_legitimacy": -3.0  },
]

func _trigger_random_crisis(ev: Array) -> void:
	var pool = CRISIS_POOL.duplicate()
	pool.shuffle()
	var c = pool[0].duplicate()
	c["resolved"] = false
	GameData.active_crisis = c
	ev.append("🆘 NEW CRISIS: '%s' — %s\nGo to Foreign Policy to respond!" % [c["title"], c["desc"]])

# ── Scandal ──────────────────────────────────────────────────────────────────
func _tick_scandal(ev: Array) -> void:
	# Scandal meter rises from media hostility and excessive whipping
	var monthly_rise = (GameData.media_hostility * 0.03) + (GameData.whip_count_this_term * 0.2)
	GameData.scandal_meter = clampf(GameData.scandal_meter + monthly_rise - 0.5, 0.0, 100.0)

	# Fires when above 65, with 10% monthly chance
	if GameData.scandal_meter > 65.0 and randf() < 0.10:
		var filled = []
		for slot in GameData.cabinet:
			if not GameData.cabinet[slot].is_empty(): filled.append(slot)

		if not filled.is_empty():
			var slot = filled[randi() % filled.size()]
			var minister_name = GameData.cabinet[slot].get("name", "Minister")
			GameData.cabinet[slot] = {}
			GameData.approval_rating = clampf(GameData.approval_rating - 8.0,  0.0, 100.0)
			GameData.legitimacy      = clampf(GameData.legitimacy      - 4.0,  0.0, 100.0)
			GameData.scandal_meter   = clampf(GameData.scandal_meter   - 25.0, 0.0, 100.0)
			ev.append("💥 SCANDAL: %s (%s) implicated in misconduct — forced to resign. (-8 approval)" % [
				minister_name, slot
			])
		else:
			# No minister to fire — hits approval directly
			GameData.approval_rating = clampf(GameData.approval_rating - 6.0,  0.0, 100.0)
			GameData.scandal_meter   = clampf(GameData.scandal_meter   - 15.0, 0.0, 100.0)
			ev.append("💥 SCANDAL: Senior official implicated. No minister fired, but damage done. (-6 approval)")

# ── Polling ──────────────────────────────────────────────────────────────────
func _tick_polling(_ev: Array) -> void:
	# Player party polling tracks approval with a lag
	var pp     = GameData.polling.get(GameData.player_party, 20.0)
	var target = 14.0 + (GameData.approval_rating - 50.0) * 0.35
	GameData.polling[GameData.player_party] = clampf(
		pp + (target - pp) * 0.07, 4.0, 65.0
	)
	# Small random noise on all parties (faction volatility)
	for party in GameData.polling:
		GameData.polling[party] = clampf(
			GameData.polling[party] + randf_range(-0.3, 0.3), 2.0, 65.0
		)
	GameData.normalise_polling()

# ── Legitimacy ───────────────────────────────────────────────────────────────
func _tick_legitimacy(ev: Array) -> void:
	# Legitimacy drifts slowly toward 55 (natural equilibrium)
	GameData.legitimacy = clampf(
		GameData.legitimacy + (55.0 - GameData.legitimacy) * 0.008, 0.0, 100.0
	)
	# Very low legitimacy causes compounding approval damage
	if GameData.legitimacy < 20.0:
		GameData.approval_rating = clampf(GameData.approval_rating - 1.5, 0.0, 100.0)
		if randf() < 0.04:
			ev.append("⚠ Constitutional legitimacy critically low. Parliament questions your mandate.")

# ── Capital Regen ─────────────────────────────────────────────────────────────
func _regen_capital(_ev: Array) -> void:
	# Base 2/month + 1 per 2 filled cabinet slots + 1 if legitimacy is high
	var regen = 2
	regen += int(float(GameData.filled_cabinet_slots()) / 2.0)
	if GameData.legitimacy > 65.0: regen += 1
	if GameData.approval_rating > 60.0: regen += 1
	GameData.gain_capital(regen)

# ── Goal Checking ─────────────────────────────────────────────────────────────
func _check_goals(ev: Array) -> void:
	for goal in GameData.term_goals:
		if goal.get("achieved", false) or goal.get("failed", false): continue
		var achieved = false
		match goal.get("type", ""):
			"unemployment": achieved = GameData.unemployment    <= goal.get("target", 4.0)
			"bills_passed": achieved = GameData.bills_passed    >= goal.get("target", 3)
			"approval":     achieved = GameData.approval_rating >= goal.get("target", 60.0)
			"legitimacy":   achieved = GameData.legitimacy      >= goal.get("target", 70.0)
			"trade_deals":
				var count = 0
				for n in GameData.foreign_relations:
					if GameData.foreign_relations[n]["trade_deal"]: count += 1
				achieved = count >= goal.get("target", 2)
		if achieved:
			goal["achieved"] = true
			GameData.gain_capital(6)
			GameData.legacy_score += 15
			GameData.legitimacy    = clampf(GameData.legitimacy + 4.0, 0.0, 100.0)
			ev.append("✅ GOAL ACHIEVED: \"%s\" (+6 capital, +15 prestige, +4 legitimacy)" % goal["desc"])

# ── Opposition AI ─────────────────────────────────────────────────────────────
func _opposition_ai(ev: Array) -> void:
	# Find the largest rival by seats
	var rival = ""
	var best_seats = 0
	for party in GameData.seats:
		if party == GameData.player_party: continue
		if GameData.seats[party] > best_seats:
			best_seats = GameData.seats[party]
			rival = party
	if rival == "": return

	var leader   = GameData.party_leaders.get(rival, "Opposition")
	var approval = GameData.approval_rating

	# No-confidence vote: triggered when approval < 33%, 20% monthly chance
	if approval < 33.0 and randf() < 0.20:
		var against = 0
		for party in GameData.seats:
			if party == GameData.player_party: continue
			if GameData.coalition_stance.get(party, 0) != 1:
				against += GameData.seats.get(party, 0)
		var for_us = GameData.coalition_seats()
		if against > for_us:
			GameData.approval_rating = clampf(GameData.approval_rating - 12.0, 0.0, 100.0)
			GameData.legitimacy      = clampf(GameData.legitimacy      -  7.0, 0.0, 100.0)
			ev.append("⚠ NO-CONFIDENCE PASSED: %s (%s) wins %d vs %d. Government weakened. (-12 approval, -7 legitimacy)" % [
				leader, rival, against, for_us
			])
		else:
			GameData.approval_rating = clampf(GameData.approval_rating + 2.0, 0.0, 100.0)
			ev.append("✔ No-confidence by %s (%s) DEFEATED %d vs %d. (+2 approval)" % [
				leader, rival, for_us, against
			])
		return

	# Election campaign blitz in final 6 months
	if GameData.months_until_election <= 6 and randf() < 0.40:
		var boost = randf_range(1.5, 3.0)
		GameData.polling[rival] = clampf(GameData.polling.get(rival, 20.0) + boost, 2.0, 65.0)
		GameData.normalise_polling()
		ev.append("📣 %s (%s) launches an election campaign blitz. (+%.1f%% polling)" % [leader, rival, boost])
		return

	# Routine pressure — happens 25% of months
	if randf() < 0.25:
		GameData.approval_rating = clampf(GameData.approval_rating - 0.8, 0.0, 100.0)
		var attacks = [
			"%s (%s) calls for a parliamentary inquiry into government conduct." % [leader, rival],
			"%s (%s) delivers a scathing speech attacking the economic record." % [leader, rival],
			"%s (%s) publishes a policy paper exposing government failures." % [leader, rival],
			"%s (%s) holds a press conference criticising the handling of public services." % [leader, rival],
		]
		ev.append(attacks[randi() % attacks.size()])
