extends Marker3D
class_name TPMarker
@export var tp_name := "placeholder"

func _ready() -> void:
	get_tree().current_scene.add_marker(self)
