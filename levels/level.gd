extends Node3D
class_name Level

@export var level_name := "placeholder"
@export var spawn_root: Marker3D
func _ready() -> void:
	pop_player()
	get_tree().current_scene.start()
func pop_player() -> void:
	if not spawn_root: return
	get_tree().current_scene.teleport_player(spawn_root.transform)
