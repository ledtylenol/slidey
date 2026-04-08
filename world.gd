extends Node
class_name Game
@export var world_3d: Node3D
@export var ui: Control
@export var player: Player
@export_category("Sun")
@export var sun: DirectionalLight3D
@export var environment: WorldEnvironment
@export var pitch_over_v: Curve
@export var vol_over_v: Curve
@export var v_over_v: Curve
@export var woosh: AudioStreamPlayer
var spawnpoint := Transform3D.IDENTITY
var start_rot := Quaternion.IDENTITY
var end_rot := Quaternion.IDENTITY
var starte_rot := Quaternion.IDENTITY
var ende_rot := Quaternion.IDENTITY
var last_id := 0

var tween: Tween
var rotations: Array[Rotation] = []
signal reset
class Rotation:
	var start_rot := Quaternion.IDENTITY
	var end_rot := Quaternion.IDENTITY
	var starte_rot := Quaternion.IDENTITY
	var ende_rot := Quaternion.IDENTITY
	var id: int
	var duration := 3.0
	func _init(s: Quaternion, e: Quaternion, se: Quaternion, ee: Quaternion, d: float, i: int) -> void:
		duration = d
		start_rot = s
		end_rot = e
		starte_rot = se
		ende_rot = ee
		id = i
func _ready() -> void:
	spawnpoint = player.transform
func on_die() -> void:
	player.transform = spawnpoint
	player.velocity = Vector3.ZERO
	player.up = spawnpoint.basis.y
	player.reset_physics_interpolation()
	invert_rotations()
func rotate_sun(q: Quaternion, env_q: Quaternion, duration: float) -> void:
	start_rot = sun.quaternion
	starte_rot = Quaternion.from_euler(environment.environment.sky_rotation)
	ende_rot = env_q
	end_rot = q
	var r := Rotation.new(start_rot, end_rot, starte_rot, ende_rot, duration, last_id)
	rotations.push_back(r)
	if tween: tween.kill()
	tween = create_tween()
	tween.tween_method(r_sun, 0.0, 1.0, duration)
	woosh.play(5.0 + randf_range(-0.5, 0.5))
	tween.tween_callback(woosh.stop)
func r_sun(v: float) -> void:
	var vv := v_over_v.sample(v)
	var eq := starte_rot.slerp(ende_rot, vv)
	woosh.volume_linear = vol_over_v.sample(v)
	woosh.pitch_scale = pitch_over_v.sample(v)
	sun.quaternion =  start_rot.slerp(end_rot, vv)
	environment.environment.sky_rotation = eq.get_euler()
func invert_rotations() -> void:
	if rotations.is_empty():
		reset.emit(last_id)
		return
	if tween: tween.kill()
	tween = create_tween()
	tween.tween_interval(0.5)
	while not rotations.is_empty():
		var r: Rotation = rotations.pop_back()
		if r.id != last_id:
			continue
		tween.tween_callback(func():
			start_rot = sun.quaternion
			starte_rot = Quaternion.from_euler(environment.environment.sky_rotation)
			ende_rot = r.starte_rot
			end_rot = r.start_rot
			woosh.play(5.0 + randf_range(-0.5, 0.5))
			)
		tween.tween_method(r_sun, 0.0, 1.0, 0.89)
	tween.tween_callback(reset.emit.bind(last_id))
