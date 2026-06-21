extends Control
@onready var lbl_goals  : Label  = $Margin/VBox/Goals
@onready var lbl_legacy : Label  = $Margin/VBox/Legacy
@onready var btn_gen    : Button = $Margin/VBox/BtnGen
@onready var lbl_result : Label  = $Margin/VBox/Result

const GOAL_POOL = [
	{ "desc": "Reduce unemployment below 4%",       "type": "unemployment", "target": 4.0  },
	{ "desc": "Pass 5 bills this term",             "type": "bills_passed", "target": 5    },
	{ "desc": "Achieve 65%+ approval",              "type": "approval",     "target": 65.0 },
	{ "desc": "Raise legitimacy above 70",          "type": "legitimacy",   "target": 70.0 },
	{ "desc": "Sign 2 trade deals",                 "type": "trade_deals",  "target": 2    },
	{ "desc": "Reduce unemployment below 5%",       "type": "unemployment", "target": 5.0  },
	{ "desc": "Pass 3 bills this term",             "type": "bills_passed", "target": 3    },
	{ "desc": "Achieve 55%+ approval",              "type": "approval",     "target": 55.0 },
]

func _ready() -> void:
	btn_gen.pressed.connect(_generate)
	if GameData.term_goals.is_empty(): _generate()
	refresh()

func refresh() -> void:
	if GameData.term_goals.is_empty():
		lbl_goals.text = "No goals set."
	else:
		var txt = "Term Goals:\n"
		for goal in GameData.term_goals:
			var s = "✔" if goal.get("achieved") else ("✘" if goal.get("failed") else "…")
			txt += "  [%s]  %s\n        Progress: %s\n" % [s, goal["desc"], _progress(goal)]
		lbl_goals.text = txt
	lbl_legacy.text = "⭐ Prestige Score: %d  |  Terms served: %d" % [GameData.legacy_score, GameData.terms_served]

func _generate() -> void:
	if not GameData.term_goals.is_empty():
		lbl_result.text = "Goals already set for this term."; lbl_result.visible = true; return
	var pool = GOAL_POOL.duplicate(); pool.shuffle()
	for i in range(min(3, pool.size())):
		var g = pool[i].duplicate(); g["achieved"] = false; g["failed"] = false
		GameData.term_goals.append(g)
	lbl_result.text = "New term goals set!"; lbl_result.visible = true; refresh()

func _progress(goal: Dictionary) -> String:
	match goal.get("type", ""):
		"unemployment": return "Unemployment currently %.1f%% (target: below %.1f%%)" % [GameData.unemployment, goal["target"]]
		"bills_passed": return "%d / %d bills passed" % [GameData.bills_passed, int(goal["target"])]
		"approval":     return "Approval currently %.1f%% (target: %.1f%%+)" % [GameData.approval_rating, goal["target"]]
		"legitimacy":   return "Legitimacy currently %.1f (target: %.1f+)" % [GameData.legitimacy, goal["target"]]
		"trade_deals":
			var n = 0
			for nation in GameData.foreign_relations:
				if GameData.foreign_relations[nation]["trade_deal"]: n += 1
			return "%d / %d trade deals signed" % [n, int(goal["target"])]
	return ""
