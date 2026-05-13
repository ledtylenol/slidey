extends MeshInstance3D
class_name Ghost
var duration := 2.0
var alpha := 1.0:
	set(v):
		alpha = v
var s_alpha := alpha
var t := 0.0
var time_interval := 0.0
func _init(_mesh: MeshInstance3D, _duration := 2.0, start_alpha := 1.0, _time_interval := 0.33) -> void:
	transform = _mesh.global_transform
	mesh = _mesh.mesh
	duration = _duration
	set_instance_shader_parameter("offset", Vector2(randf(), randf()) * 10.0)
	s_alpha = start_alpha
	time_interval = _time_interval
	set_instance_shader_parameter("alpha", s_alpha)
func _ready() -> void:
	var tw := create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	tw.tween_property(self, "alpha", 0.0, duration).from(s_alpha)
	tw.tween_callback(queue_free)

func _process(delta: float) -> void:
	t += delta
	if t > time_interval:
		t = 0.0
		set_instance_shader_parameter("alpha", alpha)
