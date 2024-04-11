extends Node3D

var player_scene = preload("res://models/players/player.tscn")
var player
var player_class

var pistol_one = preload("res://models/guns/pistol.tscn")
var smg_gun = preload("res://models/guns/pistol_2.tscn")
var freeze_gun = preload("res://models/guns/pistol_freeze.tscn")
var speed_gun = preload("res://models/guns/speed_gun.tscn")
var stake = preload("res://models/guns/stake.tscn")
var sniper = preload("res://models/guns/db_sniper.tscn")
var coin_gun = preload("res://models/guns/coin_gun.tscn")

var bullet_tracer_scene = preload("res://models/projectiles/bullet_tracer.tscn")

var player_score_label = preload("res://ui/player_score.tscn")
@onready var player_labels = $MultiplayerMenu/Score/PlayerLabels

var player_ragdoll_scene = preload("res://models/players/player_ragdoll.tscn")

@onready var multiplayer_menu = $MultiplayerMenu
@onready var hud = $MultiplayerMenu/HUD
@onready var main_menu = $MultiplayerMenu/MainMenuScreen
@onready var choose_class = $MultiplayerMenu/MainMenuScreen/MainMenu/MarginContainer/ChooseClass

@onready var timer = get_tree().create_timer(2.0)

var added_label = false

@onready var gold = preload("res://materials/gold.tres")
@onready var black = preload("res://materials/black.tres")

@onready var current_map_parent = $CurrentMap
@onready var current_map = $CurrentMap.get_child(0)

@onready var arena = preload("res://models/levels/arena.tscn")
@onready var db_building = preload("res://models/levels/double_building.tscn")

func _unhandled_input(_event):
	if Input.is_action_just_pressed("quit"):
		if !main_menu.visible:
			_open_choose_class(multiplayer.get_unique_id())
		elif choose_class.visible and player != null:
			main_menu.hide()
			hud.show()
			Input.mouse_mode = Input.MOUSE_MODE_CAPTURED


@rpc("any_peer", "reliable")
func send_to_main_menu():
	_on_multiplayer_menu_remove_player(multiplayer.get_unique_id())
	get_tree().reload_current_scene()
	
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

func _on_multiplayer_menu_add_player():
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
					"Stake":
						player_class = stake.instantiate()
					"Sniper":
						player_class = sniper.instantiate()
					"CoinGun":
						player_class = coin_gun.instantiate()
				
				match Global.players[i].Team:
					1:
						player.change_material.rpc(Global.BLUE)
					2:
						player.change_material.rpc(Global.RED)
					3:
						player.change_material.rpc(Global.GREEN)
					4:
						player.change_material.rpc(Global.YELLOW)
					_:
						player.change_material.rpc(Global.PINK)
				
				if player.is_multiplayer_authority():
					player.health_component.connect("change_health", update_health_bar)
					_add_score_label(Global.players[i].Name, Global.players[i].Score, Global.players[i].ID)
					_add_score_label.rpc(Global.players[i].Name, Global.players[i].Score, Global.players[i].ID)
					_add_weapon_class(player)
					_add_to_group()
				update_health_bar(player.health_component.current_health)
				
				player.position = current_map.pick_random_spawn().position


func _on_multiplayer_menu_remove_player(peer_id):
	Global.players.erase(peer_id)
	remove_player_for_all.rpc(peer_id)


@rpc ("call_local", "any_peer")
func remove_player_for_all(peer_id):
	Global.players.erase(peer_id)
	player = get_node_or_null(str(peer_id))
	if player:
		player.queue_free()
	var player_label = player_labels.get_node_or_null(str(peer_id))
	if player_label:
		player_label.queue_free()


