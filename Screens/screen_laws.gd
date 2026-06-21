extends Control

@onready var category_tabs : TabContainer = $Margin/VBox/Tabs
@onready var lbl_result    : Label        = $Margin/VBox/Result
@onready var lbl_capital   : Label        = $Margin/VBox/Capital

const CATEGORIES = ["Electoral", "Economic", "Social", "Civil"]

func _ready() -> void: refresh()

func refresh() -> void:
	lbl_capital.text = "Political Capital: %d / 40" % GameData.political_capital

	for i in range(category_tabs.get_tab_count()):
		var container = category_tabs.get_tab_control(i)
		if container == null: continue
		var vbox = container.get_node_or_null("Scroll/VBox")
		if vbox == null: continue
		for c in vbox.get_children(): c.queue_free()

	var available = GameData.available_laws()

	for law_name in GameData.constitution_laws:
		var law      = GameData.constitution_laws[law_name]
		var cat      = law.get("category", "Civil")
		var cat_idx  = CATEGORIES.find(cat)
		if cat_idx < 0: continue
		var container = category_tabs.get_tab_control(cat_idx)
		if container == null: continue
		var vbox = container.get_node_or_null("Scroll/VBox")
		if vbox == null: continue

		var panel = PanelContainer.new()
		var inner = VBoxContainer.new()
		inner.add_theme_constant_override("separation", 6)

		var title_row = HBoxContainer.new()
		var title = Label.new()
		var status = ""
		if law["passed"]:    status = "  ✔ ENACTED"
		elif law["repealed"]: status = "  ✘ REPEALED"
		elif available.has(law_name): status = "  [Available]"
		else: status = "  [Locked]"
		title.text = law_name + status
		title.add_theme_font_size_override("font_size", 17)
		if law["passed"]: title.add_theme_color_override("font_color", Color(0.3, 0.9, 0.3))
		elif not available.has(law_name) and not law["passed"]:
			title.add_theme_color_override("font_color", Color(0.5, 0.5, 0.5))
		title_row.add_child(title)
		inner.add_child(title_row)

		var desc = Label.new()
		desc.text = law["desc"]
		desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		desc.add_theme_font_size_override("font_size", 14)
		inner.add_child(desc)

		# Effects summary
		var fx = "Effects: "
		for key in law.get("effects", {}):
			fx += "%s %+.1f  " % [key, law["effects"][key]]
		var fx_lbl = Label.new()
		fx_lbl.text = fx
		fx_lbl.add_theme_font_size_override("font_size", 13)
		inner.add_child(fx_lbl)

		var seats_need = law.get("seats_needed", 151)
		var has_super  = law.get("requires_super", false)
		var seats_lbl  = Label.new()
		seats_lbl.text = "Requires: %d seats%s" % [seats_need, "  (SUPERMAJORITY)" if has_super else ""]
		seats_lbl.add_theme_font_size_override("font_size", 13)
		inner.add_child(seats_lbl)

		if available.has(law_name) and not law["passed"]:
			var btn_row = HBoxContainer.new()
			var btn_pass = Button.new()
			btn_pass.text = "📜 Pass Law (5 capital)"
			btn_pass.add_theme_font_size_override("font_size", 14)
			var ln = law_name
			btn_pass.pressed.connect(func(): _pass_law(ln))
			btn_row.add_child(btn_pass)
			inner.add_child(btn_row)
		elif law["passed"]:
			var btn_repeal = Button.new()
			btn_repeal.text = "✘ Repeal (8 capital)"
			btn_repeal.add_theme_font_size_override("font_size", 14)
			var ln = law_name
			btn_repeal.pressed.connect(func(): _repeal_law(ln))
			inner.add_child(btn_repeal)

		panel.add_child(inner)
		vbox.add_child(panel)

func _pass_law(law_name: String) -> void:
	if not GameData.spend_capital(5):
		lbl_result.text    = "Not enough political capital (need 5)."
		lbl_result.visible = true
		return
	var law     = GameData.constitution_laws[law_name]
	var seats   = law.get("seats_needed", 151)
	var need_sm = law.get("requires_super", false)
	var have    = GameData.coalition_seats()
	if (need_sm and not GameData.has_supermajority()) or (not need_sm and have < seats):
		GameData.gain_capital(5)  # refund
		lbl_result.text    = "Not enough votes to pass %s (have %d, need %d)." % [law_name, have, seats]
		lbl_result.visible = true
		return
	law["passed"] = true
	_apply_law_effects(law)
	GameData.legitimacy = clampf(GameData.legitimacy + 2.0, 0.0, 100.0)
	GameData.bills_passed += 1
	lbl_result.text    = "✔ %s enacted!" % law_name
	lbl_result.visible = true
	refresh()

func _repeal_law(law_name: String) -> void:
	if not GameData.spend_capital(8):
		lbl_result.text    = "Need 8 capital to repeal."
		lbl_result.visible = true
		return
	var law = GameData.constitution_laws[law_name]
	law["passed"]   = false
	law["repealed"] = true
	GameData.legitimacy = clampf(GameData.legitimacy - 5.0, 0.0, 100.0)
	lbl_result.text    = "✘ %s repealed. (-5 legitimacy)" % law_name
	lbl_result.visible = true
	refresh()

func _apply_law_effects(law: Dictionary) -> void:
	var fx = law.get("effects", {})
	for key in fx:
		var val = float(fx[key])
		match key:
			"legitimacy":        GameData.legitimacy      = clampf(GameData.legitimacy      + val, 0.0, 100.0)
			"approval":          GameData.approval_rating = clampf(GameData.approval_rating + val, 0.0, 100.0)
			"gdp_growth":        GameData.gdp_growth      = clampf(GameData.gdp_growth      + val, -5.0, 10.0)
			"budget_deficit":    GameData.budget_deficit  = clampf(GameData.budget_deficit  + val, -5.0, 20.0)
			"inflation":         GameData.inflation       = clampf(GameData.inflation        + val, -1.0, 15.0)
			"media_hostility":   GameData.media_hostility = clampf(GameData.media_hostility + val, 0.0, 100.0)
			"political_capital": GameData.gain_capital(int(val))
			"pop_working_class":
				GameData.pops["Working Class"]["satisfaction"] = clampf(GameData.pops["Working Class"]["satisfaction"] + val, 0.0, 100.0)
			"pop_business_elite":
				GameData.pops["Business Elite"]["satisfaction"] = clampf(GameData.pops["Business Elite"]["satisfaction"] + val, 0.0, 100.0)
			"pop_youth":
				GameData.pops["Youth"]["satisfaction"] = clampf(GameData.pops["Youth"]["satisfaction"] + val, 0.0, 100.0)
			"pop_pensioners":
				GameData.pops["Pensioners"]["satisfaction"] = clampf(GameData.pops["Pensioners"]["satisfaction"] + val, 0.0, 100.0)
