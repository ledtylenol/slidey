@tool
extends Camera3D
class_name PlayerCamera

@export var pan_node: Node3D
@export var roll_node: Node3D
@export var arm: Node3D
@export var rot_node: Node3D
@export var player: Player
@export var sensitivity := 7.0

@export var zoom := 1.0:
	set(v):
		zoom = clampf(v, 0.5, 2.0)
@export var starting_arm_dist := 5.0
@export var rotation_easing_coefficient := 5.0
@export var rotation_easing_coefficient_fast := 5.0
@export var fast_rotation_angle_limit := PI/7
@export var speed_curve: Curve
@export var listener: RaytracedAudioListener
var real_zoom := zoom
var target_fov := 90.0:
	set = set_target_fov
var tween: Tween
var old_up := Vector3.UP
var time_moving := 0.0
func _ready() -> void:
	if Engine.is_editor_hint():return
	get_tree().current_scene.player_teleported.connect(reset_pos)
	old_up = player.up
func _unhandled_input(event: InputEvent) -> void:
	if Engine.is_editor_hint(): return
	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		pan_node.rotate_object_local(Vector3.UP, - event.relative.x * sensitivity / 4000.0)
		roll_node.rotate_object_local(Vector3.UP, - event.relative.x * sensitivity / 4000.0)
		arm.rotation.x -= event.relative.y * sensitivity / 4000.0
		var diff = PI / 2
		arm.rotation.x = clamp(arm.rotation.x, -diff + 0.0001, diff - 0.0001)

	if event is InputEventMouseButton and event.is_pressed():
		match event.button_index:
			MOUSE_BUTTON_WHEEL_DOWN:
				zoom += 0.1
			MOUSE_BUTTON_WHEEL_UP:
				zoom -= 0.1
func _physics_process(delta: float) -> void:
	if Engine.is_editor_hint(): return
	old_up = M.slerp_normal(old_up, player.up, delta, 25.0)
	if rot_node.quaternion.angle_to(player.quaternion) > fast_rotation_angle_limit:
		rot_node.quaternion = M.slerpq_normal(rot_node.quaternion, player.quaternion, delta, rotation_easing_coefficient_fast)
	else:
		rot_node.quaternion = M.slerpq_normal(rot_node.quaternion, player.quaternion, delta, rotation_easing_coefficient)
	#rot_node.quaternion = player.quaternion
	var proj = player.position.project(old_up)
	var sproj = rot_node.position.project(old_up)
	var speed := speed_curve.sample(proj.distance_to(sproj))
	rot_node.position = player.position.slide(old_up) + M.smooth_nudgev(sproj, proj, speed, delta) 

	real_zoom = M.smooth_nudgef(real_zoom, zoom, 10.0, delta)
	arm.spring_length = real_zoom * starting_arm_dist

func set_target_fov(v: float) -> void:
	target_fov = v
	if tween: tween.kill()
	tween = create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_EXPO)
	tween.tween_property(self, "fov", target_fov, 3.5)

func reset_pos() -> void:
	rot_node.position = player.position 
	rot_node.quaternion = player.quaternion
	reset_physics_interpolation()

func _process(delta: float) -> void:
	if Engine.is_editor_hint(): return
	var ax := -Input.get_vector("lleft", "lright", "lback", "lforward") * delta * sensitivity
	if not ax.is_zero_approx():
		time_moving += delta
		if time_moving < 1.0:
			ax /= 2.0
		pan_node.rotate_object_local(Vector3.UP, ax.x)
		roll_node.rotate_object_local(Vector3.UP, ax.x)
		arm.rotation.x -= ax.y
		var diff = PI / 2
		arm.rotation.x = clamp(arm.rotation.x, -diff + 0.0001, diff - 0.0001)
	else:
		time_moving = 0.0
