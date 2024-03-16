extends Node3D

var player_scene = preload("res://player.tscn")

var player

func _unhandled_input(event):
	if Input.is_action_just_pressed("quit"):
		get_tree().quit()


func _on_multiplayer_menu_add_player(peer_id):
	player = player_scene.instantiate()
	player.name = str(peer_id)
	add_child(player)

	if player.is_multiplayer_authority():
		player.change_health.connect(update_health_bar)


func _on_multiplayer_menu_remove_player(peer_id):
	player = get_node_or_null(str(peer_id))
	if player:
		player.queue_free()


func update_health_bar(health_value):
	player.hud._on_player_change_health(health_value)


func spawn_bullet(bullet_scene, bullet_spawn_location, parent_shooter):
	if is_multiplayer_authority():
		var bullet = bullet_scene.instantiate()
		bullet.position = bullet_spawn_location.global_position
		bullet.rotation = bullet_spawn_location.global_rotation
		bullet.parent_shooter = parent_shooter
		add_child(bullet)
