extends Area3D

@export var health_component : Node3D

@onready var player = owner
@export var raycast : RayCast3D
@onready var invulnerability_timer = $InvulnerabilityTimer
var invulnerable = false

signal change_score

@rpc("any_peer", "reliable")
func handle_damage_collision(damage):
	var id = multiplayer.get_unique_id()
	if id != player.get_multiplayer_authority() and !invulnerable:
		_update_global_score.rpc(damage, id)
		health_component.receive_damage.rpc_id(player.get_multiplayer_authority(), damage)
		
		invulnerable = true
		invulnerability_timer.stop()
		invulnerability_timer.start()


func handle_speed_collision(speed_effect = player.default_speed, jump_height = player.default_jump_velocity):
	player.change_speed_and_jump.rpc(speed_effect, jump_height)


@rpc ("any_peer", "call_local", "reliable")
func _update_global_score(damage, id):
	if health_component.current_health - damage <= 0:
		Global.players[id].Score += 1
		change_score.emit()


func _on_invulnerability_timer_timeout():
	invulnerable = false
