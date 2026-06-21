extends Control
@onready var lbl_polling  : Label  = $Margin/VBox/Polling
@onready var lbl_funds    : Label  = $Margin/VBox/Funds
@onready var btn_ads      : Button = $Margin/VBox/HBox/BtnAds
@onready var btn_rally    : Button = $Margin/VBox/HBox/BtnRally
@onready var btn_attack   : Button = $Margin/VBox/HBox/BtnAttack
@onready var btn_vote     : Button = $Margin/VBox/BtnVote
@onready var lbl_result   : Label  = $Margin/VBox/Result

func _ready() -> void:
	btn_ads.pressed.connect(func(): _campaign(2, 4.0, "Ad blitz. +4 poll."))
	btn_rally.pressed.connect(func(): _campaign(1, 2.0, "Rally held. +2 poll."))
	btn_attack.pressed.connect(_attack)
	btn_vote.pressed.connect(_hold_election)
	refresh()

func refresh() -> void:
	var sorted = GameData.polling.keys()
	sorted.sort_custom(func(a, b): return GameData.polling[a] > GameData.polling[b])
	var txt = "Current Polling:\n"
	for p in sorted:
		var pct = GameData.polling[p]
		var bar = _bar(pct, 20)
		txt += "  %s%s  %s %.1f%%\n" % ["★ " if p == GameData.player_party else "  ", p, bar, pct]
	lbl_polling.text = txt
	lbl_funds.text = "Campaign Funds: %d" % GameData.campaign_funds

	var active = GameData.election_active
	btn_ads.disabled    = not active or GameData.campaign_funds < 2
	btn_rally.disabled  = not active or GameData.campaign_funds < 1
	btn_attack.disabled = not active or GameData.campaign_funds < 1
	btn_vote.disabled   = not active
	if not active:
		lbl_result.text = "No election scheduled. Elections are called every 4 years."; lbl_result.visible = true

func _campaign(cost: int, boost: float, msg: String) -> void:
	if GameData.campaign_funds < cost: return
	GameData.campaign_funds -= cost
	GameData.polling[GameData.player_party] = clampf(GameData.polling.get(GameData.player_party, 20.0) + boost, 1.0, 70.0)
	GameData.normalise_polling()
	lbl_result.text = msg; lbl_result.visible = true; refresh()

func _attack() -> void:
	if GameData.campaign_funds < 1: return
	GameData.campaign_funds -= 1
	var rival = ""; var best = 0.0
	for p in GameData.polling:
		if p == GameData.player_party: continue
		if GameData.polling[p] > best: best = GameData.polling[p]; rival = p
	if rival == "": return
	GameData.polling[rival] = clampf(GameData.polling[rival] - 3.5, 1.0, 70.0)
	GameData.normalise_polling()
	lbl_result.text = "Attack ads vs %s. Their polling drops." % rival; lbl_result.visible = true; refresh()

func _hold_election() -> void:
	GameData.run_election()
	var won = GameData.has_majority()
	lbl_result.text = ("Election held!\nYour party: %d seats.\n%s" % [
		GameData.player_seat_count(),
		"✔ You hold a majority!" if won else "✘ No majority — build a coalition."
	])
	lbl_result.visible = true; refresh()

func _bar(v: float, w: int = 20) -> String:
	var f = int(clampf(v, 0, 100) / 100.0 * w)
	return "[" + "█".repeat(f) + "░".repeat(w - f) + "]"
