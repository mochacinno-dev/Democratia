extends Control

# Draws a semicircle parliament seating chart.
# Parent must call refresh() after seat data changes.

const SEAT_RADIUS_INNER : float = 80.0
const SEAT_RADIUS_OUTER : float = 220.0
const SEAT_DOT_RADIUS   : float = 7.0
const ROWS              : int   = 5

var _seats_to_draw : Array = []   # Array of { color: Color, highlighted: bool }

func refresh() -> void:
	_seats_to_draw.clear()

	# Build ordered seat list: sort parties right-to-left by ideology (right wing first)
	var parties = GameData.seats.keys()
	parties.sort_custom(func(a, b):
		return GameData.party_ideology.get(a, 0.0) > GameData.party_ideology.get(b, 0.0)
	)

	for party in parties:
		var count = GameData.seats[party]
		var color = GameData.party_colors.get(party, Color.GRAY)
		var is_player = (party == GameData.player_party)
		for i in range(count):
			_seats_to_draw.append({ "color": color, "highlighted": is_player })

	queue_redraw()

func _draw() -> void:
	if _seats_to_draw.is_empty():
		return

	var center = Vector2(size.x * 0.5, size.y * 0.88)
	var total  = _seats_to_draw.size()

	# Distribute seats across ROWS concentric arcs
	var seats_per_row : Array = []
	var remaining = total
	for row in range(ROWS):
		var rows_left = ROWS - row
		var in_this_row = int(ceil(float(remaining) / float(rows_left)))
		seats_per_row.append(in_this_row)
		remaining -= in_this_row

	var seat_index = 0
	for row in range(ROWS):
		var count_in_row = seats_per_row[row]
		if count_in_row <= 0:
			break
		var t = float(row) / float(ROWS - 1) if ROWS > 1 else 0.5
		var radius = lerp(SEAT_RADIUS_INNER, SEAT_RADIUS_OUTER, t)

		for i in range(count_in_row):
			if seat_index >= _seats_to_draw.size():
				break
			# Angle: PI (left) to 0 (right), sweeping the top semicircle
			var angle = PI - (float(i) / float(count_in_row - 1 if count_in_row > 1 else 1)) * PI
			var pos   = center + Vector2(cos(angle), -sin(angle)) * radius
			var seat  = _seats_to_draw[seat_index]

			# Draw shadow / highlight ring for player seats
			if seat["highlighted"]:
				draw_circle(pos, SEAT_DOT_RADIUS + 3.0, Color(1, 1, 1, 0.35))

			draw_circle(pos, SEAT_DOT_RADIUS, seat["color"])
			seat_index += 1

	# Draw baseline arc
	draw_arc(center, SEAT_RADIUS_OUTER + 16.0, PI, 2.0 * PI, 64, Color(0.4, 0.4, 0.4, 0.4), 2.0)