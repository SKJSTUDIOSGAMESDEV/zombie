extends CharacterBody3D

@onready var HEAD: Node3D = $Head
@onready var Bag: ItemList = $Bag/ItemList
@onready var hand_ray_cast = $Head/RayCast3D
@onready var bag_ui_container = $Bag
@onready var hands_items_node: Node3D = $Head/hands_items # Weapon yahan aayega

# UI NODES
@onready var message_label: Label = $VBoxContainer/Label
@onready var message_timer: Timer = $VBoxContainer/Timer

# --- PLAYER STATS ---
var HP: int = 100
var huger: int = 200
var water_trusty: int = 200
var decrease_huger: bool = true
var decrease_water: bool = true

# --- WEAPON SYSTEM VARIABLES ---
# Ye variable yaad rakhega ki abhi Player ke haath mein kaunsa tool/weapon hai
var equipped_weapon: Node3D = null 
# Konsa item type (jaise "axe", "pistol") haath mein hai, ye string mein save hoga taaki drop karte waqt inventory mein wapas daal sakein
var equipped_weapon_id: String = "" 

# Constants
const SPEED: float = 5.0
const JUMP_VELOCITY: float = 4.5
const SENSITIVITY: float = 0.008 
const GRAVITY: float = 9.8 

# Vectors
var input_dir: Vector2 = Vector2.ZERO
var direction: Vector3 = Vector3.ZERO

# --- INVENTORY SYSTEM ---
var selected_item_id: String = "" 
var is_bag_open: bool = false 

func _ready() -> void:
	bag_ui_container.hide()
	message_label.hide()
	update_bag_ui()
	$Carft.hide()
	if not Items.inventory_updated.is_connected(update_bag_ui):
		Items.inventory_updated.connect(update_bag_ui)

func _input(event: InputEvent) -> void:
	if event is InputEventScreenDrag and event.position.x > 300:
		rotate_y(-event.relative.x * SENSITIVITY)
		HEAD.rotate_x(-event.relative.y * SENSITIVITY)
		HEAD.rotation.x = clampf(HEAD.rotation.x, -1.0472, 1.2217)

