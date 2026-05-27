extends Node

# Phase 3 will populate this fully.
# Stub definitions so the rest of the game can reference item IDs safely.

const ITEMS := {
	"wood":         { "name": "Wood",          "max_stack": 99, "rarity": "common"   },
	"stone":        { "name": "Stone",         "max_stack": 99, "rarity": "common"   },
	"iron_ore":     { "name": "Iron Ore",      "max_stack": 50, "rarity": "uncommon" },
	"berries":      { "name": "Berries",       "max_stack": 30, "rarity": "common"   },
	"mushroom":     { "name": "Mushroom",      "max_stack": 20, "rarity": "common"   },
	"raw_meat":     { "name": "Raw Meat",      "max_stack": 10, "rarity": "common"   },
	"cooked_meat":  { "name": "Cooked Meat",   "max_stack": 10, "rarity": "common"   },
	"healing_herb": { "name": "Healing Herb",  "max_stack": 15, "rarity": "uncommon" },
	"shadow_gem":   { "name": "Shadow Gem",    "max_stack": 5,  "rarity": "rare"     },
	"hunting_knife":{ "name": "Hunting Knife", "max_stack": 1,  "rarity": "common"   },
}

func get_item(id: String) -> Dictionary:
	return ITEMS.get(id, {})

func exists(id: String) -> bool:
	return ITEMS.has(id)
