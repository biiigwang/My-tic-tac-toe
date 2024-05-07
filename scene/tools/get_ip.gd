extends Control

@onready var option_button: OptionButton = $HBoxContainer/OptionButton
@onready var line_edit: LineEdit = $HBoxContainer/OptionButton/LineEdit
signal ip_copied

func _ready():
	option_button.clear()
	option_button.add_item("127.0.0.1")
	var ips = get_vaild_ip_address()
	for ip in ips:
		option_button.add_item(ip)

func is_ipv4_address(ip: String) -> bool:
	if not ip.is_valid_ip_address():
		return false
	if len(ip.split(".")) <= 1:
		return false
	return true

func is_ipv6_address(ip: String) -> bool:
	if not ip.is_valid_ip_address():
		return false
	if len(ip.split(":")) <= 1:
		return false
	return true

func is_loopback_ipv4(ip: String) -> bool:
	var loopback_perfix_array: Array = ["127"]
	var ret: bool = false
	if not is_ipv4_address(ip):
		return false
	var ip_array = ip.split(".")
	if (loopback_perfix_array.find(ip_array[0]) != - 1):
		ret = true
	return ret

func is_loopback_ipv6(ip: String) -> bool:
	var loopback_perfix_array: Array = ["fe80", "0"]
	var ret: bool = false
	if not is_ipv6_address(ip):
		return false
	var ip_array = ip.split(":")
	if (loopback_perfix_array.find(ip_array[0]) != - 1):
		ret = true
	return ret

func get_vaild_ip_address() -> Array:
	var vaild_ip_address: Array = []
	var ipv4_array: Array = []
	var ipv6_array: Array = []
	var ip_address = IP.get_local_addresses()
	for ip in ip_address:
		if not is_loopback_ipv4(ip) and is_ipv4_address(ip):
			ipv4_array.append(ip)
			continue
		if not is_loopback_ipv6(ip) and is_ipv6_address(ip):
			ipv6_array.append(ip)
			continue
	vaild_ip_address.append_array(ipv4_array)
	vaild_ip_address.append_array(ipv6_array)
	return vaild_ip_address

func _on_option_button_pressed():
	pass
	# option_button.clear()
	# var ips = get_vaild_ip_address()
	# for ip in ips:
	# 	option_button.add_item(ip)

func _on_option_button_item_selected(index: int):
	var ip: String = option_button.get_item_text(index)
	line_edit.text = ip
	line_edit.menu_option(line_edit.MenuItems.MENU_SELECT_ALL)
	line_edit.menu_option(line_edit.MenuItems.MENU_COPY)
	ip_copied.emit()
	if is_ipv6_address(ip):
		option_button.add_theme_font_size_override("font_size", 12)
	else:
		option_button.add_theme_font_size_override("font_size", 25)