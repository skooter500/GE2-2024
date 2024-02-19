class_name BigBoid
extends CharacterBody3D

@export var max_speed:float = 5
@export var force:Vector3
@export var acceleration:Vector3
@export var target_node_path:NodePath
@export var path:PathFollow3D
@export var mass:float = 1
@export var slowing_distance:float = 1
@export var target_speed:float = 0.05
@export var acceleration_scale:float = 1
var target:Node3D

@export var damping:float = 0.1
@export var banking:float = 1

@export var seek_enabled:bool=true
@export var arrive_enabled:bool=false
@export var player_enabled:bool=false
@export var follow_path:bool=false
@export var looped:bool=true

@export var flee_enabled:bool=false
@onready var flee_target:Node3D=get_node("../enemy")

@export var pursue_enabled:bool=false
@export var pursue_target_path:NodePath
@onready var pursue_target:Node3D=get_node(pursue_target_path)

@export var offset_pursue_enabled:bool=false
@export var leader_target_path:NodePath
@onready var leader_target:Node3D=get_node(leader_target_path)

var offset:Vector3

@onready var path:Path3D=get_node("../Path3D")

var current:int = 0 

func follow():
	var target = path.global_transform * (path.get_curve().get_point_position(current))
	var len = path.get_curve().get_point_count()
	var to_target = target - global_position
	var dist = to_target.length()
	if dist < 2:
		if not looped and current == len - 1:
			return arrive(target, slowing_distance)
		else:
			current = (current + 1) % len
	return seek(target)

#for banking, we need to calculate an 'effective up' using restitution of force
@export var grav_direction:Vector3 = Vector3(0,-1,0)
@export var grav_scale:float = 3
@export var effective_up:Vector3
var display_bank_force:Vector3
var display_look_dir:Vector3
@export var look_dir:Vector3
@export var player_power:float = 5


func draw_gizmos():
	#Red, force
	DebugDraw3D.draw_arrow(global_position, global_position + force, Color.RED, 0.1)
	#Yellow, velocity
	DebugDraw3D.draw_arrow(global_position, global_position + velocity, Color.YELLOW, 0.1)
	#Blue Violet (purps), arrive sphere
	DebugDraw3D.draw_sphere(target.global_position, slowing_distance, Color.CADET_BLUE)
	#green, effective down
	DebugDraw3D.draw_arrow(global_position, global_position + display_bank_force, Color.GREEN, 0.1)
	#orange look dir
	DebugDraw3D.draw_arrow(global_position, global_position + display_look_dir, Color.ORANGE, 0.1)

func _ready():
	target = get_node(target_node_path)	
	motion_mode = CharacterBody3D.MOTION_MODE_FLOATING #floating
	if offset_pursue_enabled:
		offset = global_position - leader_target.global_position
		offset = offset * leader_target.global_transform.basis
	
	
func arrive(target_pos:Vector3, slowing:float): 
	var distance = target_pos - global_position
	
	var length = distance.length() #calcing length once rather than twice
	
	if length == 0:
		return Vector3.ZERO
	
	var ramped_speed = max_speed*(length/slowing)
	var clipped_speed = min(ramped_speed, max_speed)
	var desired = clipped_speed * distance/length
	return desired - velocity
	
func offset_pursue(leader:BigBoid):
	var global_target = leader.transform * offset
	var to_target = global_target - global_position
	var dist = to_target.length()
	var t = dist / max_speed
	DebugDraw3D.draw_sphere(global_target, 0.1, Color.CHARTREUSE)
	var projected = global_target + leader.velocity * t
	DebugDraw3D.draw_sphere(projected, 0.1, Color.RED)

	return arrive(projected, 10)
	
func pursue(target_boid:BigBoid):
	var to_target = target_boid.global_position - global_position
	var dist = to_target.length()
	
	var t = dist / max_speed
	var projected = target_boid.global_position + target_boid.velocity * t
	
	DebugDraw3D.draw_arrow(target_boid.global_position, projected, Color.GREEN, 0.1)
	
	return seek(projected) 
	
func flee(target:Transform3D, flee_distance):
	var to_target = target.origin - global_position
	var dist = to_target.length()
	DebugDraw2D.set_text("dist", dist)
	if dist < flee_distance:
		var desired = to_target.normalized() * max_speed
		DebugDraw3D.draw_arrow(global_position, target.origin, Color.BLUE_VIOLET, 0.1)
		return velocity - desired
	else:
		return Vector3.ZERO
		
	
func seek(target_pos:Vector3):
	var to_target = target_pos - global_position
	var desired = to_target.normalized() * max_speed
	return desired - velocity
	

func bank(turn_force:Vector3):
	var restitution = -grav_direction * grav_scale # typical "up"
	var derived_up = restitution + turn_force
	display_bank_force = derived_up
	return derived_up.normalized()

func derived_look(up:Vector3, vel:Vector3):
	var right = vel.cross(up)
	var forward = up.cross(right)
	display_look_dir = forward
	return forward

func player():
	var userInForward = Input.get_axis("Back", "Forward") # Input.get_vector("Left", "Right", "Back", "Forward")
	var userInRight = Input.get_axis("Right", "Left")
	
	var forwardForce = global_basis.z
	forwardForce.y = 0
	forwardForce = forwardForce.normalized()
	forwardForce *= userInForward
	
	var rightForce = global_basis.x
	rightForce.y = 0
	rightForce = rightForce.normalized()
	rightForce *= userInRight
	return (forwardForce + rightForce) * player_power
	
func calculate():
	var forceAcc = Vector3.ZERO
	
	if seek_enabled:
		forceAcc += seek(target.global_position)
	if arrive_enabled:
		forceAcc += arrive(target.global_position, slowing_distance)
	if player_enabled:
		forceAcc += player()
	if follow_path:
		forceAcc += follow()
	if flee_enabled:
		forceAcc += flee(flee_target.global_transform, 5)
	if pursue_enabled:
		forceAcc += pursue(pursue_target)
	if offset_pursue_enabled:
		forceAcc += offset_pursue(leader_target)
	return forceAcc
	
func _physics_process(delta):
	#path.progress+=target_speed
	# force = arrive(target.global_position, slowing_distance)
	
	force = calculate()
	acceleration = force / mass
	
	velocity = velocity + acceleration * delta * acceleration_scale
	
	velocity -= velocity * delta * damping
	effective_up = bank(force)
	look_dir = derived_look(effective_up, velocity)
	if velocity.length() > 0:
		# look_at(position - velocity)
		# apply damping
					# global_transform.basis.z  = velocity.normalized()
		# global_transform = global_transform.orthonormalized()

		#var temp_up = global_transform.basis.y.lerp(Vector3.UP + (acceleration * banking), 1) #delta * 5.0)
		#look_at(global_transform.origin - velocity.normalized(), temp_up)
		look_at(global_position - look_dir, effective_up)
	
	move_and_slide()
	draw_gizmos()
	
