extends Node
class_name MapGenerator

## Procedural map generator using two FastNoiseLite layers.
## Outputs tile data and tree positions for World.gd to consume.

# ── Constants (shared with World, EntitySpawner) ──────────────────────────────
const MAP_RADIUS := 64    # tiles from centre; full map = 128×128
const TILE_PX    := 64    # world pixels per tile

const T_GRASS := 0
const T_DIRT  := 1
const T_DEEP  := 2
const T_STONE := 3

# ── Noise ─────────────────────────────────────────────────────────────────────
var _terrain := FastNoiseLite.new()
var _detail  := FastNoiseLite.new()
var _tree    := FastNoiseLite.new()

func generate(seed_val: int) -> Dictionary:
	_terrain.seed        = seed_val
	_terrain.noise_type  = FastNoiseLite.TYPE_PERLIN
	_terrain.frequency   = 0.030

	_detail.seed         = seed_val + 7
	_detail.noise_type   = FastNoiseLite.TYPE_VALUE
	_detail.frequency    = 0.07

	_tree.seed           = seed_val + 13
	_tree.noise_type     = FastNoiseLite.TYPE_SIMPLEX_SMOOTH
	_tree.frequency      = 0.055

	var tiles := {}   # Vector2i → int (tile type)
	var trees := []   # Array[Vector2]  (world positions)

	for tx in range(-MAP_RADIUS, MAP_RADIUS + 1):
		for ty in range(-MAP_RADIUS, MAP_RADIUS + 1):
			var dist    := Vector2(tx, ty).length()
			var terrain := _terrain.get_noise_2d(tx, ty)   # [-1, 1]
			var detail  := _detail.get_noise_2d(tx, ty)
			var tree_n  := _tree.get_noise_2d(tx, ty)

			var tile_id := _pick_tile(dist, terrain, detail)
			tiles[Vector2i(tx, ty)] = tile_id

			if _wants_tree(dist, terrain, tree_n, tile_id):
				var jx := randf_range(-22.0, 22.0)
				var jy := randf_range(-22.0, 22.0)
				trees.append(Vector2(
					tx * MapGenerator.TILE_PX + MapGenerator.TILE_PX * 0.5 + jx,
					ty * MapGenerator.TILE_PX + MapGenerator.TILE_PX * 0.5 + jy
				))

	return { "tiles": tiles, "trees": trees }

# ── Tile selection ────────────────────────────────────────────────────────────

func _pick_tile(dist: float, terrain: float, detail: float) -> int:
	if dist <= 5.5:
		return T_DIRT   # home clearing always dirt

	# Rocky outcrops
	if terrain < -0.45 and detail < 0.1:
		return T_STONE

	# Blend: deeper into forest = more deep-forest tiles
	var depth_bias := clampf((dist - 6.0) / 22.0, 0.0, 1.0)
	var combined   := terrain + depth_bias * 0.55 + detail * 0.15

	if combined > 0.35:
		return T_DEEP
	elif combined > -0.15:
		return T_GRASS
	else:
		return T_DIRT

# ── Tree placement ────────────────────────────────────────────────────────────

func _wants_tree(dist: float, terrain: float, tree_n: float, tile_id: int) -> bool:
	if dist <= 6.5:
		return false
	if tile_id == T_STONE or tile_id == T_DIRT:
		return false

	var density   := clampf((dist - 6.5) / 18.0, 0.0, 1.0)
	var threshold := 0.58 - density * 0.38
	return (terrain * 0.4 + tree_n * 0.6) > threshold

# ── Static helpers ────────────────────────────────────────────────────────────

static func world_to_tile(world_pos: Vector2) -> Vector2i:
	return Vector2i(
		int(floor(world_pos.x / TILE_PX)),
		int(floor(world_pos.y / TILE_PX))
	)

static func tile_to_world_center(tile: Vector2i) -> Vector2:
	return Vector2(
		tile.x * TILE_PX + TILE_PX * 0.5,
		tile.y * TILE_PX + TILE_PX * 0.5
	)
