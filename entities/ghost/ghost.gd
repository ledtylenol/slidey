extends MeshInstance3D
class_name Ghost
var duration := 2.0
func _init(_mesh: MeshInstance3D, _duration := 2.0) -> void:
	transform = _mesh.global_transform
	mesh = _mesh.mesh
	duration = _duration
func _ready() -> void:
	var t := create_tween()
	t.tween_property(self, "transparency", 1.0, duration).from(0.6)
	t.tween_callback(queue_free)
