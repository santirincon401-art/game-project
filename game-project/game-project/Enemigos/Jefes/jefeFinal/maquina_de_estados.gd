extends Node2D


# =========================================================
# REFERENCIAS
# =========================================================

@onready var jefe: CharacterBody2D = self.owner
@onready var animated_sprite: AnimatedSprite2D = $"../AnimatedSprite2D"

@onready var hitbox: Area2D = $"../Hitbox"
@onready var hurtbox: Area2D = $"../Hurtbox"

@onready var barravida: ProgressBar = $"../CanvasLayer/ProgressBar"

@onready var beam: Node2D = $"../beam"
@onready var beam_sprite: AnimatedSprite2D = $"../beam/AnimatedSprite2D"
@onready var beamArea2d: Area2D = $"../beam/dañoBeam"
@onready var marker_beam: Marker2D = $"../beam/MarkerBeam"


# =========================================================
# CONFIGURACIÓN
# =========================================================

@export var dano: int = 3
@export var vida_maxima: int = 100
@export var velocidad: float = 300.0


# =========================================================
# VARIABLES
# =========================================================

var vida: int = vida_maxima

var jugador: Node2D = null

var anguloResultante: Vector2

# Evita que una acción se ejecute varias veces
var ejecutando_accion: bool = false


# =========================================================
# ESTADOS
# =========================================================

enum Estado {
	START,
	FOLLOW,
	MELEE,
	BEAM,
	SUMMON,
	STUN,
	DEATH,
	DECIDIR
}

var estado_actual: Estado = Estado.START


# =========================================================
# READY
# =========================================================

func _ready() -> void:

	# El jugador busca enemigos mediante este grupo
	jefe.add_to_group("enemigos")

	# Buscar jugador
	jugador = get_tree().get_first_node_in_group("jugador")

	print("Jugador encontrado: ", jugador)

	# Configurar vida
	barravida.max_value = vida_maxima
	barravida.value = vida

	# Animación inicial
	animated_sprite.play("Start")

	# Ataques apagados
	hitbox.monitoring = false
	beamArea2d.monitoring = false
	beam.visible = false

	# Conectar hitbox
	if not hitbox.body_entered.is_connected(_on_hitbox_body_entered):
		hitbox.body_entered.connect(_on_hitbox_body_entered)


# =========================================================
# PHYSICS PROCESS
# =========================================================

func _physics_process(delta: float) -> void:

	match estado_actual:

		Estado.START:
			estado_start()

		Estado.FOLLOW:
			estado_follow(delta)

		Estado.MELEE:
			estado_melee()

		Estado.BEAM:
			estado_beam()

		Estado.SUMMON:
			estado_summon()

		Estado.STUN:
			estado_stun()

		Estado.DEATH:
			estado_death()

		Estado.DECIDIR:
			estado_decidir()


# =========================================================
# CAMBIAR ESTADO
# =========================================================

func cambiar_estado(nuevo_estado: Estado) -> void:

	if estado_actual == Estado.DEATH:
		return

	print(
		"ESTADO: ",
		Estado.keys()[estado_actual],
		" -> ",
		Estado.keys()[nuevo_estado]
	)

	estado_actual = nuevo_estado


# =========================================================
# START
# =========================================================

func estado_start() -> void:

	jefe.velocity = Vector2.ZERO

	if not animated_sprite.is_playing():

		cambiar_estado(Estado.FOLLOW)


# =========================================================
# FOLLOW
# =========================================================

func estado_follow(delta: float) -> void:

	if jugador == null:

		jugador = get_tree().get_first_node_in_group("jugador")

		if jugador == null:

			jefe.velocity = Vector2.ZERO

			return


	# Dirección hacia el jugador
	var direccion: Vector2 = (
		jugador.global_position
		- jefe.global_position
	).normalized()


	# Movimiento
	jefe.velocity = direccion * velocidad

	jefe.move_and_slide()


	# Girar hacia el jugador
	if direccion.x != 0:

		animated_sprite.flip_h = direccion.x < 0


