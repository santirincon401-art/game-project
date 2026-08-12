extends TextureRect

@export var textura_llena: Texture2D
@export var textura_vacia: Texture2D

func set_lleno() -> void:
	if textura_llena:
		texture = textura_llena

func set_vacio() -> void:
	if textura_vacia:
		texture = textura_vacia
