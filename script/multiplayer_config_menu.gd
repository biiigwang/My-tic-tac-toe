extends CanvasLayer

signal sig_create_server
signal sig_join_game
signal sig_player_ready
signal sig_user_name_change
signal sig_network_aready
signal sig_chat_receive(new_msg: String, is_bbcode: bool)

@onready var create_button = $Background/MessageContent/VBoxContainer/ButtonContainer/CreateServerButton
@onready var join_button = $Background/MessageContent/VBoxContainer/ButtonContainer/JoinGameButton
@onready var ip_label = $Background/MessageContent/VBoxContainer/IpContainer/LineEdit
@onready var username_label = $Background/MessageContent/VBoxContainer/UsernameContainer/LineEdit
@onready var loading_arrow = $Background/MessageContent/VBoxContainer/ButtonContainer/LoadingArrow
@onready var chat_box = $Background/ChatBoxHContainer
@onready var start_buttion = $Background/MessageContent/VBoxContainer/ButtonContainer/StartButton
@onready var ready_button = $Background/MessageContent/VBoxContainer/ButtonContainer/ReadyButton

func _ui_ready():
	ready_button.hide()
	start_buttion.hide()
	loading_arrow.hide()
	loading_arrow.self_modulate.a = 0.8

func _loading_scene(isShow: bool):
	if isShow:
		loading_arrow.show()
	else:
		loading_arrow.hide()

func _ready():
	multiplayer.peer_connected.connect(_on_player_connected)
	multiplayer.peer_disconnected.connect(_on_player_disconnected)
	multiplayer.connected_to_server.connect(_on_connected_ok)
	multiplayer.connection_failed.connect(_on_connected_fail)
	multiplayer.server_disconnected.connect(_on_server_disconnected)
	chat_box.sig_chat_send.connect(_on_chatbox_chatsend)
	_ui_ready()

func _process(delta):

	if len(players) >= 2:
		if multiplayer.is_server():
			# ready status check
			var ready_count = 0
			for id in players:
				if players[id]["is_ready"]:
					ready_count += 1
			if ready_count >= 1:
				start_buttion.set_disabled(false)
			if ready_count >= 2:
				goto_main_game.rpc()
# >>>>>> Control callback function >>>>>>

# 发射创建服务器信号
func _on_create_server_button_pressed():
	sig_create_server.emit()

# 发射加入游戏服务器信号
func _on_join_game_button_pressed():
	sig_join_game.emit()

func _on_text_edit_text_changed():
	sig_user_name_change.emit()

func _on_chatbox_chatsend(new_msg: String):
	var unique_id = multiplayer.get_unique_id()
	var player_id = players[unique_id]
	print_chat_display.rpc(player_id["net_id"],new_msg)

@rpc("authority", "call_local", "reliable")
func print_info_display(new_msg: String):
	sig_chat_receive.emit("[color=green]%s [System]:%s[/color]" % [Time.get_datetime_string_from_system(), new_msg], true)

@rpc("any_peer", "call_local", "reliable", 7)
func print_chat_display(play_id, new_msg):
	sig_chat_receive.emit("%s [%s]:%s" % [Time.get_datetime_string_from_system(), players[play_id]["name"], new_msg], false)
# <<<<<<< Control callback function <<<<<<<

# >>>>>> Multiplayer config >>>>>>

# These signals can be connected to by a UI lobby scene or the game scene.
signal player_disconnected(peer_id)
signal server_disconnected

const PORT = 7000
const DEFAULT_SERVER_IP = "127.0.0.1" # IPv4 localhost
const MAX_CONNECTIONS = 2

# This will contain player info for every player,
# with the keys being each player's unique IDs.
var players = {}

# This is the local player info. This should be modified locally
# before the connection is made. It will be passed to every other peer.
# For example, the value of "name" can be set to something the player
# entered in a UI scene.
var self_player_info = {"name": "Name", "net_id": - 1, "is_ready": false, "online": false}

# <<<<<<< Multiplayer config <<<<<<<

# >>>>>> Opeartion function >>>>>>>

func update_self_player_info():
	var text_str = username_label.text
	if text_str == "":
		print_debug("[warning] Get usrname was nil! Using default usrname.")
		text_str = "DefaultName"
	self_player_info["name"] = text_str

