extends Node

@onready var screen_size = DisplayServer.screen_get_size()

var players = {}

var game_in_progress = false

var teams = 4
