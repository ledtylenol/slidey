extends PlayerState
class_name DriftPlayerState


@export var mesh: PlayerMesh
@export var time_over_speed: Curve
var t := 0.0
func on_enter() -> void:
	player.camera.target_fov = target_fov
	t = 0.0
	player.jumped = false
	player.is_in_air = false
	player.let_go_of_space = false
	player.flew = false
	player.initiated_float = false
	player.hover_time = player.float_time_base

func on_exit() -> void:
	pass
func tick(delta: float) -> void:
	t += delta
	var vel := velocity.slide(up).length()
	if t > time_over_speed.sample(vel):
		var ghost = Ghost.new(mesh, 5.0, 1.0, 0.1)
		get_tree().current_scene.world_3d.add_child(ghost)
		t = 0.0
func physics_tick(delta: float) -> void:

	player.check_inputs()
	player.check_grounded(delta)
	player.rotate_to_normal(delta)
	player.jump()
	var acceleration := player.drift_accel
	if velocity.dot(player.direction) > player.drift_speed:
		acceleration = player.drift_friction
	var moved := velocity.slide(up).move_toward(player.direction * player.drift_speed, delta * acceleration)
	moved = M.smooth_slerp(moved, player.direction * moved.length(), delta, 3)
	velocity = velocity.project(up) + moved
	var slid := velocity.slide(up)
	var dot := -slid.normalized().dot(mesh.global_basis.x) * 5
	mesh.rotation.z = M.smooth_nudgea(mesh.rotation.z, dot * PI/8, 5.0, delta) 
	
	if not slid.is_zero_approx():
		mesh.face_z(slid.normalized())

	player.move(delta)

	if not (grounded or player.was_grounded):
		transition("fall")
		return
	if not player.direction:
		transition("stop")
		return
	if player.velocity.slide(up).length() < player.min_drift_speed:
		transition("move")
		return
