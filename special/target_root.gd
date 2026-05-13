extends Control

@export var player: Player
@export var scale_over_dist: Curve
@export var sound: AudioStreamPlayer

var tween: Tween
var rot_tween: Tween
var target: Node3D
var active := false
var camera: Camera3D
var speed := 0.0
var rot := 0.0
func _ready() -> void:
	player.target_set.connect(on_target_set)
	camera = get_window().get_camera_3d()
func _physics_process(delta: float) -> void:
	if target:
		if camera.is_position_behind(target.global_position):
			return
		position = M.smooth_nudge(position, camera.unproject_position(target.global_position), 32.0, delta)
		var sc := scale_over_dist.sample(player.global_position.distance_to(target.global_position))
		offset_transform_scale = Vector2(sc, sc)
		#rotation += speed * PI * delta
func on_target_set(_target: Node3D) -> void:
	if _target:
		if target != _target:
			sound.play()
		target = _target
	if not _target:
		tween_hidden()
	elif not active:
		tween_visible()
		sound.play()
func tween_hidden() -> void:
	if tween: tween.kill()
	active = false
	tween = create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_EXPO)
	tween.tween_property(self, "scale", Vector2.ZERO, .5)
	tween.parallel().tween_property(self, "speed", 0.0, .5)
	tween.tween_callback(hide)

func tween_visible() -> void:
	if tween: tween.kill()
	active = true
	tween = create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_ELASTIC)
	tween.tween_callback(show)
	tween.tween_property(self, "scale", Vector2.ONE, 1.0)
	tween.parallel().tween_property(self, "speed", 2.0, 1.0)

func _process(delta: float) -> void:
	if not rot_tween or not rot_tween.is_running():
		rot += speed * PI * delta
		rot = fmod(rot, TAU)
		rotation = -rot
	else:
		rot = -rotation
