extends Node

const GOAL_POOL : Array = [
	{ "desc": "Reduce unemployment below 4%",     "type": "unemployment", "target": 4.0  },
	{ "desc": "Pass 5 bills this term",           "type": "bills_passed", "target": 5    },
	{ "desc": "Maintain 60%+ approval rating",   "type": "approval",     "target": 60.0 },
	{ "desc": "Reduce unemployment below 5%",     "type": "unemployment", "target": 5.0  },
	{ "desc": "Pass 3 bills this term",           "type": "bills_passed", "target": 3    },
	{ "desc": "Achieve 55%+ approval rating",    "type": "approval",     "target": 55.0 },
]

func generate_term_goals() -> void:
	GameData.term_goals = []
	GameData.bills_passed = 0
	var pool = GOAL_POOL.duplicate()
	pool.shuffle()
	for i in range(min(3, pool.size())):
		var g = pool[i].duplicate()
		g["achieved"] = false
		g["failed"]   = false
		GameData.term_goals.append(g)

func goals_summary() -> String:
	if GameData.term_goals.is_empty():
		return "No goals set for this term."
	var lines = []
	for goal in GameData.term_goals:
		var status = ""
		if goal.get("achieved", false):
			status = " ✔ ACHIEVED"
		elif goal.get("failed", false):
			status = " ✘ FAILED"
		else:
			status = _progress(goal)
		lines.append("• %s%s" % [goal["desc"], status])
	return "\n".join(lines)

func _progress(goal: Dictionary) -> String:
	match goal.get("type", ""):
		"unemployment":
			return "  (Current: %.1f%%)" % GameData.unemployment
		"bills_passed":
			return "  (Current: %d)" % GameData.bills_passed
		"approval":
			return "  (Current: %.1f%%)" % GameData.approval_rating
	return ""