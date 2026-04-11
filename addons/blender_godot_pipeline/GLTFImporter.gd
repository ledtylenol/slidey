# Michael Burt 2025
# www.michaeljared.ca
# Join the discord for support (you can get the Discord link from my website)

@tool
extends EditorScenePostImport

# we map the extras to a dictionary (both mesh and object customs get mapped)
var node_extras_dict = {}
func _post_import(scene):
	print("Blender-Godot Pipeline: Starting the post import process.")
	
	var source := get_source_file()
	
	# capture the GLTF file that gets generated using .blend file importing
	if ".blend" in source:
		var use_hidden: bool = ProjectSettings.get_setting("application/config/use_hidden_project_data_directory")
		
		var data_folder := "godot"
		if use_hidden: data_folder = ".godot"
		
		var imported_file := "res://"+data_folder+"/imported/" + source.get_file().replace(".blend", "") + "-" + source.md5_text() + ".gltf"
		source = imported_file

	# do a direct read of the GLTF file to parse some extra stuff
	var file = FileAccess.open(source, FileAccess.READ)
	var content = file.get_as_text()
	var data := JSON.parse_string(content)
	if data:
		parse_GLTF(data)
		iterate_scene(scene, scene)
	
	print("Blender-Godot Pipeline: Post import complete.")
	
	return scene

func parse_GLTF(json):
	# go through each node and find ones which references meshes
	if "nodes" in json:
		for node in json["nodes"]:
			if "mesh" in node:
				var mesh_index = node["mesh"]
				var mesh = json["meshes"][mesh_index]
				if "extras" in mesh:
					add_extras_to_dict(node["name"], mesh["extras"])
				
			if "extras" in node:
				add_extras_to_dict(node["name"], node["extras"])

func add_extras_to_dict(node_name, extras):
	var g_node_name = node_name.replace(".", "_")
	if g_node_name not in node_extras_dict:
		node_extras_dict[g_node_name] = {}
	for extra in extras:
		node_extras_dict[g_node_name][extra] = extras[extra]

func iterate_scene(node, root):
	if not node: return
	for child in node.get_children():
		iterate_scene(child, root)
	if (node.name in node_extras_dict) and (node is Node3D):
		print("IN IT %s" % node.name)
		var extras = node_extras_dict[node.name]
		# ONLY FOR DEBUG
		#print("Set extras for: " + node.name)
		if "classname" in extras:
			print("IT HAS CLASSNAME %s" % extras["classname"])
			var script: Script = Classes.classes.get(extras["classname"])
			if not script:
				print("IT HAS NOT THAT SCRIPT! %s" % Classes.classes)
				set_metadata(node, extras)
			else:
				var inst = ClassDB.instantiate(script.get_instance_base_type())
				inst.set_script(script)
				set_parameters(inst, extras)
				node.add_child(inst)
				inst.owner = root
				inst.name = "Hermano The FIrst"
				if node is MeshInstance3D:
					var col = node.mesh.create_trimesh_shape()
					var col_shape := CollisionShape3D.new()
					col_shape.shape = col
					inst.add_child(col_shape)
					col_shape.owner = root
					for i in node.mesh.get_surface_count():
						var mat = node.mesh.surface_get_material(i).resource_name
						print("MATERIAL NAME %s" % mat)
		else:
			set_metadata(node, extras)
func set_metadata(node, extras):
	for key in extras:
		#print(key + "=" + extras[key])
		node.set_meta(key, extras[key])


func set_parameters(node, extras):
	for key in extras:
		if key == "classname": continue
		node.set(key, extras[key])
		prints(key, ":",node.get(key))