func _physics_process(delta: float) -> void:
	$UI/FPS.text = str(Engine.get_frames_per_second())
	$UI/HP.value = HP
	$UI/Huger.value = huger
	$UI/Trusty.value = water_trusty
	
	input_dir = Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	
	if not is_on_floor():
		velocity.y -= GRAVITY * delta
	elif Input.is_action_just_pressed("ui_accept"): 
		velocity.y = JUMP_VELOCITY

	if Input.is_action_just_pressed("Hand_get"):
		hand()

	# ==========================================
	# 🔫 WEAPON ATTACK & DROP LOGIC (Har frame check hoga)
	# ==========================================
	if equipped_weapon != null: # Agar haath mein kuch hai
		
		# 1. ATTACK KARNA (ui_page_up dabane par)
		if Input.is_action_pressed("ui_page_up"):
			# Future Proofing: Chahe haath mein Axe ho ya Gun, agar uski script mein "att" (attack) function hai, toh chal jayega.
			if equipped_weapon.has_method("att"):
				equipped_weapon.att()
				
		# 2. DROP/UNEQUIP KARNA (Item ko haath se hatakar inventory mein rakhna)
		if Input.is_action_just_pressed("Hand_get"): # Aap chaho toh iske liye naya Drop key map kar sakte ho jaise "drop_key"
			# Bag mein item wapas daal do (+1)
			Items.add_item_to_inventory(equipped_weapon_id, 1)
			
			# 3D model ko haath se delete kar do
			equipped_weapon.queue_free()
			
			# Memory saaf kar do taaki game ko pata chal jaye ki ab haath khaali hain
			equipped_weapon = null
			equipped_weapon_id = ""
			print("Weapon wapas bag mein daal diya!")
	# ==========================================

	if input_dir.x != 0 or input_dir.y != 0: 
		direction = (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
		velocity.x = direction.x * SPEED
		velocity.z = direction.z * SPEED
	else:
		velocity.x = 0.0
		velocity.z = 0.0

	move_and_slide()

# --- UI UPDATE ---
func update_bag_ui() -> void:
	Bag.clear()
	for item_id in Items.Item1:
		var item_data: Dictionary = Items.Item1[item_id]
		if item_data.has_i and item_data.much > 0:
			var display_text = "%s x%d" % [item_data.name, item_data.much]
			var index = Bag.add_item(display_text, item_data.icon)
			Bag.set_item_metadata(index, item_id)


# --- MESSAGE FUNCTION ---
func show_warning_message(text: String) -> void:
	message_label.text = text
	message_label.show()
	message_timer.start()

# --- INTERACTION ---
func hand():
	hand_ray_cast.force_raycast_update() 
	if hand_ray_cast.is_colliding():
		var hh = hand_ray_cast.get_collider()
		if hh and hh.is_in_group("item") and hh.has_method("pp"):
			hh.pp()


# --- BAG OPEN/CLOSE ---
func _on_bag_bag_pressed() -> void:
	if not is_bag_open:
		bag_ui_container.show()
		is_bag_open = true
	
func _on_x_pressed() -> void:
	if is_bag_open:
		bag_ui_container.hide()
		selected_item_id = "" 
		is_bag_open = false


# --- INVENTORY LOGIC (SELECT, USE, EQUIP) ---
func _on_item_list_item_clicked(index: int, _at_position: Vector2, _mouse_button_index: int) -> void:
	selected_item_id = Bag.get_item_metadata(index)

func _on_item_list_item_activated(index: int) -> void:
	var clicked_item_id = Bag.get_item_metadata(index)
	
	match clicked_item_id:
		"axe": # Future mein yahan "pistol", "pickaxe" add kar sakte hain
			# Check karo ki kahin player ke haath mein pehle se kuch aur toh nahi hai?
			if equipped_weapon != null:
				show_warning_message("Pehle purana hathiyar bag mein daalo!")
				return
				
			# 1. Inventory se 1 Axe hata do
			Items.add_item_to_inventory("axe", -1)
			
			# 2. 3D Model ko Load karke Spawn karo
			var weapon_scene = load("res://Iteam/axe.tscn")
			var weapon_instance = weapon_scene.instantiate()
			
			# 3. Model ko player ke 'hands_items' Node ke andar daal do 
			hands_items_node.add_child(weapon_instance)
			
			# 4. Position aur Rotation fix karo taaki wo theek center mein aaye
			weapon_instance.transform = Transform3D.IDENTITY 
			
			# Agar tool ki script mein freeze/equip ka function hai toh call karo
			if weapon_instance.has_method("fz"):
				weapon_instance.fz()
				
			# 5. Variables save karo taaki player ko baad mein pata chale uske paas kya hai
			equipped_weapon = weapon_instance
			equipped_weapon_id = "axe" 
			
			# Bag band kar do taaki player turant attack kar sake
			_on_x_pressed()
			

		"pickaxe":
			if equipped_weapon != null:
				show_warning_message("Pehle purana hathiyar bag mein daalo!")
				return
			Items.add_item_to_inventory("pickaxe", -1)
			var weapons = load("res://Iteam/pickaxe.tscn")
			var wepons_ = weapons.instantiate()
			hands_items_node.add_child(wepons_)
			wepons_.transform = Transform3D.IDENTITY
			if wepons_.has_method("fz"):
				wepons_.fz()
			equipped_weapon = wepons_
			equipped_weapon_id = "pickaxe"
			_on_x_pressed()
			
			
			
		"avon":
			# Raycast ko turant update karo taaki exact position mile
			hand_ray_cast.force_raycast_update()
			
			# Check karo ki raycast kisi cheez se takra raha hai ya nahi (Hawa mein place na ho)
			if hand_ray_cast.is_colliding():
				# 1. Zameen/Deewar ka exact point aur uski direction (Normal) nikalo
				var hit_point = hand_ray_cast.get_collision_point()
				var hit_normal = hand_ray_cast.get_collision_normal()
				
				# 2. Scene Load aur Instantiate karo
				var avon_scene = load("res://tool_plasch/avon.res") # (.res ya .tscn jo aapka format ho)
				if avon_scene:
					var avon_spawn = avon_scene.instantiate()
					get_tree().current_scene.add_child(avon_spawn)
					
					# 3. MINECRAFT PLACEMENT LOGIC:
					# Hit point par rakho, aur satah (surface) ke bahar ki taraf 0.5 unit push kar do.
					# (Agar aapka oven bada/chhota hai toh 0.5 ko 1.0 ya 0.25 kar ke adjust kar sakte hain)
					avon_spawn.global_position = hit_point + (hit_normal * 0.5)
					
					# 4. ROTATION (Optional par best hai):
					# Oven humesha player ki taraf muh karke place ho, ulta nahi.
					var face_direction = Vector3(global_position.x, avon_spawn.global_position.y, global_position.z)
					avon_spawn.look_at(face_direction, Vector3.UP)
					
					# 5. Inventory se 1 Avon minus karo
					Items.add_item_to_inventory("avon", -1)
					
					# 6. UI Update aur message
					show_warning_message("Oven Place Kar Diya!")
					_on_x_pressed() # UI close karne ke liye (Aapka function)
					
				else:
					print("ERROR: avon.res file load nahi hui!")
			else:
				# Agar raycast kisi cheez se nahi takraya
				show_warning_message("Aas paas koi satah (surface) nahi hai!")


		# ---- CONSUMABLES (Food/Meds) ----
		"bake_egg":
			if huger < 200:
				Items.add_item_to_inventory("bake_egg", -1)
				huger = clampi(huger + 60,0,200)
				water_trusty = clampi(water_trusty + 30,0,200)
			else:
				show_warning_message("Bhookh nahi lagi hai! ")
		"bake_Corn":
			if huger <= 200:
				Items.add_item_to_inventory("bake_Corn",-1)
				huger = clampi(huger + 80,0,200)
				water_trusty = clampi(water_trusty + 10,0,200)
			else:
				show_warning_message("bhookh nahin lagi hai!")
		
		"medkit":
			if HP < 100: 
				Items.add_item_to_inventory("medkit", -1)
				HP = clampi(HP + 40, 0, 100) 
			else:
				show_warning_message("Health is already full!") 
		"Corn":
			if huger < 200: 
				Items.add_item_to_inventory("Corn", -1)
				huger = clampi(huger + 35, 0, 200)
				water_trusty = clampi(water_trusty + 5, 0, 200)
			else:
				show_warning_message("Bhookh nahi lagi hai!")
		"carrot":
			if huger < 200:
				Items.add_item_to_inventory("carrot", -1)
				huger = clampi(huger + 23, 0, 200)
				water_trusty = clampi(water_trusty + 10, 0, 200)
			else:
				show_warning_message("Bhookh nahi lagi hai!")
		"egg":
			if huger < 200:
				Items.add_item_to_inventory("egg", -1)
				huger = clampi(huger + 22, 0, 200)
				water_trusty = clampi(water_trusty + 2,0,200)
			else:
				show_warning_message("Bhookh nahi lagi hai!")
		"apple":
			if huger < 200:
				Items.add_item_to_inventory("apple", -1)
				huger = clampi(huger + 25, 0, 200)
				water_trusty = clampi(water_trusty + 12,0,200)
			else:
				show_warning_message("Bhookh nahi lagi hai!")
		"strawberry":
			if huger < 200:
				Items.add_item_to_inventory("strawberry", -1)
				huger = clampi(huger + 20, 0, 200)
				water_trusty = clampi(water_trusty + 10,0,200)
			else:
				show_warning_message("Bhookh nahi lagi hai!")
		"water_bottle": 
			if water_trusty < 200:
				Items.add_item_to_inventory("water_bottle", -1)
				water_trusty = clampi(water_trusty + 50, 0, 200)
			else:
				show_warning_message("Pyaas nahi lagi hai!")
				
	selected_item_id = ""


# --- THROW ITEM IN 3D MAP ---
func _on_drop_button_pressed() -> void:
	if selected_item_id != "":
		Items.add_item_to_inventory(selected_item_id, -1)
		drop_item_in_3d(selected_item_id)
		selected_item_id = "" 

func drop_item_in_3d(item_id: String) -> void:
	var scene_path = "res://Iteam/%s.tscn" % item_id
	if FileAccess.file_exists(scene_path):
		var item_scene = load(scene_path)
		if item_scene and item_scene.can_instantiate():
			var item_instance = item_scene.instantiate()
			get_tree().current_scene.add_child(item_instance)
			
			item_instance.global_position = self.global_position - (transform.basis.z * 1.5)
			item_instance.global_position.y += 1.2 
			if item_instance is RigidBody3D:
				item_instance.linear_velocity = -transform.basis.z * 2.0 
		else:
			print("ERROR: Scene instantiate nahi ho raha: ", scene_path)
	else:
		print("ERROR: File nahi mili -> ", scene_path)


# --- TIMERS ---
func _on_timer_timeout() -> void:
	message_label.hide()

func _on_huger_timer_timeout() -> void:
	var de = randf_range(1,32)
	huger = clampi(huger - de, 0,200)
	if huger <= 1:
		HP_decrease_huger_water()

func _on_trusty_timer_2_timeout() -> void:
	var wd = randf_range(1,22)
	water_trusty = clampi(water_trusty - wd, 0,200)
	if water_trusty <= 1:
		HP_decrease_huger_water()

func HP_decrease_huger_water():
	if water_trusty <= 0 or huger <= 0:
		HP = clampi(HP - 3, 0, 100)


func _on_crafting_pressed() -> void:
	$Carft.show()


func _on_craft_xx_pressed() -> void:
	$Carft.hide()
