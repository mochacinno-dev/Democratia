extends Control
# Sparkline graph + stats + policy levers
@onready var graph      : Control      = $Margin/HBox/Left/Graph
@onready var lbl_stats  : Label        = $Margin/HBox/Left/Stats
@onready var policy_box : VBoxContainer = $Margin/HBox/Right/VBox
@onready var lbl_result : Label        = $Margin/HBox/Right/Result

func _ready() -> void: refresh()

func refresh() -> void:
	lbl_stats.text = (
		"GDP Growth:    %+.2f%%\n" % GameData.gdp_growth +
		"Unemployment:  %.1f%%\n" % GameData.unemployment +
		"Budget Deficit: %.1f%% GDP\n" % GameData.budget_deficit +
		"Inflation:     %.1f%%\n" % GameData.inflation +
		"GDP Absolute:  £%.0fbn" % GameData.gdp_absolute
	)
	graph.queue_redraw()
	_build_policy_panel()

func _build_policy_panel() -> void:
	for c in policy_box.get_children(): c.queue_free()
	_add_policy("💰 Stimulus Package",   "GDP ▲ +0.8  Deficit ▲ +1.0\nWorkers +5", "stimulus")
	_add_policy("✂ Austerity Cuts",      "Deficit ▼ -1.2  GDP ▼ -0.5\nWorkers -8  Business +6", "austerity")
	_add_policy("🏦 Cut Interest Rates", "GDP ▲ +0.4  Jobs ▲\nYouth +4", "rate_cut")
	_add_policy("📦 Trade Liberalisation","GDP ▲ +0.5  Inflation ▲ +0.3\nBusiness +8", "trade_lib")
	_add_policy("🌱 Green Investment",   "GDP ▲ +0.2  Deficit ▲ +0.6\nYouth +10  Workers +5", "green_invest")

func _add_policy(label: String, detail: String, action: String) -> void:
	var panel = PanelContainer.new()
	var vb    = VBoxContainer.new()
	vb.add_theme_constant_override("separation", 4)
	var hdr = Label.new(); hdr.text = label; hdr.add_theme_font_size_override("font_size", 16)
	var det = Label.new(); det.text = detail; det.add_theme_font_size_override("font_size", 13); det.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	var btn = Button.new(); btn.text = "Apply (costs 2 capital)"; btn.add_theme_font_size_override("font_size", 14)
	var a = action
	btn.pressed.connect(func(): _do_policy(a))
	vb.add_child(hdr); vb.add_child(det); vb.add_child(btn)
	panel.add_child(vb)
	policy_box.add_child(panel)

func _do_policy(action: String) -> void:
	if not GameData.spend_capital(2):
		lbl_result.text = "Need 2 capital."; lbl_result.visible = true; return
	match action:
		"stimulus":
			GameData.gdp_growth = clampf(GameData.gdp_growth + 0.8, -5.0, 10.0)
			GameData.budget_deficit = clampf(GameData.budget_deficit + 1.0, -5.0, 20.0)
			GameData.approval_rating = clampf(GameData.approval_rating + 3.0, 0.0, 100.0)
			GameData.pops["Working Class"]["satisfaction"] = clampf(GameData.pops["Working Class"]["satisfaction"] + 5.0, 0.0, 100.0)
			lbl_result.text = "Stimulus applied."
		"austerity":
			GameData.gdp_growth = clampf(GameData.gdp_growth - 0.5, -5.0, 10.0)
			GameData.budget_deficit = clampf(GameData.budget_deficit - 1.2, -5.0, 20.0)
			GameData.approval_rating = clampf(GameData.approval_rating - 5.0, 0.0, 100.0)
			GameData.pops["Business Elite"]["satisfaction"] = clampf(GameData.pops["Business Elite"]["satisfaction"] + 6.0, 0.0, 100.0)
			GameData.pops["Working Class"]["satisfaction"]  = clampf(GameData.pops["Working Class"]["satisfaction"]  - 8.0, 0.0, 100.0)
			lbl_result.text = "Austerity applied."
		"rate_cut":
			GameData.gdp_growth   = clampf(GameData.gdp_growth   + 0.4, -5.0, 10.0)
			GameData.unemployment = clampf(GameData.unemployment  - 0.3,  0.5, 18.0)
			GameData.approval_rating = clampf(GameData.approval_rating + 1.0, 0.0, 100.0)
			GameData.pops["Youth"]["satisfaction"] = clampf(GameData.pops["Youth"]["satisfaction"] + 4.0, 0.0, 100.0)
			lbl_result.text = "Rate cut applied."
		"trade_lib":
			GameData.gdp_growth = clampf(GameData.gdp_growth + 0.5, -5.0, 10.0)
			GameData.inflation  = clampf(GameData.inflation   + 0.3, -1.0, 15.0)
			GameData.pops["Business Elite"]["satisfaction"] = clampf(GameData.pops["Business Elite"]["satisfaction"] + 8.0, 0.0, 100.0)
			lbl_result.text = "Trade liberalisation applied."
		"green_invest":
			GameData.gdp_growth     = clampf(GameData.gdp_growth     + 0.2, -5.0, 10.0)
			GameData.budget_deficit = clampf(GameData.budget_deficit  + 0.6, -5.0, 20.0)
			GameData.pops["Youth"]["satisfaction"]         = clampf(GameData.pops["Youth"]["satisfaction"]         + 10.0, 0.0, 100.0)
			GameData.pops["Working Class"]["satisfaction"] = clampf(GameData.pops["Working Class"]["satisfaction"] + 5.0,  0.0, 100.0)
			lbl_result.text = "Green investment applied."
	lbl_result.visible = true
	refresh()
