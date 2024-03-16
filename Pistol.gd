extends Node3D

@onready var animation_player = $AnimationPlayer
@onready var muzzle_flash = $MuzzleFlash
@onready var hitmarker = $Hitmarker
@onready var hitmarker_timer = $Hitmarkerlength

@onready var bullet_spawn_location = $BulletSpawnLocation
@onready var bullet_scene = preload("res://pistol_bullet.tscn")

@onready var level_scene = get_tree().current_scene


var damage = 30


@rpc ("call_local")
func play_shoot_effects():
	animation_player.stop()
	animation_player.play("shoot")
	muzzle_flash.restart()
	muzzle_flash.emitting = true
	
	#level_scene.spawn_bullet(bullet_scene, bullet_spawn_location, owner)


func play_local_shoot_effects():
	hitmarker.show()
	hitmarker_timer.start()


func _on_hitmarkerlength_timeout():
	hitmarker.hide()
