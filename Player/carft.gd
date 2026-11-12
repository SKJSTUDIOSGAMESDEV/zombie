extends Control

@onready var leabl: Label = $VBoxContainer/Label
@onready var recipe_list: ItemList = $VBoxContainer/ItemList 
@onready var recipe_show: ItemList = $VBoxContainer/rescepe_show # Requirement dikhane ke liye naya ItemList

var selected_craft_id: String = ""

func _ready() -> void:
	leabl.text = "Craft karne ke liye koi item chunein."
	recipe_show.clear() # Shuru mein requirement list khali rahegi
	load_recipes_in_ui()

# 1. UI mein Recipes Load karna (Main List)
func load_recipes_in_ui() -> void:
	recipe_list.clear()
	
	for recipe_id in Items.CraftingRecipes:
		var item_data: Dictionary = Items.Item1[recipe_id]
		var index = recipe_list.add_item(item_data.name, item_data.icon)
		recipe_list.set_item_metadata(index, recipe_id)

# 2. Jab player main list mein se kisi item par click kare
func _on_item_list_item_clicked(index: int, _at_position: Vector2, _mouse_button_index: int) -> void:
	selected_craft_id = recipe_list.get_item_metadata(index)
	update_requirement_text()

# 3. Label par Title aur 'recipe_show' mein Icons/Requirement dikhana
func update_requirement_text() -> void:
	recipe_show.clear() # Pehle ki requirements hatao
	
	if selected_craft_id == "":
		leabl.text = "Craft karne ke liye koi item chunein."
		return
		
	var recipe: Dictionary = Items.CraftingRecipes[selected_craft_id]
	var display_name: String = Items.Item1[selected_craft_id].name
	
	# Label ko sirf Heading ke liye use karenge
	leabl.text = display_name + " Banane Ke Liye:" 
	
	# Har requirement ko check karo aur recipe_show (ItemList) mein add karo
	for req_item_id in recipe:
		var required_amount: int = recipe[req_item_id]
		var item_data: Dictionary = Items.Item1[req_item_id] # Item ka poora data nikalo
		
		var item_name: String = item_data.name
		var item_icon = item_data.icon # Icon yahan se milega
		
		# Pata karo player ke paas kitna hai
		var player_has: int = 0
		if item_data.has_i:
			player_has = item_data.much
			
		# Text format karein -> "Wood: 2 / 5"
		var display_text = "%s: %d / %d" % [item_name, player_has, required_amount]
		
		# Naye ItemList mein Icon ke sath add karein
		recipe_show.add_item(display_text, item_icon)


# 4. Jab CRAFT button dabaya jaye
func _on_craft_pressed() -> void:
	if selected_craft_id == "":
		leabl.text = "Pehle list se kuch select karo!"
		return
		
	var recipe: Dictionary = Items.CraftingRecipes[selected_craft_id]
	var can_craft: bool = true
	
	# STEP A: Check karo ki kya poora saman hai?
	for req_item_id in recipe:
		var required_amount: int = recipe[req_item_id]
		var player_has: int = 0
		if Items.Item1[req_item_id].has_i:
			player_has = Items.Item1[req_item_id].much
			
		if player_has < required_amount:
			can_craft = false
			break # Check rok do, kyunki saman kam hai
			
	# STEP B: Agar saman poora hai, toh Craft karo!
	if can_craft:
		# Purana saman (Ingredients) minus karo
		for req_item_id in recipe:
			var required_amount: int = recipe[req_item_id]
			Items.add_item_to_inventory(req_item_id, -required_amount)
			
		# Naya craft kiya hua item add karo
		Items.add_item_to_inventory(selected_craft_id, 1)
		
		# Label ko update karo taaki successfully craft message dikhe
		leabl.text = "Success! " + Items.Item1[selected_craft_id].name + " Ban gaya!"
		
		# Craft hone ke baad requirements ko turant update karo taaki player ko naye numbers (jaise 0/5) dikh jayein
		update_requirement_text() 
		# Title dobara purana wala (Success message overwrite karke) 1.5s baad wapas layenge
		leabl.text = "Success! " + Items.Item1[selected_craft_id].name + " Ban gaya!"
		await get_tree().create_timer(1.5).timeout
		if selected_craft_id != "":
			leabl.text = Items.Item1[selected_craft_id].name + " Banane Ke Liye:"
	else:
		leabl.text = "Craft fail: Saman poora nahi hai!"


# --- EXTRA SIGNALS ---

func _on_item_list_empty_clicked(_at_position: Vector2, _mouse_button_index: int) -> void:
	selected_craft_id = ""
	recipe_show.clear() # Khaali jagah click karne par requirement list bhi saaf kar do
	leabl.text = "Craft karne ke liye koi item chunein."

func _on_item_list_item_activated(_index: int) -> void:
	# Double click par seedha craft
	_on_craft_pressed()

func _on_item_list_item_selected(_index: int) -> void:
	pass 

func _on_item_list_multi_selected(_index: int, _selected: bool) -> void:
	pass
