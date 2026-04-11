extends PhysicsBody3D
class_name Entity

@export_category("Components")
@export var state_machine: StateMachine
@export var rot_node: Node3D
@export_category("Stats")
@export var jump_state: JumpState
@export var delta_iterations := 5
@export var max_ground_angle := PI/4
@export var snap_height := 0.085
@export var max_down_vel := 200.0

var up := Vector3.UP
var old_up := Vector3.UP
var velocity := Vector3.ZERO
var grounded := false
var direction := Vector3.ZERO
var jumped := false
var is_in_air := false
var current_terrain: Terrain
var current_up := Vector3.ZERO
var former_velocity := Vector3.ZERO
var was_grounded := false
@warning_ignore_start("unused_signal")
signal landed()
signal left_ground()
signal started_moving()
signal stopped_moving()
signal just_jumped()

func _process(delta: float) -> void:
	state_machine.tick(delta)
func jump() -> void:
	if jumped or not Input.is_action_just_pressed("jump"): return
	velocity = velocity.slide(up) + up * jump_state.jump_velocity
	jumped = true
	just_jumped.emit()
func check_grounded(delta: float) -> void:
	old_up = up
	var col = KinematicCollision3D.new()
	var cold = KinematicCollision3D.new()
	var is_colliding := test_move(global_transform, (velocity + up * g_gravity() * delta) * delta, col, 0.005, true)
	var is_colliding_down := test_move(global_transform, (up * g_gravity() * delta) * delta, cold, 0.005, true)
	was_grounded = grounded
	if not is_colliding and current_terrain and current_terrain.override_up:
		is_colliding = test_move(global_transform, (velocity + current_up * g_gravity() * delta) * delta , col, 0.005, true)
	if is_colliding or is_colliding_down:
		col = col if is_colliding else cold
		var new_up := col.get_normal(0)
		var terrain := col.get_collider() as Terrain
		if terrain:
			current_terrain = terrain
			if terrain.override_up:
				current_up = new_up
			if new_up.angle_to(up) < get_max_angle():
				grounded = true
				up = new_up
				return
			else: 
				current_terrain = null
				grounded = false
		elif new_up.angle_to(up) < get_max_angle():
			grounded = true
			up = new_up
			current_terrain = null
			current_up = Vector3.ZERO
			return
		else:
			current_terrain = null
			current_up = Vector3.ZERO
			grounded = false
	else:
		grounded = false
func check_inputs() -> void:
	var d := Input.get_vector("left", "right", "front", "back") 
	direction = rot_node.global_basis * Vector3(d.x, 0, d.y)

func rotate_to_normal(delta: float) -> void:
	if up != basis.y:
		var q := Quaternion(basis.y, up)
		quaternion =  M.slerpq_normal(quaternion, q * quaternion, delta, 15.0)

func get_max_angle() -> float:
	return max_ground_angle if not current_terrain or not current_terrain.override_angle else current_terrain.max_angle
func apply_gravity(delta: float) -> void:
	if grounded: return
	var d := velocity.dot(up)
	if d > 0.0:
		#up
		velocity += up * jump_state.jump_gravity * delta
	elif d >= -max_down_vel :
		#down
		velocity += up * jump_state.fall_gravity * delta

func g_gravity() -> float:
	var d := velocity.dot(up)
	if d > 0.0:
		#up
		return jump_state.jump_gravity
	else :
		#down
		return jump_state.fall_gravity

func apply_snap(_delta: float) -> void:
	var col = KinematicCollision3D.new()
	var collided := test_move(transform, -basis.y * snap_height, col, 0.001, true, 1)
	if collided:
		var angle := col.get_normal().angle_to(up)
		if angle <= 0.1 or angle >= get_max_angle(): return
		print(col.get_normal().dot(up))
		#position += col.get_travel()
		up = col.get_normal()
		var q := Quaternion(basis.y, up)
		velocity = q * velocity
func move(delta: float) -> void:
	var subdelt := delta / delta_iterations
	for i in delta_iterations:
		var col := move_and_collide(velocity * subdelt)
		if col:
			velocity = velocity.slide(col.get_normal(0))

func reslide_velocity() -> void:
	var slid := velocity.slide(old_up).length()
	var proj := velocity.dot(old_up)
	
	velocity = velocity.slide(up).normalized() * slid + up * proj
func get_nearest_cardinal() -> Vector3:
	var dotup := up.dot(Vector3.UP)
	#var dotleft := up.dot(Vector3.LEFT)
	#var dotfront := up.dot(Vector3.FORWARD)
	#
	#var adotup := absf(dotup)
	#var adotleft := absf(dotleft)
	#var adotfront := absf(dotfront)
	#if adotup >= adotleft and adotup > adotfront:
		#if dotup > 0:
			#return Vector3.UP
		#return Vector3.DOWN
	#if adotleft >= adotup and adotleft > adotfront:
		#if dotleft > 0:
			#return Vector3.LEFT
		#return Vector3.RIGHT
	#
	#if adotfront >= adotup and adotfront > adotleft:
		#if dotfront > 0:
			#return Vector3.FORWARD
	#return Vector3.BACK
	if current_terrain and current_terrain.override_up:
		return current_up
	if dotup >= 0:
		return Vector3.UP
	return Vector3.DOWN
