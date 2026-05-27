extends Node

var day_count := 1
var total_xp := 0
var resources_gathered: Dictionary = {}

var upgrades := {
	"health":  0,
	"speed":   0,
	"sight":   0,
	"reload":  0,
	"stamina": 0,
}

func _ready() -> void:
	EventBus.day_changed.connect(func(d: int) -> void: day_count = d)
	EventBus.xp_gained.connect(func(amount: int) -> void: total_xp += amount)

func add_resource(id: String, qty: int) -> void:
	resources_gathered[id] = resources_gathered.get(id, 0) + qty
	EventBus.item_picked_up.emit(id, qty)
