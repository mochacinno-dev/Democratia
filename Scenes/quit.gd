extends Button

func _pressed() -> void:
	print("Closing.") # debug!!
	get_tree().quit()
