extends CharacterBody3D

@export var max_speed:float = 5
@export var force:Vector3
@export var acceleration:Vector3
@export var target_node_path:NodePath
@export var path:PathFollow3D
@export var mass:float = 1
@export var slowing_distance:float = 3
@export var target_speed:float = 0.05
var target:Node3D


#for banking, we need to calculate an 'effective down' using restitution of force
@export var grav_direction:Vector3 = Vector3(0,-1,0)
@export var grav_scale:float = 3
@export var effective_down:Vector3

func draw_gizmos():
	#Red, force
	DebugDraw3D.draw_arrow(global_position, global_position + force, Color.RED, 0.1)
	#Yellow, velocity
	DebugDraw3D.draw_arrow(global_position, global_position + velocity, Color.YELLOW, 0.1)
	#Blue Violet (purps), arrive sphere
	DebugDraw3D.draw_sphere(target.global_position, slowing_distance, Color.BLUE_VIOLET)
	#green, effective down
	DebugDraw3D.draw_arrow(global_position, global_position + effective_down, Color.GREEN, 0.1)

func _ready():
	target = get_node(target_node_path)	
	motion_mode = CharacterBody3D.MOTION_MODE_FLOATING #floating
	
	
func arrive(target_pos:Vector3, slowing:float): 
	var distance = target_pos - global_position
	var ramped_speed = max_speed*(distance.length()/slowing)
	var clipped_speed = min(ramped_speed, max_speed)
	var desired = clipped_speed * distance.normalized()
	return desired - velocity
	
	
func seek(target_pos:Vector3):
	var to_target = target_pos - global_position
	var desired = to_target.normalized() * max_speed
	return desired - velocity
	
func bank(vel:Vector3, turn_force:Vector3):
	var restitution = -grav_direction * grav_scale # typical "up"
	var derived_up = restitution + force
	effective_down = -derived_up
	return derived_up

func _physics_process(delta):
	path.progress+=target_speed
	force = arrive(target.global_position, slowing_distance)
	acceleration = force / mass
	
	velocity = velocity + acceleration * delta
	if velocity.length() > 0:
		look_at(position - velocity, bank(velocity, force))
		# global_transform.basis.z  = velocity.normalized()
		# global_transform = global_transform.orthonormalized()
	
	move_and_slide()
	draw_gizmos()
	
