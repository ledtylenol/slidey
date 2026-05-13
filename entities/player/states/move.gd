extends PlayerState
class_name PlayerMoveState

@export var mesh: PlayerMesh
var t := 0.0
var rot := 0.0
func on_enter() -> void:
	player.started_moving.emit()
	player.camera.target_fov = target_fov
	t = 0.0
	player.jumped = false
	player.is_in_air = false
	player.let_go_of_space = false
	player.flew = false
	player.initiated_float = false
	player.hover_time = player.float_time_base

func on_exit() -> void:
	t = 0.0
	
	rot = 0.0
func tick(delta: float) -> void:
	t += delta
	if player.grounded:
		var spd :=  player.velocity.slide(player.up).length()
		rot += delta * spd
		#mesh.rotation.z = sin(rot) * (PI / 12) * (1.0 - (spd / player.min_drift_speed))
func physics_tick(delta: float) -> void:

	player.rotate_to_normal(delta)

	player.check_grounded(delta)
	player.check_inputs()

	player.jump()

	var slid := velocity.slide(up)
	var dir_angle := slid.angle_to(player.direction)
	if slid.length() < 15.0:
		var angle := player.get_max_angle()
		if up.angle_to(player.get_nearest_cardinal()) > angle:
			player.up = player.get_nearest_cardinal()
		if not slid.is_zero_approx() and dir_angle < PI/4:
			var new_slid := slid.move_toward(slid.normalized() * player.move_speed, delta *  player.move_accel_start)
			new_slid = M.smooth_slerp(new_slid, player.direction * new_slid.length(), delta, 10)
			velocity = velocity.project(up) + new_slid
		else:
			var new_slid := slid.move_toward(player.direction * player.move_speed, delta *  player.move_accel_start)
			velocity = velocity.project(up) + new_slid
	else:

		if dir_angle < PI/2:
			var new_slid := slid.move_toward(slid.normalized() * player.move_speed, delta *  player.move_accel)
			new_slid = M.smooth_slerp(new_slid, player.direction * new_slid.length(), delta, 10)
			velocity = velocity.project(up) + new_slid
		else:
			var new_slid := slid.move_toward(player.direction * player.move_speed, delta *  player.move_accel * 5)
			velocity = velocity.project(up) + new_slid
	var dot := -slid.normalized().dot(mesh.global_basis.x) * 5
	mesh.rotation.z = M.smooth_nudgea(mesh.rotation.z, dot * PI/8, 5.0, delta) 
	
	if not slid.is_zero_approx():
		mesh.face_z(slid.normalized())
	player.move(delta)
	if not (grounded or player.was_grounded):
		transition("fall")
		return
	if not player.direction:
		transition("idle")
		return
	elif t > 0.5 and not player.direction and velocity.slide(up).length() > 30.0:
		transition("stop")
		return
	if slid.length() >  player.min_drift_speed:
		transition("drift")
		return
	
