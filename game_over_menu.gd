extends CanvasLayer

signal restart

func _on_restart_button_pressed():
	# Emit signal of restart game
	restart.emit()
