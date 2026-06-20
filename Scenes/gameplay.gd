extends Control

@onready var tab_container     : TabContainer = $TabContainer

@onready var lbl_player_name   : Label = $TabContainer/Overview/VBox/PlayerName
@onready var lbl_party         : Label = $TabContainer/Overview/VBox/Party
@onready var lbl_date          : Label = $TabContainer/Overview/VBox/Date
@onready var lbl_approval      : Label = $TabContainer/Overview/VBox/Approval
@onready var lbl_majority      : Label = $TabContainer/Overview/VBox/MajorityStatus
@onready var btn_next_month    : Button = $TabContainer/Overview/VBox/NextMonthBtn

@onready var seat_container    : VBoxContainer = $TabContainer/Parliament/VBox/SeatList

@onready var event_title       : Label  = $TabContainer/Events/VBox/EventTitle
@onready var event_desc        : Label  = $TabContainer/Events/VBox/EventDesc
@onready var btn_choice_a      : Button = $TabContainer/Events/VBox/ChoiceA
@onready var btn_choice_b      : Button = $TabContainer/Events/VBox/ChoiceB
@onready var lbl_event_result  : Label  = $TabContainer/Events/VBox/EventResult

var events : Array = [
	{
		"title": "Healthcare Bill",
		"desc":  "A bill proposing universal healthcare coverage has reached the floor. How do you vote?",
		"a_text": "Support the bill (+8 approval)",
		"b_text": "Oppose the bill (-5 approval)",
		"a_approval":  8.0,
		"b_approval": -5.0,
	},
	{
		"title": "Tax Reform Proposal",
		"desc":  "The treasury proposes cutting corporate taxes to attract investment. Your stance?",
		"a_text": "Back the cuts (-4 approval)",
		"b_text": "Block the cuts (+6 approval)",
		"a_approval": -4.0,
		"b_approval":  6.0,
	},
	{
		"title": "Education Funding",
		"desc":  "Schools in rural areas are under-resourced. A spending bill needs your vote.",
		"a_text": "Fund the schools (+10 approval)",
		"b_text": "Defer to next term (-3 approval)",
		"a_approval":  10.0,
		"b_approval":  -3.0,
	},
	{
		"title": "Environmental Act",
		"desc":  "A sweeping green energy act would reduce emissions but raise energy prices short-term.",
		"a_text": "Pass the act (+5 approval)",
		"b_text": "Reject the act (-7 approval)",
		"a_approval":  5.0,
		"b_approval": -7.0,
	},
	{
		"title": "Immigration Reform",
		"desc":  "New immigration legislation is being debated. Where does your party stand?",
		"a_text": "Support reform (+4 approval)",
		"b_text": "Oppose reform (-4 approval)",
		"a_approval":  4.0,
		"b_approval": -4.0,
	},
	{
		"title": "Judicial System Reform",
		"desc": "The current judicial system is deficient, a reform is being discussed.",
		"a_text": "Support reform (+2 approval)",
		"b_text": "Oppose reform (-5 approval)",
		"a_approval": 2.0,
		"b_approval": -5.0,
	}
]

var current_event_index : int = -1
var event_answered      : bool = false

func _ready() -> void:
	btn_next_month.pressed.connect(_on_next_month)
	btn_choice_a.pressed.connect(_on_choice_a)
	btn_choice_b.pressed.connect(_on_choice_b)

	_refresh_overview()
	_refresh_parliament()
	_load_next_event()

func _refresh_overview() -> void:
	lbl_player_name.text = "Politician: " + GameData.player_full_name()
	lbl_party.text       = "Party: "      + GameData.player_party
	lbl_date.text        = "Date: "       + GameData.month_name() + " " + str(GameData.current_year)
	lbl_approval.text    = "Approval: "   + "%.1f" % GameData.approval_rating + "%"

	if GameData.has_majority():
		lbl_majority.text            = "✔ Your party holds a MAJORITY (" + str(GameData.player_seat_count()) + " seats)"
		lbl_majority.add_theme_color_override("font_color", Color(0.2, 0.8, 0.2))
	else:
		lbl_majority.text            = "✘ Your party is in OPPOSITION (" + str(GameData.player_seat_count()) + " seats)"
		lbl_majority.add_theme_color_override("font_color", Color(0.9, 0.3, 0.3))

func _on_next_month() -> void:
	GameData.advance_month()
	var drift = (50.0 - GameData.approval_rating) * 0.02
	GameData.approval_rating = clampf(GameData.approval_rating + drift, 0.0, 100.0)
	_refresh_overview()
	_load_next_event()
	tab_container.current_tab = 2   

func _refresh_parliament() -> void:
	for child in seat_container.get_children():
		child.queue_free()

	var header = Label.new()
	header.text = "%-32s %s / %d seats" % ["Party", "Seats", GameData.TOTAL_SEATS]
	header.add_theme_font_size_override("font_size", 18)
	seat_container.add_child(header)

	var sorted_parties = GameData.seats.keys()
	sorted_parties.sort_custom(func(a, b): return GameData.seats[a] > GameData.seats[b])

	for party in sorted_parties:
		var count    = GameData.seats[party]
		var pct      = float(count) / float(GameData.TOTAL_SEATS) * 100.0
		var is_player = (party == GameData.player_party)

		var row = HBoxContainer.new()

		var name_lbl = Label.new()
		name_lbl.text              = ("★ " if is_player else "  ") + party
		name_lbl.custom_minimum_size = Vector2(280, 0)
		name_lbl.add_theme_font_size_override("font_size", 17)
		if is_player:
			name_lbl.add_theme_color_override("font_color", Color(1.0, 0.85, 0.1))

		var seat_lbl = Label.new()
		seat_lbl.text = "%d  (%.1f%%)" % [count, pct]
		seat_lbl.add_theme_font_size_override("font_size", 17)

		row.add_child(name_lbl)
		row.add_child(seat_lbl)
		seat_container.add_child(row)

func _load_next_event() -> void:
	current_event_index = (current_event_index + 1) % events.size()
	event_answered = false
	lbl_event_result.visible = false
	btn_choice_a.disabled    = false
	btn_choice_b.disabled    = false

	var ev = events[current_event_index]
	event_title.text   = ev["title"]
	event_desc.text    = ev["desc"]
	btn_choice_a.text  = ev["a_text"]
	btn_choice_b.text  = ev["b_text"]

func _on_choice_a() -> void:
	_resolve_event(events[current_event_index]["a_approval"])

func _on_choice_b() -> void:
	_resolve_event(events[current_event_index]["b_approval"])

func _resolve_event(approval_delta: float) -> void:
	if event_answered:
		return
	event_answered = true

	GameData.approval_rating = clampf(GameData.approval_rating + approval_delta, 0.0, 100.0)
	btn_choice_a.disabled    = true
	btn_choice_b.disabled    = true

	var sign_str = "+" if approval_delta >= 0 else ""
	lbl_event_result.text    = "Decision made. Approval: %.1f%% (%s%.1f)" % [
		GameData.approval_rating, sign_str, approval_delta
	]
	lbl_event_result.visible = true
	_refresh_overview()
