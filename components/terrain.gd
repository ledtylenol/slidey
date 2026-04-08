@tool
extends StaticBody3D
class_name Terrain

@export var sound: String
@export var override_max_angle := false
@export var max_angle := PI/5
@export var override_up := false

func _func_godot_apply_properties(entity_properties: Dictionary) -> void:
	for prop in entity_properties.keys():
		if prop == "classname": continue
		set(prop, entity_properties[prop])
		print("applied %s %s" % [prop, entity_properties[prop]])
