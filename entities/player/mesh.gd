extends MeshInstance3D
class_name PlayerMesh
var tween: Tween
@export var player: Player
@export var scale_root: Node3D
func _ready() -> void:
	player.landed.connect(on_landing)
func on_landing(vel: Vector3) -> void:
	var spd := vel.dot(-player.up)
	if spd < 10.0: return
	if tween:
		tween.kill()
	tween = create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_EXPO)
	tween.tween_property(scale_root, "scale", Vector3.ONE, 0.6).from(Vector3(1.2, 0.89, 1.2))
func on_ground_left() -> void:
	if tween:
		tween.kill()
	tween = create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_EXPO)
	tween.tween_property(scale_root, "scale", Vector3.ONE, 0.6).from(Vector3(.89, 1.1, 1.1))

func stop() -> void:
	if tween:
		tween.kill()
	tween = create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_EXPO)
	tween.tween_property(scale_root, "scale", Vector3(1.0, 1.2, 0.7), 1.1)
	tween.tween_property(scale_root, "scale", Vector3.ONE, 1.5).set_trans(Tween.TRANS_ELASTIC)
func reset_size() -> void:
	if tween:
		tween.kill()
	tween = create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_EXPO)
	tween.tween_property(scale_root, "scale", Vector3.ONE, 1.1)
