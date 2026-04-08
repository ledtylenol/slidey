@tool
extends Node3D
@onready var area_3d: Area3D = $Area3D
@onready var respawn_song: RaytracedAudioPlayer3D = $RespawnSong
@export var id := 0
@onready var pop: RaytracedAudioPlayer3D = $Pop

func _func_godot_apply_properties(entity_properties: Dictionary) -> void:
	id = entity_properties.id
	print("applied %d" % id)
func _ready() -> void:
	if Engine.is_editor_hint(): return
	area_3d.body_entered.connect(set_spawnpoint)
	respawn_song.play(9.0)
func set_spawnpoint(b: Node3D) -> void:
	if b is not Player: return
	
	get_tree().current_scene.spawnpoint = transform
	get_tree().current_scene.last_id = max(get_tree().current_scene.last_id, id)
	pop.play()
	visible = false
	pop.finished.connect(queue_free)
