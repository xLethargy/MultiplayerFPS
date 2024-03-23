extends Node3D

@onready var player = owner
@onready var heal_timer = $HealTimer
var can_heal = false

var max_health = 100
@export var current_health = max_health

signal change_health(health_value)
signal death

func _process(delta):
	if !current_health == max_health and can_heal:
		current_health += 10 * delta
		if current_health > max_health:
			current_health = max_health
		change_health.emit(current_health)

@rpc ("any_peer")
func receive_damage(damage):
	can_heal = false
	current_health -= damage
	if current_health <= 0:
		current_health = max_health
		player.position = Vector3.ZERO
		player.change_speed_and_jump.rpc()
		heal_timer.stop()
		death.emit()
	else:
		heal_timer.stop()
		heal_timer.start()
	
	change_health.emit(current_health)


func _on_heal_timer_timeout():
	can_heal = true
