extends State
class_name BaseStubState

@export var model: Node3D
@export var ring1: Node3D
@export var ring2: Node3D
@export var health: Health
@export var hurtbox: HurtBox3D
@export var spin_over_dist: Curve
@export var scale_over_dist: Curve
@export var reform_sound: RaytracedAudioPlayer3D
var player: Player
var tween: Tween
var vel_mul := 1.0
func on_enter() -> void:
	health.damaged.connect(damage.unbind(6))
	get_tree().current_scene.just_reset.connect(on_reset)
	player = get_tree().current_scene.player
func tick(delta: float) -> void:
	var dist := player.position.distance_to(owner.position)
	var spd := spin_over_dist.sample(dist) * PI * delta * vel_mul
	var sc := Vector3.ONE * scale_over_dist.sample(dist)
	ring1.scale = sc
	model.rotate_x(spd / 10)
	model.rotate_z(spd / 10)
	ring1.rotate_y(-spd)
	ring2.rotate_x(-spd / 3)
	ring2.rotate_z(-spd)
	#hurtbox.set_deferred("monitorable", dist > 3 or player.target == hurtbox and not health.is_dead())
	#hurtbox.set_deferred("monitoring", dist > 3 or player.target == hurtbox and not health.is_dead())
func damage() -> void:
	if not owner.one_shot:
		tween_start()
func on_reset() -> void:
	if tween: tween.kill()
	health.fill()
	model.scale = Vector3.ONE
	model.transparency = 0.0

func tween_start() -> void:
	if tween: tween.kill()
	tween = create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_ELASTIC)
	tween.tween_property(model, "scale", Vector3.ONE * 0.4, 0.4)
	tween.parallel().tween_property(self, "vel_mul", 0.1, 0.4)
	tween.tween_callback(reform_sound.play)
	tween.tween_callback(health.fill)
	tween.tween_property(model, "scale", Vector3.ONE, 1.0)
	tween.parallel().tween_property(self, "vel_mul", 1.0, 1.0)
