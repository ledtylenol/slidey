extends PlayerState
class_name PlayerMoveState

@export var speed := 50.0
@export var drift_speed := 45.0
@export var accel := 50.0

var t := 0.0
func on_enter() -> void:
	player.started_moving.emit()
	player.camera.target_fov = target_fov
	t = 0.0
func on_exit() -> void:
	t = 0.0
func tick(delta: float) -> void:
	t += delta
func physics_tick(delta: float) -> void:
	if not grounded:
		transition("fall")
		return
	if not player.direction:
		transition("idle")
		return
	elif t > 0.5 and player.direction.dot(velocity.slide(up)) < 0 and velocity.slide(up).length() > 30.0:
		transition("stop")
		return
	var slid := velocity.slide(up).length()
	if slid > drift_speed:
		transition("drift")
		return
	if slid < 15.0:
		var angle := player.get_max_angle()
		if up.angle_to(player.get_nearest_cardinal()) > angle:
			player.up = player.get_nearest_cardinal()
	player.jump()
	velocity = velocity.project(up) + velocity.slide(up).move_toward(player.direction * speed, delta * accel)
	player.move(delta)
