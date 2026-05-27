extends CanvasLayer

@onready var health_bar:  ProgressBar = $Root/StatsPanel/Stats/HealthRow/HealthBar
@onready var stamina_bar: ProgressBar = $Root/StatsPanel/Stats/StaminaRow/StaminaBar
@onready var hunger_bar:  ProgressBar = $Root/StatsPanel/Stats/HungerRow/HungerBar
@onready var day_label:   Label       = $Root/DayLabel

func _ready() -> void:
	EventBus.stats_changed.connect(_on_stats_changed)
	EventBus.day_changed.connect(_on_day_changed)
	EventBus.phase_changed.connect(_on_phase_changed)
	_style_bars()

func _on_stats_changed(hp: float, st: float, hu: float,
					   max_hp: float, max_st: float, max_hu: float) -> void:
	health_bar.max_value  = max_hp
	health_bar.value      = hp
	stamina_bar.max_value = max_st
	stamina_bar.value     = st
	hunger_bar.max_value  = max_hu
	hunger_bar.value      = hu

func _on_day_changed(day: int) -> void:
	day_label.text = "Day %d" % day

func _on_phase_changed(phase_name: String) -> void:
	day_label.text = "Day %d  ·  %s" % [GameState.day_count, phase_name]

func _style_bars() -> void:
	_tint_bar(health_bar,  Color(0.80, 0.18, 0.18))
	_tint_bar(stamina_bar, Color(0.18, 0.55, 0.80))
	_tint_bar(hunger_bar,  Color(0.80, 0.60, 0.18))

static func _tint_bar(bar: ProgressBar, col: Color) -> void:
	var style := StyleBoxFlat.new()
	style.bg_color     = col
	style.corner_radius_top_left    = 3
	style.corner_radius_top_right   = 3
	style.corner_radius_bottom_left  = 3
	style.corner_radius_bottom_right = 3
	bar.add_theme_stylebox_override("fill", style)

	var bg := StyleBoxFlat.new()
	bg.bg_color = Color(0.08, 0.08, 0.08, 0.75)
	bg.corner_radius_top_left    = 3
	bg.corner_radius_top_right   = 3
	bg.corner_radius_bottom_left  = 3
	bg.corner_radius_bottom_right = 3
	bar.add_theme_stylebox_override("background", bg)
