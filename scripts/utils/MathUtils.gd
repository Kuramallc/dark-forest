class_name MathUtils

static func world_to_tile(world_pos: Vector2, tile_size: int) -> Vector2i:
	return Vector2i(
		int(floor(world_pos.x / tile_size)),
		int(floor(world_pos.y / tile_size))
	)

static func tile_to_world_center(tile: Vector2i, tile_size: int) -> Vector2:
	return Vector2(tile.x * tile_size + tile_size * 0.5,
				   tile.y * tile_size + tile_size * 0.5)

static func dist_tiles(a: Vector2i, b: Vector2i) -> float:
	return Vector2(a).distance_to(Vector2(b))

## Shared radial gradient texture used by torch, campfire, item glows etc.
static func radial_gradient(inner: Color, outer: Color, size: int = 256) -> GradientTexture2D:
	var grad     := Gradient.new()
	grad.colors   = PackedColorArray([inner, outer])
	grad.offsets  = PackedFloat32Array([0.0, 1.0])
	var tex       := GradientTexture2D.new()
	tex.gradient   = grad
	tex.fill       = GradientTexture2D.FILL_RADIAL
	tex.fill_from  = Vector2(0.5, 0.5)
	tex.fill_to    = Vector2(1.0, 0.5)
	tex.width      = size
	tex.height     = size
	return tex
