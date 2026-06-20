extends ItemList

@onready var first_name   = $"../Nombre"
@onready var last_name    = $"../Apellido"
@onready var error_label  = $"../ErrorLabel"

var selected_party : String = ""

func _ready() -> void:
	item_selected.connect(_on_party_selected)

func _on_party_selected(index: int) -> void:
	selected_party = get_item_text(index)
	_clear_error()

func validate_and_save() -> bool:
	if first_name.text.strip_edges() == "":
		_show_error("Please enter your first name.")
		return false
	if last_name.text.strip_edges() == "":
		_show_error("Please enter your last name.")
		return false
	if selected_party == "":
		_show_error("Please select a party.")
		return false

	GameData.player_first_name = first_name.text.strip_edges()
	GameData.player_last_name  = last_name.text.strip_edges()
	GameData.player_party      = selected_party
	return true

func _show_error(msg: String) -> void:
	if error_label:
		error_label.text    = msg
		error_label.visible = true

func _clear_error() -> void:
	if error_label:
		error_label.visible = false
