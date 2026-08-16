extends CharacterBody2D

@export var escena_flecha: PackedScene
@export var speed: float = 500.0
@export var speed_sprint: float = 1000
@export var inercia_resbaladiza: float = 1.0
@export var dano: int = 1
@export var vida_maxima: int = 7
@export var escena_corazon: PackedScene

@onready var contenedor_corazones: HBoxContainer = $CanvasLayer/ContenedorCorazones
@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var area_ataque: Area2D = $Area2D
@onready var collision_ataque: CollisionShape2D = $Area2D/ataque
@onready var label_puntos: Label = $CanvasLayer/Label2
@onready var label_combo: Label = $CanvasLayer/Label3
@onready var barra_combo: ProgressBar = $CanvasLayer/BarraCombo
@onready var salida_fuego: Marker2D = $Marker2D


var multipuntos = 1
var puntos: int = 0
var vida: int

var atacando := false
var rodando := false
var invencible := false
var puede_curarse := true

var combo: int = 0
var comboTime: float = 0.0
var comboTimeMax: float = 1.5

var tween_score: Tween

var a = 0
var guardar = true

# Última dirección en la que se movió el jugador
var ultima_direccion := Vector2.RIGHT

# Control del disparo
var puede_lanzar_fuego := true
var fuego_presionado := false


func _ready() -> void:
	print("hola")
	label_combo.visible = false

	animated_sprite.play("default")

	puntos = 0
	vida = vida_maxima

	collision_ataque.disabled = true

	iniciar_animacion_continua()

	add_to_group("jugador")

	actualizar_hud()

	barra_combo.visible = false
	barra_combo.max_value = comboTimeMax


func _physics_process(_delta: float) -> void:

	# ==========================================
	# COMBO
	# ==========================================

	if combo > 0:

		comboTime -= _delta

		barra_combo.value = comboTime

		if comboTime <= 0:

			combo = 0
			label_combo.visible = false
			barra_combo.visible = false
	if Input.is_action_just_pressed("fuego") and puede_lanzar_fuego and not fuego_presionado:
		_lanzar_fuego()
		fuego_presionado = true

	# ==========================================
	# RODAR
	# ==========================================

	var presionando_shift := Input.is_key_pressed(KEY_SHIFT) or Input.is_action_pressed("shift")

	rodando = presionando_shift


	# ==========================================
	# ATAQUE NORMAL
	# ==========================================

	if Input.is_action_just_pressed("ataque") and not atacando and not rodando:

		atacando = true
		collision_ataque.disabled = false
		animated_sprite.play("ataque")


	# ==========================================
	# BOLA DE FUEGO
	# ==========================================

	


	if not Input.is_key_pressed(KEY_F):

		fuego_presionado = false


	# ==========================================
	# DIRECCIÓN
	# ==========================================

	var direction := Vector2.ZERO

	direction.x = Input.get_axis("ui_left", "ui_right")
	direction.y = Input.get_axis("ui_up", "ui_down")


	if direction != Vector2.ZERO:

		direction = direction.normalized()

		# Guardamos la última dirección
		ultima_direccion = direction

		actualizar_orientacion_ataque(direction)


	# ==========================================
	# MOVIMIENTO
	# ==========================================

	if rodando:

		# Interrumpir ataque al rodar

		if atacando:

			atacando = false
			collision_ataque.disabled = true


		var velocidad_objetivo = direction * speed_sprint

		velocity = velocity.lerp(
			velocidad_objetivo,
			inercia_resbaladiza * _delta
		)

	else:

		velocity = direction * speed


	move_and_slide()


	# ==========================================
	# ANIMACIONES
	# ==========================================

	if rodando:

		if not guardar and animated_sprite.animation == "guardar":
			return


		if guardar:

			animated_sprite.play("guardar")
			guardar = false

			return


		animated_sprite.play("rodar")


	elif not atacando:

		if not guardar:

			animated_sprite.play("desguardar")


		guardar = true


		if animated_sprite.animation == "desguardar":
			return


		if direction != Vector2.ZERO:

			animated_sprite.play("Walk")

		else:

			animated_sprite.play("default")


	# ==========================================
	# COLISIONES
	# ==========================================

	_procesar_colisiones()


func _procesar_colisiones() -> void:

	for i in get_slide_collision_count():

		var collision = get_slide_collision(i)
		var body = collision.get_collider()


		if body == self:
			continue


		# Curación

		if body.has_method("drenar_vida") and vida < vida_maxima and puede_curarse:

			if body.drenar_vida():

				curar(1)


		# Enemigos normales

		elif body.is_in_group("enemigos"):

			recibir_dano(1)


		# Enemigos tipo pum

		elif body.is_in_group("pum"):

			recibir_dano(2)

			if body.has_method("recibir_dano"):

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


	elif animated_sprite.animation == "guardar":

		animated_sprite.play("rodar")


	elif animated_sprite.animation == "desguardar":

		animated_sprite.play("Walk")


func _on_area_2d_body_entered(body: Node2D) -> void:

	if body == self or body.is_in_group("jugador"):
		return


	if atacando and body.has_method("recibir_dano"):

		Sonidos.play("Hit_ene")


		# Verificar invencibilidad

		if "invencible" in body and body.invencible:

			return


		if body.is_in_group("enemigos"):

			var puntos_a_sumar = 1 + combo

			body.recibir_dano(dano)

			combo += 1

			comboTime = comboTimeMax

			barra_combo.visible = true

			label_combo.text = "x" + str(combo)

			label_combo.visible = true

			agregar_puntos(puntos_a_sumar)

			animar_combo()

			print(combo)


