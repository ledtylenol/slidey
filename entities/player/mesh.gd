extends MeshInstance3D
class_name PlayerMesh
var tween: Tween
@export var player: Player
@export var scale_root: Node3D
@export var pos_root: Node3D
var quat: Quaternion
var rot := 0.0
func _ready() -> void:
	player.landed.connect(on_landing)
	get_tree().current_scene.just_reset.connect(tween_reset)
	get_tree().current_scene.player_teleported.connect(reset_pos)

func on_landing(vel: Vector3) -> void:
	rot = 0.0
	var spd := vel.dot(-player.up)
	var displace := scale_root.scale if spd < 10.0 else Vector3(1.2, 0.89, 1.2)
	if tween:
		tween.kill()
	tween = create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_EXPO)
	tween.tween_property(scale_root, "scale", Vector3.ONE, 0.6).from(displace)
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

func tween_reset() -> void:
	if tween:
		tween.kill()
	tween = create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_ELASTIC)
	var r := randf_range(0.4, 1.5)
	tween.tween_property(scale_root, "scale", Vector3.ONE, 1.1).from(Vector3(r, 1 / r, r))

func _physics_process(_delta: float) -> void:
	pos_root.position = player.position - player.basis.y
	var velocity := player.velocity
	var up := player.up
	var q: Quaternion
	if velocity.slide(up).length() > 0.2:
		q = Quaternion(-pos_root.basis.z,velocity.slide(up))
		pos_root.quaternion = q * pos_root.quaternion
	q = Quaternion(pos_root.basis.y,player.basis.y)

	pos_root.quaternion = q * pos_root.quaternion
func reset_pos() -> void:
	pos_root.position = player.position - player.basis.y
	reset_physics_interpolation()
