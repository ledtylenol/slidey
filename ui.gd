extends Control
class_name UI

var current_menu: Node = null:
	set = set_current_menu


func set_current_menu(m: Node) -> void:
	if not m:
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	else:
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	current_menu = m

func _ready() -> void:
	current_menu = null

func _input(event: InputEvent) -> void:
	if event.is_action("ui_cancel") and event.is_pressed():
		match Input.mouse_mode:
			Input.MOUSE_MODE_CAPTURED: Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
			Input.MOUSE_MODE_VISIBLE: Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
