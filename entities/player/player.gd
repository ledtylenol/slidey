extends PhysicsBody3D
class_name Player

const STAIRS_FEELING_COEFFICIENT: float = 2.5
const WALL_MARGIN: float = 0.001
const STEP_DOWN_MARGIN: float = 0.01
const STEP_HEIGHT_DEFAULT := 3.6
const STEP_HEIGHT_IN_AIR_DEFAULT := 3.6
const STEP_CHECK_COUNT: int = 2
const SPEED_CLAMP_AFTER_JUMP_COEFFICIENT = 0.4
const SPEED_CLAMP_SLOPE_STEP_UP_COEFFICIENT = 0.4

@export var jump_state: JumpState
@export_category("Components")
@export var camera: PlayerCamera
@export var state_machine: StateMachine
@export var walk_particles: GPUParticles3D
@export var mesh: MeshInstance3D
@export var rot_node: Node3D
@export var light: OmniLight3D
@export var light_sound: RaytracedAudioPlayer3D
@export_category("Params")
@export var delta_iterations := 5
@export var max_ground_angle := PI/5
@export var particle_ratio_curve: Curve

var up := Vector3.UP
var velocity := Vector3.ZERO
var grounded := false
var direction := Vector3.ZERO
var jumped := false
var let_go_of_space := false
var is_in_air := false

var step_height_main: Vector3
var step_incremental_check_height: Vector3
var is_enabled_stair_stepping_in_air: bool = true
var is_jumping: bool:
	get: return jumped
var head_offset := Vector3.ZERO
var current_terrain: Terrain
var current_up := Vector3.ZERO
var former_velocity := Vector3.ZERO
var was_grounded := false
@warning_ignore_start("unused_signal")
signal landed()
signal left_ground()
signal started_moving()
signal stopped_moving()


class StepResult:
	var diff_position: Vector3 = Vector3.ZERO
	var normal: Vector3 = Vector3.ZERO
	var is_step_up: bool = false

func _ready() -> void:
	var tween := create_tween()
	tween.tween_interval(randf_range(1.8, 3.5))
	tween.tween_callback(func():
		light_sound.play()
		light.visible = true
	)
func _physics_process(delta: float) -> void:
	check_grounded(delta)
	check_inputs()
	rotate_to_normal(delta)
	state_machine.physics_tick(delta)
	if grounded:
		walk_particles.amount_ratio = particle_ratio_curve.sample(velocity.slide(up).length())
	else:
		walk_particles.amount_ratio = 0.0
	walk_particles.process_material.direction = (-velocity.normalized()).slerp(Vector3.UP * 2.0, 0.8)
	walk_particles.process_material.gravity = -9.8 * up
	if not velocity.is_zero_approx():
		mesh.rotation.y = velocity.slide(up).angle_to(Vector3.FORWARD)
	former_velocity = velocity
func _process(delta: float) -> void:
	state_machine.tick(delta)

func step(delta: float, speed: float) -> void:
	var is_step := false
	var step_result : StepResult = StepResult.new()
	
	is_step = step_check(delta, is_jumping, step_result)
	
	if is_step:
		var is_enabled_stair_stepping: bool = true
		if step_result.is_step_up and is_in_air and not is_enabled_stair_stepping_in_air:
			is_enabled_stair_stepping = false

		if is_enabled_stair_stepping:
			global_transform.origin += step_result.diff_position
			head_offset = step_result.diff_position

