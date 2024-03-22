extends Node3D

var player_scene = preload("res://player.tscn")
var player
var player_class
var pistol_one = preload("res://pistol.tscn")
var pistol_two = preload("res://pistol_2.tscn")
var freeze_gun = preload("res://pistol_freeze.tscn")
var speed_gun = preload("res://speed_gun.tscn")
@onready var hud = $MultiplayerMenu/HUD
@onready var choose_class = $MultiplayerMenu/MainMenu/MarginContainer/ChooseClass

@onready var timer = get_tree().create_timer(2.0)

func _unhandled_input(_event):
	if Input.is_action_just_pressed("quit"):
		get_tree().quit()
		#_on_multiplayer_menu_remove_player.rpc(multiplayer.get_unique_id())
		#player = get_node_or_null(str(multiplayer.get_unique_id()))
		#player.queue_free()


func _on_multiplayer_menu_add_player():
	#var index = 0 THIS IS FOR SPAWNING PLAYERS INA 
	
	if multiplayer.is_server():
		for i in Global.players:
			player = player_scene.instantiate()
			player.name = str(Global.players[i].ID)
			add_child(player, true)
			
			if Global.players[i].Class == "PistolOne":
				player_class = pistol_one.instantiate()
				_add_weapon_class(player)
			elif Global.players[i].Class == "PistolTwo":
				player_class = pistol_two.instantiate()
				_add_weapon_class(player)
			elif Global.players[i].Class == "FreezeGun":
				player_class = freeze_gun.instantiate()
				_add_weapon_class(player)
			elif Global.players[i].Class == "SpeedGun":
				player_class = speed_gun.instantiate()
				_add_weapon_class(player)
			
			if player.is_multiplayer_authority():
				player.health_component.connect("change_health", update_health_bar)
				#print ("HOST: ", player)



func _on_multiplayer_menu_remove_player(peer_id):
	player = get_node_or_null(str(peer_id))
	if player:
		player.queue_free()
		


@rpc ("any_peer", "call_local")
func _open_choose_class(peer_id):
	player = get_node_or_null(str(peer_id))
	if player:
		player.queue_free()
		hud.hide()
		choose_class.show()



func update_health_bar(health_value):
	var healthbar = hud.healthbar
	healthbar.value = health_value


func spawn_bullet(bullet_scene, bullet_spawn_location, parent_shooter):
	if is_multiplayer_authority():
		var bullet = bullet_scene.instantiate()
		bullet.position = bullet_spawn_location.global_position
		bullet.rotation = bullet_spawn_location.global_rotation
		bullet.parent_shooter = parent_shooter
		add_child(bullet)


func _on_multiplayer_spawner_spawned(node):
	if node.is_multiplayer_authority():
		node.health_component.connect("change_health", update_health_bar)
		
		if Global.players.has((str(node.name).to_int())):
			var id = str(node.name).to_int()
			if Global.players[id].Class == "PistolOne":
				player_class = pistol_one.instantiate()
			elif Global.players[id].Class == "PistolTwo":
				player_class = pistol_two.instantiate()
			elif Global.players[id].Class == "FreezeGun":
				player_class = freeze_gun.instantiate()
			elif Global.players[id].Class == "SpeedGun":
				player_class = speed_gun.instantiate()
			
			_add_weapon_class(node)
		
		#print ("CLIENT: ", multiplayer.get_unique_id())


func _add_weapon_class(player_node):
	player_node.camera.add_child(player_class, true)
