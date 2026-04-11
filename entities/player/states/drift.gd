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
func on_exit() -> void:
	pass
func tick(delta: float) -> void:
	t += delta
	var vel := velocity.slide(up).length()
	if t > time_over_speed.sample(vel):
		var ghost = Ghost.new(mesh, 5.0)
		get_tree().current_scene.world_3d.add_child(ghost)
		t = 0.0
func physics_tick(delta: float) -> void:


	player.jump()
	var acceleration := player.drift_accel
	if velocity.dot(player.direction) > player.drift_speed:
		acceleration = player.drift_friction
	var moved := velocity.slide(up).move_toward(player.direction * player.drift_speed, delta * acceleration)

	velocity = velocity.project(up) + moved
	if not player.jumped:
		player.apply_snap(delta)
	player.move(delta)
	player.check_grounded(delta)
	if not (grounded or player.was_grounded):
		transition("fall")
		return
	if not player.direction or player.direction.dot(velocity.slide(up)) < 0:
		transition("stop")
		return
	if player.velocity.slide(up).length() < player.min_drift_speed:
		transition("move")
		return
