extends StaticBody3D


func _on_audio_stream_player_3d_finished():
	await get_tree().create_timer(30).timeout
	$AudioStreamPlayer3D.play()
