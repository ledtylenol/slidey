extends Node
class_name MeshSpinManager
@export var player: Player
@export var mesh: PlayerMesh
var rot := 0.0
var state := 0
var anim_t := 0.0

var states: Array[int] = []
@export var full_rot_vol_curve: Curve
@export var vol_over_vel_curve: Curve
@export var pitch_over_full_rot : Curve
@export var rot_vel_over_vel : Curve
@export var update_freq_over_vel : Curve
@export var sound: RaytracedAudioPlayer3D

var mode := 0
func start(start_mode: int) -> void:
	anim_t = 0.0
	rot = 0.0
	sound.volume_linear = 0.0
	if not sound.playing:
		sound.play(10.0)
	mode = start_mode

func reset_rot() -> void:
	rot = 0.0
func get_next_state() -> void:
	if states.is_empty():
		for i in 6:
			states.push_back(i)
		states.shuffle()
	state = states.pop_back()

func tick(delta: float) -> void:
	
	var upvel := player.velocity.dot(player.up) if mode != 1 else -player.velocity.slide(player.up).length()
	if anim_t > 1.0 / update_freq_over_vel.sample(upvel):
		anim_t = 0.0
		rotate_mesh()
	anim_t += delta

func physics_tick(delta: float) -> void:
	var pitch = pitch_over_full_rot.sample(rot)
	var vol = full_rot_vol_curve.sample(rot)
	var vel: float
	if mode != 2:
		vel = player.velocity.dot(player.up) if mode == 0 else -player.velocity.slide(player.up).length()
	else:
		vel = -30.0
	var vol_over_v = vol_over_vel_curve.sample(vel)
	sound.volume_linear = M.smooth_nudgef(sound.volume_linear, vol * vol_over_v, 20.0, delta)
	sound.pitch_scale = pitch
	var rotvel := rot_vel_over_vel.sample(vel)
	rot += PI * delta * rotvel
	rot = fmod(rot, TAU)

func rotate_mesh() -> void: 
	if mode == 0 or mode == 1:
		match state:
			0:
				mesh.rotation.z = -rot
				mesh.rotation.x = rot
			1:
				mesh.rotation.z = rot
				mesh.rotation.x = -rot
			2:
				mesh.rotation.z = -rot
			3:
				mesh.rotation.x = rot
			4:
				mesh.rotation.z = rot
			5:
				mesh.rotation.x = -rot
	else:
		if state % 2 == 0:
			mesh.rotation.y = rot
		else:
			mesh.rotation.y = -rot


func stop() -> void:
	mesh.rotation.z = 0.0
	mesh.rotation.x = 0.0
	sound.volume_linear = 0.0
	if mode == 2:
		mesh.rotation.y = 0.0
func set_state(s: int) -> void:
	state = s
