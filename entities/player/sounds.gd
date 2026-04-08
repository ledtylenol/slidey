extends Node3D

@export var player: Player

var d_travelled := 0.0
@export var d_to_sound_over_velocity: Curve

@export var footstep: RaytracedAudioPlayer3D
@export var impact: RaytracedAudioPlayer3D
@export var impact_over_velocity: Curve
func _ready() -> void:
	player.landed.connect(land)
func _physics_process(delta: float) -> void:
	if not player.grounded: return
	var pl := player.velocity.slide(player.up).length()
	var d := pl * delta
	d_travelled += d
	if d_travelled > d_to_sound_over_velocity.sample(pl):
		footstep.play()
		d_travelled = 0.0
	if is_zero_approx(d):
		d_travelled = 0.0

func land(vel: Vector3) -> void:
	var spd := vel.dot(-player.up)
	if spd < 10.0: return
	impact.volume_linear = impact_over_velocity.sample(spd)
	impact.play()
