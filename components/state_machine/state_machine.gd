extends Node
class_name StateMachine

@export var initial_state: State

var current_state: State
var states: Dictionary[String, State]
func _ready() -> void:
	for child in get_children():
		if child is State:
			states[child.name.to_lower()] = child
			child.transitioned.connect(transition)
	current_state = initial_state
	get_tree().current_scene.player_teleported.connect(func(): current_state.transition("idle"))
func tick(delta: float) -> void:
	if current_state:
		current_state.tick(delta)

func physics_tick(delta: float) -> void:
	if current_state:
		current_state.physics_tick(delta)

func transition(f: String, t: String) -> void:
	var from: State = states.get(f.to_lower())
	if not from:
		print("could not find %s" % f)
		return
	var to: State = states.get(t.to_lower())
	if not to:
		print("could not find %s" % t)
		return

	if from != current_state: return
	
	from.on_exit()
	current_state = to
	to.on_enter()
