extends PlayerState
class_name PlayerFloatState

@export var manager: MeshSpinManager
@export var jump_sound: RaytracedAudioPlayer3D
var startvel := 0.0
func on_enter() -> void:
	startvel = velocity.length()
	manager.start(2)
	if not player.initiated_float:
		player.initiated_float = true
		manager.get_next_state()
		player.hover_time = player.float_time_base
func on_exit() -> void:
	manager.stop()
func physics_tick(delta: float) -> void:
	player.check_inputs()
	player.rotate_to_normal(delta)
	player.check_grounded(delta)
	if grounded:
		transition("idle")
		return
	var queries: Array[HurtBox3D] = player.query_enemies()
	var jump_pressed := Input.is_action_just_pressed("jump")
	if not queries.is_empty():
		var area: HurtBox3D = queries.back()
		player.target = area
	else:
		player.target = null
	if not Input.is_action_pressed("dash") or player.hover_time <= 0.0:
		if jump_pressed:
			jump()
		transition("fall")
		return
	if jump_pressed:
		jump()
		transition("fall")
		return
	var vert := velocity.project(up).move_toward(-up * 2, delta * 80.0)
	var slid := velocity.slide(up)
	var accel := player.float_accel
	if slid.length() > player.float_speed:
		accel = player.float_friction
	var hor := slid.move_toward(player.direction * player.float_speed, accel * delta)
	velocity = vert + hor
	
	player.move(delta)
	manager.physics_tick(delta)
	
func tick(delta: float) -> void:
	manager.tick(delta)
	player.hover_time -= delta

func jump() -> void:
	player.flew = true
	player.air_jump()
	velocity = velocity.project(up) + player.direction * startvel
	jump_sound.play()
