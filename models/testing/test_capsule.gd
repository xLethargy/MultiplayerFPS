extends RigidBody3D


@export var target_color : Color
@onready var meshes = $Meshes
@onready var mesh = $Meshes/MeshInstance3D
@onready var despawn_timer = $DespawnTimer
@onready var freeze_timer = $FreezeTimer
@onready var death_audio = $DeathAudio
@onready var animation_player = $AnimationPlayer

@onready var death_sounds = ["res://sounds/hurt/death1.wav", "res://sounds/hurt/death2.wav"]

var tween

var base_mesh_material

func _ready():
	var death_sound = death_sounds.pick_random()
	call_deferred("_play_death_sound", death_sound)


func add_force_to_test(given_force):
	linear_velocity = given_force
	despawn_timer.start()
	freeze_timer.start()


func _on_despawn_timer_timeout():
	animation_player.play("death")

func _on_freeze_timer_timeout():
	freeze = true


@rpc("any_peer", "call_local", "reliable")
func _play_death_sound(given_sound):
	death_audio.stream = load(given_sound)
	death_audio.play()


func _on_animation_player_animation_finished(_anim_name):
	queue_free()
