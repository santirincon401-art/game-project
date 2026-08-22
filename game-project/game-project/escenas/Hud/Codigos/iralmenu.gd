extends Button


func _on_pressed() -> void:
	Sonidos.play("seleccion")
	
	get_tree().change_scene_to_file("res://escenas/Hud/inicio/pantalla_de_inicio.tscn")
