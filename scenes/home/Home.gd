extends Node2D

@onready var home_zone:     Area2D     = $HomeZone
@onready var campfire_light: PointLight2D = $CampfireLight

var _fire_energy_target := 1.8

func _ready() -> void:
	campfire_light.texture      = _fire_gradient()
	campfire_light.texture_scale = 5.5
	campfire_light.energy       = _fire_energy_target
	campfire_light.color        = Color(1.0, 0.58, 0.18)
	campfire_light.shadow_enabled = true

	home_zone.body_entered.connect(_on_body_entered)
	home_zone.body_exited.connect(_on_body_exited)

	_build_visual()

func _process(delta: float) -> void:
	# Subtle campfire flicker
	_fire_energy_target = randf_range(1.5, 2.1)
	campfire_light.energy = lerpf(campfire_light.energy, _fire_energy_target, delta * 6.0)

func _on_body_entered(body: Node2D) -> void:
	if body.has_method("set_at_home"):
		body.set_at_home(true)
		EventBus.player_entered_home.emit()

func _on_body_exited(body: Node2D) -> void:
	if body.has_method("set_at_home"):
		body.set_at_home(false)
		EventBus.player_left_home.emit()

func _build_visual() -> void:
	# Dirt clearing
	var clearing := Polygon2D.new()
	var pts := PackedVector2Array()
	for i in 20:
		var a := TAU * i / 20.0
		pts.append(Vector2(cos(a) * randf_range(88, 108), sin(a) * randf_range(88, 108)))
	clearing.polygon = pts
	clearing.color   = Color(0.30, 0.21, 0.11)
	clearing.z_index = -1
	add_child(clearing)

	# Cabin body
	var cabin := Polygon2D.new()
	cabin.polygon = PackedVector2Array([
		Vector2(-48, -38), Vector2(48, -38),
		Vector2(48,  36),  Vector2(-48, 36),
	])
	cabin.color = Color(0.42, 0.28, 0.16)
	add_child(cabin)

	# Cabin roof hint (darker top)
	var roof := Polygon2D.new()
	roof.polygon = PackedVector2Array([
		Vector2(-48, -38), Vector2(48, -38),
		Vector2(48, -26),  Vector2(-48, -26),
	])
	roof.color = Color(0.22, 0.14, 0.07)
	add_child(roof)

	# Door
	var door := Polygon2D.new()
	door.polygon = PackedVector2Array([
		Vector2(-13, 14), Vector2(13, 14),
		Vector2(13,  36), Vector2(-13, 36),
	])
	door.color = Color(0.20, 0.12, 0.06)
	add_child(door)

	# Campfire glow circle (visual only, light handled by PointLight2D)
	var fire := Polygon2D.new()
	var fpts := PackedVector2Array()
	for i in 10:
		var a := TAU * i / 10.0
		fpts.append(Vector2(cos(a) * 9.0, sin(a) * 9.0 + 58.0))
	fire.polygon = fpts
	fire.color   = Color(1.0, 0.55, 0.1)
	add_child(fire)

	# Log circle around fire
	var logs := Polygon2D.new()
	var lpts := PackedVector2Array()
	for i in 10:
		var a := TAU * i / 10.0
		lpts.append(Vector2(cos(a) * 15.0, sin(a) * 15.0 + 58.0))
	logs.polygon = lpts
	logs.color   = Color(0.28, 0.16, 0.06)
	logs.z_index = -1
	add_child(logs)

static func _fire_gradient() -> GradientTexture2D:
	var grad := Gradient.new()
	grad.colors  = PackedColorArray([Color(1.0, 0.65, 0.25, 1.0), Color(1.0, 0.45, 0.1, 0.0)])
	grad.offsets = PackedFloat32Array([0.0, 1.0])
	var tex := GradientTexture2D.new()
	tex.gradient  = grad
	tex.fill      = GradientTexture2D.FILL_RADIAL
	tex.fill_from = Vector2(0.5, 0.5)
	tex.fill_to   = Vector2(1.0, 0.5)
	tex.width     = 256
	tex.height    = 256
	return tex
