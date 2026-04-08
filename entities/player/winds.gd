extends Node3D
class_name Winds
@onready var light_woosh: RaytracedAudioPlayer3D = $LightWoosh
@onready var medium_woosh: RaytracedAudioPlayer3D = $MediumWoosh
@onready var hard_woosh: RaytracedAudioPlayer3D = $HardWoosh
@export var player: Player
@export_category("Curves")
@export var light: Curve
@export var medium: Curve
@export var hard: Curve

var real_val: float
var relative := 0.0
func _ready() -> void:
	light_woosh.play()
	medium_woosh.play()
	hard_woosh.play()

func _physics_process(delta: float) -> void:
	var xz := player.velocity.slide(player.up).length()
	var vel := player.velocity.dot(player.up)
	vel = 0.3 * xz + 0.7 * vel
	real_val = vel
	relative = M.smooth_nudgef(relative, real_val, 5.0, delta)
	light_woosh.volume_db = linear_to_db(light.sample(relative))
	medium_woosh.volume_db = linear_to_db(medium.sample(relative))
	hard_woosh.volume_db = linear_to_db(hard.sample(relative))
