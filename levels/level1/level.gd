extends Level
@onready var gpu_particles_3d: GPUParticles3D = $GPUParticles3D
@onready var rotate_area: Area3D = $RotateArea
@export var pop: AudioStreamPlayer
@export var level_area: Area3D
@export var sc_l: SceneLoader
func _ready() -> void:
	super()
	rotate_area.body_entered.connect(bbb)
	get_tree().current_scene.reset.connect(reset)
	level_area.body_entered.connect(change_level.bind("tunnel"))
func bbb(_b: Node3D) -> void:
	gpu_particles_3d.emitting = false

func reset(id: int) -> void:
	if id != 0: return
	gpu_particles_3d.emitting = true
func pop_player() -> void:
	super()
	pop.play()

func change_level(_n, path: String) -> void:
	sc_l.try_load(path)
