extends PlayerState
class_name FallPlayerState

@export var minimum_jump_timer := 0.2
@export var mesh: PlayerMesh
@export var scale_over_curve: Curve
@export var coyote_timer := 0.1
@export var rotate_node: Node3D
@export var full_rot_vol_curve: Curve
@export var vol_over_vel_curve: Curve
@export var pitch_over_full_rot : Curve
@export var rot_vel_over_vel : Curve
@export var update_freq_over_vel : Curve
@export var sound: RaytracedAudioPlayer3D
@export var ghost_threshold := -40.0
var t := 0.0
var jump_t := 0.0
var ghost_t := 0.0
var anim_t := 0.0
var rot := 0.0
var old_rot := 0.0
func on_enter():
	prints("ENTERED AIR", up)
	player.left_ground.emit()
	t = 0.0
	jump_t = 0.0
	ghost_t = 0.0
	anim_t = 0.0
	rot = 0.0
	old_rot = 0.0
	player.camera.target_fov = target_fov
	if mesh.tween: mesh.tween.kill()
	player.is_in_air = true
	if not sound.playing:
		sound.play(10.0)
func on_exit():
	player.jumped = false
	player.let_go_of_space = false
	player.is_in_air = false
	mesh.rotation.x = 0.0
	sound.volume_linear = 0.0
	mesh.reset_physics_interpolation()
func tick(delta: float):
	jump_t += delta
	var upvel := velocity.dot(up)
	if upvel < 0.0:
		t += delta
	if t > 2.0: 
		get_tree().current_scene.on_die()
		t = 0.0
	if upvel < ghost_threshold:
		ghost_t += delta
	if ghost_t > 0.08:
		var g := Ghost.new(player.mesh, 2.0, 0.5)
		get_tree().current_scene.world_3d.add_child(g)
		ghost_t = 0.0
	anim_t += delta
	if anim_t > 1.0 / update_freq_over_vel.sample(upvel):
		anim_t = 0.0
		mesh.rotation.x = rot
func physics_tick(delta: float):
	if grounded or player.was_grounded:
		player.landed.emit(player.former_velocity)
		var spd := velocity.slide(up).length()
		if player.direction:
			if spd > 45.0:
				transition("drift")
			else:
				transition("move")
		else:
			if player.direction.dot(velocity.slide(up)) < 0:
				transition("stop")
			else:
				transition("idle")
		return

	if jump_t > minimum_jump_timer and not player.let_go_of_space and not Input.is_action_pressed("jump"):
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
	var pitch = pitch_over_full_rot.sample(rot)
	var vol = full_rot_vol_curve.sample(rot)
	var vol_over_v = vol_over_vel_curve.sample(velocity.dot(up))
	sound.volume_linear = vol * vol_over_v
	sound.pitch_scale = pitch
	var rotvel := rot_vel_over_vel.sample(velocity.dot(up))
	old_rot = rot
	rot += PI * delta * rotvel
	rot = fmod(rot, TAU)
	#mesh.rotation.x = -rot
