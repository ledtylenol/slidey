extends Node
class_name CommandManager
@export var game: Game

func _ready() -> void:
	Console.add_command("goto", goto, ["marker name"], 1, "Teleports to the marker's transform")
	Console.add_command("list_markers", list_markers, [],  0, "Lists all markers")
	Console.pause_enabled = true
func goto(_name: String) -> void:
	if not game.tpmarkers.has(_name):
		Console.print_info("%s could not be found" % _name)
	else:
		game.teleport_player(game.tpmarkers[_name])

func list_markers() -> void:
	for marker in game.tpmarkers.keys():
		Console.print_line("\"%s\"" % marker)
	if game.tpmarkers.is_empty():
		Console.print_info("There are no markers")
