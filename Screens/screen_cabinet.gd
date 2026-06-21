extends Control
@onready var lbl_slots   : Label        = $Margin/VBox/Slots
@onready var lbl_cap     : Label        = $Margin/VBox/Capital
@onready var opt_slot    : OptionButton = $Margin/VBox/HBox/SlotOpt
@onready var opt_cand    : OptionButton = $Margin/VBox/HBox/CandOpt
@onready var btn_appoint : Button       = $Margin/VBox/HBox/BtnAppoint
@onready var btn_dismiss : Button       = $Margin/VBox/HBox/BtnDismiss
@onready var lbl_result  : Label        = $Margin/VBox/Result

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
]

var candidates : Array = []

func _ready() -> void:
	btn_appoint.pressed.connect(_on_appoint)
	btn_dismiss.pressed.connect(_on_dismiss)
	refresh()

func refresh() -> void:
	lbl_cap.text = "Political Capital: %d / 40  (Appoint costs 3)" % GameData.political_capital
	var txt = "Current Cabinet:\n"
	for slot in GameData.cabinet:
		var m = GameData.cabinet[slot]
		if m.is_empty():
			txt += "  %-18s  [VACANT]\n" % slot
		else:
			txt += "  %-18s  %s  (Competence: %d/10, Months: %d)\n" % [slot, m["name"], m.get("competence", 5), m.get("months_served", 0)]
	lbl_slots.text = txt

	opt_slot.clear()
	for slot in GameData.cabinet: opt_slot.add_item(slot)

	candidates = _available_candidates()
	opt_cand.clear()
	for c in candidates:
		opt_cand.add_item("%s  (Comp %d, %s)" % [c["name"], c["competence"], c["party"]])

func _available_candidates() -> Array:
	var used = []
	for slot in GameData.cabinet:
		if not GameData.cabinet[slot].is_empty():
			used.append(GameData.cabinet[slot].get("name", ""))
	var out = []
	for m in MINISTER_POOL:
		if not used.has(m["name"]): out.append(m)
	return out

func _on_appoint() -> void:
	var si = opt_slot.selected; var ci = opt_cand.selected
	if si < 0 or ci < 0 or ci >= candidates.size():
		lbl_result.text = "Select a slot and candidate."; lbl_result.visible = true; return
	if not GameData.spend_capital(3):
		lbl_result.text = "Need 3 capital."; lbl_result.visible = true; return
	var slot = opt_slot.get_item_text(si)
	var cand = candidates[ci].duplicate()
	cand["months_served"] = 0
	GameData.cabinet[slot] = cand
	if cand["party"] != GameData.player_party and GameData.coalition_stance.has(cand["party"]):
		if GameData.coalition_stance[cand["party"]] == 0:
			GameData.coalition_stance[cand["party"]] = 1
	lbl_result.text = "%s appointed to %s." % [cand["name"], slot]; lbl_result.visible = true
	refresh()

func _on_dismiss() -> void:
	var si = opt_slot.selected
	if si < 0: return
	var slot = opt_slot.get_item_text(si)
	if GameData.cabinet[slot].is_empty():
		lbl_result.text = "Slot is already vacant."; lbl_result.visible = true; return
	var name = GameData.cabinet[slot].get("name", "Minister")
	GameData.cabinet[slot] = {}
	GameData.approval_rating = clampf(GameData.approval_rating - 3.0, 0.0, 100.0)
	lbl_result.text = "%s dismissed. (-3 approval)" % name; lbl_result.visible = true
	refresh()
