extends Control

# Skin selector panel, created at runtime and added to the start screen

const SKINS = [
	{ "name": "blue",   "anim": "blue", "preview": "res://Assets/Sprites/Planes/planeBlue1.png",   "cost": 0 },
	{ "name": "green",  "anim": "green",  "preview": "res://Assets/Sprites/Planes/planeGreen1.png",  "cost": 2 },
	{ "name": "red",    "anim": "red",    "preview": "res://Assets/Sprites/Planes/planeRed1.png",    "cost": 5 },
	{ "name": "yellow", "anim": "yellow", "preview": "res://Assets/Sprites/Planes/planeYellow1.png", "cost": 10 },
]

var _skin_buttons: Array = []
var _stars_label: Label
var _card_container: VBoxContainer

func _ready():
	_build_ui()
	refresh()

func _build_ui():
	# Use the existing NinePatchRect from the scene (UIbg.png as modal card)
	var card_node = get_node_or_null("NinePatchRect")
	if card_node == null:
		# Fallback: create a simple card if the NinePatchRect is missing
		card_node = NinePatchRect.new()
		card_node.name = "NinePatchRect"
		card_node.set_anchors_preset(Control.PRESET_CENTER)
		card_node.custom_minimum_size = Vector2(340, 480)
		add_child(card_node)

	# Clear any existing children so we can rebuild the layout inside the card
	for child in card_node.get_children():
		child.queue_free()

	# Vertical layout container inside the card
	var vbox = VBoxContainer.new()
	vbox.set_anchors_preset(Control.PRESET_FULL_RECT)
	vbox.add_theme_constant_override("separation", 14)
	card_node.add_child(vbox)
	_card_container = vbox

	# Title
	var title = Label.new()
	title.text = "✈  SELECT SKIN"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	var ts = LabelSettings.new()
	ts.font_size = 24
	ts.outline_size = 2
	ts.outline_color = Color.BLACK
	title.label_settings = ts
	_card_container.add_child(title)

	# Stars display
	_stars_label = Label.new()
	_stars_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	var ss = LabelSettings.new()
	ss.font_size = 18
	ss.outline_size = 2
	ss.outline_color = Color.BLACK
	_stars_label.label_settings = ss
	_card_container.add_child(_stars_label)

	# Skin grid (2 columns)
	var grid = GridContainer.new()
	grid.columns = 2
	grid.add_theme_constant_override("h_separation", 10)
	grid.add_theme_constant_override("v_separation", 10)
	_card_container.add_child(grid)

	_skin_buttons.clear()
	for skin in SKINS:
		var card = _make_skin_card(skin)
		grid.add_child(card)
		_skin_buttons.append({ "skin": skin, "card": card })

	# Close button
	var close_btn = Button.new()
	close_btn.text = "← Back"
	close_btn.custom_minimum_size = Vector2(0, 40)
	close_btn.pressed.connect(_on_close_pressed)
	_card_container.add_child(close_btn)

func _make_skin_card(skin: Dictionary) -> VBoxContainer:
	var card = VBoxContainer.new()
	card.custom_minimum_size = Vector2(130, 150)
	card.add_theme_constant_override("separation", 4)

	# Plane preview image
	var tex_rect = TextureRect.new()
	tex_rect.texture = load(skin["preview"])
	tex_rect.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
	tex_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	tex_rect.custom_minimum_size = Vector2(0, 80)
	card.add_child(tex_rect)

	# Skin name label
	var name_lbl = Label.new()
	name_lbl.text = skin["name"].capitalize()
	name_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	card.add_child(name_lbl)

	# Action button (select / unlock / locked)
	var btn = Button.new()
	btn.custom_minimum_size = Vector2(0, 36)
	btn.name = "ActionBtn_" + skin["name"]
	btn.pressed.connect(_on_skin_action.bind(skin["name"]))
	card.add_child(btn)

	return card

func refresh():
	if _stars_label:
		_stars_label.text = "⭐  Total Stars: %d" % SaveData.total_stars

	for entry in _skin_buttons:
		var skin = entry["skin"]
		var card = entry["card"]
		var btn: Button = card.get_node_or_null("ActionBtn_" + skin["name"])
		if not btn:
			continue

		var is_unlocked = SaveData.is_skin_unlocked(skin["name"])
		var is_selected = (SaveData.selected_skin == skin["name"])
		var can_afford  = (SaveData.total_stars >= skin["cost"])

		if is_selected:
			btn.text = "✔ Selected"
			btn.disabled = true
			btn.modulate = Color(0.4, 1.0, 0.4)
		elif is_unlocked:
			btn.text = "Select"
			btn.disabled = false
			btn.modulate = Color.WHITE
		elif can_afford:
			btn.text = "Unlock (%d⭐)" % skin["cost"]
			btn.disabled = false
			btn.modulate = Color(1.0, 0.85, 0.3)
		else:
			btn.text = "🔒 %d⭐" % skin["cost"]
			btn.disabled = true
			btn.modulate = Color(0.6, 0.6, 0.6)

func _on_skin_action(skin_name: String):
	if SaveData.is_skin_unlocked(skin_name):
		SaveData.select_skin(skin_name)
	else:
		var success = SaveData.unlock_skin(skin_name)
		if success:
			SaveData.select_skin(skin_name)
	refresh()

func _on_close_pressed():
	visible = false
