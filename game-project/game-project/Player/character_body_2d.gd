extends CharacterBody2D

@export var speed: float = 500.0
@export var speed_sprint: float = 1000
@export var inercia_resbaladiza: float = 1.0 # Menor número = más resbala
@export var dano: int = 1
@export var vida_maxima: int = 5

var puntos: int = 0
var vida: int
var atacando := false
var rodando := false
var invencible := false
var puede_curarse := true
var combo: int = 0
var comboTime: float = 0.0
var comboTimeMax: float = 1.5

@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var area_ataque: Area2D = $Area2D
@onready var collision_ataque: CollisionShape2D = $Area2D/ataque
@onready var label_vida: Label = $CanvasLayer/Label
@onready var label_puntos: Label = $CanvasLayer/Label2
@onready var label_combo: Label = $CanvasLayer/Label3
var a = 0
var guardar = true
func _ready() -> void:
	label_combo.visible = false
	animated_sprite.play("default")
	puntos = 0
	vida = vida_maxima
	collision_ataque.disabled = true
	
	add_to_group("jugador")
	actualizar_hud()


func _physics_process(_delta: float) -> void:
	# DETECTAR SI ESTÁ PRESIONANDO SHIFT
	if combo > 0:
		comboTime -= _delta
		if comboTime <= 0:
			combo = 0
			comboTime = 0
			label_combo.visible = false
			print("Combo terminado")
	var presionando_shift := Input.is_key_pressed(KEY_SHIFT) or Input.is_action_pressed("shift")
	rodando = presionando_shift
	

	# 1. INICIAR ATAQUE (Bloqueado si está rodando)
	if Input.is_action_just_pressed("ataque") and not atacando and not rodando:
		atacando = true
		collision_ataque.disabled = false
		animated_sprite.play("ataque")

	# 2. CÁLCULO DE DIRECCIÓN DE MOVIMIENTO
	var direction := Vector2.ZERO
	direction.x = Input.get_axis("ui_left", "ui_right")
	direction.y = Input.get_axis("ui_up", "ui_down")

	if direction != Vector2.ZERO:
		direction = direction.normalized()
		actualizar_orientacion_ataque(direction)

	# 3. APLICAR MOVIMIENTO E INERCIA
	if rodando:
		# Si está rodando, interrumpe de inmediato cualquier ataque activo
		if atacando:
			atacando = false
			collision_ataque.disabled = true

		var velocidad_objetivo = direction * speed_sprint
		velocity = velocity.lerp(velocidad_objetivo, inercia_resbaladiza * _delta)
	else:
		velocity = direction * speed

	move_and_slide()

	# 4. GESTIÓN DE ANIMACIONES
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

	# 5. DETECCIÓN DE COLISIONES FÍSICAS
	_procesar_colisiones()


func _procesar_colisiones() -> void:
	for i in get_slide_collision_count():
		var collision = get_slide_collision(i)
		var body = collision.get_collider()

		if body == self:
			continue

		# Interacción con la Vela / Curación
		if body.has_method("drenar_vida") and vida < vida_maxima and puede_curarse:
			if body.drenar_vida():
				curar(1)

		# Daño por enemigos normales
		elif body.is_in_group("enemigos"):
			recibir_dano(1)

		# Daño por enemigos de tipo "pum"
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
		if body.is_in_group("enemigos"):
			body.recibir_dano(dano)
			combo += 1
			comboTime = comboTimeMax

			label_combo.text = "x" + str(combo)
			label_combo.visible = true

			animar_combo()

			print(combo)
func animar_combo() -> void:
	var tween = create_tween()

	label_combo.scale = Vector2(1.5, 1.5)

	tween.tween_property(
		label_combo,
		"scale",
		Vector2(1.0, 1.0),
		0.15
	).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

func recibir_dano(dano_recibido: int) -> void:
	if invencible:
		return

	invencible = true
	vida = clampi(vida - dano_recibido, 0, vida_maxima)
	actualizar_hud()

	animated_sprite.modulate = Color(0.885, 0.096, 0.037, 1.0)
	var tween = create_tween()
	tween.tween_property(animated_sprite, "modulate", Color.WHITE, 0.2)

	if vida <= 0:
		morir()
		return

	await get_tree().create_timer(1.0).timeout
	invencible = false


func curar(cantidad: int) -> void:
	if vida < vida_maxima and puede_curarse:
		vida = clampi(vida + cantidad, 0, vida_maxima)
		actualizar_hud()
		
		animated_sprite.modulate = Color(0.2, 1.0, 0.2)
		var tween = create_tween()
		tween.tween_property(animated_sprite, "modulate", Color.WHITE, 0.2)
		
		puede_curarse = false
		await get_tree().create_timer(0.5).timeout
		puede_curarse = true


func agregar_puntos(puntos_agregados: int) -> void:
	puntos += puntos_agregados
	actualizar_hud()


func actualizar_hud() -> void:
	if label_vida:
		label_vida.text = "HP: " + str(vida) + " / " + str(vida_maxima)
	if label_puntos:
		label_puntos.text = "Score: " + str(puntos)
	
		
	if puntos >= 250:
		get_tree().change_scene_to_file("res://ganar.tscn")


func morir() -> void:
	get_tree().change_scene_to_file("res://pantalla_de_perdida.tscn")
