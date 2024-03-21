extends Node3D

@onready var player = owner

var max_health = 100
@export var current_health = max_health

signal change_health(health_value)
signal death

@rpc ("any_peer")
func receive_damage(damage):
	current_health -= damage
	if current_health <= 0:
		
		current_health = max_health
		player.position = Vector3.ZERO
	
	change_health.emit(current_health)
	
	#if player.is_multiplayer_authority():
		#print (player)
		#healthbar.value = current_health
