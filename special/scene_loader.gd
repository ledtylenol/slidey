extends Node
class_name SceneLoader

@export_file("*.tscn")var file: String

var scene: PackedScene
@export var load_immediately := true
var p: Array = []
func _ready() -> void:
	if load_immediately: request_load()
func _process(_delta: float) -> void:
	if ResourceLoader.load_threaded_get_status(file, p) == ResourceLoader.THREAD_LOAD_LOADED:
		scene = ResourceLoader.load_threaded_get(file)
func request_load() -> void:
	ResourceLoader.load_threaded_request(file)

func try_load(path: String) -> void:
	if scene:
		get_tree().current_scene.change_level_3d(scene, path)
	else:
		scene = ResourceLoader.load_threaded_get(file)
		get_tree().current_scene.change_level_3d(scene, path)
