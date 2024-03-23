extends Node3D

var player_scene = preload("res://player.tscn")
var player
var player_class
var pistol_one = preload("res://pistol.tscn")
var smg_gun = preload("res://pistol_2.tscn")
var freeze_gun = preload("res://pistol_freeze.tscn")
var speed_gun = preload("res://speed_gun.tscn")
@onready var hud = $MultiplayerMenu/HUD
@onready var main_menu = $MultiplayerMenu/MainMenuScreen

@onready var timer = get_tree().create_timer(2.0)

func _unhandled_input(_event):
	if Input.is_action_just_pressed("quit"):
		if !main_menu.visible:
			#_on_multiplayer_menu_remove_player.rpc(multiplayer.get_unique_id())
			_open_choose_class(multiplayer.get_unique_id())
		else:
			get_tree().quit()


func _on_multiplayer_menu_add_player():
	#var index = 0 THIS IS FOR SPAWNING PLAYERS INA 
	
	if multiplayer.is_server():
		for i in Global.players:
			player = get_node_or_null(str(Global.players[i].ID))
			if !player and Global.players[i].Class != "":
				player = player_scene.instantiate()
				player.name = str(Global.players[i].ID)
				add_child(player, true)
				
				match Global.players[i].Class:
					"PistolOne":
						player_class = pistol_one.instantiate()
					"SMG":
						player_class = smg_gun.instantiate()
					"FreezeGun":
						player_class = freeze_gun.instantiate()
					"SpeedGun":
						player_class = speed_gun.instantiate()
				
				if player.is_multiplayer_authority():
					player.health_component.connect("change_health", update_health_bar)
					_add_weapon_class(player)
					#print ("HOST: ", player)
				update_health_bar(player.health_component.current_health)


@rpc("any_peer", "call_remote")
func _on_multiplayer_menu_remove_player(peer_id):
	player = get_node_or_null(str(peer_id))
	if player:
		player.queue_free()


func _open_choose_class(peer_id):
	player = get_node_or_null(str(peer_id))
	if player:
		player.global_position = Vector3(0, -100, 0)
		player.frozen = true
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	hud.hide()
	main_menu.show()


func update_health_bar(health_value):
	var healthbar = hud.healthbar
	healthbar.value = health_value


func _on_multiplayer_spawner_spawned(node):
	if node.is_multiplayer_authority():
		node.health_component.connect("change_health", update_health_bar)
		update_health_bar(node.health_component.current_health)
		
		if Global.players.has((str(node.name).to_int())):
			var id = str(node.name).to_int()
			if Global.players[id].Class == "PistolOne":
				player_class = pistol_one.instantiate()
			elif Global.players[id].Class == "SMG":
				player_class = smg_gun.instantiate()
			elif Global.players[id].Class == "FreezeGun":
				player_class = freeze_gun.instantiate()
			elif Global.players[id].Class == "SpeedGun":
				player_class = speed_gun.instantiate()
			
			if node.is_multiplayer_authority():
				_add_weapon_class(node)


func _add_weapon_class(player_node):
	print(player_node)
	player_class.name = "item" + str(randf_range(0, 10))
	player_node.view.add_child(player_class, true)
	player_node.weapon = player_class