# =========================================================
# MELEE
# =========================================================

func estado_melee() -> void:

	if ejecutando_accion:
		return

	ejecutando_accion = true

	jefe.velocity = Vector2.ZERO

	await ejecutar_melee()

	ejecutando_accion = false


# =========================================================
# EJECUTAR MELEE
# =========================================================

func ejecutar_melee() -> void:

	if jugador == null:

		jugador = get_tree().get_first_node_in_group("jugador")

		if jugador == null:

			cambiar_estado(Estado.FOLLOW)

			return


	# Cantidad de ataques
	var teletransportes: int = randi_range(3, 5)

	print(
		"MELEE: ",
		teletransportes,
		" ataques"
	)


	while teletransportes > 0:

		if jugador == null:
			break


		# =====================================================
		# ELEGIR POSICIÓN ALREDEDOR DEL JUGADOR
		# =====================================================

		var angulo: float = randf_range(0.0, TAU)

		var distancia: float = 100.0

		var desplazamiento: Vector2 = (
			Vector2.RIGHT.rotated(angulo)
			* distancia
		)

		anguloResultante = (
			jugador.global_position
			+ desplazamiento
		)


		# =====================================================
		# EFECTO DE TELETRANSPORTE
		# =====================================================

		await efecto_teletransporte()


		# =====================================================
		# TELETRANSPORTARSE
		# =====================================================

		jefe.global_position = anguloResultante


		# =====================================================
		# MIRAR AL JUGADOR
		# =====================================================

		var direccion: Vector2 = (
			jugador.global_position
			- jefe.global_position
		).normalized()


		if direccion.x != 0:

			animated_sprite.flip_h = direccion.x < 0


		# =====================================================
		# ATAQUE
		# =====================================================

		animated_sprite.play("melee")

		# Activar hitbox
		hitbox.monitoring = true


		# Tiempo de ataque
		await get_tree().create_timer(0.24).timeout


		# Desactivar hitbox
		hitbox.monitoring = false


		teletransportes -= 1

		print(
			"Ataques restantes: ",
			teletransportes
		)


		# Pequeña pausa
		await get_tree().create_timer(0.10).timeout


	# =====================================================
	# TELETRANSPORTE FINAL LEJOS
	# =====================================================

	if jugador != null:

		var angulo_final: float = randf_range(
			0.0,
			TAU
		)

		var distancia_final: float = randf_range(
			800.0,
			1200.0
		)

		var desplazamiento_final: Vector2 = (
			Vector2.RIGHT.rotated(angulo_final)
			* distancia_final
		)

		anguloResultante = (
			jugador.global_position
			+ desplazamiento_final
		)


		# Efecto
		await efecto_teletransporte()


		# Teletransportarse lejos
		jefe.global_position = anguloResultante


	# Seguridad
	hitbox.monitoring = false


	# Decidir siguiente ataque
	cambiar_estado(Estado.DECIDIR)


# =========================================================
# EFECTO TELETRANSPORTE
# =========================================================

