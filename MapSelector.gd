extends Control

@onready var tick_box_scene = preload("res://components/tick_box.tscn")

@onready var arena_hbox = $PanelContainer/HBoxContainer/VBoxContainer/ArenaHBox
@onready var db_hbox = $PanelContainer/HBoxContainer/VBoxContainer2/DBHBox
@onready var map_timer = $MapTimer
@onready var timer_label = $TimerLabel

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

func _ready():
	timer_label.text = str(timer_label_value)

func _unhandled_input(event):
	if multiplayer.is_server():
		if event.is_action_pressed("testing_input"):
			if !self.visible:
				_show_maps.rpc()
			else:
				_hide_maps.rpc()

@rpc ("call_local", "any_peer", "reliable")
func _show_maps():
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
	
	_display_vote.rpc(arena_hbox.get_path())
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
	
	_display_vote.rpc(db_hbox.get_path())
	current_hbox = db_hbox
	current_vote = "db_box"
	_add_vote.rpc("db", true)


@rpc("any_peer", "call_local", "reliable")
func _display_vote(hbox_path):
	tick_box = tick_box_scene.instantiate()
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
	
	print ("total votes: ", total_votes)
	print ("players: ", Global.players.size())
	
	if timer_label_value == 0 or total_votes == Global.players.size():
		var map_to_load
		if arena_votes > db_votes:
			map_to_load = "arena"
		elif db_votes > arena_votes:
			map_to_load = "db_building"
		else:
			map_to_load = maps.pick_random()
		
		get_tree().current_scene.load_map.rpc(map_to_load)
		_hide_maps.rpc()


@rpc ("any_peer", "call_local", "reliable")
func _remove_all_votes():
	current_vote = ""
	for i in arena_hbox.get_children():
		print (i)
		arena_hbox.remove_child(i)
	
	for i in db_hbox.get_children():
		print (i)
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
