extends Control
@onready var lbl_headline : Label  = $Margin/VBox/Headline
@onready var lbl_hostility: Label  = $Margin/VBox/Hostility
@onready var lbl_groups   : Label  = $Margin/VBox/Groups
@onready var btn_conf     : Button = $Margin/VBox/HBox/BtnConf
@onready var btn_buy      : Button = $Margin/VBox/HBox/BtnBuy
@onready var lbl_result   : Label  = $Margin/VBox/Result

const GOOD = ["\"{name} DELIVERS\": Record growth figures praised by markets.","POLL BOOST: {party} surges in latest survey.","PARLIAMENT BACKS PM: Key vote passes comfortably."]
const BAD  = ["CRISIS AT THE TOP: Cabinet infighting exposed.","POLL SLUMP: {party} loses ground.","SCANDAL LOOMS: Rumours swirl around senior officials."]
const NEUT = ["{party} HOLDS STEADY: No major shifts.", "PARLIAMENT IN SESSION: Busy legislative week ahead."]

func _ready() -> void:
	btn_conf.pressed.connect(_press_conference)
	btn_buy.pressed.connect(_buy_media)
	refresh()

func refresh() -> void:
	if GameData.last_headline == "":
		GameData.last_headline = _gen_headline()
	lbl_headline.text = "📰 " + GameData.last_headline
	var h = GameData.media_hostility
	lbl_hostility.text = "Media Hostility:  %.0f / 100  %s" % [h, "(HOSTILE)" if h > 50 else "(Manageable)"]
	var g = "👥 Public Group Satisfaction:\n"
	for pop in GameData.pops:
		var sat = GameData.pops[pop]["satisfaction"]
		var rad = GameData.pops[pop]["radicalisation"]
		var bar = _bar(sat)
		g += "  %-14s  %s %.0f%%  (Radicalisation: %.0f%%)\n" % [pop, bar, sat, rad]
	lbl_groups.text = g

func _gen_headline() -> String:
	var pool = NEUT
	if GameData.approval_rating >= 60: pool = GOOD if randf() < 0.7 else NEUT
	elif GameData.approval_rating <= 35: pool = BAD if randf() < 0.7 else NEUT
	if GameData.media_hostility > 50 and randf() < 0.4: pool = BAD
	var t = pool[randi() % pool.size()]
	return t.replace("{name}", GameData.player_full_name()).replace("{party}", GameData.player_party)

func _press_conference() -> void:
	if not GameData.spend_capital(2):
		lbl_result.text = "Need 2 capital."; lbl_result.visible = true; return
	var chance = 0.6 - GameData.media_hostility / 200.0
	if randf() < chance:
		GameData.approval_rating = clampf(GameData.approval_rating + 5.0, 0.0, 100.0)
		GameData.media_hostility  = clampf(GameData.media_hostility  - 5.0, 0.0, 100.0)
		lbl_result.text = "✔ Press conference went well. (+5 approval)"
	else:
		GameData.approval_rating = clampf(GameData.approval_rating - 4.0, 0.0, 100.0)
		GameData.media_hostility  = clampf(GameData.media_hostility  + 8.0, 0.0, 100.0)
		GameData.scandal_meter    = clampf(GameData.scandal_meter    + 5.0, 0.0, 100.0)
		lbl_result.text = "✘ Backfired. (-4 approval, media turns hostile)"
	GameData.last_headline = _gen_headline()
	lbl_result.visible = true; refresh()

func _buy_media() -> void:
	if not GameData.spend_capital(8):
		lbl_result.text = "Need 8 capital."; lbl_result.visible = true; return
	GameData.media_hostility = clampf(GameData.media_hostility - 25.0, 0.0, 100.0)
	lbl_result.text = "Media outlet acquired. Hostility -25."; lbl_result.visible = true; refresh()

func _bar(v: float, w: int = 10) -> String:
	var f = int(clampf(v, 0, 100) / 100.0 * w)
	return "[" + "█".repeat(f) + "░".repeat(w - f) + "]"
