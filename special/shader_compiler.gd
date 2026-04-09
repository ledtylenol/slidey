extends Node3D

@export_file("*.tscn") var scenes: Array[String]
@onready var progress_bar: ProgressBar = $ColorRect/VBoxContainer/ProgressBar

var nodes: Array[Node]
var p : int
func _ready() -> void:
	for scene in scenes:
		print("loading %s" % scene)
		ResourceLoader.load_threaded_request(scene)
		nodes = []
		nodes.resize(scenes.size())
	p = scenes.size()
func _process(_delta: float) -> void:
	var i = 0
	while not scenes.is_empty() and i < 3:
		var scene = load(scenes.pop_back())
		var inst = scene.instantiate()
		nodes.push_back(inst)
		add_child(inst)
		await inst.ready
		i += 1
	i = 0
	while not nodes.is_empty() and i < 3:
		var node = nodes.pop_back()
		if node:
			node.queue_free()
		i += 1
	prints(scenes, nodes)
	if scenes.is_empty() and nodes.is_empty():
		get_tree().change_scene_to_file("res://world.tscn")
	progress_bar.value = 1.0 - float(scenes.size()) / p
