extends Area3D
class_name Coin
@onready var sound: RaytracedAudioPlayer3D = $RaytracedAudioPlayer3D
@onready var raycast: RayCast3D = $RayCast3D

@export var pitch_over_heat: Curve
var id := 0
var s := 1.0
func _ready() -> void:
	body_entered.connect(on_body)
	if randi() % 2 == 0:
		s = -1.0
	call_deferred("rotate_object_local", Vector3.UP ,(randf_range(-PI, PI)))
func _process(delta: float) -> void:
	rotate_object_local(Vector3.UP, PI * delta * s)
func _physics_process(_delta: float) -> void:
	if raycast.is_colliding():
		var p := raycast.get_collision_point()
		var n := raycast.get_collision_normal()
		var q := Quaternion(basis.y, n)
		position = p + n * 1.9
		quaternion = q * quaternion
func on_body(b: Node3D) -> void:
	if b is not Player: return
	get_tree().current_scene.coin_manager.coin(self)
	set_deferred("monitoring", false)
	visible = false
	sound.pitch_scale = pitch_over_heat.sample(CoinManager.heat)
	sound.play()
	sound.finished.connect(queue_free)
