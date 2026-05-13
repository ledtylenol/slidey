extends StateMachine

func _ready() -> void:
	super()
	get_tree().current_scene.player_teleported.connect(func(): current_state.transition("idle"))
