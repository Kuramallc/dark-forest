extends Node2D
class_name FogOfWar

## Fog-of-War overlay.
## Uses a 128×128 R8 ImageTexture (one texel = one world tile).
## The shader handles both the "currently visible" transparent ring and
## the "explored memory" dim overlay.  PointLight2D does NOT illuminate
## this sprite (light_mask = 0 + render_mode unshaded in shader).

const MAP_TILES := 128        # must equal MapGenerator.MAP_RADIUS * 2
const TILE_PX   := 64         # pixels per tile — must match World / MapGenerator
const FOG_REVEAL_MULT := 1.6  # fog reveal radius = sight_radius * this

var _player:    Node2D
var _sprite:    Sprite2D
var _mat:       ShaderMaterial
var _fog_image: Image
var fog_tex:    ImageTexture   # public — minimap shader reads this directly
var _dirty:     bool = false

# Cached last-reveal position to avoid redundant updates
var _last_reveal_px := Vector2i(-9999, -9999)

func _ready() -> void:
	_fog_image = Image.create(MAP_TILES, MAP_TILES, false, Image.FORMAT_R8)
	_fog_image.fill(Color(0, 0, 0, 1))   # start fully hidden
	fog_tex = ImageTexture.create_from_image(_fog_image)

	var shader := load("res://shaders/fog_of_war.gdshader") as Shader
	_mat = ShaderMaterial.new()
	_mat.shader = shader
	_mat.set_shader_parameter("fog_tex",      fog_tex)
	_mat.set_shader_parameter("player_uv",    Vector2(0.5, 0.5))
	_mat.set_shader_parameter("vision_uv",    0.035)
	_mat.set_shader_parameter("memory_alpha", 0.72)

	_sprite = Sprite2D.new()
	_sprite.texture    = _fog_tex
	_sprite.material   = _mat
	_sprite.scale      = Vector2(TILE_PX, TILE_PX)   # each texel = one tile
	_sprite.z_index    = 100
	_sprite.light_mask = 0   # not illuminated by any PointLight2D
	add_child(_sprite)

func setup(player: Node2D) -> void:
	_player = player

func _process(_delta: float) -> void:
	if not _player:
		return

	var player_uv := _world_to_uv(_player.global_position)
	_mat.set_shader_parameter("player_uv", player_uv)

	# Sight radius → UV units
	var sight_px: float = 200.0
	if _player.has_method("get") :
		sight_px = _player.get("sight_radius") if _player.get("sight_radius") != null else 200.0
	var total_px := float(MAP_TILES * TILE_PX)
	_mat.set_shader_parameter("vision_uv", sight_px / total_px)

	# Reveal fog around player
	var px := _world_to_pixel(_player.global_position)
	if px != _last_reveal_px:
		_last_reveal_px = px
		var reveal_tiles := int(ceil(sight_px * FOG_REVEAL_MULT / TILE_PX))
		_reveal(px, reveal_tiles)

	if _dirty:
		fog_tex.update(_fog_image)
		_dirty = false

# ── Fog helpers ───────────────────────────────────────────────────────────────

func _reveal(center: Vector2i, radius: int) -> void:
	for dx in range(-radius, radius + 1):
		for dy in range(-radius, radius + 1):
			if Vector2(dx, dy).length() <= radius + 0.5:
				var px := center.x + dx
				var py := center.y + dy
				if px >= 0 and px < MAP_TILES and py >= 0 and py < MAP_TILES:
					if _fog_image.get_pixel(px, py).r < 0.9:
						_fog_image.set_pixel(px, py, Color(1, 1, 1))
						_dirty = true

func _world_to_pixel(world_pos: Vector2) -> Vector2i:
	# World runs from -(MAP_TILES/2)*TILE_PX to +(MAP_TILES/2)*TILE_PX
	var half := MAP_TILES * TILE_PX * 0.5
	return Vector2i(
		clampi(int((world_pos.x + half) / TILE_PX), 0, MAP_TILES - 1),
		clampi(int((world_pos.y + half) / TILE_PX), 0, MAP_TILES - 1)
	)

func _world_to_uv(world_pos: Vector2) -> Vector2:
	var px := _world_to_pixel(world_pos)
	return Vector2(
		(float(px.x) + 0.5) / MAP_TILES,
		(float(px.y) + 0.5) / MAP_TILES
	)
