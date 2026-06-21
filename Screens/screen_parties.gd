extends Control
@onready var box : VBoxContainer = $Scroll/VBox
@onready var lbl_result : Label = $Result
@onready var lbl_cap : Label = $Capital
func _ready() -> void: refresh()
func refresh() -> void:
	lbl_cap.text = "Political Capital: %d / 40" % GameData.political_capital
	for c in box.get_children(): c.queue_free()
	for party in GameData.seats:
		var panel = PanelContainer.new()
		var vbox  = VBoxContainer.new()
		vbox.add_theme_constant_override("separation", 6)
		# Party header
		var hdr = Label.new()
		var dom = GameData.dominant_faction(party)
		var stance = GameData.coalition_stance.get(party, 0)
		var stance_txt = "  [ALLIED ✔]" if stance == 1 else ("  [HOSTILE ✘]" if stance == -1 else "")
		hdr.text = "%s%s  —  %d seats  |  Ideology: %+.1f  |  Leader: %s" % [
			party, stance_txt, GameData.seats.get(party, 0),
			GameData.party_ideology.get(party, 0.0), GameData.party_leaders.get(party, "?")
		]
		hdr.add_theme_font_size_override("font_size", 16)
		if party == GameData.player_party:
			hdr.add_theme_color_override("font_color", Color(1.0, 0.85, 0.1))
		vbox.add_child(hdr)
		# Factions
		var factions = GameData.party_factions.get(party, {})
		for fname in factions:
			var power = factions[fname]
			var bar   = _bar(power)
			var is_dom = (fname == dom)
			var flbl  = Label.new()
			flbl.text = "  %s%s  %s  %.0f%%" % ["★ " if is_dom else "  ", fname, bar, power]
			flbl.add_theme_font_size_override("font_size", 14)
			if is_dom: flbl.add_theme_color_override("font_color", Color(1.0, 0.9, 0.3))
			vbox.add_child(flbl)
		# Polling
		var poll_lbl = Label.new()
		poll_lbl.text = "  Polling: %.1f%%  |  Ideology trend: %+.1f" % [
			GameData.polling.get(party, 0.0), GameData.party_ideology.get(party, 0.0)
		]
		poll_lbl.add_theme_font_size_override("font_size", 14)
		vbox.add_child(poll_lbl)
		# Coalition buttons (not for own party)
		if party != GameData.player_party:
			var btn_row = HBoxContainer.new()
			btn_row.add_theme_constant_override("separation", 8)
			var current_stance = GameData.coalition_stance.get(party, 0)
			if current_stance != 1:
				var btn_ally = Button.new()
				btn_ally.text = "🤝 Court Alliance (4 capital)"
				btn_ally.add_theme_font_size_override("font_size", 13)
				var p = party
				btn_ally.pressed.connect(func(): _court_alliance(p))
				btn_row.add_child(btn_ally)
			if current_stance == 1:
				var btn_drop = Button.new()
				btn_drop.text = "✘ Drop Alliance"
				btn_drop.add_theme_font_size_override("font_size", 13)
				var p = party
				btn_drop.pressed.connect(func(): _drop_alliance(p))
				btn_row.add_child(btn_drop)
			vbox.add_child(btn_row)
		panel.add_child(vbox)
		box.add_child(panel)

func _court_alliance(party: String) -> void:
	if not GameData.spend_capital(4):
		lbl_result.text = "Need 4 capital."; lbl_result.visible = true; return
	var dist = GameData.ideology_distance(party)
	var chance = clampf(1.0 - dist / 14.0, 0.1, 0.85)
	if randf() < chance:
		GameData.coalition_stance[party] = 1
		lbl_result.text = "✔ %s agreed to an alliance!" % party
	else:
		lbl_result.text = "✘ %s declined." % party
	lbl_result.visible = true
	refresh()

func _drop_alliance(party: String) -> void:
	GameData.coalition_stance[party] = 0
	lbl_result.text = "Alliance with %s ended." % party
	lbl_result.visible = true
	refresh()

func _bar(value: float, w: int = 10) -> String:
	var f = int(clampf(value, 0.0, 100.0) / 100.0 * w)
	return "[" + "█".repeat(f) + "░".repeat(w - f) + "]"
