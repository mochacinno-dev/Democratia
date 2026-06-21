extends Control

@onready var chart      : Control        = $Margin/HBox/Left/Chart
@onready var legend_box : VBoxContainer  = $Margin/HBox/Left/Legend
@onready var lbl_header : Label          = $Margin/HBox/Left/Header
@onready var detail_box : VBoxContainer  = $Margin/HBox/Right/VBox

func _ready() -> void: refresh()

func refresh() -> void:
	lbl_header.text = "Parliament  —  %d seats  |  Majority: %d  |  Supermajority: %d" % [
		GameData.TOTAL_SEATS, GameData.majority_threshold(), GameData.supermajority_threshold()
	]

	# Legend
	for c in legend_box.get_children(): c.queue_free()
	var sorted = GameData.seats.keys()
	sorted.sort_custom(func(a, b): return GameData.seats[a] > GameData.seats[b])
	for party in sorted:
		var count     = GameData.seats[party]
		var pct       = float(count) / GameData.TOTAL_SEATS * 100.0
		var is_player = party == GameData.player_party
		var stance    = GameData.coalition_stance.get(party, 0)
		var row = HBoxContainer.new()
		row.add_theme_constant_override("separation", 8)
		var dot = ColorRect.new()
		dot.custom_minimum_size = Vector2(16, 16)
		dot.color = GameData.party_colors.get(party, Color.GRAY)
		var lbl = Label.new()
		var tag = ""
		if is_player: tag = " ★"
		elif stance == 1: tag = " [ally]"
		elif stance == -1: tag = " [hostile]"
		lbl.text = "%s%s  —  %d  (%.1f%%)" % [party, tag, count, pct]
		lbl.add_theme_font_size_override("font_size", 15)
		if is_player: lbl.add_theme_color_override("font_color", Color(1.0, 0.85, 0.1))
		elif stance == 1: lbl.add_theme_color_override("font_color", Color(0.4, 0.9, 0.4))
		row.add_child(dot)
		row.add_child(lbl)
		legend_box.add_child(row)

	# Detail panel: coalition analysis
	for c in detail_box.get_children(): c.queue_free()
	_add_detail("Coalition Seats", "%d / %d" % [GameData.coalition_seats(), GameData.TOTAL_SEATS])
	_add_detail("Majority at", "%d seats" % GameData.majority_threshold())
	_add_detail("Supermajority at", "%d seats" % GameData.supermajority_threshold())
	_add_detail("Your seats", str(GameData.player_seat_count()))
	_add_detail("Has majority?", "Yes ✔" if GameData.has_majority() else "No ✘")
	_add_detail("Coalition majority?", "Yes ✔" if GameData.has_coalition_majority() else "No ✘")
	_add_detail("Supermajority?", "Yes ✔" if GameData.has_supermajority() else "No ✘")

	detail_box.add_child(HSeparator.new())
	var lbl_allies = Label.new()
	lbl_allies.text = "Allied parties:"
	lbl_allies.add_theme_font_size_override("font_size", 15)
	detail_box.add_child(lbl_allies)
	for party in GameData.coalition_stance:
		if GameData.coalition_stance[party] == 1 and party != GameData.player_party:
			_add_detail("  " + party, "%d seats" % GameData.seats.get(party, 0))

	chart.refresh()

func _add_detail(key: String, val: String) -> void:
	var row = HBoxContainer.new()
	var k = Label.new(); k.text = key; k.custom_minimum_size = Vector2(180, 0); k.add_theme_font_size_override("font_size", 15)
	var v = Label.new(); v.text = val; v.add_theme_font_size_override("font_size", 15)
	row.add_child(k); row.add_child(v)
	detail_box.add_child(row)
