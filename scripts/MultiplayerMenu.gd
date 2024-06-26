extends CanvasLayer

@onready var main_menu = $MainMenuScreen
@onready var server_joiner = $MainMenuScreen/MainMenu/MarginContainer/ServerJoiner
@onready var choose_class = $MainMenuScreen/MainMenu/MarginContainer/ChooseClass
@onready var address_entry = $MainMenuScreen/MainMenu/MarginContainer/ServerJoiner/AddressEntry
@onready var name_entry = $MainMenuScreen/MainMenu/MarginContainer/ServerJoiner/NameEntry
@onready var sensitivity = $MainMenuScreen/MainMenu/MarginContainer/ChooseClass/VBoxContainer/HBoxContainer/Sensitivity
@onready var sensitivity_slider = $MainMenuScreen/MainMenu/MarginContainer/ChooseClass/VBoxContainer/HBoxContainer/SensSlider
@onready var team_chooser = $MainMenuScreen/MainMenu/MarginContainer/TeamChooser
@onready var click_audio = $MainMenuScreen/ClickAudio

@onready var hud = $HUD
@onready var level_scene = get_tree().current_scene

var pistol_one = preload("res://models/guns/pistol.tscn")
var smg_gun = preload("res://models/guns/pistol_2.tscn")
var freeze_gun = preload("res://models/guns/pistol_freeze.tscn")
var speed_gun = preload("res://models/guns/speed_gun.tscn")
var stake = preload("res://models/guns/stake.tscn")
var sniper = preload("res://models/guns/db_sniper.tscn")
var coin_gun = preload("res://models/guns/coin_gun.tscn")

var team_setter = 0

var death_connected = false

var port = 9999

var enet_peer

var upnp

var check_for_player
var weapon_class_node

var min_click_audio_pitch = 0.9
var max_click_audio_pitch = 1.1

signal add_player
signal remove_player

signal warning_signal(menu)

func _ready():
	multiplayer.peer_connected.connect(peer_connected, multiplayer.get_unique_id())
	multiplayer.peer_disconnected.connect(peer_disconnected, multiplayer.get_unique_id())
	multiplayer.connected_to_server.connect(connected_to_server)
	multiplayer.connection_failed.connect(connection_failed)


func _on_host_pressed():
	_play_ui_audio(click_audio, min_click_audio_pitch, max_click_audio_pitch)
	
	server_joiner.hide()
	team_chooser.show()

func setup_server():
	enet_peer = ENetMultiplayerPeer.new()
	
	var error = enet_peer.create_server(port)
	if error != OK:
		print ("cannot host...")
		team_chooser.hide()
		server_joiner.show()
		return
	
	enet_peer.get_host().compress(ENetConnection.COMPRESS_RANGE_CODER)
	
	multiplayer.set_multiplayer_peer(enet_peer)
	
	upnp_setup()
	
	team_setter = (team_setter % Global.teams) + 1
	send_player_information(name_entry.text, multiplayer.get_unique_id())
	
	team_chooser.hide()
	choose_class.show()

func _on_join_pressed():
	_play_ui_audio(click_audio, min_click_audio_pitch, max_click_audio_pitch)
	
	enet_peer = ENetMultiplayerPeer.new()
	server_joiner.hide()
	choose_class.show()
	
	enet_peer.create_client(address_entry.text, port)
	
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


@rpc("any_peer", "reliable")
func send_player_information(given_name, id, team = team_setter, weapon_class = "", score = 0, player_sensitivity = 11):
	if given_name == "":
		given_name = str(id)
	
	if !Global.players.has(id):
		Global.players[id] = {
			"Name": given_name,
			"ID": id,
			"Class": weapon_class,
			"Team": team,
			"Sensitivity": player_sensitivity,
			"Score": score
		}
	
	if multiplayer.is_server():
		team_setter = (team_setter % Global.teams) + 1
		for i in Global.players:
			send_player_information.rpc(Global.players[i].Name, i, Global.players[i].Team, Global.players[i].Class, Global.players[i].Score, Global.players[i].Sensitivity)
			_update_global_teams.rpc(Global.teams)


@rpc("any_peer", "reliable")
func _update_global_teams(value):
	Global.teams = value


