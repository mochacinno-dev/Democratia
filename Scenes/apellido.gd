extends LineEdit

var plname : String = ""

func _on_line_edit_text_submitted(new_text: String):
	plname = new_text
	print("Variable updated to: ", plname)
