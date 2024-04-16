extends Control

@onready var world = "res://models/levels/world.tscn"

func _on_animation_player_animation_finished(_anim_name):
	get_tree().call_deferred("change_scene_to_file", world)
