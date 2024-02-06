extends Node3D

func _input(event):
	if(event is InputEventKey && event.keycode == KEY_Q):
		get_tree().quit()
