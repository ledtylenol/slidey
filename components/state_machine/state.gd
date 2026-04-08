@abstract
extends Node
class_name State

@abstract func on_enter() -> void
@abstract func on_exit() -> void

@abstract func tick(_delta: float) -> void
@abstract func physics_tick(_delta: float) -> void

signal transitioned(from: String, to: String)

func transition(to: String) -> void:
	transitioned.emit(self.name.to_lower(), to)
