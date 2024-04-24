extends CanvasLayer

signal sig_create_server
signal sig_join_game
signal sig_user_name_change

@onready var create_button = $Background/MessageContent/VBoxContainer/ButtonContainer/CreateServerButton
@onready var join_button = $Background/MessageContent/VBoxContainer/ButtonContainer/JoinGameButton
@onready var ip_label = $Background/MessageContent/VBoxContainer/IpContainer/LineEdit
@onready var username_label = $Background/MessageContent/VBoxContainer/UsernameContainer/LineEdit

func _ready():
	multiplayer.peer_connected.connect(_on_player_connected)
	multiplayer.peer_disconnected.connect(_on_player_disconnected)
	multiplayer.connected_to_server.connect(_on_connected_ok)
	multiplayer.connection_failed.connect(_on_connected_fail)
	multiplayer.server_disconnected.connect(_on_server_disconnected)

# >>>>>> Control callback function >>>>>>

# 发射创建服务器信号
func _on_create_server_button_pressed():
	sig_create_server.emit()

# 发射加入游戏服务器信号
func _on_join_game_button_pressed():
	sig_join_game.emit()

func _on_text_edit_text_changed():
	sig_user_name_change.emit()
# <<<<<<< Control callback function <<<<<<<

# >>>>>> Multiplayer config >>>>>>

# These signals can be connected to by a UI lobby scene or the game scene.
signal player_connected(peer_id, player_info)
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
var player_info = {"name": "Name"}

var players_loaded = 0

# <<<<<<< Multiplayer config <<<<<<<

# >>>>>> Opeartion function >>>>>>>

# Creating game
func creating_game():
	var peer = ENetMultiplayerPeer.new()
	var err = peer.create_server(PORT, MAX_CONNECTIONS)
	if err:
		print_debug("Server creation failed! Error code: %s" % err)
		return
	print_debug("The server was created successfully.")
	multiplayer.multiplayer_peer = peer

	players[1] = player_info
	player_connected.emit(1, player_info)

func joining_game(address=""):
	if address.is_empty():
		address = DEFAULT_SERVER_IP
	var peer = ENetMultiplayerPeer.new()
	var error = peer.create_client(address, PORT)
	if error:
		print_debug("Failed to connect to the server! Error code: %s" % error)
		return error
	multiplayer.multiplayer_peer = peer

@rpc("any_peer", "reliable")
func rpc_print(message: String):
	var player_id = multiplayer.get_remote_sender_id()
	print("RPC message {%s} -> {%s}: \r\n\tMessage: [\"%s\"]" % [player_id, multiplayer.get_unique_id(), message])

@rpc("any_peer", "reliable")
func _register_player(new_player_info):
	var new_player_id = multiplayer.get_remote_sender_id()
	players[new_player_id] = new_player_info
	player_connected.emit(new_player_id, new_player_info)
	print_debug("Player connected! id: {%s}, player_info:{%s}" % [new_player_id, new_player_info])

# <<<<<<< Opeartion function <<<<<<<

# >>>>>> Signal callback function >>>>>>
func _on_sig_create_server():
	print("\"Create Game\" button was pressed")
	create_button.set_disabled(true)
	join_button.set_disabled(true)
	creating_game()

func _on_sig_join_game():
	print("\"Join Game\" button was pressed")
	create_button.set_disabled(true)
	join_button.set_disabled(true)
	joining_game()

func _on_player_connected(peer_id):
	print_debug("[Info] Player connected! id: {%s}" % peer_id)
	_register_player.rpc_id(peer_id, player_info)

func _on_player_disconnected(peer_id):
	print_debug("[Warnning] Player[%s] disconnected!" % peer_id)

func _on_server_disconnected():
	print_debug("[Warnning] Host servers disconnected!")

func _on_connected_ok():
	var peer_id = multiplayer.get_unique_id()
	players[peer_id] = player_info
	player_connected.emit(peer_id, player_info)
	print_debug("[Info] Success to connect server! My id:{%s}, player_info:{%s}" % [peer_id, player_info])

func _on_connected_fail():
	print_debug("[Error] Connect fail!")
# <<<<<<< Signal callback function <<<<<<<

func _on_test_button_pressed():
	var ip_string = ip_label.get_text()
	var username_string = username_label.get_text()
	if username_string == "":
		username_string = "Defualt name"
	print_debug("Ip: %s, Username: %s" % [ip_string, username_string])
