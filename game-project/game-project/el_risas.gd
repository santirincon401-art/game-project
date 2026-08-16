extends CharacterBody2D

@export var velocidad: float = 250.0
@export var vida: int = 1

var jugador: Node2D = null
@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D

func _ready() -> void:
	set_invisible(true)
	# Arranca en default y busca al jugador automáticamente en la escena
	sprite.play("default")

	
	# Intenta encontrar al jugador al iniciar (si está en el grupo "jugador")
	jugador = get_tree().get_first_node_in_group("jugador")
	if not jugador:
		# Intento alternativo por nombre si no usa grupos
		jugador = get_tree().current_scene.find_child("Jugador", true, false)

# Función para manejar la visibilidad suave con un Tween (al entrar/salir de rango)
func set_invisible(es_invisible: bool) -> void:
	var target_alpha = 0.0 if es_invisible else 1.0
	var tween = create_tween()
	tween.tween_property(sprite, "modulate:a", target_alpha, 0.5)

# Función ejecutada cuando el jugador lo ataca
func recibir_dano(dano: int) -> void:
	vida -= dano
	
	# Reproduce la animación de daño

	if vida <= 0:
		if jugador and jugador.has_method("agregar_puntos"):
			jugador.agregar_puntos(10)
		queue_free()

func _physics_process(_delta: float) -> void:
	# Siempre persigue al jugador a velocidad de 250
	if jugador:
		var direccion = (jugador.global_position - global_position).normalized()
		velocity = direccion * velocidad

		# Girar sprite hacia el jugador
		if direccion.x != 0:
			sprite.flip_h = direccion.x < 0

		move_and_slide()
	else:
		velocity = Vector2.ZERO
		# Reintentar buscar al jugador si se perdió la referencia
		jugador = get_tree().get_first_node_in_group("jugador")

# EL GATO ENTRA AL RANGO (Se vuelve invisible)
func _on_detector_rango_body_entered(body: Node) -> void:
	if body.is_in_group("jugador") or body.name == "Jugador":
		jugador = body # Actualiza referencia por si acaso
		set_invisible(false)

# EL GATO SALE DEL RANGO (Vuelve a ser visible)
func _on_detector_rango_body_exited(body: Node) -> void:
	if body.is_in_group("jugador") or body == jugador or body.name == "Jugador":
		set_invisible(true)
