extends Entity
class_name Player

const STAIRS_FEELING_COEFFICIENT: float = 2.5
const WALL_MARGIN: float = 0.001
const STEP_DOWN_MARGIN: float = 0.01
const STEP_HEIGHT_DEFAULT := 3.6
const STEP_HEIGHT_IN_AIR_DEFAULT := 3.6
const STEP_CHECK_COUNT: int = 2
const SPEED_CLAMP_AFTER_JUMP_COEFFICIENT = 0.4
const SPEED_CLAMP_SLOPE_STEP_UP_COEFFICIENT = 0.4


@export_category("Components")
@export var camera: PlayerCamera
@export var walk_particles: GPUParticles3D
@export var mesh: MeshInstance3D

@export var light: OmniLight3D
@export var light_sound: RaytracedAudioPlayer3D
@export var enemy_detection_area: Area3D
@export var hitbox: HitBox3D
@export var hurtbox: HurtBox3D
@export var home_timer: Timer
@export var ground_cast: RayCast3D

@export_category("Params")

@export var particle_ratio_curve: Curve
@export_group("Move Params")
@export_subgroup("Standard Params")
@export var move_speed := 50.0
@export var move_accel := 50.0
@export var move_accel_start := 50.0
@export var min_drift_speed := 45.0
@export_subgroup("Drift Params")
@export var drift_speed := 80.0
@export var drift_accel := 25.0
@export var drift_friction := 2.0
@export_subgroup("Stop Params")
@export var stop_friction := 100.0
@export var stop_friction_over := 200.0

@export_subgroup("Float Params")
@export var float_friction := 50.0
@export var float_speed := 5.0
@export var float_accel := 10.0
@export var float_time_base := 2.5

var let_go_of_space := false
var target: HurtBox3D:
	set(v):
		target = v
		target_set.emit(v)
var flew := false
var initiated_float := false
var hover_time := 2.5
signal target_set(target: HurtBox3D)
func _ready() -> void:
	super()
	var tween := create_tween()
	tween.tween_interval(randf_range(1.8, 3.5))
	tween.tween_callback(func():
		light_sound.play()
		light.visible = true
	)

func rotate_to_normal(_delta: float) -> void:
	if not up.is_equal_approx(basis.y):
		var qq := Quaternion(basis.y, up)
		var q :=  qq * quaternion
		
		var angle = (qq * camera.global_basis.z).angle_to(camera.global_basis.z)
		#quaternion =  M.slerpq_normal(quaternion, q, delta, 15.0)
		quaternion = q
		print(angle)
		if angle > PI / 2:
			rotate_object_local(Vector3.UP, PI)
func can_home() -> bool:
	return home_timer.is_stopped()
func _physics_process(delta: float) -> void:

	state_machine.physics_tick(delta)
	if grounded:
		walk_particles.amount_ratio = particle_ratio_curve.sample(velocity.slide(up).length())
	else:
		walk_particles.amount_ratio = 0.0
	walk_particles.process_material.direction = (-velocity.normalized()).slerp(Vector3.UP * 2.0, 0.8)
	walk_particles.process_material.gravity = -9.8 * up

	former_velocity = velocity
	RenderingServer.global_shader_parameter_set("playerpos", position)
func update_up_raycast() -> void:
	if ground_cast.is_colliding():
		var new_up := ground_cast.get_collision_normal()
		var terrain := ground_cast.get_collider() as Terrain
		if terrain:
			current_terrain = terrain
		if new_up.angle_to(up) < get_max_angle():
			up = new_up
			if not up.is_equal_approx(basis.y):
				var q := Quaternion(basis.y, up)
				quaternion =  q * quaternion
				velocity = q * velocity
func apply_gravity(delta: float) -> void:
	#if grounded: return
	var d := velocity.dot(up)
	var modifier := 1.0
	if jumped and let_go_of_space: modifier = 2.0
	if d > 0.0:
		#up
		velocity += modifier * up * jump_state.jump_gravity * delta
	elif d >= -max_down_vel :
		#down
		velocity += modifier * up * jump_state.fall_gravity * delta

func query_enemies() -> Array[HurtBox3D]:
	var state := get_world_3d().direct_space_state
	var query := PhysicsRayQueryParameters3D.new()
	query.from = global_position
	query.collide_with_areas = true
	query.collide_with_bodies = true
	query.collision_mask = 0b1001
	query.exclude = [hitbox.get_rid(), hurtbox.get_rid(), enemy_detection_area.get_rid()]
	var arr: Array[HurtBox3D] = [] 
	for area in enemy_detection_area.get_overlapping_areas():
		if area == hurtbox: continue
		if area is not HurtBox3D:
			continue
		if area.health.is_dead(): 
			continue
		if area.global_position.distance_to(global_position) < 3:
			continue
		var angle = (-camera.global_basis.z).angle_to(camera.global_position.direction_to(area.global_position))
		if angle > PI / 4: 
			continue
		query.to = area.global_position
		var res: Dictionary = state.intersect_ray(query)
		if not res:
			continue
		if res.collider != area:
			continue
		arr.push_back(area)
	if not arr.is_empty():
		arr.sort_custom(func(a, b): return a.global_position.distance_to(global_position) > b.global_position.distance_to(global_position))
	return arr
