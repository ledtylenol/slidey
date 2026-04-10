extends Node
class_name CoinManager

static var count := 0
static var heat := 0.0

signal coin_collected
func _process(delta: float) -> void:
	heat = move_toward(heat, 0.0, delta * 2)

func coin(_c: Coin) -> void:
	count += 1
	heat += 0.4
	coin_collected.emit()
