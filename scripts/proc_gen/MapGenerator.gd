extends Node
class_name MapGenerator

# Phase 2: Full procedural generation using FastNoiseLite.
# Phase 1 uses the hand-drawn test map in World.gd directly.
#
# Planned API:
#   generate(seed: int) -> Dictionary   { "tiles": Array2D, "entities": Array }
