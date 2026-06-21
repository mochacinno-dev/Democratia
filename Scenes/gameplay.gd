extends Control
# ═══════════════════════════════════════════════════════════════════════════════
# GAMEPLAY — sidebar nav + main panel
# ═══════════════════════════════════════════════════════════════════════════════

const SCREENS = {
	"Overview":    "res://Screens/screen_overview.tscn",
	"Parliament":  "res://Screens/screen_parliament.tscn",
	"Laws":        "res://Screens/screen_laws.tscn",
	"Parties":     "res://Screens/screen_parties.tscn",
	"Legislation": "res://Screens/screen_legislation.tscn",
	"Economy":     "res://Screens/screen_economy.tscn",
	"Cabinet":     "res://Screens/screen_cabinet.tscn",
	"Foreign":     "res://Screens/screen_foreign.tscn",
	"Press":       "res://Screens/screen_press.tscn",
	"Election":    "res://Screens/screen_election.tscn",
	"Goals":       "res://Screens/screen_goals.tscn",
}

const ICONS = {
	"Overview":    "🏛",
	"Parliament":  "🪑",
	"Laws":        "📜",
	"Parties":     "🎭",
	"Legislation": "⚖",
	"Economy":     "📈",
	"Cabinet":     "👔",
	"Foreign":     "🌍",
	"Press":       "📰",
	"Election":    "🗳",
	"Goals":       "🏆",
}

@onready var sidebar      : VBoxContainer  = $Body/Sidebar/Scroll/VBox
@onready var main_panel   : Control        = $Body/MainPanel
@onready var bar_date     : Label          = $TopBar/HBox/Date
@onready var bar_approval : Label          = $TopBar/HBox/Approval
@onready var bar_capital  : Label          = $TopBar/HBox/Capital
@onready var bar_seats    : Label          = $TopBar/HBox/Seats
@onready var bar_legit    : Label          = $TopBar/HBox/Legitimacy
@onready var bar_crisis   : Label          = $TopBar/HBox/CrisisAlert
@onready var btn_advance  : Button         = $TopBar/HBox/AdvanceBtn
@onready var events_panel : PanelContainer = $EventsOverlay
@onready var events_list  : VBoxContainer  = $EventsOverlay/Margin/VBox/Scroll/EventsList
@onready var btn_dismiss  : Button         = $EventsOverlay/Margin/VBox/DismissBtn

var current_screen  : String     = ""
var sidebar_buttons : Dictionary = {}

func _ready() -> void:
	_build_sidebar()
	btn_advance.pressed.connect(_on_advance_month)
	btn_dismiss.pressed.connect(_on_events_dismissed)
	events_panel.visible = false
	_refresh_topbar()
	_switch_screen("Overview")

func _build_sidebar() -> void:
	for child in sidebar.get_children():
		child.queue_free()
	for screen_name in SCREENS:
		var btn = Button.new()
		btn.text = "  %s  %s" % [ICONS.get(screen_name, ""), screen_name]
		btn.alignment = HORIZONTAL_ALIGNMENT_LEFT
		btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		btn.custom_minimum_size   = Vector2(0, 40)
		btn.flat = true
		var sn = screen_name
		btn.pressed.connect(func(): _switch_screen(sn))
		sidebar.add_child(btn)
		sidebar_buttons[screen_name] = btn

func _switch_screen(screen_name: String) -> void:
	if current_screen == screen_name: return
	current_screen = screen_name
	for sn in sidebar_buttons:
		sidebar_buttons[sn].flat = (sn != screen_name)
	for child in main_panel.get_children():
		child.queue_free()
	var path = SCREENS.get(screen_name, "")
	if path == "": return
	var node = load(path).instantiate()
	node.set_name("Screen")
	node.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	main_panel.add_child(node)
	if node.has_method("refresh"):
		node.refresh()

func _refresh_topbar() -> void:
	bar_date.text = "📅 %s %d" % [GameData.month_name(), GameData.current_year]
	if GameData.election_active:
		bar_date.text = "🗳 ELECTION  " + bar_date.text

	var appr = GameData.approval_rating
	bar_approval.text = "👍 %.0f%%" % appr
	bar_approval.add_theme_color_override("font_color",
		Color(0.3, 0.9, 0.3) if appr >= 55 else
		(Color(0.95, 0.65, 0.1) if appr >= 38 else Color(0.95, 0.3, 0.3)))

	bar_capital.text = "⚡ %d" % GameData.political_capital

	var have = GameData.coalition_seats()
	var need = GameData.majority_threshold()
	bar_seats.text = "🪑 %d/%d" % [have, GameData.TOTAL_SEATS]
	bar_seats.add_theme_color_override("font_color",
		Color(0.3, 0.9, 0.3) if have >= need else Color(0.95, 0.65, 0.1))

	var legit = GameData.legitimacy
	bar_legit.text = "⚖ %.0f" % legit
	bar_legit.add_theme_color_override("font_color",
		Color(0.3, 0.9, 0.3) if legit >= 60 else
		(Color(0.95, 0.65, 0.1) if legit >= 35 else Color(0.95, 0.3, 0.3)))

	var has_crisis = not GameData.active_crisis.is_empty() \
		and not GameData.active_crisis.get("resolved", true)
	bar_crisis.visible = has_crisis
	if has_crisis:
		bar_crisis.text = "⚠ " + GameData.active_crisis.get("title", "CRISIS")

func _on_advance_month() -> void:
	btn_advance.disabled = true
	GameData.advance_month()
	var events = Systems.process_month()
	_refresh_topbar()
	var screen = main_panel.get_node_or_null("Screen")
	if screen and screen.has_method("refresh"):
		screen.refresh()
	for child in events_list.get_children():
		child.queue_free()
	for ev_text in events:
		var lbl = Label.new()
		lbl.text = ev_text
		lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		lbl.add_theme_font_size_override("font_size", 15)
		events_list.add_child(lbl)
	if events.size() > 0:
		events_panel.visible = true
	else:
		# No events — re-enable immediately
		btn_advance.disabled = false
	if GameData.election_active:
		_switch_screen("Election")

func _on_events_dismissed() -> void:
	events_panel.visible = false
	btn_advance.disabled = false  # Always re-enable on dismiss