extends CodeEdit

var hello: int = 321

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	var highlighter: CodeHighlighter = CodeHighlighter.new()
	
	var symbol_color: Color = Color.hex(0xabc9ffff)
	var keyword_color: Color = Color.hex(0xff7085ff)
	var control_flow_keyword_color: Color = Color.hex(0xff8cccff)
	#var base_type_color: Color = Color.hex(0x42ffc2ff)
	var comment_color: Color = Color.hex(0xffffff80)
	var string_color: Color = Color.hex(0xffeda1ff)
	var number_color: Color = Color.hex(0xa1ffe0ff)
	var function_color: Color = Color.hex(0x57b3ffff)
	var member_variable_color: Color = Color.hex(0xbce0ffff)
	
	highlighter.add_keyword_color("var", keyword_color)
	highlighter.add_keyword_color("func", keyword_color)
	highlighter.add_keyword_color("extends", keyword_color)
	highlighter.add_keyword_color("class_name", keyword_color)
	
	highlighter.add_keyword_color("if", control_flow_keyword_color)
	highlighter.add_keyword_color("for", control_flow_keyword_color)
	highlighter.add_keyword_color("pass", control_flow_keyword_color)
	highlighter.add_keyword_color("continue", control_flow_keyword_color)
	highlighter.add_keyword_color("break", control_flow_keyword_color)
	highlighter.add_keyword_color("return", control_flow_keyword_color)
	
	highlighter.add_color_region('"', '"', string_color)
	highlighter.add_color_region("'", "'", string_color)
	highlighter.add_color_region("#", "", comment_color)
	
	highlighter.number_color = number_color
	highlighter.symbol_color = symbol_color
	highlighter.function_color = function_color
	highlighter.member_variable_color = member_variable_color
	
	syntax_highlighter = highlighter


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func _request_code_completion(force: bool) -> void:
	var txt: String = get_text_for_code_completion()
	var lines: PackedStringArray = txt.split("\n")
	var line: String
	var carot_position: int
	
	for l: String in lines:
		var index: int = l.find(char(0xFFFF))
		if index != -1:
			line = l
			carot_position = index
	print_debug("%s (%d:%d)" % [line, lines.find(line) + 1, carot_position + 1])
	
	add_code_completion_option(CodeEdit.KIND_KEYWORD, "var", "var")
	add_code_completion_option(CodeEdit.KIND_KEYWORD, "func", "func")
	add_code_completion_option(CodeEdit.KIND_KEYWORD, "extends", "extends")
	add_code_completion_option(CodeEdit.KIND_KEYWORD, "class_name", "class_name ")
	add_code_completion_option(CodeEdit.KIND_KEYWORD, "pass", "pass")
	
	add_code_completion_option(CodeEdit.KIND_FUNCTION, "print", "print(\"\")")
	
	# TODO: Only when the cursor is not in a method.
	# TODO: Only in tile logic code edit.
	add_code_completion_option(CodeEdit.KIND_FUNCTION, "_interact", "func _interact():\n\t")
	
	update_code_completion_options(true)


func _on_focus_entered() -> void:
	Creator.dark_world_ui.can_pan_camera = false


func _on_focus_exited() -> void:
	Creator.dark_world_ui.can_pan_camera = true


func _on_tree_exiting() -> void:
	Creator.dark_world_ui.can_pan_camera = true


func _on_hidden() -> void:
	Creator.dark_world_ui.can_pan_camera = true