func efecto_teletransporte() -> void:

	# =====================================================
	# PONER JEFE ROJO
	# =====================================================

	animated_sprite.modulate = Color(
		1.0,
		0.0,
		0.0,
		1.0
	)


	# =====================================================
	# CREAR PARTÍCULAS
	# =====================================================

	var particulas: GPUParticles2D = GPUParticles2D.new()

	particulas.global_position = jefe.global_position

	particulas.amount = 30

	particulas.lifetime = 0.35

	particulas.one_shot = true


	# =====================================================
	# MATERIAL DE PARTÍCULAS
	# =====================================================

	var material: ParticleProcessMaterial = (
		ParticleProcessMaterial.new()
	)

	material.emission_shape = (
		ParticleProcessMaterial.EMISSION_SHAPE_SPHERE
	)

	material.emission_sphere_radius = 15.0

	material.direction = Vector3(
		0.0,
		-1.0,
		0.0
	)

	material.spread = 180.0

	material.initial_velocity_min = 40.0

	material.initial_velocity_max = 130.0

	material.gravity = Vector3.ZERO

	material.scale_min = 0.5

	material.scale_max = 1.5


	particulas.process_material = material


	# =====================================================
	# CREAR TEXTURA DE PARTÍCULA
	# =====================================================

	var imagen: Image = Image.create(
		4,
		4,
		false,
		Image.FORMAT_RGBA8
	)

	imagen.fill(Color.WHITE)


	var textura: ImageTexture = (
		ImageTexture.create_from_image(imagen)
	)

	particulas.texture = textura


	# =====================================================
	# AÑADIR A LA ESCENA
	# =====================================================

	get_tree().current_scene.add_child(
		particulas
	)

	particulas.emitting = true


	# =====================================================
	# PEQUEÑA ESPERA
	# =====================================================

	await get_tree().create_timer(0.08).timeout


	# =====================================================
	# DESAPARECER
	# =====================================================

	animated_sprite.visible = false


	await get_tree().create_timer(0.12).timeout


	# =====================================================
	# VOLVER A APARECER
	# =====================================================

	animated_sprite.visible = true

	animated_sprite.modulate = Color.WHITE


	# =====================================================
	# ELIMINAR PARTÍCULAS
	# =====================================================

	await get_tree().create_timer(0.3).timeout


	if is_instance_valid(particulas):

		particulas.queue_free()


# =========================================================
# DECIDIR
# =========================================================

func estado_decidir() -> void:

	if ejecutando_accion:
		return


	ejecutando_accion = true

	jefe.velocity = Vector2.ZERO


	# Esperar antes de elegir
	await get_tree().create_timer(0.5).timeout


	escogerAtaque()


	ejecutando_accion = false


# =========================================================
# ESCOGER ATAQUE
# =========================================================

func escogerAtaque() -> void:

	var ataqueEscogido: int = randi_range(0, 1)

	match ataqueEscogido:

		0:

			print("🎲 ATAQUE ELEGIDO: BEAM")

			cambiar_estado(
				Estado.BEAM
			)


		1:

			print("🎲 ATAQUE ELEGIDO: SUMMON")

			cambiar_estado(
				Estado.SUMMON
			)


# =========================================================
# BEAM
# =========================================================
func estado_beam() -> void:
	if ejecutando_accion:
		return

	ejecutando_accion = true
	jefe.velocity = Vector2.ZERO

	if jugador == null:
		jugador = get_tree().get_first_node_in_group("jugador")

	if jugador == null:
		ejecutando_accion = false
		cambiar_estado(Estado.FOLLOW)
		return

	# Apuntar una sola vez al jugador
	var direccion: Vector2 = (
		jugador.global_position - beam.global_position
	).normalized()

	beam.global_rotation = direccion.angle()

	beam.visible = true
	beamArea2d.monitoring = false

	# =========================
	# 1. CARGA
	# =========================
	animated_sprite.play("Beam_inicio")
	beam_sprite.play("carga")

	await beam_sprite.animation_finished

	# =========================
	# 2. PREPARACIÓN
	# =========================
	animated_sprite.play("Beam_preparation")
	beam_sprite.play("Beam_inicio")

	await beam_sprite.animation_finished

	# =========================
	# 3. BEAM ACTIVO
	# =========================
	animated_sprite.play("Beam")
	beam_sprite.play("Beam")

	beamArea2d.monitoring = true

	await get_tree().create_timer(1.0).timeout

	# =========================
	# TERMINAR
	# =========================
	beamArea2d.monitoring = false
	beam.visible = false
	beam_sprite.stop()

	ejecutando_accion = false
	cambiar_estado(Estado.DECIDIR)


