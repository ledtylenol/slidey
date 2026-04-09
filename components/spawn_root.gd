extends Marker3D
class_name SpawnRoot

@export var id := "placeholder"
func _ready() -> void:
	get_tree().current_scene.level_changed.connect(on_level_change)

func on_level_change(_id: String) -> void:
	if id == _id:
		get_tree().current_scene.teleport_player(self.transform)
		get_tree().current_scene.set_spawnpoint(self.transform)
