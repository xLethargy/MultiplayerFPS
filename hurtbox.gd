extends Area3D

@export var health_component : Node3D

@onready var player = owner

func handle_damage_collision(damage):
	health_component.receive_damage.rpc_id(player.get_multiplayer_authority(), damage)


func handle_speed_collision(speed_effect = player.default_speed, jump_height = player.default_jump_velocity):
	player.change_speed_and_jump.rpc_id(player.get_multiplayer_authority(), speed_effect, jump_height)


func _on_body_entered(body):
	if body.is_in_group("Bullet"):
		handle_damage_collision(body.damage)
