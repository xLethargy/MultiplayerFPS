extends VBoxContainer

@onready var multiplayer_menu = $"../../../.."
@onready var server_joiner = $"../ServerJoiner"
@onready var choose_class = $"../ChooseClass"
@onready var warning_label = $WarningLabel

var last_menu

# Called when the node enters the scene tree for the first time.
func _ready():
	multiplayer_menu.connect("warning_signal", warning_prompt_menu)


func warning_prompt_menu(menu):
	
	match menu:
		"ChooseClass":
			warning_label.text = (
			"Are you sure you 
			want to leave the match?")
			
			last_menu = choose_class
			
		"ServerJoiner":
			warning_label.text = (
			"Are you sure you 
			want to quit the game?")
			
			last_menu = server_joiner
	self.show()


func _on_yes_pressed():
	if last_menu == server_joiner:
		get_tree().quit()
	elif last_menu == choose_class:
		self.hide()
		if multiplayer.is_server():
			var _upnp = multiplayer_menu.upnp
			var _port = multiplayer_menu.port
			#upnp.delete_port_mapping(port)
			get_tree().current_scene.send_to_main_menu.rpc()
			get_tree().current_scene.send_to_main_menu()
			server_joiner.show()
		else:
			var id = multiplayer.get_unique_id()
			multiplayer.peer_disconnected.emit(id)
			await get_tree().create_timer(0.5).timeout
			get_tree().quit()
			Global.players = {}
			#get_tree().current_scene._on_multiplayer_menu_remove_player.rpc_id(1, multiplayer.get_unique_id())
			#get_tree().current_scene.send_to_main_menu()
			
			#server_joiner.show()


func _on_no_pressed():
	self.hide()
	last_menu.show()
