extends CharacterBody2D

# ── Base stats ──────────────────────────────────────────────────────────────
var max_health    := 100.0
var health        := 100.0
var max_stamina   := 100.0
var stamina       := 100.0
var max_hunger    := 100.0
var hunger        := 100.0

# ── Movement ─────────────────────────────────────────────────────────────────
var base_speed          := 160.0
var sprint_multiplier   := 1.8
var stamina_drain_rate  := 22.0   # per second while sprinting
var stamina_regen_rate  := 12.0   # per second while not sprinting
var hunger_drain_rate   :=  0.5   # per second
var hunger_damage_rate  :=  2.0   # health lost per second when starving

# ── Upgradeable ───────────────────────────────────────────────────────────────
var movement_speed_bonus := 0.0
var sight_radius         := 200.0  # pixels

# ── State ─────────────────────────────────────────────────────────────────────
var is_at_home   := false
var is_sprinting := false

@onready var torch:  PointLight2D = $Torch
@onready var cam:    Camera2D     = $Camera2D
@onready var visual: Node2D       = $PlayerVisual

var _sprite: Polygon2D

func _ready() -> void:
	_build_visual()
	torch.texture       = _radial_gradient(Color(1.0, 0.85, 0.55, 1), Color(1.0, 0.85, 0.55, 0))
	torch.texture_scale = sight_radius / 50.0
	torch.shadow_enabled = true
	torch.shadow_filter  = 1

	EventBus.player_entered_home.connect(func() -> void: set_at_home(true))
	EventBus.player_left_home.connect(func()    -> void: set_at_home(false))

func _physics_process(delta: float) -> void:
	_handle_movement(delta)
	_tick_survival(delta)

func _handle_movement(delta: float) -> void:
	var dir := Vector2.ZERO
	if Input.is_action_pressed("move_up"):    dir.y -= 1
	if Input.is_action_pressed("move_down"):  dir.y += 1
	if Input.is_action_pressed("move_left"):  dir.x -= 1
	if Input.is_action_pressed("move_right"): dir.x += 1

	is_sprinting = Input.is_action_pressed("sprint") and stamina > 0

	var speed := (base_speed + movement_speed_bonus) * (sprint_multiplier if is_sprinting else 1.0)

	if dir != Vector2.ZERO:
		dir = dir.normalized()
		velocity = dir * speed
		visual.rotation = dir.angle()
	else:
		velocity = velocity.move_toward(Vector2.ZERO, speed * 10.0 * delta)

	move_and_slide()

func _tick_survival(delta: float) -> void:
	# Stamina
	if is_sprinting and velocity.length() > 20.0:
		stamina = maxf(0.0, stamina - stamina_drain_rate * delta)
	else:
		stamina = minf(max_stamina, stamina + stamina_regen_rate * delta)

	# Hunger & home healing
	if is_at_home:
		health = minf(max_health, health + 5.0 * delta)
	else:
		hunger = maxf(0.0, hunger - hunger_drain_rate * delta)
		if hunger <= 0.0:
			take_damage(hunger_damage_rate * delta)

	EventBus.stats_changed.emit(health, stamina, hunger, max_health, max_stamina, max_hunger)

func take_damage(amount: float) -> void:
	health = maxf(0.0, health - amount)
	if health <= 0.0:
		_die()

func heal(amount: float) -> void:
	health = minf(max_health, health + amount)

func set_at_home(value: bool) -> void:
	is_at_home      = value
	torch.energy    = 0.6 if value else 1.5

func upgrade_sight(bonus_px: float) -> void:
	sight_radius   += bonus_px
	torch.texture_scale = sight_radius / 50.0

func upgrade_speed(bonus: float) -> void:
	movement_speed_bonus += bonus

func upgrade_health(bonus: float) -> void:
	max_health += bonus
	health = minf(health, max_health)

func upgrade_stamina(bonus: float) -> void:
	max_stamina += bonus

func _die() -> void:
	EventBus.player_died.emit()
	set_physics_process(false)

# ── Visuals ───────────────────────────────────────────────────────────────────
func _build_visual() -> void:
	# Arrow shape — "forward" along +X so rotation = dir.angle() just works
	_sprite = Polygon2D.new()
	_sprite.polygon = PackedVector2Array([
		Vector2( 18,   0),   # nose
		Vector2(-10, -13),   # left wing
		Vector2( -4,   0),   # tail notch
		Vector2(-10,  13),   # right wing
	])
	_sprite.color = Color(0.72, 0.56, 0.36)
	visual.add_child(_sprite)

	# Dark outline (slightly larger, drawn first)
	var outline := Polygon2D.new()
	outline.polygon = PackedVector2Array([
		Vector2( 21,   0),
		Vector2(-13, -16),
		Vector2( -6,   0),
		Vector2(-13,  16),
	])
	outline.color = Color(0.12, 0.08, 0.04)
	outline.z_index = -1
	visual.add_child(outline)

# ── Helpers ───────────────────────────────────────────────────────────────────
static func _radial_gradient(inner: Color, outer: Color) -> GradientTexture2D:
	var grad := Gradient.new()
	grad.colors  = PackedColorArray([inner, outer])
	grad.offsets = PackedFloat32Array([0.0, 1.0])
	var tex := GradientTexture2D.new()
	tex.gradient  = grad
	tex.fill      = GradientTexture2D.FILL_RADIAL
	tex.fill_from = Vector2(0.5, 0.5)
	tex.fill_to   = Vector2(1.0, 0.5)
	tex.width     = 256
	tex.height    = 256
	return tex
