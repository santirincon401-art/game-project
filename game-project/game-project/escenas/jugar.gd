extends Button
@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D

func _on_pressed() -> void:
	Sonidos.play("seleccion")
	get_tree().change_scene_to_file("res://City.tscn")
func _ready() -> void:
	animated_sprite.play("default")
func _on_mouse_entered() -> void:
	animated_sprite.play("dormir")


func _on_mouse_exited() -> void:
	animated_sprite.play("default")
