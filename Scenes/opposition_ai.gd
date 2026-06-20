extends Node

# Tracks the largest rival party and runs their monthly AI logic.

func largest_rival() -> String:
	var best_party = ""
	var best_seats = 0
	for party in GameData.seats:
		if party == GameData.player_party:
			continue
		if GameData.seats[party] > best_seats:
			best_seats = GameData.seats[party]
			best_party = party
	return best_party

func tick() -> String:
	var rival = largest_rival()
	if rival == "":
		return ""

	var msg = ""
	var approval = GameData.approval_rating

	# No-confidence vote if approval below 35
	if approval < 35.0 and randf() < 0.3:
		msg = _no_confidence_vote(rival)

	# Campaign harder near election
	elif GameData.months_until_election <= 6 and randf() < 0.4:
		msg = _campaign_attack(rival)

	# Occasional routine attacks
	elif randf() < 0.2:
		msg = _routine_attack(rival)

	return msg

func _no_confidence_vote(rival: String) -> String:
	var leader = GameData.party_leaders.get(rival, "Opposition Leader")
	# Tally up votes against player
	var against = 0
	for party in GameData.seats:
		if party == GameData.player_party: continue
		if GameData.coalition_stance.get(party, 0) != 1:
			against += GameData.seats.get(party, 0)

	var player_votes = GameData.coalition_seats()
	if against > player_votes:
		# Motion passes — heavy approval hit
		GameData.approval_rating = clampf(GameData.approval_rating - 15.0, 0.0, 100.0)
		GameData.polling[GameData.player_party] = clampf(
			GameData.polling.get(GameData.player_party, 20.0) - 5.0, 5.0, 60.0
		)
		GameData._normalise_polling()
		return "⚠ NO-CONFIDENCE: %s (%s) called a vote — and WON (%d vs %d). (-15 approval)" % [
			leader, rival, against, player_votes
		]
	else:
		GameData.approval_rating = clampf(GameData.approval_rating + 3.0, 0.0, 100.0)
		return "✔ NO-CONFIDENCE: %s (%s) called a vote — but it FAILED (%d vs %d). (+3 approval)" % [
			leader, rival, against, player_votes
		]

func _campaign_attack(rival: String) -> String:
	var leader = GameData.party_leaders.get(rival, "Opposition Leader")
	GameData.polling[rival] = clampf(GameData.polling.get(rival, 20.0) + 2.0, 5.0, 60.0)
	GameData._normalise_polling()
	return "📣 %s (%s) launches campaign blitz ahead of the election. Their polling rises." % [leader, rival]

func _routine_attack(rival: String) -> String:
	var leader = GameData.party_leaders.get(rival, "Opposition Leader")
	var attacks = [
		"%s (%s) accuses the government of mishandling the economy." % [leader, rival],
		"%s (%s) demands a parliamentary inquiry into recent decisions." % [leader, rival],
		"%s (%s) releases a policy paper attacking your record." % [leader, rival],
	]
	var msg = attacks[randi() % attacks.size()]
	GameData.approval_rating = clampf(GameData.approval_rating - 1.0, 0.0, 100.0)
	return msg