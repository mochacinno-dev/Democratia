extends Node

const GOOD_HEADLINES : Array = [
	"'{name} DELIVERS': Economic figures beat expectations.",
	"POLL SURGE: {party} climbs in latest survey.",
	"PRAISE FOR PM: Opposition concedes on key issue.",
	"GROWTH UP: GDP figures show strongest quarter in years.",
	"UNITY IN PARLIAMENT: Cross-party bill passes with ease.",
	"PUBLIC BACKS {name}: Approval at highest point this term.",
]

const BAD_HEADLINES : Array = [
	"CRISIS IN CABINET: Sources report infighting at the top.",
	"POLL SLUMP: {party} loses ground amid voter discontent.",
	"UNDER FIRE: {name} faces questions over economic record.",
	"UNEMPLOYMENT RISES: Voters punish {party} at doorstep.",
	"BACKBENCH REVOLT: MPs defy {name} on key vote.",
	"SCANDAL LOOMS: Rumours swirl around senior officials.",
]

const NEUTRAL_HEADLINES : Array = [
	"PARLIAMENT IN SESSION: Busy week ahead for lawmakers.",
	"BUDGET WATCH: Treasury officials tight-lipped on figures.",
	"{party} HOLDS STEADY: No major shift in public mood.",
	"FOREIGN VISIT: {name} meets international counterparts.",
	"POLICY REVIEW: Government orders inquiry into key area.",
]

const CRISIS_HEADLINES : Array = [
	"EMERGENCY TALKS: Government convenes crisis cabinet.",
	"NATION ON EDGE: {name} urged to act fast.",
	"OPPOSITION DEMANDS ANSWERS: Crisis deepens.",
]

func generate_headline() -> String:
	var pool : Array
	var approval = GameData.approval_rating
	var has_crisis = not GameData.active_crisis.is_empty() and not GameData.active_crisis.get("resolved", true)

	if has_crisis:
		pool = CRISIS_HEADLINES
	elif approval >= 60.0:
		pool = GOOD_HEADLINES if randf() < 0.75 else NEUTRAL_HEADLINES
	elif approval <= 35.0:
		pool = BAD_HEADLINES if randf() < 0.75 else NEUTRAL_HEADLINES
	else:
		pool = NEUTRAL_HEADLINES if randf() < 0.5 else (GOOD_HEADLINES if approval > 50.0 else BAD_HEADLINES)

	# Hostile media amplifies bad news
	if GameData.media_hostility > 50.0 and randf() < 0.4:
		pool = BAD_HEADLINES

	var template = pool[randi() % pool.size()]
	var headline = template \
		.replace("{name}", GameData.player_full_name()) \
		.replace("{party}", GameData.player_party)

	GameData.last_headline = headline
	return headline

func press_conference() -> Dictionary:
	# Costs 2 political capital
	if not GameData.spend_capital(2):
		return { "success": false, "msg": "Not enough political capital (need 2)." }

	GameData.press_spun_this_month = true
	# Base 60% chance of good spin; hostile media reduces it
	var chance = 0.6 - (GameData.media_hostility / 200.0)
	if randf() < chance:
		GameData.approval_rating = clampf(GameData.approval_rating + 5.0, 0.0, 100.0)
		GameData.media_hostility  = clampf(GameData.media_hostility  - 5.0, 0.0, 100.0)
		return { "success": true,  "msg": "Press conference went well. (+5 approval, media softens)" }
	else:
		GameData.approval_rating = clampf(GameData.approval_rating - 4.0, 0.0, 100.0)
		GameData.media_hostility  = clampf(GameData.media_hostility  + 8.0, 0.0, 100.0)
		GameData.scandal_meter    = clampf(GameData.scandal_meter    + 5.0, 0.0, 100.0)
		return { "success": false, "msg": "Press conference backfired. (-4 approval, media turns hostile)" }

func buy_media_outlet() -> String:
	# Costs 8 political capital — reduces media hostility significantly
	if not GameData.spend_capital(8):
		return "Not enough political capital (need 8)."
	GameData.media_hostility = clampf(GameData.media_hostility - 25.0, 0.0, 100.0)
	return "Friendly ownership deal secured. Media hostility reduced. (Cost: 8 capital)"