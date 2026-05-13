extends PlayerState
class_name PlayerDashState

@export var dash_cooldown: Timer
@export var manager: MeshSpinManager
@export var mesh: PlayerMesh
var startvel := 0.0
var startdir := Vector3.ZERO
var ground_count := 0
func on_enter() -> void:
	dash_cooldown.start()
	print("entered dash state")
	player.air_jump(.7)
	startdir = player.direction
	startvel = velocity.slide(up).length()
	manager.start(1)
	manager.get_next_state()
	ground_count = 0
func on_exit() -> void:
	velocity = velocity.project(up) + velocity.slide(up).normalized() * maxf(startvel, 50.0)
	print("exited dash state")
	manager.stop()
	mesh.reset_physics_interpolation()
func tick(delta: float) -> void:
	manager.tick(delta)

func physics_tick(delta: float) -> void:
	player.check_inputs()
	player.check_grounded(delta)
	if grounded:
		ground_count += 1
	player.update_up_raycast()
	startdir = startdir.slide(up).normalized()
	velocity = velocity.project(up) + startdir* 50
	player.apply_gravity(delta)
	player.move(delta)
	manager.physics_tick(delta)
	if ground_count >= 2:
		transition("move")
		return
	if Input.is_action_just_pressed("jump"):
		var queries: Array[HurtBox3D] = player.query_enemies()
		if not queries.is_empty():
			print("A")
			var area: HurtBox3D = queries.back()
			player.target = area
			transition("home")
			return
