extends PlayerState
class_name DriftPlayerState

@export var speed := 80.0
@export var accel := 10.0

@export var mesh: PlayerMesh
@export var time_over_speed: Curve
var t := 0.0
func on_enter() -> void:
	print("entered drift")
	player.camera.target_fov = target_fov
	t = 0.0
func on_exit() -> void:
	print("exited drift")

func tick(delta: float) -> void:
	t += delta
	var vel := velocity.slide(up).length()
	if t > time_over_speed.sample(vel):
		var ghost = Ghost.new(mesh)
		get_tree().current_scene.world_3d.add_child(ghost)
		t = 0.0
func physics_tick(delta: float) -> void:
	if not grounded:
		transition("fall")
		return
	if not player.direction or player.direction.dot(velocity.slide(up)) < 0:
		transition("stop")
		return
	player.jump()
	velocity = velocity.project(up) + velocity.slide(up).move_toward(player.direction * speed, delta * accel)
	player.move(delta)
