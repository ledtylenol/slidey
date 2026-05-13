extends PlayerState
class_name FallPlayerState

@export var manager: MeshSpinManager
@export var minimum_jump_timer := 0.2
@export var mesh: PlayerMesh
@export var scale_over_curve: Curve
@export var coyote_timer := 0.1
@export var ghost_threshold := -40.0
var t := 0.0
var jump_t := 0.0
var ghost_t := 0.0

var fell := false
func on_enter():
	prints("ENTERED AIR", up)
	player.left_ground.emit()
	t = 0.0
	jump_t = 0.0
	ghost_t = 0.0
	manager.start(0)
	player.camera.target_fov = target_fov
	player.is_in_air = true
	
	if not player.initiated_float:
		if not player.jumped:
			manager.set_state(3)
			fell = true
		else:
			manager.get_next_state()
	else:
		print("NOT FLEW")
func on_exit():
	fell = false
	player.jumped = false
	player.let_go_of_space = false
	player.is_in_air = false
	manager.stop()
	mesh.reset_physics_interpolation()
func tick(delta: float):
	var upvel := player.velocity.dot(player.up)
	jump_t += delta
	if upvel < 0.0:
		t += delta
	#if t > 2.0: 
		#get_tree().current_scene.on_die()
		#t = 0.0
	if upvel < ghost_threshold:
		ghost_t += delta
	if ghost_t > 0.08:
		var g := Ghost.new(player.mesh, 2.0, 0.5, 0.22)
		get_tree().current_scene.world_3d.add_child(g)
		ghost_t = 0.0
	manager.tick(delta)

func physics_tick(delta: float):
	player.check_inputs()
	player.rotate_to_normal(delta)
	player.check_grounded(delta)
	var jumped := player.jumped
	if (player.jumped or jump_t > coyote_timer) and jump_t > minimum_jump_timer and not player.let_go_of_space and not Input.is_action_pressed("jump"):
		player.let_go_of_space = true
	var queries: Array[HurtBox3D] = player.query_enemies()
	if not queries.is_empty():
		var area: HurtBox3D = queries.back()
		player.target = area
		if (player.jumped or jump_t > 0.5 or player.initiated_float) and player.can_home() and Input.is_action_just_pressed("jump"):
				transition("home")
				return
	else:
		player.target = null
	if t <= coyote_timer:
		player.jump()
	if not (player.jumped and not jumped):
		player.apply_snap(delta)
	if player.jumped and fell:
		print("fell?")
		fell = false
		manager.get_next_state()
	if not player.flew and (player.hover_time > 0) and Input.is_action_just_pressed("dash"):
		transition("float")
		return
	if grounded or player.was_grounded:
		player.landed.emit(player.former_velocity)
		var spd := velocity.slide(up).length()
		player.target = null
		if player.direction:
			if spd > 45.0:
				transition("drift")
			else:
				transition("move")
		else:
			if not player.direction or player.direction.dot(velocity.slide(up)) < 0:
				transition("stop")
			else:
				transition("idle")
		return

	var slid := velocity.slide(up)

	player.apply_gravity(delta)
	if player.direction:
		var slerped := player.direction * slid.length()
		if slid.dot(slerped) > 0:
			velocity = velocity.project(up) + M.smooth_slerp(slid, slerped, delta, 1.0)
		else:
			velocity = velocity.project(up) + M.smooth_nudgev(slid, slerped, delta, 1.0)
	#if not slid.is_zero_approx():
		#mesh.face_z(slid.normalized())
	player.move(delta)
	var c := velocity.dot(up)
	var sc := scale_over_curve.sample(c)
	if not mesh.tween or not mesh.tween.is_running(): 
		mesh.scale_root.scale = Vector3(1.0 / sc, sc, 1.0 / sc)
	manager.physics_tick(delta)
	#mesh.rotation.x = -rot
