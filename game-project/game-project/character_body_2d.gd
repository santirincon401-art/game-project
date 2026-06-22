extends CharacterBody2D

@export var velocidad: float = 100
var jugador: Node2D = null
var esta_en_rango: bool = false

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D

var vida = 3

func recibir_dano(dano):
	vida -= dano
	print("Vida:", vida)

	if vida <= 0:
		queue_free()
func _ready() -> void:
	# Empieza oculto y quieto
	sprite.play("hide")

func _physics_process(delta: float) -> void:
	# Condición estricta: SOLO se mueve si está en rango Y la animación es "default"
	if esta_en_rango and jugador and sprite.animation == "default":
		var direccion = (jugador.global_position - global_position).normalized()
		velocity = direccion * velocidad
		move_and_slide()
	else:
		# Si no cumple las condiciones, se frena por completo
		velocity = Vector2.ZERO

# Cuando el jugador entra al rango
func _on_detector_rango_body_entered(body: Node) -> void:
	if body.is_in_group("jugador") or body.name == "Jugador":
		jugador = body
		esta_en_rango = true
		sprite.play("default") # Cambia a default para activarse y empezar a seguirlo

# Cuando el jugador sale del rango
func _on_detector_rango_body_exited(body: Node) -> void:
	if body == jugador:
		jugador = null
		esta_en_rango = false
		sprite.play("hide") # Vuelve a ocultarse y la física lo detendrá
