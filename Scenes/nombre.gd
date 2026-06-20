extends LineEdit

var pname : String = ""

func _on_line_edit_text_submitted(new_text: String):
	pname = new_text
	print("Variable updated to: ", pname)
