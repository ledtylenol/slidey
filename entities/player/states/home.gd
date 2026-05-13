extends PlayerState
class_name PlayerHomeState

@export var hitbox: HitBox3D
@export var home_speed := 150.0
@export var manager: MeshSpinManager
@export var mesh: PlayerMesh
@export var minvel := 40.0
@export var home_timer: Timer
@export var sound: RaytracedAudioPlayer3D
var startvel := 0.0
var target: Node3D
var active := false
func on_enter() -> void:
	hitbox.ignore_collisions = false
	hitbox.hurt_box_entered.connect(on_hurtbox)
	startvel = maxf(velocity.length(), minvel)
	manager.start(1)
	manager.get_next_state()
	active = true
	target = player.target
	player.target = null
	player.initiated_float = false
	sound.play()
func on_exit() -> void:
	hitbox.ignore_collisions = true
	hitbox.hurt_box_entered.disconnect(on_hurtbox)
	home_timer.start()
	manager.stop()
func tick(delta: float) -> void:
	manager.tick(delta)
func physics_tick(delta: float) -> void:
	player.check_inputs()
	player.check_grounded(delta)
	if not target:
		if grounded:
			if player.direction: 
				transition("move")
			else:
				transition("stop")
		else:
			player.air_jump()
			transition("fall")
		return
	velocity = player.global_position.direction_to(target.global_position) * home_speed
	mesh.face_z(-velocity.normalized())
	player.move(delta)
	manager.physics_tick(delta)
func on_hurtbox(hurtbox: HurtBox3D) -> void:
	if hurtbox != target:
		return
	player.up = hurtbox.global_basis.y
	player.air_jump()
	var influence := 1.0
	if hurtbox.owner is EntityStub:
		influence = hurtbox.owner.speed_influence
	
		velocity = velocity.project(up) * hurtbox.owner.dir_sign + velocity.slide(up).normalized() * startvel * influence + hurtbox.owner.dir_sign * up * (1.0 - influence) * startvel
	else:
		velocity = velocity.project(up) + velocity.slide(up).normalized() * startvel 
	mesh.on_hit()
	hitbox.ignore_collisions = true
	player.flew = false
	player.hover_time = player.float_time_base
	if grounded:
		if player.direction: 
			transition("move")
		else:
			transition("stop")
	else:
		transition("fall")
