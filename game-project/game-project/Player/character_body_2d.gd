extends CharacterBody2D

@export var speed: float = 500
@export var dano: int = 1
@export var vida_maxima: int = 5
var puntos = 0
var vida: int
var atacando := false
var invencible := false

@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var area_ataque: Area2D = $Area2D
@onready var collision_ataque: CollisionShape2D = $Area2D/ataque
@onready var label_vida: Label = $CanvasLayer/Label
@onready var label_puntos: Label = $CanvasLayer/Label2

func _ready() -> void:
	puntos = 0
	vida = vida_maxima
	collision_ataque.disabled = true
	
	# Aseguramos que el jugador esté en el grupo "jugador"
	add_to_group("jugador")
	
	actualizar_hud()

func _physics_process(_delta: float) -> void:
	# ATAQUE
	if Input.is_action_just_pressed("ataque") and !atacando:
		atacando = true
		collision_ataque.disabled = false
		animated_sprite.play("ataque")

	# MOVIMIENTO
	if !atacando:
		var direction := Vector2.ZERO
		direction.x = Input.get_axis("ui_left", "ui_right")
		direction.y = Input.get_axis("ui_up", "ui_down")

		if direction != Vector2.ZERO:
			direction = direction.normalized()
			animated_sprite.play("Walk")

			# Reorientar el Area2D según hacia dónde camines (4 direcciones)
			actualizar_orientacion_ataque(direction)
		else:
			animated_sprite.play("default")

		velocity = direction * speed
	else:
		velocity = Vector2.ZERO

	move_and_slide()

	# Recibir daño si colisionas FÍSICAMENTE contra un enemigo
	for i in get_slide_collision_count():
		var collision = get_slide_collision(i)
		var body = collision.get_collider()

		# Solo nos hace daño si el cuerpo colisionado es un ENEMIGO (y no nosotros mismos)
		if body != self and body.is_in_group("enemigos"):
			recibir_dano(1)
	# Detección de colisiones físicas (enemigos y objetos interactuables)
	for i in get_slide_collision_count():
		var collision = get_slide_collision(i)
		var body = collision.get_collider()

		# Interacción con la Vela
		if body.has_method("drenar_vida") and vida < vida_maxima and puede_curarse:
			# Solo nos curamos si la vela aún tenía vida para darnos
			if body.drenar_vida():
				curar(1)

		# Daño por enemigos (lo que ya tenías)
		elif body != self and body.is_in_group("enemigos"):
			recibir_dano(1)
		elif body != self and body.is_in_group("pum"):
			recibir_dano(2)
			
			body.recibir_dano(dano)
			

func actualizar_orientacion_ataque(direction: Vector2) -> void:
	if direction.x > 0:
		animated_sprite.flip_h = false
		area_ataque.position = Vector2(32, 0)
		area_ataque.rotation_degrees = 0
	elif direction.x < 0:
		animated_sprite.flip_h = true
		area_ataque.position = Vector2(-32, 0)
		area_ataque.rotation_degrees = 180
	elif direction.y > 0:
		area_ataque.position = Vector2(0, 32)
		area_ataque.rotation_degrees = 90
	elif direction.y < 0:
		area_ataque.position = Vector2(0, -32)
		area_ataque.rotation_degrees = 270

func _on_animated_sprite_2d_animation_finished() -> void:
	if animated_sprite.animation == "ataque":
		collision_ataque.disabled = true
		atacando = false

# CUANDO EL ATAQUE TOCA A UN ENEMIGO
func _on_area_2d_body_entered(body: Node2D) -> void:
	# Ignoramos al jugador para evitar automutilarse
	if body == self or body.is_in_group("jugador"):
		return

	if atacando and body.has_method("recibir_dano"):
		body.recibir_dano(dano)

func recibir_dano(dano_recibido: int) -> void:
	if invencible:
		return

	invencible = true
	vida = clampi(vida - dano_recibido, 0, vida_maxima)

	actualizar_hud()

	# Parpadeo/Modulación en rojo
	animated_sprite.modulate = Color(1, 0.2, 0.2)
	var tween = create_tween()
	tween.tween_property(animated_sprite, "modulate", Color.WHITE, 0.2)

	if vida <= 0:
		morir()
		return

	await get_tree().create_timer(1.0).timeout
	invencible = false
func agregar_puntos(puntosagregados):
	puntos += puntosagregados
	actualizar_hud()
func actualizar_hud() -> void:
	if label_vida:
		label_vida.text = "HP: " + str(vida) + " / " + str(vida_maxima)
	if label_puntos:
		label_puntos.text = "Score: " + str(puntos) 
	if puntos == 100:
		get_tree().change_scene_to_file("res://ganar.tscn")

func morir() -> void:
	print("Jugador muerto - Reiniciando...")
	# En lugar de queue_free(), reiniciamos la escena completa
	get_tree().change_scene_to_file("res://pantalla_de_perdida.tscn")
var puede_curarse := true

func curar(cantidad: int) -> void:
	# Solo curar si falta vida y el cooldown lo permite
	if vida < vida_maxima and puede_curarse:
		vida = clampi(vida + cantidad, 0, vida_maxima)
		actualizar_hud()
		
		# Efecto visual rápido (se ilumina / tiñe verde)
		animated_sprite.modulate = Color(0.2, 1.0, 0.2)
		var tween = create_tween()
		tween.tween_property(animated_sprite, "modulate", Color.WHITE, 0.2)
		
		# Cooldown para no vaciar la vela al instante al chocar
		puede_curarse = false
		await get_tree().create_timer(0.5).timeout
		puede_curarse = true
	
