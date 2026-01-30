extends Node

signal game_over
signal game_started
signal restart_game
signal star_collected

var is_game_active = false
var is_game_over = false
var score = 0
var scroll_speed = 200.0
var distance: float = 0.0
var stars_collected: int = 0

# Spawn control
var spike_spawn_timer: float = 0.0
var star_spawn_timer: float = 0.0
var spike_spawn_interval: float = 2.5
var star_spawn_interval: float = 3.5

# Preloaded scenes
var spike_scene = preload("res://Scenes/base_spike.tscn")
var star_scene = preload("res://Scenes/stars.tscn")

@onready var ui_canvas = $CanvasLayer
@onready var game_over_screen = $CanvasLayer/GameOverControl
@onready var restart_button = $CanvasLayer/GameOverControl/RestartButton
@onready var start_game_screen = $CanvasLayer/StartGameControl
@onready var play_button = $CanvasLayer/StartGameControl/PlayButton
@onready var hud_label = $CanvasLayer/HUD/Label
@onready var parallax_bg = $Parallax2D

# Game Over UI labels
@onready var game_over_distance_label: Label = null
@onready var game_over_stars_label: Label = null

func _ready():
	# Configure custom cursor
	var arrow = load("res://Assets/Sprites/UI/tap.png")
	Input.set_custom_mouse_cursor(arrow)
	
	restart_button.pressed.connect(_on_restart_pressed)
	play_button.pressed.connect(_on_play_pressed)
	
	# Create game over UI labels if they don't exist
	_setup_game_over_labels()
	
	# Initial state - show start menu, hide game over
	game_over_screen.visible = false
	start_game_screen.visible = true
	is_game_active = false
	is_game_over = false
	
	# Update HUD
	_update_hud()

func _setup_game_over_labels():
	# Check if labels already exist
	var distance_label_node = game_over_screen.get_node_or_null("FinalDistanceLabel")
	var stars_label_node = game_over_screen.get_node_or_null("FinalStarsLabel")
	
	if distance_label_node == null:
		# Create distance label
		game_over_distance_label = Label.new()
		game_over_distance_label.name = "FinalDistanceLabel"
		game_over_distance_label.text = "Distance: 0m"
		game_over_distance_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		game_over_distance_label.anchors_preset = Control.PRESET_CENTER
		game_over_distance_label.position = Vector2(-50, 30)
		game_over_distance_label.size = Vector2(200, 30)
		
		# Style the label
		var label_settings = LabelSettings.new()
		label_settings.font_size = 22
		label_settings.outline_size = 3
		label_settings.outline_color = Color.BLACK
		game_over_distance_label.label_settings = label_settings
		
		game_over_screen.add_child(game_over_distance_label)
	else:
		game_over_distance_label = distance_label_node
	
	if stars_label_node == null:
		# Create stars label
		game_over_stars_label = Label.new()
		game_over_stars_label.name = "FinalStarsLabel"
		game_over_stars_label.text = "Stars: 0"
		game_over_stars_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		game_over_stars_label.anchors_preset = Control.PRESET_CENTER
		game_over_stars_label.position = Vector2(-50, 60)
		game_over_stars_label.size = Vector2(200, 30)
		
		# Style the label
		var label_settings = LabelSettings.new()
		label_settings.font_size = 22
		label_settings.outline_size = 3
		label_settings.outline_color = Color.BLACK
		game_over_stars_label.label_settings = label_settings
		
		game_over_screen.add_child(game_over_stars_label)
	else:
		game_over_stars_label = stars_label_node

func _process(delta):
	if is_game_active and not is_game_over:
		# Update distance (10m per second)
		distance += 10.0 * delta
		_update_hud()
		
		# Spike spawning (after 50m)
		if distance >= 50.0:
			spike_spawn_timer -= delta
			if spike_spawn_timer <= 0:
				_spawn_spike()
				spike_spawn_timer = randf_range(1.5, 3.5) # Random interval
		
		# Star spawning (after 100m)
		if distance >= 100.0:
			star_spawn_timer -= delta
			if star_spawn_timer <= 0:
				_spawn_star()
				star_spawn_timer = randf_range(2.5, 5.0) # Random interval

func _update_hud():
	if hud_label:
		hud_label.text = "Distance: %dm | Stars: %d" % [int(distance), stars_collected]

func _spawn_spike():
	var spike = spike_scene.instantiate()
	# Spawn on the right side of screen, random Y position
	# Avoid spawning too low (ground) or too high (off screen)
	var spawn_y = randf_range(350, 450) # Safe vertical range
	spike.position = Vector2(600, spawn_y) # Right side of visible area
	add_child(spike)

func _spawn_star():
	var star = star_scene.instantiate()
	# Spawn on the right side of screen, random Y position
	var spawn_y = randf_range(80, 320) # Safe vertical range
	star.position = Vector2(650, spawn_y)
	add_child(star)

func collect_star():
	stars_collected += 1
	emit_signal("star_collected")
	_update_hud()

func _on_play_pressed():
	start_game()

func start_game():
	is_game_active = true
	is_game_over = false
	score = 0
	distance = 0.0
	stars_collected = 0
	spike_spawn_timer = 2.0
	star_spawn_timer = 3.0
	
	start_game_screen.visible = false
	game_over_screen.visible = false
	
	# Resume parallax if it was stopped
	if parallax_bg:
		parallax_bg.autoscroll = Vector2(-50, 0)
	
	_update_hud()
	emit_signal("game_started")

func end_game():
	if is_game_over: return
	is_game_over = true
	is_game_active = false
	
	# Stop parallax scrolling
	if parallax_bg:
		parallax_bg.autoscroll = Vector2.ZERO
	
	# Update game over labels with final stats
	if game_over_distance_label:
		game_over_distance_label.text = "Distance: %dm" % int(distance)
	if game_over_stars_label:
		game_over_stars_label.text = "Stars: %d" % stars_collected
	
	game_over_screen.visible = true
	emit_signal("game_over")

func _on_restart_pressed():
	get_tree().reload_current_scene()
