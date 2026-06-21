extends Control
# Draws sparklines for GDP, approval, unemployment over last 24 months

const COLORS = {
	"gdp":          Color(0.2, 0.8, 0.3),
	"approval":     Color(0.3, 0.6, 1.0),
	"unemployment": Color(1.0, 0.4, 0.3),
	"legitimacy":   Color(0.9, 0.8, 0.2),
}

func _draw() -> void:
	var history = GameData.month_history
	if history.size() < 2: return

	var w = size.x
	var h = size.y
	var pad = 30.0

	# Background
	draw_rect(Rect2(0, 0, w, h), Color(0.1, 0.1, 0.15, 0.8))

	# Grid lines
	for i in range(5):
		var y = pad + (h - pad * 2) * i / 4.0
		draw_line(Vector2(pad, y), Vector2(w - pad, y), Color(0.3, 0.3, 0.3, 0.5), 1.0)

	var metrics = [
		{ "key": "gdp",          "min": -5.0,  "max": 10.0,  "label": "GDP%" },
		{ "key": "approval",     "min": 0.0,   "max": 100.0, "label": "Approval" },
		{ "key": "unemployment", "min": 0.0,   "max": 20.0,  "label": "Unemp%" },
		{ "key": "legitimacy",   "min": 0.0,   "max": 100.0, "label": "Legit" },
	]

	for m in metrics:
		var key   = m["key"]
		var mn    = m["min"]
		var mx    = m["max"]
		var color = COLORS.get(key, Color.WHITE)
		var points = PackedVector2Array()
		for i in range(history.size()):
			var val = float(history[i].get(key, 0.0))
			var x   = pad + (w - pad * 2) * i / float(history.size() - 1)
			var y   = pad + (h - pad * 2) * (1.0 - clampf((val - mn) / (mx - mn), 0.0, 1.0))
			points.append(Vector2(x, y))
		if points.size() >= 2:
			for i in range(points.size() - 1):
				draw_line(points[i], points[i + 1], color, 2.0)
			# Current value dot
			draw_circle(points[-1], 5.0, color)

	# Legend
	var lx = pad
	var ly = 6.0
	for m in metrics:
		var color = COLORS.get(m["key"], Color.WHITE)
		draw_rect(Rect2(lx, ly, 14, 10), color)
		draw_string(ThemeDB.fallback_font, Vector2(lx + 18, ly + 10), m["label"], HORIZONTAL_ALIGNMENT_LEFT, -1, 12, color)
		lx += 90.0

	# X-axis labels
	if history.size() > 0:
		var first = history[0]
		var last  = history[-1]
		draw_string(ThemeDB.fallback_font, Vector2(pad, h - 6), "%s %d" % [_mname(first.get("month", 1)), first.get("year", 2025)], HORIZONTAL_ALIGNMENT_LEFT, -1, 11, Color.GRAY)
		draw_string(ThemeDB.fallback_font, Vector2(w - pad - 60, h - 6), "%s %d" % [_mname(last.get("month", 1)), last.get("year", 2025)], HORIZONTAL_ALIGNMENT_LEFT, -1, 11, Color.GRAY)

func _mname(m: int) -> String:
	var names = ["Jan","Feb","Mar","Apr","May","Jun","Jul","Aug","Sep","Oct","Nov","Dec"]
	return names[clampi(m - 1, 0, 11)]
