extends Node

# COLOURS
const BLUE = "res://materials/blue.tres"
const RED = "res://materials/red.tres"
const GREEN = "res://materials/green.tres"
const YELLOW = "res://materials/yellow.tres"
const PINK = "res://materials/pink.tres"
const RAGDOLL_OUTLINE = "res://materials/ragdoll_outline.tres"
const RAGDOLL_BLACK = "res://materials/ragdoll_black.tres"

# HATS
const COWBOY_HAT = "res://models/objects/cowboy_hat.tscn"

@onready var screen_size = DisplayServer.screen_get_size()

var players = {}

var game_in_progress = false

var teams = 12
