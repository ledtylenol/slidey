extends Node3D
@onready var gpu_particles_3d: GPUParticles3D = $GPUParticles3D
@onready var rotate_area: Area3D = $RotateArea

func _ready() -> void:
	rotate_area.body_entered.connect(bbb)
	get_tree().current_scene.reset.connect(reset)
func bbb(_b: Node3D) -> void:
	gpu_particles_3d.emitting = false

func reset(id: int) -> void:
	if id != 0: return
	gpu_particles_3d.emitting = true
