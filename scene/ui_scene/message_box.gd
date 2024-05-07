extends Control

@export var message: String = ""
@export_enum("one:1", "two:2") var button_num: int = 2
@export_enum("Info", "Warn", "Error") var msg_type: String = "Info"
@onready var title: Panel = $BoxBody/TitlePanel
@onready var massage_box: RichTextLabel = $BoxBody/RichTextLabel
@onready var body_background = $Panel
@onready var button1 = $BoxBody/HBoxContainer/Button1
@onready var button2 = $BoxBody/HBoxContainer/Button2
@onready var place_holder1 = $BoxBody/HBoxContainer/PlaceHolder1
@onready var place_holder2 = $BoxBody/HBoxContainer/PlaceHolder2
@onready var place_holder3 = $BoxBody/HBoxContainer/PlaceHolder3

func _ui_button_init(b_num: int) -> void:
	if (b_num) == 1:
		button2.hide()
		place_holder3.hide()
		button1.text = "Ok"

func _get_title_color(type: String) -> Color:
	var ret_color: Color
	if type == "Info":
		ret_color = Color.SEA_GREEN
	elif type == "Warn":
		ret_color = Color.LIGHT_YELLOW
	elif type == "Error":
		ret_color = Color.ORANGE_RED
	else:
		ret_color = Color.LIGHT_SLATE_GRAY
	return ret_color

func show_message(type: String, msg: String, b_num=1):

	var new_stylebox_panel = title.get_theme_stylebox("panel").duplicate()
	new_stylebox_panel.bg_color = _get_title_color(type)
	title.add_theme_stylebox_override("panel", new_stylebox_panel)

	_ui_button_init(b_num)

	massage_box.clear()
	massage_box.append_text("[center]"+msg+"[/center]")

	if not visible:
		show()

func _draw():
	# show_message(msg_type, message, button_num)
	pass

func _on_button_2_pressed():
	hide()

func _on_button_1_pressed():
	hide()
