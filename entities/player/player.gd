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
@export_category("Params")

@export var particle_ratio_curve: Curve
@export_group("Move Params")
@export_subgroup("Standard Params")
@export var move_speed := 50.0
@export var move_accel := 50.0
@export var min_drift_speed := 45.0
@export_subgroup("Drift Params")
@export var drift_speed := 80.0
@export var drift_accel := 25.0
@export var drift_friction := 2.0
@export_subgroup("Stop Params")
@export var stop_friction := 100.0
@export var stop_friction_over := 200.0

var let_go_of_space := false

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

	former_velocity = velocity

func apply_gravity(delta: float) -> void:
	if grounded: return
	var d := velocity.dot(up)
	var modifier := 1.0
	if let_go_of_space: modifier = 2.0
	if d > 0.0:
		#up
		velocity += modifier * up * jump_state.jump_gravity * delta
	elif d >= -max_down_vel :
		#down
		velocity += modifier * up * jump_state.fall_gravity * delta
