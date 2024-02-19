extends Marker3D


@export var random_offest_range:float=20
var p:Vector3 = Vector3(0,0,0)


func _on_timer_timeout():
	
	
	p.x = randf_range(-random_offest_range, random_offest_range)
	# p.y = randf_range(-random_offest_range, random_offest_range)
	p.z = randf_range(-random_offest_range, random_offest_range)
	
	global_position = p 
	pass # Replace with function body.
