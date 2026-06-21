extends Control
@onready var lbl_nations : Label        = $Margin/VBox/Nations
@onready var opt_nation  : OptionButton = $Margin/VBox/HBox/NationOpt
@onready var btn_envoy   : Button       = $Margin/VBox/HBox/BtnEnvoy
@onready var btn_trade   : Button       = $Margin/VBox/HBox/BtnTrade
@onready var btn_alliance: Button       = $Margin/VBox/HBox/BtnAlliance
@onready var btn_sanction: Button       = $Margin/VBox/HBox/BtnSanction
@onready var lbl_crisis  : Label        = $Margin/VBox/Crisis
@onready var btn_resolve : Button       = $Margin/VBox/HBoxCrisis/BtnResolve
@onready var btn_ignore  : Button       = $Margin/VBox/HBoxCrisis/BtnIgnore
@onready var lbl_result  : Label        = $Margin/VBox/Result
@onready var lbl_cap     : Label        = $Margin/VBox/Capital

func _ready() -> void:
	btn_envoy.pressed.connect(_send_envoy)
	btn_trade.pressed.connect(_sign_trade)
	btn_alliance.pressed.connect(_join_alliance)
	btn_sanction.pressed.connect(_impose_sanction)
	btn_resolve.pressed.connect(_resolve_crisis)
	btn_ignore.pressed.connect(_ignore_crisis)
	refresh()

func refresh() -> void:
	lbl_cap.text = "Political Capital: %d / 40" % GameData.political_capital
	var txt = "Foreign Relations:\n"
	for nation in GameData.foreign_relations:
		var r = GameData.foreign_relations[nation]
		var rel = r["relation"]
		var tags = []
		if r["envoy_sent"]:  tags.append("Envoy")
		if r["trade_deal"]:  tags.append("Trade ✔")
		if r["alliance"]:    tags.append("Allied ✔")
		if r["sanctions"]:   tags.append("SANCTIONS ✘")
		var rel_bar = _rel_bar(rel)
		txt += "  %-12s  %s %+d  %s\n" % [nation, rel_bar, rel, "  |  ".join(tags)]
	lbl_nations.text = txt

	opt_nation.clear()
	for nation in GameData.foreign_relations: opt_nation.add_item(nation)

	var c = GameData.active_crisis
	if c.is_empty() or c.get("resolved", true):
		lbl_crisis.text = "Active Crisis: None"
		btn_resolve.disabled = true; btn_ignore.disabled = true
	else:
		lbl_crisis.text = "⚠ CRISIS: %s\n%s\nDeadline: %d months | Severity: %d | Cost: %d capital" % [
			c["title"], c["desc"], c["deadline_months"], c["severity"], c["resolve_cost"]
		]
		btn_resolve.disabled = false; btn_ignore.disabled = false

func _get_nation() -> String:
	var i = opt_nation.selected
	if i < 0: return ""
	return opt_nation.get_item_text(i)

func _send_envoy() -> void:
	var n = _get_nation(); if n == "": return
	if not GameData.spend_capital(2):
		lbl_result.text = "Need 2 capital."; lbl_result.visible = true; return
	GameData.foreign_relations[n]["envoy_sent"] = true
	GameData.foreign_relations[n]["relation"] = clampf(GameData.foreign_relations[n]["relation"] + 15, -100, 100)
	lbl_result.text = "Envoy sent to %s. Relations improve." % n; lbl_result.visible = true; refresh()

func _sign_trade() -> void:
	var n = _get_nation(); if n == "": return
	var rel = GameData.foreign_relations[n]
	if rel["relation"] < 10:
		lbl_result.text = "Relations too low with %s (need >10)." % n; lbl_result.visible = true; return
	if not GameData.spend_capital(4):
		lbl_result.text = "Need 4 capital."; lbl_result.visible = true; return
	rel["trade_deal"] = true
	lbl_result.text = "Trade deal signed with %s!" % n; lbl_result.visible = true; refresh()

func _join_alliance() -> void:
	var n = _get_nation(); if n == "": return
	var rel = GameData.foreign_relations[n]
	if rel["relation"] < 40:
		lbl_result.text = "Need relations > 40 with %s." % n; lbl_result.visible = true; return
	if not GameData.spend_capital(6):
		lbl_result.text = "Need 6 capital."; lbl_result.visible = true; return
	rel["alliance"] = true
	GameData.approval_rating = clampf(GameData.approval_rating + 4.0, 0.0, 100.0)
	GameData.legitimacy = clampf(GameData.legitimacy + 3.0, 0.0, 100.0)
	lbl_result.text = "Alliance formed with %s! (+4 approval, +3 legitimacy)" % n; lbl_result.visible = true; refresh()

func _impose_sanction() -> void:
	var n = _get_nation(); if n == "": return
	GameData.foreign_relations[n]["sanctions"] = true
	GameData.foreign_relations[n]["relation"] = clampf(GameData.foreign_relations[n]["relation"] - 30, -100, 100)
	lbl_result.text = "Sanctions imposed on %s. Relations drop." % n; lbl_result.visible = true; refresh()

func _resolve_crisis() -> void:
	var c = GameData.active_crisis
	if c.is_empty() or c.get("resolved", true): return
	if not GameData.spend_capital(c.get("resolve_cost", 5)):
		lbl_result.text = "Need %d capital." % c["resolve_cost"]; lbl_result.visible = true; return
	GameData.gdp_growth      = clampf(GameData.gdp_growth      + c.get("resolve_gdp", 0.0),      -5.0, 10.0)
	GameData.approval_rating = clampf(GameData.approval_rating + c.get("resolve_approval", 0.0), 0.0, 100.0)
	GameData.active_crisis["resolved"] = true
	lbl_result.text = "✔ Crisis resolved: %s" % c["title"]; lbl_result.visible = true; refresh()

func _ignore_crisis() -> void:
	var c = GameData.active_crisis
	if c.is_empty() or c.get("resolved", true): return
	GameData.gdp_growth      = clampf(GameData.gdp_growth      + c.get("ignore_gdp", -1.0),      -5.0, 10.0)
	GameData.approval_rating = clampf(GameData.approval_rating + c.get("ignore_approval", -10.0), 0.0, 100.0)
	GameData.legitimacy      = clampf(GameData.legitimacy       + c.get("ignore_legitimacy", -5.0), 0.0, 100.0)
	GameData.scandal_meter   = clampf(GameData.scandal_meter    + 10.0, 0.0, 100.0)
	GameData.active_crisis["resolved"] = true
	lbl_result.text = "✘ Crisis ignored — consequences felt."; lbl_result.visible = true; refresh()

func _rel_bar(rel: int) -> String:
	var norm = (rel + 100) / 200.0
	var f = int(norm * 10)
	return "[" + "█".repeat(f) + "░".repeat(10 - f) + "]"