func _open_choose_class(_peer_id):
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
		
		_add_to_group.rpc()
		
		var id = str(node.name).to_int()
		if Global.players.has(id):
			match Global.players[id].Class:
				"PistolOne":
					player_class = pistol_one.instantiate()
				"SMG":
					player_class = smg_gun.instantiate()
				"FreezeGun":
					player_class = freeze_gun.instantiate()
				"SpeedGun":
					player_class = speed_gun.instantiate()
				"Stake":
					player_class = stake.instantiate()
				"Sniper":
					player_class = sniper.instantiate()
				"CoinGun":
					player_class = coin_gun.instantiate()
			
			if node.is_multiplayer_authority():
				_add_weapon_class(node)
			
			_add_score_label.rpc(Global.players[id].Name, Global.players[id].Score, Global.players[id].ID)
			match Global.players[id].Team:
				1:
					node.change_material.rpc(Global.BLUE)
				2:
					node.change_material.rpc(Global.RED)
				3:
					node.change_material.rpc(Global.GREEN)
				4:
					node.change_material.rpc(Global.YELLOW)
				_:
					node.change_material.rpc(Global.PINK)
			
			
			
		for i in Global.players:
			player = get_node_or_null(str(Global.players[i].ID))
			if player != null:
				_add_score_label(Global.players[i].Name, Global.players[i].Score, Global.players[i].ID)
				
				match Global.players[i].Team:
					1:
						player.change_material(Global.BLUE)
					2:
						player.change_material(Global.RED)
					3:
						player.change_material(Global.GREEN)
					4:
						player.change_material(Global.YELLOW)
					_:
						player.change_material(Global.PINK)


func _add_weapon_class(player_node):
	player_class.name = "item" + str(randf_range(0, 10))
	player_node.view.add_child(player_class, true)
	player_node.weapon = player_class


@rpc("any_peer", "reliable")
func _add_score_label(given_name, score, id):
	var player_label = player_score_label.instantiate()
	player_label.name = str(id)
	player_label.text = given_name + ": " + str(score)
	player_labels.add_child(player_label, true)
	added_label = true


@rpc("any_peer", "call_local", "reliable")
func _add_to_group():
	var current_id = multiplayer.get_unique_id()
	
	for i in Global.players:
		var player_in_tree = get_node_or_null(str(Global.players[i].ID))
		if player_in_tree != null:
			if Global.players[i].Team != Global.players[current_id].Team:
				player_in_tree.add_to_group("Enemy")
			else:
				player_in_tree.add_to_group("Team")


@rpc ("any_peer", "call_local", "reliable")
func spawn_tracer_pivot(tracer_colour, tracer_spawn_pos, tracer_spawn_rot, distance = 1, collider = null):
	var bullet_tracer = bullet_tracer_scene.instantiate()
	
	bullet_tracer.position = tracer_spawn_pos
	bullet_tracer.rotation = tracer_spawn_rot
	
	bullet_tracer.scale.z = distance
	
	bullet_tracer.name = "tracer " + str(randf_range(0, 10))
	
	add_child(bullet_tracer, true)
	
	if tracer_colour == "gold":
		bullet_tracer.mesh.set_surface_override_material(0, gold)
	elif tracer_colour == "black":
		bullet_tracer.mesh.set_surface_override_material(0, black)
	
	if collider != null:
		bullet_tracer.look_at(collider)
	await get_tree().create_timer(2).timeout
	bullet_tracer.queue_free()


@rpc ("any_peer", "call_local", "reliable")
func load_map(given_map):
	current_map_parent.remove_child(current_map)
	
	var map_to_load
	match given_map:
		"arena":
			map_to_load = arena
		"db_building":
			map_to_load = db_building
	
	var map = map_to_load.instantiate()
	current_map_parent.add_child(map, true)
	current_map = map
	
	player = get_node_or_null(str(multiplayer.get_unique_id()))
	
	if player != null:
		player.position = current_map.pick_random_spawn().position


@rpc("any_peer", "call_local")
func spawn_player_ragdoll(given_position, given_rotation, given_force, ragdoll_colour):
	var player_ragdoll = player_ragdoll_scene.instantiate()
	add_child(player_ragdoll)
	
	player_ragdoll.global_position = given_position
	player_ragdoll.global_position.y += 1
	player_ragdoll.global_rotation = given_rotation
	
	
	player_ragdoll.mesh.set_surface_override_material(0, load(ragdoll_colour))
	
	player_ragdoll.add_force_to_test(given_force)
