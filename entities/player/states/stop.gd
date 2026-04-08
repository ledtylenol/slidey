extends PlayerState
class_name StopPlayerState 

@export var friction := 100.0
@export var skid: RaytracedAudioPlayer3D
@export var mesh: PlayerMesh
@export var time_over_speed: Curve

var t := 0.0
func on_enter() -> void:
	skid.play()
	mesh.stop()
	t = 0.0
func on_exit() -> void:
	skid.stop()
	mesh.reset_size()
func tick(delta: float) -> void:
	t += delta
	var vel := velocity.slide(up).length()
	if t > time_over_speed.sample(vel):
		var ghost = Ghost.new(mesh, 0.5)
		get_tree().current_scene.world_3d.add_child(ghost)
		t = 0.0
func physics_tick(delta: float) -> void:
	if grounded:
		if player.direction and player.direction.dot(velocity) > 0:
			transition("move")
			return
	if velocity.slide(up).is_zero_approx():
		if grounded:
			transition("idle")
		else:
			transition("fall")
		return
	velocity = velocity.project(up) + velocity.slide(up).move_toward(Vector3.ZERO, delta * friction)
	player.jump()
	player.move(delta)
