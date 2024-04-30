extends Node

# Import the circle from the outside and enter the node.
@export var circle_sence: PackedScene

@export var cross_sence: PackedScene

# How much step of player moves
var moves: int
# Current player
var now_player: int
# Position of right panel of window
var player_panel_pos: Vector2i
# The next marker
var temp_marker
# Data struct of grid
var grid_data: Array
# Grid position of the currently clicked cell
var grid_pos: Vector2i
# The width of board
var board_size: int
# The size of cell that shape of square
var cell_size: int
# Game score
var row_sum: int
var col_sum: int
var diagonal_sum1: int
var diagonal_sum2: int

# Called when the node enters the scene tree for the first time.
# 在节点首次进入场景树时被调用，只会调用一次
func _ready():

	board_size = $Board.texture.get_width()
	# divied board by 3 to get the size of individual cell
	cell_size = board_size / 3

	# Get coordinates of small panel on right side of window
	player_panel_pos = $PlayerPanel.get_position()

	new_game()

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass

func _input(event):
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			# check if mouse on game board
			if event.position.x < board_size:
				# Convert mouse position into grid location
				grid_pos = event.position / cell_size
				if grid_data[grid_pos.y][grid_pos.x] == 0:
					grid_data[grid_pos.y][grid_pos.x] = now_player
					# Place that play's marker
					create_marker.rpc(now_player, grid_pos * cell_size + Vector2i(cell_size / 2, cell_size / 2))
					
					moves += 1

					# Print grid data
					print("moves:%s, grid_data:%s" % [moves, grid_data])

					if multiplayer.is_server():
						var win_player = check_win()
						if win_player != 0 or moves >= 9:
							game_over_handle.rpc(win_player)
					
					now_player *= - 1

					# Update the panel marker
					create_marker.rpc(now_player, player_panel_pos + Vector2i(cell_size / 2, cell_size / 2), true)

@rpc("any_peer", "call_local", "reliable")
func new_game():
	print("Start new game")
	# Set up first player
	now_player = 1

	moves = 0

	row_sum = 0
	col_sum = 0
	diagonal_sum1 = 0
	diagonal_sum2 = 0

	# Clear up existing markers
	get_tree().call_group("circles", "queue_free")
	get_tree().call_group("crosses", "queue_free")

	# Create a marker to show the starting player's turn
	create_marker(now_player, player_panel_pos + Vector2i(cell_size / 2, cell_size / 2), true)

	# Initial grid data
	grid_data = [
		[0, 0, 0],
		[0, 0, 0],
		[0, 0, 0]]

	# Hide game over layout
	$GameOverMenu.hide()

	# Continue this scene tree
	get_tree().paused = false

@rpc("any_peer", "call_local","reliable")
func create_marker(player, position, temp=false):
	# Create a marker node and add it as a child
	if player == 1:
		var circle = circle_sence.instantiate()
		circle.position = position
		add_child(circle)
		if temp:
			if temp_marker != null:
				temp_marker.queue_free()
			temp_marker = circle
	else:
		var cross = cross_sence.instantiate()
		cross.position = position
		add_child(cross)
		if temp:
			if temp_marker != null:
				temp_marker.queue_free()
			temp_marker = cross

func check_win() -> int:
	var win_player: int = 0
	for i in len(grid_data):
		row_sum = grid_data[i][0] + grid_data[i][1] + grid_data[i][2]
		col_sum = grid_data[0][i] + grid_data[1][i] + grid_data[2][i]
		diagonal_sum1 = grid_data[0][0] + grid_data[1][1] + grid_data[2][2]
		diagonal_sum2 = grid_data[2][0] + grid_data[1][1] + grid_data[0][2]

		if row_sum == 3 or col_sum == 3 or diagonal_sum1 == 3 or diagonal_sum2 == 3:
			win_player = 1
			break

		if row_sum == - 3 or col_sum == - 3 or diagonal_sum1 == - 3 or diagonal_sum2 == - 3:
			win_player = -1
			break

	return win_player

@rpc("authority", "call_local", "reliable")
func game_over_handle(winner: int):
	get_tree().paused = true
	$GameOverMenu.show()
	var player_name_dict: Dictionary = {1: "1", - 1: "2"}
	var panel_str: String = "Player %s Wins!"
	var game_over_str: String = "Game Over! %s"
	var winner_str: String
	if winner == 0:
		winner_str = "There is a tie"
		panel_str = "It's a Tie!"
	else:
		winner_str = "Winner is player%s" % winner
		panel_str = panel_str % player_name_dict[winner]
	
	$GameOverMenu.get_node("ResultLabel").text = panel_str
	print(game_over_str % winner_str)

func _on_game_over_menu_restart():
	# Create new game When restart game button has been pressed
	print("Restart button is pressed")
	new_game()

# func _on_ui_menu_user_name_change():
# 	player_info['name'] = $UIMenu.get_node("UsernameTextEdit").text
# 	print("New username: ", player_info['name'])