func step_check(delta: float, is_jumping_: bool, step_result: StepResult):
	var is_step: bool = false
	
	step_height_main = up * STEP_HEIGHT_DEFAULT
	step_incremental_check_height = up * STEP_HEIGHT_DEFAULT / STEP_CHECK_COUNT
	
	if is_in_air and is_enabled_stair_stepping_in_air:
		step_height_main = up * STEP_HEIGHT_IN_AIR_DEFAULT
		step_incremental_check_height = up * STEP_HEIGHT_IN_AIR_DEFAULT / STEP_CHECK_COUNT
		
	for i in range(STEP_CHECK_COUNT):
		var test_motion_result: PhysicsTestMotionResult3D = PhysicsTestMotionResult3D.new()
		
		var step_height: Vector3 = step_height_main - i * step_incremental_check_height
		var transform3d: Transform3D = global_transform
		var motion: Vector3 = step_height
		var test_motion_params: PhysicsTestMotionParameters3D = PhysicsTestMotionParameters3D.new()
		test_motion_params.from = transform3d
		test_motion_params.motion = motion
		
		var is_player_collided: bool = PhysicsServer3D.body_test_motion(self.get_rid(), test_motion_params, test_motion_result)

		if is_player_collided and test_motion_result.get_collision_normal().dot(up) < 0:
			continue

		transform3d.origin += step_height
		motion = velocity * delta
		test_motion_params.from = transform3d
		test_motion_params.motion = motion
		
		is_player_collided = PhysicsServer3D.body_test_motion(self.get_rid(), test_motion_params, test_motion_result)
		
		if not is_player_collided:
			transform3d.origin += motion
			motion = -step_height
			test_motion_params.from = transform3d
			test_motion_params.motion = motion
			
			is_player_collided = PhysicsServer3D.body_test_motion(self.get_rid(), test_motion_params, test_motion_result)
			
			if is_player_collided:
				if test_motion_result.get_collision_normal().angle_to(up) <= max_ground_angle:
					is_step = true
					step_result.is_step_up = true
					step_result.diff_position = -test_motion_result.get_remainder()
					step_result.normal = test_motion_result.get_collision_normal()
					break
		else:
			var wall_collision_normal: Vector3 = test_motion_result.get_collision_normal()
			transform3d.origin += wall_collision_normal * WALL_MARGIN
			motion = (velocity * delta).slide(wall_collision_normal)
			test_motion_params.from = transform3d
			test_motion_params.motion = motion
			
			is_player_collided = PhysicsServer3D.body_test_motion(self.get_rid(), test_motion_params, test_motion_result)
			
			if not is_player_collided:
				transform3d.origin += motion
				motion = -step_height
				test_motion_params.from = transform3d
				test_motion_params.motion = motion
				
				is_player_collided = PhysicsServer3D.body_test_motion(self.get_rid(), test_motion_params, test_motion_result)
				
				if is_player_collided:
					if test_motion_result.get_collision_normal().angle_to(up) <= max_ground_angle:
						is_step = true
						step_result.is_step_up = true
						step_result.diff_position = -test_motion_result.get_remainder()
						step_result.normal = test_motion_result.get_collision_normal()
						break

	if not is_jumping and not is_step and grounded:
		step_result.is_step_up = false
		var test_motion_result: PhysicsTestMotionResult3D = PhysicsTestMotionResult3D.new()
		var transform3d: Transform3D = global_transform
		var motion: Vector3 = velocity * delta
		var test_motion_params: PhysicsTestMotionParameters3D = PhysicsTestMotionParameters3D.new()
		test_motion_params.from = transform3d
		test_motion_params.motion = motion
		test_motion_params.recovery_as_collision = true

		var is_player_collided: bool = PhysicsServer3D.body_test_motion(self.get_rid(), test_motion_params, test_motion_result)
			
		if not is_player_collided:
			transform3d.origin += motion
			motion = -step_height_main
			test_motion_params.from = transform3d
			test_motion_params.motion = motion
			
			is_player_collided = PhysicsServer3D.body_test_motion(self.get_rid(), test_motion_params, test_motion_result)
			
			if is_player_collided and test_motion_result.get_travel().dot(up) < -STEP_DOWN_MARGIN:
				if test_motion_result.get_collision_normal().angle_to(up) <= max_ground_angle:
					is_step = true
					step_result.diff_position = test_motion_result.get_travel()
					step_result.normal = test_motion_result.get_collision_normal()
		elif is_zero_approx(test_motion_result.get_collision_normal().dot(up)):
			print("CACA")
			var wall_collision_normal: Vector3 = test_motion_result.get_collision_normal()
			transform3d.origin += wall_collision_normal * WALL_MARGIN
			motion = (velocity * delta).slide(wall_collision_normal)
			test_motion_params.from = transform3d
			test_motion_params.motion = motion
			
			is_player_collided = PhysicsServer3D.body_test_motion(self.get_rid(), test_motion_params, test_motion_result)
			
			if not is_player_collided:
				transform3d.origin += motion
				motion = -step_height_main
				test_motion_params.from = transform3d
				test_motion_params.motion = motion
				
				is_player_collided = PhysicsServer3D.body_test_motion(self.get_rid(), test_motion_params, test_motion_result)
				
				if is_player_collided and test_motion_result.get_travel().dot(up) < -STEP_DOWN_MARGIN:
					if test_motion_result.get_collision_normal().angle_to(up) <= max_ground_angle:
						is_step = true
						step_result.diff_position = test_motion_result.get_travel()
						step_result.normal = test_motion_result.get_collision_normal()

	return is_step
func jump() -> void:
	if jumped or not Input.is_action_just_pressed("jump"): return
	velocity = velocity.slide(up) + up * jump_state.jump_velocity
	jumped = true
func check_grounded(delta: float) -> void:
	var col = KinematicCollision3D.new()
	var is_colliding := test_move(transform, (velocity - up) * delta, col, 0.001, true)
	was_grounded = grounded
	if is_colliding:
		var new_up := col.get_normal(0)
		var terrain := col.get_collider() as Terrain
		if terrain:
			current_terrain = terrain
			if new_up.angle_to(up) < max_ground_angle or terrain.override_max_angle and new_up.angle_to(up) < terrain.max_angle:
				grounded = true
				up = new_up
				if terrain.override_up:
					current_up = new_up
				return
		elif new_up.angle_to(up) < max_ground_angle:
			grounded = true
			up = new_up
			current_terrain = null
			current_up = Vector3.ZERO
			return
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
	return max_ground_angle if not current_terrain or not current_terrain.override_max_angle else current_terrain.max_angle
func apply_gravity(delta: float) -> void:
	if grounded: return
	var d := velocity.dot(up)
	var modifier := 1.0
	if let_go_of_space: modifier = 2.0
	if d > 0.0:
		#up
		velocity += modifier * up * jump_state.jump_gravity * delta
	elif d >= -100.0 :
		#down
		velocity += modifier * up * jump_state.fall_gravity * delta

func move(delta: float) -> void:
	var subdelt := delta / delta_iterations
	for i in delta_iterations:
		var col := move_and_collide(velocity * subdelt)
		if col:
			if col.get_normal().angle_to(up) < get_max_angle() and not was_grounded and grounded:
				print(col.get_remainder().dot(up), "A")
			velocity = velocity.slide(col.get_normal(0))
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
