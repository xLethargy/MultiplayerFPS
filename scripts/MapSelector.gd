extends Control

@onready var tick_box_scene = preload("res://components/tick_box.tscn")

@onready var arena_hbox = $PanelContainer/HBoxContainer/VBoxContainer/ArenaHBox
@onready var db_hbox = $PanelContainer/HBoxContainer/VBoxContainer2/DBHBox
@onready var map_timer = $MapTimer
@onready var timer_label = $TimerLabel
@onready var vote_audio = $VoteAudio
@onready var multiplayer_menu = $".."

var timer_length = 15

var timer_label_value = timer_length
var tick_box
var id
var current_vote = ""
var current_hbox

var arena_votes = 0
var db_votes = 0
var total_votes = 0

var maps = ["arena", "db_building"]

var player_team = 0

func _ready():
	timer_label.text = str(timer_label_value)
	get_tree().current_scene.connect("map_loaded", _place_players)
	get_tree().current_scene.connect("players_loaded", _hide_map)

func _unhandled_input(event):
	if multiplayer.is_server() and multiplayer_menu.hud.visible:
		if event.is_action_pressed("testing_input"):
			if !self.visible:
				_show_maps.rpc()
			else:
				_hide_maps.rpc()

@rpc ("call_local", "any_peer", "reliable")
func _show_maps():
	if Global.players.has(multiplayer.get_unique_id()):
		id = multiplayer.get_unique_id()
		player_team = Global.players[id].Team
	
	show()
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	
	for i in range(timer_length):
		map_timer.start()
		await map_timer.timeout
		if self.visible == false:
			return


@rpc ("call_local", "any_peer", "reliable")
func _hide_maps():
	hide()
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	map_timer.stop()
	timer_label_value = timer_length
	timer_label.text = str(timer_label_value)
	
	db_votes = 0
	arena_votes = 0
	_remove_all_votes.rpc()

func _on_arena_texture_pressed():
	if current_vote == "arena":
		return
	
	if current_vote != "arena" and current_vote != "":
		_remove_vote.rpc(tick_box.get_path())
		if current_vote == "db_box":
			_add_vote.rpc("db", false)
	
	var random_rotation = randi_range(-20, 20)
	_display_vote.rpc(arena_hbox.get_path(), player_team, random_rotation)
	current_hbox = arena_hbox
	current_vote = "arena"
	_add_vote.rpc("arena", true)


func _on_double_building_texture_pressed():
	if current_vote == "db_box":
		return
	
	if current_vote != "db_box" and current_vote != "":
		_remove_vote.rpc(tick_box.get_path())
		if current_vote == "arena":
			_add_vote.rpc("arena", false)
	
	var random_rotation = randi_range(-15, 15)
	_display_vote.rpc(db_hbox.get_path(), player_team, random_rotation)
	current_hbox = db_hbox
	current_vote = "db_box"
	_add_vote.rpc("db", true)


@rpc("any_peer", "call_local", "reliable")
func _display_vote(hbox_path, team, icon_rotation):
	_play_vote_audio.rpc()
	
	tick_box = tick_box_scene.instantiate()
	
	var tick_box_texture = tick_box.get_child(0)
	
	match team:
		1:
			tick_box_texture.texture = load("res://images/dogs/retriever.png")
		2:
			tick_box_texture.texture = load("res://images/dogs/shiba.png")
		3:
			tick_box_texture.texture = load("res://images/dogs/thing.png")
		4:
			tick_box_texture.texture = load("res://images/dogs/labrador.png")
	
	tick_box_texture.rotation_degrees = icon_rotation
	
	var hbox = get_node(hbox_path)
	hbox.add_child(tick_box, true)
	
	


@rpc("any_peer", "call_local", "reliable")
func _remove_vote(peer_tick_box_path):
	var peer_tick_box = get_node_or_null(peer_tick_box_path)
	if peer_tick_box != null:
		peer_tick_box.queue_free()


func _on_map_timer_timeout():
	timer_label_value -= 1
	timer_label.text = str(timer_label_value)
	
	total_votes = db_votes + arena_votes
	
	if timer_label_value == 0 or total_votes == Global.players.size():
		var map_to_load
		if arena_votes > db_votes:
			map_to_load = "arena"
		elif db_votes > arena_votes:
			map_to_load = "db_building"
		else:
			map_to_load = maps.pick_random()
		
		get_tree().current_scene.load_map.rpc(map_to_load)


@rpc ("any_peer", "call_local", "reliable")
func _remove_all_votes():
	current_vote = ""
	for i in arena_hbox.get_children():
		arena_hbox.remove_child(i)
	
	for i in db_hbox.get_children():
		db_hbox.remove_child(i)


@rpc ("any_peer", "call_local", "reliable")
func _add_vote(map, add):
	if map == "db":
		if add:
			db_votes += 1
		else:
			db_votes -= 1
	elif map == "arena":
		if add:
			arena_votes += 1
		else:
			arena_votes -= 1


@rpc("any_peer", "call_local", "reliable")
func _play_vote_audio():
	vote_audio.play()


func _place_players():
	get_tree().current_scene.change_player_position.rpc_id(multiplayer.get_unique_id())


func _hide_map():
	_hide_maps.rpc()
