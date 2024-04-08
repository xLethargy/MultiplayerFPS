extends Control

@onready var server_joiner_animation_player = $MainMenu/MarginContainer/ServerJoiner/AnimationPlayer

func _on_host_mouse_entered():
	server_joiner_animation_player.play("hover")
