extends Control
class_name UI
@export var fps_label: Label
@export var speed_label: Label
@export var coin_label: Label
@export var player: Player

var coin_tween: Tween
var current_menu: Node = null:
	set = set_current_menu
@export var coin_manager: CoinManager

func set_current_menu(m: Node) -> void:
	if not m:
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	else:
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	current_menu = m

func _ready() -> void:
	current_menu = null
	coin_manager.coin_collected.connect(update_coin_label)
	coin_label.pivot_offset_ratio = Vector2(0.5, 0.5)
func _input(event: InputEvent) -> void:
	if event.is_action("ui_cancel") and event.is_pressed():
		match Input.mouse_mode:
			Input.MOUSE_MODE_CAPTURED: Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
			Input.MOUSE_MODE_VISIBLE: Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
func _process(_delta: float) -> void:
	fps_label.text = "%s" % Engine.get_frames_per_second()
	speed_label.text = "%.2f" % player.velocity.length()

func update_coin_label() -> void:
	if coin_tween: coin_tween.kill()
	coin_tween = create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_ELASTIC)
	coin_tween.tween_property(coin_label, "scale:x", 1.0, 1.0).from(1.3 + coin_manager.heat / 10.0)
	coin_label.text = "%d" %  coin_manager.count
