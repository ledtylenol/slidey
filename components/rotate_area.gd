extends Area3D
@export var target: Node3D
@export var env_target: Node3D
@export var id := 0
func _ready() -> void:
	body_entered.connect(on_body_enter)
	get_tree().current_scene.reset.connect(reset)
func on_body_enter(n: Node3D) -> void:
	if n is not Player: return
	get_tree().current_scene.rotate_sun(target.quaternion, env_target.quaternion)
	set_deferred("monitoring", false)

func reset(_id: int) -> void:
	if id != _id: return
	set_deferred("monitoring", true)
