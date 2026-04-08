extends PlayerState
class_name FallPlayerState

@export var minimum_jump_timer := 0.2
@export var mesh: PlayerMesh
@export var scale_over_curve: Curve
@export var coyote_timer := 0.1
var t := 0.0
func on_enter():
	player.left_ground.emit()
	t = 0.0
	player.camera.target_fov = target_fov
	if mesh.tween: mesh.tween.kill()
	player.is_in_air = true
func on_exit():
	player.jumped = false
	player.let_go_of_space = false
	player.is_in_air = false

func tick(delta: float):
	if velocity.dot(up) < 0.0:
		t += delta
	if t > 2.0: 
		get_tree().current_scene.on_die()
		t = 0.0
func physics_tick(delta: float):
	if grounded:
		player.landed.emit(player.former_velocity)
		if player.direction:
			transition("move")
		else:
			transition("idle")
		return
	if t > minimum_jump_timer and not player.let_go_of_space and not Input.is_action_pressed("jump"):
		player.let_go_of_space = true
	player.apply_gravity(delta)
	if player.direction:
		var slid := velocity.slide(up)
		var slerped := player.direction * slid.length()
		if slid.dot(slerped) > 0:
			velocity = velocity.project(up) + M.smooth_slerp(slid, slerped, delta, 1.0)
		else:
			velocity = velocity.project(up) + M.smooth_nudgev(slid, slerped, delta, 1.0)
	if t <= coyote_timer:
		player.jump()
	player.move(delta)
	var c := velocity.dot(up)
	var sc := scale_over_curve.sample(c)
	if not mesh.tween or not mesh.tween.is_running(): 
		mesh.scale_root.scale = Vector3(1.0 / sc, sc, 1.0 / sc)
