extends Area2D
class_name GroundItem

## A pickup item lying on the ground.
## Player presses [E] when nearby to collect it.

var item_id  := ""
var quantity := 1

var _player_nearby := false
var _glow: PointLight2D

# Colour coding by category
const ITEM_COLORS := {
	"wood":         Color(0.55, 0.35, 0.12),
	"stone":        Color(0.65, 0.65, 0.65),
	"iron_ore":     Color(0.60, 0.45, 0.30),
	"berries":      Color(0.85, 0.18, 0.22),
	"mushroom":     Color(0.75, 0.62, 0.20),
	"healing_herb": Color(0.20, 0.82, 0.32),
	"iron_ore":     Color(0.70, 0.50, 0.30),
	"shadow_gem":   Color(0.45, 0.10, 0.75),
}
const DEFAULT_COLOR := Color(0.80, 0.80, 0.80)

func setup(id: String, qty: int) -> void:
	item_id  = id
	quantity = qty
	_build_visual()

func _ready() -> void:
	collision_layer = 8
	collision_mask  = 1   # detect player (layer 1)
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)

func _process(_delta: float) -> void:
	if _player_nearby and Input.is_action_just_pressed("interact"):
		_pickup()

func _pickup() -> void:
	GameState.add_resource(item_id, quantity)
	# Brief flash before freeing
	var tween := create_tween()
	tween.tween_property(self, "modulate", Color(2, 2, 2, 0), 0.15)
	tween.tween_callback(queue_free)

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		_player_nearby = true
		if _glow:
			_glow.energy = 2.5   # pulse brighter when player is near

func _on_body_exited(body: Node2D) -> void:
	if body.is_in_group("player"):
		_player_nearby = false
		if _glow:
			_glow.energy = 1.0

func _build_visual() -> void:
	var col := ITEM_COLORS.get(item_id, DEFAULT_COLOR)

	# Outer ring
	var ring := Polygon2D.new()
	var rpts := PackedVector2Array()
	for i in 10:
		var a := TAU * i / 10.0
		rpts.append(Vector2(cos(a) * 10.0, sin(a) * 10.0))
	ring.polygon = rpts
	ring.color   = col.darkened(0.4)
	add_child(ring)

	# Inner dot
	var dot  := Polygon2D.new()
	var dpts := PackedVector2Array()
	for i in 10:
		var a := TAU * i / 10.0
		dpts.append(Vector2(cos(a) * 6.0, sin(a) * 6.0))
	dot.polygon = dpts
	dot.color   = col
	add_child(dot)

	# Item label (shows above dot)
	var label       := Label.new()
	var item_data   := ItemDB.get_item(item_id)
	label.text      = item_data.get("name", item_id)
	label.position  = Vector2(-24, -22)
	label.add_theme_font_size_override("font_size", 9)
	label.modulate  = Color(1, 1, 1, 0.85)
	add_child(label)

	# Soft glow (PointLight2D)
	_glow = PointLight2D.new()
	_glow.texture       = _radial_gradient(col.lightened(0.3), Color(col.r, col.g, col.b, 0))
	_glow.texture_scale = 0.6
	_glow.energy        = 1.0
	_glow.color         = col
	add_child(_glow)

	# Collision shape
	var cshape := CollisionShape2D.new()
	var circle := CircleShape2D.new()
	circle.radius  = 20.0
	cshape.shape   = circle
	add_child(cshape)

static func _radial_gradient(inner: Color, outer: Color) -> GradientTexture2D:
	var grad := Gradient.new()
	grad.colors  = PackedColorArray([inner, outer])
	grad.offsets = PackedFloat32Array([0.0, 1.0])
	var tex      := GradientTexture2D.new()
	tex.gradient  = grad
	tex.fill      = GradientTexture2D.FILL_RADIAL
	tex.fill_from = Vector2(0.5, 0.5)
	tex.fill_to   = Vector2(1.0, 0.5)
	tex.width     = 128
	tex.height    = 128
	return tex
