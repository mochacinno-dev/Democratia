extends Node

# Pool of possible ministers
const MINISTER_POOL : Array = [
	{ "name": "Arthur Blythe",   "competence": 8, "party": "Centre Compass Party" },
	{ "name": "Diana Kowalski",  "competence": 7, "party": "Rose Democracy Party" },
	{ "name": "Felix Oduya",     "competence": 9, "party": "Green Alliance Party" },
	{ "name": "Grace Halvorsen", "competence": 6, "party": "Liberal Society Party" },
	{ "name": "Henry Stearn",    "competence": 5, "party": "Fair Nationalism Party" },
	{ "name": "Isabel Morrow",   "competence": 8, "party": "Centre Compass Party" },
	{ "name": "James Okafor",    "competence": 7, "party": "Rose Democracy Party" },
	{ "name": "Karen Tse",       "competence": 9, "party": "Green Alliance Party" },
	{ "name": "Leo Brandt",      "competence": 6, "party": "Liberal Society Party" },
	{ "name": "Maria Solano",    "competence": 8, "party": "Fair Nationalism Party" },
	{ "name": "Nolan Pierce",    "competence": 5, "party": "Centre Compass Party" },
	{ "name": "Olivia Reeves",   "competence": 7, "party": "Rose Democracy Party" },
]

var _used_ministers : Array = []

func get_candidates(count: int = 3) -> Array:
	var available = []
	for m in MINISTER_POOL:
		if not _used_ministers.has(m["name"]):
			available.append(m)
	available.shuffle()
	return available.slice(0, min(count, available.size()))

func appoint(slot: String, minister: Dictionary) -> String:
	# Costs 3 political capital
	if not GameData.spend_capital(3):
		return "Not enough political capital (need 3)."
	# Fire existing minister if slot filled
	if not GameData.cabinet[slot].is_empty():
		var old = GameData.cabinet[slot]
		_used_ministers.erase(old["name"])

	var m = minister.duplicate()
	m["months_served"] = 0
	m["scandal_risk"]  = 20
	GameData.cabinet[slot] = m
	_used_ministers.append(m["name"])

	# Appointing from ally party improves coalition stance
	var party = m.get("party", "")
	if party != GameData.player_party and GameData.coalition_stance.has(party):
		if GameData.coalition_stance[party] == 0:
			GameData.coalition_stance[party] = 1

	return "%s appointed as Minister of %s. (Cost: 3 capital)" % [m["name"], slot]

func dismiss(slot: String) -> String:
	if GameData.cabinet[slot].is_empty():
		return "No minister in that slot."
	var m = GameData.cabinet[slot]
	_used_ministers.erase(m["name"])
	GameData.cabinet[slot] = {}
	# Small approval hit — looks disorganised
	GameData.approval_rating = clampf(GameData.approval_rating - 3.0, 0.0, 100.0)
	return "%s dismissed from %s. (-3 approval)" % [m["name"], slot]

func tick_ministers() -> void:
	for slot in GameData.cabinet:
		var m = GameData.cabinet[slot]
		if m.is_empty(): continue
		m["months_served"] = m.get("months_served", 0) + 1
		# Senior ministers become more competent over time (up to a cap)
		if m["months_served"] % 6 == 0 and m["competence"] < 10:
			m["competence"] = min(10, m["competence"] + 1)