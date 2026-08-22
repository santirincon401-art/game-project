extends Button
@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D

func _on_pressed() -> void:	
	Sonidos.play("seleccion")
	get_tree().change_scene_to_file("res://Sistemas/Sala_principal.tscn")
func _ready() -> void:
	pass
func _on_mouse_entered() -> void:
	animated_sprite.play("dormir")
var propietario = null
func agregar_puntos(cantidad: int) -> void:
	# La flecha recibe la orden y se la pasa al jugador
	if is_instance_valid(propietario) and propietario.has_method("agregar_puntos"):
		propietario.agregar_puntos(cantidad)

func _on_mouse_exited() -> void:
	animated_sprite.play("default")
