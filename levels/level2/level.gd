extends Level
@onready var marker_3d: Marker3D = $Marker3D
@onready var marker_3d_2: Marker3D = $Marker3D2
@onready var area_3d: Area3D = $Area3D
@onready var back: SceneLoader = $Back
@onready var pop: AudioStreamPlayer = $Pop

func _ready() -> void:
	super()
	get_tree().current_scene.rotate_sun(marker_3d.quaternion, marker_3d_2.quaternion, 4.0)
	area_3d.body_entered.connect(change_level.bind("tunnel"))
	pop.play()
func change_level(_n, path: String) -> void:
	back.try_load(path)
