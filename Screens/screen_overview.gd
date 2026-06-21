extends Control

@onready var lbl_name      : Label = $Margin/VBox/Name
@onready var lbl_party     : Label = $Margin/VBox/Party
@onready var lbl_summary   : Label = $Margin/VBox/Summary
@onready var lbl_majority  : Label = $Margin/VBox/Majority
@onready var lbl_economy   : Label = $Margin/VBox/Economy
@onready var lbl_pops      : Label = $Margin/VBox/Pops
@onready var lbl_goals     : Label = $Margin/VBox/Goals

func _ready() -> void:
	refresh()

func refresh() -> void:
	lbl_name.text    = "👤  " + GameData.player_full_name()
	lbl_party.text   = "🎖  " + GameData.player_party + "  |  Ideology: %+.1f" % GameData.player_ideology()
	lbl_summary.text = (
		"📅  %s %d   |   Term %d   |   Election in %d months\n" % [
			GameData.month_name(), GameData.current_year,
			GameData.terms_served + 1, GameData.months_until_election
		] +
		"⭐  Prestige: %d   |   Legitimacy: %.0f / 100" % [GameData.legacy_score, GameData.legitimacy]
	)

	if GameData.has_majority():
		lbl_majority.text = "✔ MAJORITY — %d / %d seats" % [GameData.player_seat_count(), GameData.TOTAL_SEATS]
		lbl_majority.add_theme_color_override("font_color", Color(0.2, 0.85, 0.2))
	elif GameData.has_coalition_majority():
		lbl_majority.text = "◈ COALITION MAJORITY — %d / %d seats" % [GameData.coalition_seats(), GameData.TOTAL_SEATS]
		lbl_majority.add_theme_color_override("font_color", Color(0.9, 0.75, 0.1))
	else:
		lbl_majority.text = "✘ OPPOSITION — %d / %d seats" % [GameData.player_seat_count(), GameData.TOTAL_SEATS]
		lbl_majority.add_theme_color_override("font_color", Color(0.9, 0.3, 0.3))

	lbl_economy.text = "📊  " + GameData.economy_summary()

	var pop_lines = "👥  Population Satisfaction:\n"
	for pop_name in GameData.pops:
		var p    = GameData.pops[pop_name]
		var sat  = p["satisfaction"]
		var bars = _bar(sat)
		var rad  = p["radicalisation"]
		var warn = " 🔥" if rad > 50 else ""
		pop_lines += "  %-14s  %s  %.0f%%%s\n" % [pop_name, bars, sat, warn]
	lbl_pops.text = pop_lines

	var g_lines = "🏆  Term Goals:\n"
	if GameData.term_goals.is_empty():
		g_lines += "  No goals set."
	for goal in GameData.term_goals:
		var status = "✔" if goal.get("achieved") else ("✘" if goal.get("failed") else "…")
		g_lines += "  [%s]  %s\n" % [status, goal["desc"]]
	lbl_goals.text = g_lines

func _bar(value: float, width: int = 12) -> String:
	var filled = int(clampf(value, 0.0, 100.0) / 100.0 * width)
	return "[" + "█".repeat(filled) + "░".repeat(width - filled) + "]"
