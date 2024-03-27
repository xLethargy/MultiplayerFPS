extends Node3D

@onready var spawn_points = get_tree().current_scene.spawn_points
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
		change_health.emit(current_health)

@rpc ("any_peer", "reliable")
func receive_damage(damage):
	can_heal = false
	current_health -= damage
	if current_health <= 0:
		current_health = max_health
		player.position = spawn_points.get_child(randi_range(0, 4)).position
		player.change_speed_and_jump()
		heal_timer.stop()
		death.emit()
	else:
		heal_timer.stop()
		heal_timer.start()
	
	change_health.emit(current_health)
	flinch.emit(damage)


func _on_heal_timer_timeout():
	can_heal = true
