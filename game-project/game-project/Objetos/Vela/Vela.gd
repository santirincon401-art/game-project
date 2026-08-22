extends StaticBody2D

# Accedemos al nodo de la animación usando su ruta
@onready var anim: AnimatedSprite2D = $AnimatedSprite2D

func _ready() -> void:
	# Le decimos que reproduzca la animación default
	anim.play("default")

@export var vida_vela: int = 3 # Cuántas veces te puede curar antes de consumirse
@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D

func drenar_vida() -> bool:
	# Si la vela ya no tiene cera/vida, no cura
	if vida_vela <= 0:
		return false
		
	vida_vela -= 1
	print("Vela usada. Cera restante:", vida_vela)
	
	# Efecto visual: si tienes animaciones como "3", "2", "1" o "apagada"
	if animated_sprite.sprite_frames.has_animation(str(vida_vela)):
		animated_sprite.play(str(vida_vela))
	
	# Si se quedó sin vida, se apaga o destruye
	if vida_vela <= 0:
		apagar_vela()
		
	return true # Confirmamos que la curación fue exitosa

func apagar_vela() -> void:
	print("La vela se ha consumido por completo.")
	# Si tienes una animación de 'apagada', puedes reproducirla y quitar la colisión,
	# o simplemente eliminar el nodo:
	queue_free()
