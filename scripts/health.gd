extends Node3D

@onready var hurt_sounds = ["res://sounds/hurt/hurt1.wav", "res://sounds/hurt/hurt2.wav"]

@onready var heartbeat_audio = $HeartbeatAudio
@onready var hurt_audio = $HurtAudio

@onready var player = owner
@onready var heal_timer = $HealTimer
var can_heal = false

var max_health = 100
@export var current_health = max_health

signal flinch(damage)
signal change_health(health_value)
signal death

func _process(delta):
	if !current_health == max_health and can_heal:
		current_health += 10 * delta
		if current_health > max_health:
			current_health = max_health
		
		if current_health > 50:
			heartbeat_audio.volume_db -= 10 * delta
		
		if current_health == max_health:
			heartbeat_audio.stop()
		change_health.emit(current_health)

@rpc ("any_peer", "reliable")
func receive_damage(damage):
	can_heal = false
	current_health -= damage
	if current_health <= 0:
		current_health = max_health
		player.position = get_tree().current_scene.current_map.pick_random_spawn().position
		player.change_speed_and_jump()
		heal_timer.stop()
		heartbeat_audio.stop()
		death.emit()
	else:
		heal_timer.stop()
		heal_timer.start()
		
		if !hurt_audio.playing:
			var hurt_sound = hurt_sounds.pick_random()
			_play_hurt_audio.rpc(hurt_sound)
	
	change_health.emit(current_health)
	flinch.emit(damage)
	
	if !heartbeat_audio.playing and current_health <= 50:
		heartbeat_audio.play()
	
	if current_health <= 50 and heartbeat_audio.volume_db != -10:
		heartbeat_audio.volume_db = -15


func _on_heal_timer_timeout():
	can_heal = true


func _on_heartbeat_audio_finished():
	heartbeat_audio.play()


@rpc ("any_peer", "call_local")
func _play_hurt_audio(given_sound):
	hurt_audio.stream = load(given_sound)
	hurt_audio.play()
