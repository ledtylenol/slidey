extends MeshInstance3D
class_name Ghost
var duration := 2.0
var alpha := 1.0:
	set(v):
		set_instance_shader_parameter("alpha", v)
		alpha = v
var s_alpha := alpha
func _init(_mesh: MeshInstance3D, _duration := 2.0, start_alpha := 1.0) -> void:
	transform = _mesh.global_transform
	mesh = _mesh.mesh
	duration = _duration
	set_instance_shader_parameter("offset", Vector2(randf(), randf()) * 10.0)
	s_alpha = start_alpha
func _ready() -> void:
	var t := create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	t.tween_property(self, "alpha", 0.0, duration).from(s_alpha)
	t.tween_callback(queue_free)
