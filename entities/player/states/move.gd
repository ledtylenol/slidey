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
func on_exit() -> void:
	t = 0.0
	
	mesh.rotation.z = 0.0
	rot = 0.0
func tick(delta: float) -> void:
	t += delta
	if player.grounded:
		var spd :=  player.velocity.slide(player.up).length()
		rot += delta * spd
		mesh.rotation.z = sin(rot) * (PI / 12) * (1.0 - (spd / player.min_drift_speed))
func physics_tick(delta: float) -> void:
	var slid := velocity.slide(up).length()

	if slid < 15.0:
		var angle := player.get_max_angle()
		if up.angle_to(player.get_nearest_cardinal()) > angle:
			player.up = player.get_nearest_cardinal()
	player.jump()
	if not player.jumped:
		player.apply_snap(delta)

	velocity = velocity.project(up) + velocity.slide(up).move_toward(player.direction * player.move_speed, delta *  player.move_accel)
	player.move(delta)
	if not (grounded or player.was_grounded):
		transition("fall")
		return
	if not player.direction:
		transition("idle")
		return
	elif t > 0.5 and player.direction.dot(velocity.slide(up)) < 0 and velocity.slide(up).length() > 30.0:
		transition("stop")
		return
	if slid >  player.min_drift_speed:
		transition("drift")
		return
