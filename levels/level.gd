extends Node3D
class_name Level

@export var level_name := "placeholder"
@export var spawn_root: Marker3D
@export var sun_visible := true
@export var stub := false
func _ready() -> void:
	if stub:
		ready.emit()
		return
	pop_player()
	get_tree().current_scene.start()
func pop_player() -> void:
	if not spawn_root: return
	get_tree().current_scene.teleport_player(spawn_root.transform)