# =========================================================
# SUMMON
# =========================================================

func estado_summon() -> void:

	if ejecutando_accion:
		return


	ejecutando_accion = true

	jefe.velocity = Vector2.ZERO

	print("SUMMON")


	# =====================================================
	# AQUÍ PONDREMOS LAS INVOCACIONES
	# =====================================================

	await get_tree().create_timer(
		1.0
	).timeout


	ejecutando_accion = false


	cambiar_estado(
		Estado.DECIDIR
	)


# =========================================================
# STUN
# =========================================================

func estado_stun() -> void:

	jefe.velocity = Vector2.ZERO


# =========================================================
# DEATH
# =========================================================

func estado_death() -> void:

	jefe.velocity = Vector2.ZERO

	hitbox.monitoring = false

	beamArea2d.monitoring = false

	beam.visible = false

	# Detener animación
	animated_sprite.stop()


# =========================================================
# DETECCIÓN - ENTRA EL JUGADOR
# =========================================================

func _on_deteccion_body_entered(
	body: Node2D
) -> void:

	print(
		"ENTRO ALGO: ",
		body.name
	)


	if body.is_in_group("jugador"):

		jugador = body


		# Si estaba siguiendo,
		# comienza melee
		if estado_actual == Estado.FOLLOW:

			cambiar_estado(
				Estado.MELEE
			)


# =========================================================
# DETECCIÓN - SALE EL JUGADOR
# =========================================================

func _on_deteccion_body_exited(
	body: Node2D
) -> void:

	if body.is_in_group("jugador"):

		# No usamos null como estado.
		# Pasamos a decidir.

		if estado_actual == Estado.FOLLOW:

			cambiar_estado(
				Estado.DECIDIR
			)


# =========================================================
# RECIBIR DAÑO
# =========================================================

func recibir_dano(cantidad: int) -> void:

	if estado_actual == Estado.DEATH:
		return


	# =====================================================
	# QUITAR VIDA
	# =====================================================

	vida -= cantidad

	vida = clampi(
		vida,
		0,
		vida_maxima
	)


	# =====================================================
	# ACTUALIZAR BARRA
	# =====================================================

	barravida.value = vida


	print(
		"💥 JEFE RECIBIÓ ",
		cantidad,
		" DE DAÑO"
	)

	print(
		"❤️ VIDA DEL JEFE: ",
		vida
	)


	# =====================================================
	# EFECTO ROJO AL RECIBIR DAÑO
	# =====================================================

	animated_sprite.modulate = Color(
		1.0,
		0.1,
		0.1,
		1.0
	)


	var tween: Tween = create_tween()

	tween.tween_property(
		animated_sprite,
		"modulate",
		Color.WHITE,
		0.15
	)


	# =====================================================
	# MUERTE
	# =====================================================

	if vida <= 0:

		cambiar_estado(
			Estado.DEATH
		)


# =========================================================
# HITBOX DEL JEFE
# =========================================================

func _on_hitbox_body_entered(
	body: Node2D
) -> void:

	print(
		"HITBOX DEL JEFE DETECTÓ: ",
		body.name
	)


	if body.is_in_group("jugador"):

		if body.has_method(
			"recibir_dano"
		):

			body.recibir_dano(
				dano
			)

			print(
				"💥 JEFE GOLPEÓ AL JUGADOR"
			)


# =========================================================
# DAÑO DEL BEAM
# =========================================================

func _on_daño_beam_body_entered(
	body: Node2D
) -> void:

	if body.is_in_group("jugador"):

		if body.has_method(
			"recibir_dano"
		):

			body.recibir_dano(
				dano * 2
			)

			print(
				"🔥 BEAM GOLPEÓ AL JUGADOR"
			)


# =========================================================
# HURTBOX
# =========================================================

func _on_hurtbox_area_entered(
	area: Area2D
) -> void:

	pass
