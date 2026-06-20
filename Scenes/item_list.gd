extends ItemList

@onready var item_list = self
@onready var first_name = $"../Nombre"
@onready var last_name = $"../Apellido"
@onready var start_button = $"../Start"

var selected_party = ""

var parties = [
	"Green Alliance Party",
	"Centre Compass Party",
	"Fair Nationalism Party",
	"Rose Democracy Party",
	"Liberal Society Party",
]

func _ready():
	_populate_item_list()
	item_list.item_selected.connect(_on_party_selected)
	start_button.pressed.connect(_on_start_pressed)

func _populate_item_list():
	item_list.clear()
	for party in parties:
		item_list.add_item(party)

func _on_party_selected(index: int):
	selected_party = item_list.get_item_text(index)
	print("Partido seleccionado: ", selected_party)

func _on_start_pressed():
	if first_name.text.strip_edges() == "":
		print("Escribe tu nombre")
		return
	if last_name.text.strip_edges() == "":
		print("Escribe tu apellido")
		return
	if selected_party == "":
		print("Selecciona un partido")
		return

	print("Iniciando con: ", first_name.text, " ", last_name.text, " - ", selected_party)
	get_tree().change_scene_to_file("res://Scenes/config.tscn")
