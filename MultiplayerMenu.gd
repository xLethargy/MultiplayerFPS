extends CanvasLayer

@onready var main_menu = $MainMenu
@onready var address_entry = $MainMenu/MarginContainer/VBoxContainer/AddressEntry

const PORT = 9999
var enet_peer = ENetMultiplayerPeer.new()

signal add_player
signal remove_player

func _on_host_pressed():
	main_menu.hide()
	
	enet_peer.create_server(PORT)
	multiplayer.multiplayer_peer = enet_peer
	multiplayer.peer_connected.connect(call_signal_add_player, multiplayer.get_unique_id())
	multiplayer.peer_disconnected.connect(call_signal_remove_player, multiplayer.get_unique_id())
	
	add_player.emit(multiplayer.get_unique_id())
	
	upnp_setup()


func _on_join_pressed():
	main_menu.hide()
	
	enet_peer.create_client(address_entry.text, PORT)
	multiplayer.multiplayer_peer = enet_peer


func call_signal_add_player(peer_id):
	add_player.emit(peer_id)


func call_signal_remove_player(peer_id):
	remove_player.emit(peer_id)


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











