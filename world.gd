extends Node
class_name Game
@export var world_3d: GameWorld3D
@export var coin_manager: CoinManager
@export var ui: Control
@export var player: Player
@export_category("Sun")
@export var sun: DirectionalLight3D
@export var environment: WorldEnvironment
@export var pitch_over_v: Curve
@export var vol_over_v: Curve
@export var v_over_v: Curve
@export var pitch_over_diff: Curve
@export var v_over_diff: Curve
@export var duration_over_diff: Curve
@export var woosh: AudioStreamPlayer
var spawnpoint := Transform3D.IDENTITY
var start_rot := Quaternion.IDENTITY
var end_rot := Quaternion.IDENTITY
var starte_rot := Quaternion.IDENTITY
var ende_rot := Quaternion.IDENTITY
var last_id := 0

var tween: Tween
var rotations: Array[Rotation] = []
var tpmarkers: Dictionary[String, Transform3D] = {}
signal reset
signal just_reset
signal player_teleported
signal level_changed(String)
class Rotation:
	var start_rot := Quaternion.IDENTITY
	var end_rot := Quaternion.IDENTITY
	var starte_rot := Quaternion.IDENTITY
	var ende_rot := Quaternion.IDENTITY
	var id: int
	func _init(s: Quaternion, e: Quaternion, se: Quaternion, ee: Quaternion, i: int) -> void:
		start_rot = s
		end_rot = e
		starte_rot = se
		ende_rot = ee
		id = i
func start() -> void:
	spawnpoint = player.transform

func teleport_player(xf: Transform3D) -> void:
	player.transform = xf
	player.up = xf.basis.y
	player.velocity = Vector3.ZERO
	player.reset_physics_interpolation()
	player_teleported.emit()
func on_die() -> void:
	just_reset.emit()
	teleport_player(spawnpoint)
	invert_rotations()
func rotate_sun(q: Quaternion, env_q: Quaternion, duration := 0.0) -> void:
	start_rot = sun.quaternion
	starte_rot = Quaternion.from_euler(environment.environment.sky_rotation)
	ende_rot = env_q
	end_rot = q
	var d := duration if not is_zero_approx(duration) else duration_over_diff.sample(start_rot.angle_to(end_rot))
	var r := Rotation.new(start_rot, end_rot, starte_rot, ende_rot, last_id)
	rotations.push_back(r)
	if tween: tween.kill()
	tween = create_tween()
	tween.tween_method(r_sun, 0.0, 1.0, d)
	woosh.play(5.0 + randf_range(-0.5, 0.5))
	tween.tween_callback(woosh.stop)
func r_sun(v: float) -> void:
	var vv := v_over_v.sample(v)
	var eq := starte_rot.slerp(ende_rot, vv)
	var rot := start_rot.angle_to(end_rot)
	woosh.volume_linear = vol_over_v.sample(v) * v_over_diff.sample(rot)
	woosh.pitch_scale = pitch_over_v.sample(v) * pitch_over_diff.sample(rot)
	sun.quaternion =  start_rot.slerp(end_rot, vv)
	environment.environment.sky_rotation = eq.get_euler()
func _input(event: InputEvent) -> void:
	if event.is_pressed():
		if event.is_action("restart"):
			on_die()
		if event.is_action("swap_fps"):
			#TODO godot 4.7 adds nearest viewport scaling!!
			if Engine.max_fps == 0:
				Engine.max_fps = 260
				get_window().scaling_3d_scale = 1.0
			else:
				Engine.max_fps = 0
				get_window().scaling_3d_scale = 1.0
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

func set_spawnpoint(xf: Transform3D) -> void:
	spawnpoint = xf
func change_level_3d(scene: PackedScene, id: String) -> void:
	world_3d.reset_physics_interpolation()
	world_3d.level.queue_free()
	var sc = scene.instantiate()
	world_3d.add_child(sc)
	world_3d.level = sc
	rotations.clear()
	tpmarkers.clear()
	level_changed.emit(id)
	world_3d.reset_physics_interpolation()
func add_marker(marker: TPMarker) -> void:
	tpmarkers[marker.tp_name] = marker.transform
