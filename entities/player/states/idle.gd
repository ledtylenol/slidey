extends PlayerState
class_name IdlePlayerState

@export var friction := 50.0
func on_enter():
	player.stopped_moving.emit()
	player.camera.target_fov = target_fov
func on_exit():
	pass

func tick(_delta: float):
	pass
func physics_tick(delta: float):
	var slid := velocity.slide(up).length()
	if slid < 15.0 :
		var angle := player.get_max_angle()
		if up.angle_to(player.get_nearest_cardinal()) > angle:
			player.up = player.get_nearest_cardinal()
	velocity = velocity.project(up) + velocity.slide(up).move_toward(Vector3.ZERO, delta * friction)
	player.jump()
	player.move(delta)
	if grounded or player.was_grounded:
		if player.direction:
			transition("move")
			return
	else:
		transition("fall")
		return
