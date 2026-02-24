extends Node

# Persistent save data for TappyPlane
# Registered as autoload "SaveData" in project.godot

const SAVE_PATH = "user://save.cfg"

var total_stars: int = 0
var selected_skin: String = "blue"
var unlocked_skins: Array = ["blue"]

# Skin unlock costs (blue is always free)
const SKIN_COSTS: Dictionary = {
	"blue": 0,
	"green": 50,
	"red": 100,
	"yellow": 200
}

func _ready():
	load_data()

func load_data():
	var cfg = ConfigFile.new()
	var err = cfg.load(SAVE_PATH)
	if err != OK:
		# No save file yet, use defaults
		save_data()
		return
	total_stars = cfg.get_value("player", "total_stars", 0)
	selected_skin = cfg.get_value("player", "selected_skin", "blue")
	unlocked_skins = cfg.get_value("player", "unlocked_skins", ["blue"])
	# Always ensure blue is unlocked
	if not "blue" in unlocked_skins:
		unlocked_skins.append("blue")

func save_data():
	var cfg = ConfigFile.new()
	cfg.set_value("player", "total_stars", total_stars)
	cfg.set_value("player", "selected_skin", selected_skin)
	cfg.set_value("player", "unlocked_skins", unlocked_skins)
	cfg.save(SAVE_PATH)

func add_stars(amount: int):
	total_stars += amount
	save_data()

func is_skin_unlocked(skin_name: String) -> bool:
	return skin_name in unlocked_skins

func unlock_skin(skin_name: String) -> bool:
	if is_skin_unlocked(skin_name):
		return true
	var cost = SKIN_COSTS.get(skin_name, 9999)
	if total_stars >= cost:
		total_stars -= cost
		unlocked_skins.append(skin_name)
		save_data()
		return true
	return false

func select_skin(skin_name: String):
	if is_skin_unlocked(skin_name):
		selected_skin = skin_name
		save_data()
