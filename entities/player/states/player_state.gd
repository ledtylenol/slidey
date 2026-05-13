@abstract
extends State
class_name PlayerState

var up: Vector3:
	get:
		return player.up

var velocity: Vector3:
	get:
		return player.velocity
	set(v):
		player.velocity = v
var horizontal_speed: float:
	get:
		return player.horizontal_speed
	set(v):
		player.horizontal_speed = v

var grounded: bool:
	get:
		return player.grounded
@export var player: Player = owner
@export var target_fov := 90.0
