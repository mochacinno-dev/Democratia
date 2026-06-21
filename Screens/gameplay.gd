extends Control
# ═══════════════════════════════════════════════════════════════════════════════
# GAMEPLAY — top-level controller: sidebar nav + main panel swap
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

@onready var sidebar      : VBoxContainer = $HBox/Sidebar/VBox
@onready var main_panel   : Control       = $HBox/MainPanel

# Top status bar
@onready var bar_date     : Label = $TopBar/HBox/Date
@onready var bar_approval : Label = $TopBar/HBox/Approval
@onready var bar_capital  : Label = $TopBar/HBox/Capital
@onready var bar_seats    : Label = $TopBar/HBox/Seats
@onready var bar_legit    : Label = $TopBar/HBox/Legitimacy
@onready var bar_crisis   : Label = $TopBar/HBox/CrisisAlert
@onready var btn_advance  : Button = $TopBar/HBox/AdvanceBtn

@onready var events_panel : PanelContainer = $EventsOverlay
@onready var events_list  : VBoxContainer  = $EventsOverlay/Margin/VBox/Scroll/EventsList
@onready var btn_dismiss  : Button         = $EventsOverlay/Margin/VBox/DismissBtn

var current_screen : String = ""
var screen_cache   : Dictionary = {}
var sidebar_buttons: Dictionary = {}

func _ready() -> void:
	_build_sidebar()
	btn_advance.pressed.connect(_on_advance_month)
	btn_dismiss.pressed.connect(func(): events_panel.visible = false)
	events_panel.visible = false
	_switch_screen("Overview")

func _build_sidebar() -> void:
	for child in sidebar.get_children():
		child.queue_free()

	for screen_name in SCREENS:
		var btn = Button.new()
		btn.text                 = "%s  %s" % [ICONS.get(screen_name, ""), screen_name]
		btn.alignment            = HORIZONTAL_ALIGNMENT_LEFT
		btn.custom_minimum_size  = Vector2(170, 44)
		btn.add_theme_font_size_override("font_size", 15)
		btn.flat                 = true
		var sn = screen_name
		btn.pressed.connect(func(): _switch_screen(sn))
		sidebar.add_child(btn)
		sidebar_buttons[screen_name] = btn

func _switch_screen(name: String) -> void:
	if current_screen == name: return
	current_screen = name

	# Highlight active button
	for sn in sidebar_buttons:
		sidebar_buttons[sn].flat = (sn != name)

	# Clear main panel
	for child in main_panel.get_children():
		child.queue_free()

	# Load (or reuse) screen scene
	var path = SCREENS.get(name, "")
	if path == "": return

	var scene : PackedScene = load(path)
	var node  = scene.instantiate()
	node.name = "Screen"
	node.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	main_panel.add_child(node)
	if node.has_method("refresh"):
		node.refresh()

func _refresh_topbar() -> void:
	bar_date.text     = "%s %d" % [GameData.month_name(), GameData.current_year]
	bar_approval.text = "Approval: %.0f%%" % GameData.approval_rating
	bar_capital.text  = "Capital: %d" % GameData.political_capital
	bar_seats.text    = "Seats: %d/%d" % [GameData.coalition_seats(), GameData.TOTAL_SEATS]
	bar_legit.text    = "Legitimacy: %.0f" % GameData.legitimacy

	var has_crisis = not GameData.active_crisis.is_empty() and not GameData.active_crisis.get("resolved", true)
	bar_crisis.text    = "⚠ CRISIS" if has_crisis else ""
	bar_crisis.visible = has_crisis

	# Election warning
	if GameData.election_active:
		bar_date.text += "  🗳 ELECTION!"

func _on_advance_month() -> void:
	GameData.advance_month()
	var events = Systems.process_month()
	_refresh_topbar()

	# Refresh current screen
	var screen = main_panel.get_node_or_null("Screen")
	if screen and screen.has_method("refresh"):
		screen.refresh()

	# Show events overlay
	for child in events_list.get_children():
		child.queue_free()
	for ev_text in events:
		var lbl = Label.new()
		lbl.text           = ev_text
		lbl.autowrap_mode  = TextServer.AUTOWRAP_WORD_SMART
		lbl.add_theme_font_size_override("font_size", 16)
		events_list.add_child(lbl)
	if events.size() > 0:
		events_panel.visible = true

	# Auto-navigate to election if triggered
	if GameData.election_active:
		_switch_screen("Election")
