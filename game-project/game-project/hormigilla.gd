extends CharacterBody2D

@export var velocidad: float = 600.0
@export var vida: int = 1
var muerto: bool = false
var jugador: Node2D = null
var esta_en_rango: bool = false
var invulnerable := false

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D

func _ready() -> void:
	sprite.play("default")
	invulnerable = false
func _efecto_dano_azul():
	sprite.modulate = Color(0.3, 0.7, 1.0)
	var tween = create_tween()
	tween.tween_property(sprite, "modulate", Color.WHITE, 0.25)

# Función ejecutada cuando el jugador lo ataca
func recibir_dano(dano: int) -> void:

	if invulnerable:
		_efecto_dano_azul()
		return
	vida -= dano
	print("Vida del enemigo:", vida)
	if muerto:
		return
	# EFECTO ROJO DE DAÑO (Tinte temporal)
	var tween = create_tween()
	sprite.modulate = Color(1, 0.2, 0.2)
	tween.tween_property(sprite, "modulate", Color(1, 1, 1), 0.4)

	# Si se queda sin vida, desaparece
	if vida <= 0:
		if vida <= -1:
			if jugador:
				jugador.agregar_puntos(30)
		muerto = true
		sprite.play("pum")
		Sonidos.play("explosion")
		$CollisionShape2D.disabled = true
		set_physics_process(false)

		await sprite.animation_finished
		queue_free()
func _physics_process(_delta: float) -> void:
	if esta_en_rango and jugador and sprite.animation == "default":
		var direccion = (jugador.global_position - global_position).normalized()
		velocity = direccion * velocidad

		# Girar sprite hacia el jugador
		if direccion.x != 0:
			sprite.flip_h = direccion.x > 0

		move_and_slide()
	else:
		velocity = Vector2.ZERO

# EL JUGADOR ENTRA AL RANGO
func _on_detector_rango_body_entered(body: Node) -> void:
	if body.is_in_group("jugador") or body.name == "Jugador":
		jugador = body
		esta_en_rango = true
		

# EL JUGADOR SALE DEL RANGO
func _on_detector_rango_body_exited(body: Node) -> void:
	if body.is_in_group("jugador") or body == jugador or body.name == "Jugador":
		jugador = null
		esta_en_rango = false
