extends CanvasLayer

@onready var main_menu = $MainMenuScreen
@onready var server_joiner = $MainMenuScreen/MainMenu/MarginContainer/ServerJoiner
@onready var choose_class = $MainMenuScreen/MainMenu/MarginContainer/ChooseClass
@onready var address_entry = $MainMenuScreen/MainMenu/MarginContainer/ServerJoiner/AddressEntry
@onready var name_entry = $MainMenuScreen/MainMenu/MarginContainer/ServerJoiner/NameEntry
@onready var sensitivity = $MainMenuScreen/MainMenu/MarginContainer/ChooseClass/HBoxContainer/Sensitivity
@onready var sensitivity_slider = $MainMenuScreen/MainMenu/MarginContainer/ChooseClass/HBoxContainer/SensSlider

@onready var hud = $HUD

var pistol_one = preload("res://pistol.tscn")
var smg_gun = preload("res://pistol_2.tscn")
var freeze_gun = preload("res://pistol_freeze.tscn")
var speed_gun = preload("res://speed_gun.tscn")

var player_sensitivity = 11

var team_setter = 0
var teams = 2

const PORT = 9999

var enet_peer

signal add_player
signal remove_player

func _ready():
	multiplayer.peer_connected.connect(peer_connected, multiplayer.get_unique_id())
	multiplayer.peer_disconnected.connect(peer_disconnected, multiplayer.get_unique_id())
	multiplayer.connected_to_server.connect(connected_to_server)
	multiplayer.connection_failed.connect(connection_failed)


func _on_host_pressed():
	server_joiner.hide()
	choose_class.show()
	
	enet_peer = ENetMultiplayerPeer.new()
	
	var error = enet_peer.create_server(PORT)
	if error != OK:
		print ("cannot host...")
		return
	
	enet_peer.get_host().compress(ENetConnection.COMPRESS_RANGE_CODER)
	
	multiplayer.set_multiplayer_peer(enet_peer)
	
	upnp_setup()
	
	send_player_information(name_entry.text, multiplayer.get_unique_id())


func _on_join_pressed():
	enet_peer = ENetMultiplayerPeer.new()
	server_joiner.hide()
	choose_class.show()
	
	enet_peer.create_client(address_entry.text, PORT)
	
	enet_peer.get_host().compress(ENetConnection.COMPRESS_RANGE_CODER)
	
	multiplayer.set_multiplayer_peer(enet_peer)


func peer_connected(peer_id):
	print ("Player connected: ", str(peer_id))


func peer_disconnected(peer_id):
	remove_player.emit(peer_id)


func connected_to_server():
	print("connected to server")
	send_player_information.rpc_id(1, name_entry.text, multiplayer.get_unique_id())


func connection_failed():
	print ("connection failed")

@rpc("any_peer")
func send_player_information(given_name, id, weapon_class = ""):
	team_setter = (team_setter % teams) + 1
	if !Global.players.has(id):
		Global.players[id] = {
			"Name": given_name,
			"ID": id,
			"Class": weapon_class,
			"Team": team_setter,
			"Sensitivity": player_sensitivity
		}
	
	if multiplayer.is_server():
		for i in Global.players:
			send_player_information.rpc(Global.players[i].Name, i)


func upnp_setup():
	var upnp = UPNP.new()
	
	var discover_result = upnp.discover()
	assert(discover_result == UPNP.UPNP_RESULT_SUCCESS, \
		"UPNP Discover Failed! Error %s" % discover_result)
	
	assert(upnp.get_gateway() and upnp.get_gateway().is_valid_gateway(), \
		"UPNP Invalid Gateway!")
	
	var map_result = upnp.add_port_mapping(PORT)
	assert(map_result == UPNP.UPNP_RESULT_SUCCESS, \
		"UPNP Port Mapping Failed! Error %s" % map_result)
	
	print ("Success! Join Address: %s" % upnp.query_external_address())


@rpc ("any_peer", "call_local")
func _server_add_player():
	add_player.emit()


func _on_pistol_one_pressed():
	_class_selected("PistolOne", pistol_one)


func _on_pistol_two_pressed():
	_class_selected("SMG", smg_gun)


func _on_freeze_gun_pressed():
	_class_selected("FreezeGun", freeze_gun)


func _on_speed_gun_pressed():
	_class_selected("SpeedGun", speed_gun)


func _class_selected(weapon_class, weapon_class_node, peer_id = multiplayer.get_unique_id()):
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	if Global.players.has(peer_id):
		if !Global.game_in_progress:
			Global.game_in_progress = true
		
		update_class.rpc(multiplayer.get_unique_id(), weapon_class)
		main_menu.hide()
		hud.show()
		var check_for_player = get_tree().current_scene.get_node_or_null(str(multiplayer.get_unique_id()))
		if !check_for_player:
			_server_add_player.rpc_id(1)
			check_for_player = get_tree().current_scene.get_node_or_null(str(multiplayer.get_unique_id()))
		
		if check_for_player:
			var player_class = weapon_class_node.instantiate()
			check_for_player.global_position = Vector3(0, 0, 0)
			check_for_player.update_current_class(player_class)
			check_for_player.weapon = player_class
			check_for_player.frozen = false


@rpc ("any_peer", "call_local")
func update_class(id, weapon_class):
	if Global.players.has(id):
		Global.players[id].Class = weapon_class


func _on_sens_slider_value_changed(value):
	var id = multiplayer.get_unique_id()
	sensitivity.text = str(value)
	player_sensitivity = value
	if Global.players.has(id):
		Global.players[id].Sensitivity = player_sensitivity
