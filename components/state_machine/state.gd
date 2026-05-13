@abstract
extends Node
class_name State

func on_enter() -> void:
	pass
func on_exit() -> void:
	pass

func tick(_delta: float) -> void:
	pass
func physics_tick(_delta: float) -> void:
	pass

signal transitioned(from: String, to: String)

func transition(to: String) -> void:
	transitioned.emit(self.name.to_lower(), to)