# Creating game
func creating_game():
	var peer = ENetMultiplayerPeer.new()
	var err = peer.create_server(PORT, MAX_CONNECTIONS)
	if err:
		print_debug("Server creation failed! Error code: %s" % err)
		return
	print_debug("The server was created successfully.")
	multiplayer.multiplayer_peer = peer

	self_player_info["net_id"] = 1
	players[1] = self_player_info

func joining_game(address=""):
	if address.is_empty() or not address.is_valid_ip_address():
		address = DEFAULT_SERVER_IP
	var peer = ENetMultiplayerPeer.new()
	var error = peer.create_client(address, PORT)
	if error:
		print_debug("Failed to connect to the server! Error code: %s" % error)
		return error
	multiplayer.multiplayer_peer = peer
	_loading_scene(true)

@rpc("any_peer", "reliable")
func rpc_print(message: String):
	var player_id = multiplayer.get_remote_sender_id()
	print("RPC message {%s} -> {%s}: \r\n\tMessage: [\"%s\"]" % [player_id, multiplayer.get_unique_id(), message])

@rpc("any_peer", "reliable")
func _register_player(new_player_info):
	var new_player_id = multiplayer.get_remote_sender_id()
	players[new_player_id] = new_player_info
	print_info_display("%s join game" % new_player_info["name"])
	print_debug("Player connected! id: {%s}, player_info:{%s}" % [new_player_id, new_player_info])
	if len(players) >= 2:
		create_button.hide()
		join_button.hide()
		if multiplayer.is_server():
			# Host show "Start" button
			start_buttion.show()
			start_buttion.set_disabled(true)
		else:
			ready_button.show()

@rpc("any_peer", "call_local", "reliable")
func _update_player(new_player_info):
	var new_player_id = multiplayer.get_remote_sender_id()
	players[new_player_id] = new_player_info
	if new_player_info["is_ready"]:
		print_info_display("%s is [color=yellow]ready[/color]!" % new_player_info["name"])
	print_debug("Player information updated! id: {%s}, player_info:{%s}" % [new_player_id, new_player_info])

func _delect_player(player_id):
	var ret = players.erase(player_id)
	print_debug("[Info] Delect player[%s] information. Deletc status: %s" % [player_id, ret])
# <<<<<<< Opeartion function <<<<<<<

# >>>>>> Signal callback function >>>>>>
func _on_sig_create_server():
	print("\"Create Game\" button was pressed")
	create_button.set_disabled(true)
	join_button.set_disabled(true)
	join_button.hide()
	update_self_player_info()
	creating_game()

func _on_sig_join_game():
	print("\"Join Game\" button was pressed")
	create_button.set_disabled(true)
	join_button.set_disabled(true)
	update_self_player_info()
	joining_game(ip_label.text)

func _on_player_connected(peer_id):
	print_debug("[Info] Player connected! id: {%s}" % peer_id)
	_register_player.rpc_id(peer_id, self_player_info)

func _on_player_disconnected(peer_id):
	# self_player_info["online"] = false
	_delect_player(peer_id)
	print_debug("[warning] Player[%s] disconnected!" % peer_id)

func _on_server_disconnected():
	# self_player_info["online"] = false
	print_debug("[warning] Host servers disconnected!")

func _on_connected_ok():
	var peer_id = multiplayer.get_unique_id()
	self_player_info["net_id"] = peer_id
	players[peer_id] = self_player_info
	_loading_scene(false)
	print_debug("[Info] Success to connect server! My id:{%s}, self_player_info:{%s}" % [peer_id, self_player_info])

func _on_connected_fail():
	print_debug("[warning] Connect fail!")
	print_debug("[Info] Enable button agin!")
	create_button.set_disabled(false)
	join_button.set_disabled(false)
	_loading_scene(false)

func _on_start_button_pressed():
	self_player_info["is_ready"] = true
	_update_player.rpc(self_player_info)

func _on_test_button_pressed():
	var ip_string = ip_label.get_text()
	var username_string = username_label.get_text()
	if username_string == "":
		username_string = "Defualt name"
	print_debug("Ip: %s, Username: %s" % [ip_string, username_string])
	sig_chat_receive.emit("New chat massage")

func _on_ready_button_pressed():
	sig_player_ready.emit()
	self_player_info["is_ready"] = true
	_update_player.rpc(self_player_info)
# <<<<<<< Signal callback function <<<<<<<

@rpc("authority", "call_local", "reliable")
func goto_main_game():
	Global.goto_scene("res://scene/main_game.tscn")
