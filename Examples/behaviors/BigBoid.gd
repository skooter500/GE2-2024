extends CharacterBody3D

@export var max_speed:float = 10
@export var force:Vector3
@export var acceleration:Vector3
@export var target_node_path:NodePath

@export var mass:float = 1

var target:Node3D

#Similar to Awake
func _ready():
	target = get_node(target_node_path)	
	
#seek is the go-to behaviour, travel at max speed towards target_pos
func seek(target_pos:Vector3):
	var to_target = target_pos - global_position
	var desired = to_target.normalized() * max_speed
	return desired - velocity
	
#Similar to FixedUpdate
func _physics_process(delta):
	force = seek(target.global_position)
	acceleration = force / mass
	
	velocity = velocity + acceleration * delta
	if velocity.length() > 0:
		look_at(position - velocity)
		# global_transform.basis.z = velocity.normalized()
	
	
	move_and_slide()
	

func _on_timer_timeout():
	pass # Replace with function body.
