extends StaticBody2D

# Accedemos al nodo de la animación usando su ruta
@onready var anim: AnimatedSprite2D = $AnimatedSprite2D

func _ready() -> void:
	# Le decimos que reproduzca la animación default
	anim.play("default")
