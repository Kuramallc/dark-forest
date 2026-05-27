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
