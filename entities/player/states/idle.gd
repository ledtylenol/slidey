extends PlayerState
class_name IdlePlayerState

@export var friction := 50.0
@export var mesh: PlayerMesh
func on_enter():
	player.stopped_moving.emit()
	player.camera.target_fov = target_fov
	player.jumped = false
	player.is_in_air = false
	player.let_go_of_space = false
	player.flew = false
	player.initiated_float = false
	player.hover_time = player.float_time_base

func on_exit():
	pass

func tick(_delta: float):
	pass
func physics_tick(delta: float):
	player.check_grounded(delta)
	player.check_inputs()
	player.rotate_to_normal(delta)
	var slid := velocity.slide(up).length()
	if slid < 15.0 :
		var angle := player.get_max_angle()
		if up.angle_to(player.get_nearest_cardinal()) > angle:
			player.up = player.get_nearest_cardinal()
	velocity = velocity.project(up) + velocity.slide(up).move_toward(Vector3.ZERO, delta * friction)
	player.jump()
	player.move(delta)
	mesh.rotation.z = M.smooth_nudgea(mesh.rotation.z, 0.0, 15.0, delta)

	if grounded or player.was_grounded:
		if player.direction:
			transition("move")
			return
	else:
		transition("fall")
		return
