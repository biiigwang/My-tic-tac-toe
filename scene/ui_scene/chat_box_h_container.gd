extends VBoxContainer

class_name ChatbooxHContainer

signal sig_chat_send(send_str: String)

@export var consumer_node: Node
@export var enable_bbcode: bool = false
@export var displayboard_placeholder = ""
@export var typeline_placeholder = ""

@onready var display_board: RichTextLabel = $DisplayBoard
@onready var type_line: LineEdit = $HBoxContainer/TypeLine
@onready var send_button = $HBoxContainer/SendButton

# Called when the node enters the scene tree for the first time.
func _ready():
	display_board.text = displayboard_placeholder
	type_line.text = typeline_placeholder
	if consumer_node:
		var has_receive_signal = consumer_node.has_signal("sig_chat_receive")
		if has_receive_signal:
			consumer_node.sig_chat_receive.connect(_on_consumer_receive)
		else:
			print_debug("[Warning] consumer_node don't have the signal: [sig_chat_receive] !")
	else:
		print_debug("[Warning] consumer_node was not correct setup!")
	
func _on_consumer_receive(new_msg: String, is_bbcode: bool):
	if enable_bbcode or is_bbcode:
		display_board.append_text("%s\r\n" % new_msg)
	else:
		display_board.append_text("%s\r\n" % new_msg.replace("[", "[lb]"))

func _on_send_button_pressed():
	var new_msg = type_line.text
	if new_msg != "":
		sig_chat_send.emit(new_msg)
		type_line.clear()