func animar_combo() -> void:

	var tween = create_tween()

	label_combo.pivot_offset = label_combo.size / 2

	label_combo.scale = Vector2(1.6, 1.6)
	label_combo.rotation_degrees = 10

	tween.set_parallel(true)

	tween.tween_property(
		label_combo,
		"scale",
		Vector2(1.0, 1.0),
		0.3
	).set_trans(Tween.TRANS_BACK)

	tween.tween_property(
		label_combo,
		"rotation_degrees",
		0,
		0.3
	).set_trans(Tween.TRANS_ELASTIC)


func recibir_dano(dano_recibido: int) -> void:

	if invencible:

		return


	Sonidos.play("Hit_jugador")

	invencible = true

	vida = clampi(
		vida - dano_recibido,
		0,
		vida_maxima
	)

	actualizar_hud()


	# Efecto de daño

	animated_sprite.modulate = Color(
		0.885,
		0.096,
		0.037,
		1.0
	)

	var tween = create_tween()

	tween.tween_property(
		animated_sprite,
		"modulate",
		Color.WHITE,
		0.2
	)


	if vida <= 0:

		morir()

		return


	await get_tree().create_timer(1.0).timeout

	invencible = false


func curar(cantidad: int) -> void:

	if vida < vida_maxima and puede_curarse:

		vida = clampi(
			vida + cantidad,
			0,
			vida_maxima
		)

		actualizar_hud()


		# Efecto de curación

		animated_sprite.modulate = Color(
			0.2,
			1.0,
			0.2
		)

		var tween = create_tween()

		tween.tween_property(
			animated_sprite,
			"modulate",
			Color.WHITE,
			0.2
		)


		puede_curarse = false

		await get_tree().create_timer(0.5).timeout

		puede_curarse = true


func agregar_puntos(puntos_agregados: int) -> void:

	puntos += puntos_agregados * multipuntos

	actualizar_hud()

	animar_score()


func iniciar_animacion_continua() -> void:

	if tween_score and tween_score.is_valid():

		tween_score.kill()


	tween_score = create_tween().set_loops()


	tween_score.tween_property(
		label_puntos,
		"scale",
		Vector2(1.1, 1.1),
		0.4
	).set_trans(Tween.TRANS_SINE)


	tween_score.tween_property(
		label_puntos,
		"scale",
		Vector2(1.0, 1.0),
		0.4
	).set_trans(Tween.TRANS_SINE)


func animar_score() -> void:

	if tween_score and tween_score.is_valid():

		tween_score.kill()


	var tween = create_tween()

	label_puntos.modulate = Color(
		0.2,
		1.0,
		0.2
	)

	label_puntos.scale = Vector2(1.5, 1.5)


	tween.parallel().tween_property(
		label_puntos,
		"scale",
		Vector2(1.0, 1.0),
		0.3
	).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


	tween.parallel().tween_property(
		label_puntos,
		"modulate",
		Color.WHITE,
		0.3
	)


	tween.tween_callback(iniciar_animacion_continua)


func actualizar_hud() -> void:

	# Puntos

	if label_puntos:

		label_puntos.text = "Score: " + str(puntos)


	# Corazones

	_actualizar_corazones_visuales()


	# Ganar

	if puntos >= 2500:

		get_tree().change_scene_to_file("res://ganar.tscn")


# ==========================================
# LANZAR BOLA DE FUEGO
# ==========================================

# ==========================================
# LANZAR BOLA DE FUEGO
# ==========================================

func _lanzar_fuego() -> void:

	if escena_flecha == null:
		print("ERROR: escena_flecha no está asignada")
		return

	if salida_fuego == null:
		print("ERROR: No existe Marker2D llamado Marker2D")
		return

	if not puede_lanzar_fuego:
		return

	puede_lanzar_fuego = false

	var bola = escena_flecha.instantiate()

	get_tree().current_scene.add_child(bola)

	bola.global_position = salida_fuego.global_position

	if bola.has_method("configurar"):
		bola.configurar(ultima_direccion)
	else:
		bola.direccion = ultima_direccion

	print("🔥 BOLA CREADA")
	print("Dirección: ", ultima_direccion)

	await get_tree().create_timer(0.5).timeout

	puede_lanzar_fuego = true


	# Cooldown

	await get_tree().create_timer(0.5).timeout

	puede_lanzar_fuego = true


func _actualizar_corazones_visuales() -> void:

	if not contenedor_corazones:

		return


	# Crear corazones

	if contenedor_corazones.get_child_count() != vida_maxima:

		for n in contenedor_corazones.get_children():

			n.queue_free()


		for i in range(vida_maxima):

			var corazon = escena_corazon.instantiate()

			contenedor_corazones.add_child(corazon)


	# Actualizar corazones

	var lista_corazones = contenedor_corazones.get_children()


	for i in range(lista_corazones.size()):

		var corazon = lista_corazones[i]


		if i < vida:

			if corazon.has_method("set_lleno"):

				corazon.set_lleno()

			else:

				corazon.texture = preload(
					"res://corazon.png"
				)


		else:

			if corazon.has_method("set_vacio"):

				corazon.set_vacio()

			else:

				corazon.texture = preload(
					"res://nocorazon.png"
				)


func morir() -> void:

	get_tree().change_scene_to_file(
		"res://pantalla_de_perdida.tscn"
	)
