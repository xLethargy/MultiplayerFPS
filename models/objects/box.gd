extends StaticBody3D


func _on_audio_stream_player_3d_finished():
	$AudioStreamPlayer3D.play()
