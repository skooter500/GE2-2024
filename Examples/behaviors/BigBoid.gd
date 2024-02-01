extends CharacterBody3D

@export var max_speed:float = 20
@export var force:Vector3
@export var acceleration:Vector3
@export var target_node_path:NodePath
@export var path:Path3D
@export var mass:float = 1
@export var slowing_distance = 5


func draw_gizmos():
	DebugDraw3D.draw_arrow(global_position, global_position + force * 20, Color.RED, 0.1)
	DebugDraw3D.draw_arrow(global_position, global_position + velocity, Color.YELLOW, 0.1)

	DebugDraw3D.draw_sphere(target.global_position, slowing_distance, Color.BLUE_VIOLET)

var target:Node3D
func _ready():
	target = get_node(target_node_path)	
	
func arrive(target_pos:Vector3, slowing:float): #dist = 10, #slowing = 5
	var to_target = target_pos - global_position #dist is 10
	var dist = to_target.length() #dist is 10
	var ramped = dist / slowing #ramped = 2
	var clamped = min(ramped, dist) #clamped = 0
	var desired = ((to_target * clamped) / dist) * max_speed #desired = 0
	return desired - velocity
	
	
func seek(target_pos:Vector3):
	var to_target = target_pos - global_position
	var desired = to_target.normalized() * max_speed
	return desired - velocity
	
func _physics_process(delta):
	if((target.global_position - global_position).length < 0.01):
		target = path.curve.get_baked_points()[0]
	# force = arrive(target.global_position, slowing_distance)
	force = seek(target.global_position)
	acceleration = force / mass
	
	velocity = velocity + acceleration * delta
	if velocity.length() > 0:
		look_at(position - velocity)
		# global_transform.basis.z  = velocity.normalized()
		# global_transform = global_transform.orthonormalized()
	
	move_and_slide()
	draw_gizmos()
	
