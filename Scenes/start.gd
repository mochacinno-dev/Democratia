extends Button

@onready var item_list = $"../ItemList"

func _pressed() -> void:
	if item_list.validate_and_save():
		get_tree().change_scene_to_file("res://Screens/gameplay.tscn")