func upnp_setup():
	upnp = UPNP.new()
	
	var discover_result = upnp.discover()
	assert(discover_result == UPNP.UPNP_RESULT_SUCCESS, \
		"UPNP Discover Failed! Error %s" % discover_result)
	
	assert(upnp.get_gateway() and upnp.get_gateway().is_valid_gateway(), \
		"UPNP Invalid Gateway!")
	
	var map_result = upnp.add_port_mapping(port)
	assert(map_result == UPNP.UPNP_RESULT_SUCCESS, \
		"UPNP Port Mapping Failed! Error %s" % map_result)
	
	print ("Success! Join Address: %s" % upnp.query_external_address())


@rpc ("any_peer", "call_local", "reliable")
func _server_add_player():
	add_player.emit()


func _on_pistol_one_pressed():
	_play_ui_audio(click_audio, min_click_audio_pitch, max_click_audio_pitch)
	
	_class_selected("PistolOne")
	weapon_class_node = pistol_one


func _on_pistol_two_pressed():
	_play_ui_audio(click_audio, min_click_audio_pitch, max_click_audio_pitch)
	
	_class_selected("SMG")
	weapon_class_node = smg_gun


func _on_freeze_gun_pressed():
	_play_ui_audio(click_audio, min_click_audio_pitch, max_click_audio_pitch)
	
	_class_selected("FreezeGun")
	weapon_class_node = freeze_gun


func _on_speed_gun_pressed():
	_play_ui_audio(click_audio, min_click_audio_pitch, max_click_audio_pitch)
	
	_class_selected("SpeedGun")
	weapon_class_node = speed_gun


func _on_stake_pressed():
	_play_ui_audio(click_audio, min_click_audio_pitch, max_click_audio_pitch)
	
	_class_selected("Stake")
	weapon_class_node = stake


func _on_sniper_pressed():
	_play_ui_audio(click_audio, min_click_audio_pitch, max_click_audio_pitch)
	
	weapon_class_node = sniper
	_class_selected("Sniper")

func _on_coin_gun_pressed():
	_play_ui_audio(click_audio, min_click_audio_pitch, max_click_audio_pitch)
	
	weapon_class_node = coin_gun
	_class_selected("CoinGun")

func _class_selected(weapon_class, peer_id = multiplayer.get_unique_id()):
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	if Global.players.has(peer_id):
		if !Global.game_in_progress:
			Global.game_in_progress = true
		
		update_class.rpc(multiplayer.get_unique_id(), weapon_class)
		main_menu.hide()
		hud.show()
		check_for_player = get_tree().current_scene.get_node_or_null(str(multiplayer.get_unique_id()))
		if !check_for_player:
			_server_add_player.rpc_id(1)
			check_for_player = get_tree().current_scene.get_node_or_null(str(multiplayer.get_unique_id()))
		
		if check_for_player and !death_connected:
			check_for_player.health_component.connect("death", player_died)
			death_connected = true


func player_died():
	var player_class = weapon_class_node.instantiate()
	#check_for_player.global_position = spawn_points.get_child(0, 4).position
	check_for_player.update_current_class(player_class)
	check_for_player.weapon = player_class
	check_for_player.change_speed_and_jump()


func save_class(saved_class):
	weapon_class_node = saved_class

@rpc ("any_peer", "call_local", "reliable")
func update_class(id, weapon_class):
	if Global.players.has(id):
		Global.players[id].Class = weapon_class


func _on_sens_slider_value_changed(value):
	var id = multiplayer.get_unique_id()
	sensitivity.text = str(value)
	var player_sensitivity : float = value
	if Global.players.has(id):
		Global.players[id].Sensitivity = player_sensitivity
		var player = get_tree().current_scene.get_node_or_null(str(id))
		if player != null:
			player.sensitivity = player_sensitivity
			if player_sensitivity < 6:
				player.sens_to_sway = 2
			elif player_sensitivity < 30:
				player.sens_to_sway = 10
			else:
				player.sens_to_sway = 30


func _on_quit_game_pressed():
	_play_ui_audio(click_audio, min_click_audio_pitch, max_click_audio_pitch)
	
	server_joiner.hide()
	warning_signal.emit("ServerJoiner")


func _on_leave_match_pressed():
	_play_ui_audio(click_audio, min_click_audio_pitch, max_click_audio_pitch)
	
	choose_class.hide()
	warning_signal.emit("ChooseClass")


func _play_ui_audio(audio_stream, min_pitch_scale = 1, max_pitch_scale = 1):
	audio_stream.pitch_scale = randf_range(min_pitch_scale, max_pitch_scale)
	audio_stream.play()
