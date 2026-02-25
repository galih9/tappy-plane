extends Node

var players: Dictionary = {}

var audio_files = {
	"play": "res://Assets/Audio/play.ogg",
	"stars": "res://Assets/Audio/stars.ogg",
	"fly": "res://Assets/Audio/fly.ogg",
	"game_over": "res://Assets/Audio/game_over.ogg",
	"click": "res://Assets/Audio/click.ogg"
}

func _ready():
	for key in audio_files.keys():
		var player = AudioStreamPlayer.new()
		player.stream = load(audio_files[key])
		add_child(player)
		players[key] = player

func play(sound_name: String):
	if players.has(sound_name):
		players[sound_name].play()
