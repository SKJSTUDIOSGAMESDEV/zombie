extends Node

# 1. Signal banayein jo UI ko update karne ke liye use hoga
signal inventory_updated 

# 2. Aapki banayi hui Item dictionary
var Item1 = {
	"ammo": {"name": "",  "icon": preload("res://icon.svg"), "much": 0, "has_i": false },
	"medkit": {"name": "", "icon": preload("res://icons/Medkit.png"),"much": 0, "has_i": false},
	"Corn": {"name": "", "icon": preload("res://icons/Corn.png"), "much": 0, "has_i": false},
	"carrot": {"name": "", "icon": preload("res://icons/carrot.png"), "much": 0, "has_i": false},
	"egg": {"name": "", "icon": preload("res://icons/egg.png"), "much": 0, "has_i": false},
	"apple": {"name": "", "icon": preload("res://icons/Apple.png"), "much": 0, "has_i": false},
	"strawberry": {"name": "", "icon": preload("res://icons/strawberry.png"), "much": 0, "has_i": false},
	"axe": {"name": "", "icon": preload("res://icons/axe.png"), "much": 0, "has_i": false},
	"pickaxe": {"name": "", "icon": preload("res://icons/pickaxe.png"), "much": 0, "has_i": false},
	"wood": {"name": "", "icon": preload("res://icons/wood.png"), "much": 0, "has_i": false},
	"stone": {"name": "", "icon": preload("res://icons/stone.png"), "much": 0, "has_i": false},
	"iron_ore": {"name": "", "icon": preload("res://icons/iron_ore.png"), "much": 0, "has_i": false},
	"iron_ingot": {"name": "", "icon": preload("res://icons/iron_ingot.png"), "much": 0, "has_i": false},
	"avon": {"name": "", "icon": preload("res://icons/avon.png"), "much": 0, "has_i": false},
	"bake_Corn": {"name": "", "icon": preload("res://icons/bake_corn.png"), "much": 0, "has_i": false},
	"bake_egg": {"name": "", "icon": preload("res://icons/bake_egg.png"), "much": 0, "has_i": false},
	"wire": {"name": "", "icon": preload("res://icons/wire.png"), "much": 0, "has_i": false},
	"spring": {"name": "", "icon": preload("res://icons/spring.png"), "much": 0, "has_i": false},
	"pipe": {"name": "", "icon": preload("res://icons/pipe.png"), "much": 0, "has_i": false},
	"sword": {"name": "", "icon": preload("res://icons/sword.png"), "much": 0, "has_i": false},
}

# ITEMS.GD (Global Script) mein ye function theek karein:

func add_item_to_inventory(item_id: String, amount: int = 1):
	if Item1.has(item_id):
		Item1[item_id]["much"] += amount
		
		# FIX: Agar quantity 0 ya usse kam ho jaye, toh item player ke paas nahi raha
		if Item1[item_id]["much"] <= 0:
			Item1[item_id]["much"] = 0
			Item1[item_id]["has_i"] = false
		else:
			Item1[item_id]["has_i"] = true
			
		inventory_updated.emit()



var CraftingRecipes = {
	"axe": {"wood": 5, "stone": 3, "iron_ingot": 1},
	"pickaxe": {"wood": 5, "stone": 6, "iron_ingot": 1},
	"avon": {"stone": 9},
	"spring": {"wire": 2},
	"pipe": {"wire": 2, "spring": 1, "iron_ingot": 1},
	"sword": {"iron_ingot": 2, "wood": 1, "stone": 1},
	
	
}


var SmeltRecipes = {
	"iron_ore": {"result": "iron_ingot", "time": 8.0},
	"Corn": {"result": "bake_Corn", "time": 5.0},
	"egg": {"result": "bake_egg", "time": 3.0},
}
