extends Control

@onready var color_rect = $ColorRect
@onready var logo_texture = $TextureRect
@onready var animation_player = $AnimationPlayer

func _ready():
	# Start black, fade in logo, hold, fade out whole scene to main game
	animation_player.play("intro")

func _on_animation_player_animation_finished(anim_name):
	if anim_name == "intro":
		get_tree().change_scene_to_file("res://Scenes/main.tscn")
