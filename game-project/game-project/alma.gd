extends CharacterBody2D

@export var speed: float = 400.0
@export var escena_bala: PackedScene 
@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
var dano = 1
var cuerpo_principal: Node2D = null # Referencia al Jugador
var ultima_direccion := Vector2.RIGHT
var puede_disparar := true
var distancia_maxima: float = 400.0 # Límite antes de regresar solo al cuerpo

func _ready() -> void:
	# Asegura que el alma nazca exactamente en la posición del cuerpo sin tirones
	if is_instance_valid(cuerpo_principal):
		global_position = cuerpo_principal.global_position

func _physics_process(_delta: float) -> void:
	# 1. BOTÓN DE REGRESO: Si presionas la tecla de transformar, regresa al cuerpo
	if Input.is_action_just_pressed("cambiar"):
		regresar_al_cuerpo()
		return

	# 2. LÍMITE DE DISTANCIA: Si te alejas mucho del cuerpo, regresa solo
	if is_instance_valid(cuerpo_principal):
		if global_position.distance_to(cuerpo_principal.global_position) > distancia_maxima:
			regresar_al_cuerpo()
			return

	# 3. MOVIMIENTO DEL ALMA
	velocity = Vector2.ZERO
	var direction = Vector2.ZERO
	if Input.is_action_pressed("ui_right"): direction.x += 1
	if Input.is_action_pressed("ui_left"): direction.x -= 1
	if Input.is_action_pressed("ui_down"): direction.y += 1
	if Input.is_action_pressed("ui_up"): direction.y -= 1

	if direction != Vector2.ZERO:
		direction = direction.normalized()
		ultima_direccion = direction 
		
		if abs(direction.x) > abs(direction.y):
			animated_sprite.play("derecha" if direction.x > 0 else "izquierda")
		else:
			animated_sprite.play("abajo" if direction.y > 0 else "arriba")
	

	velocity = direction * speed
	move_and_slide()

	# 4. DISPARO
	if Input.is_action_pressed("ataque") and puede_disparar:
		_disparar()
	_procesar_colisiones()

func _disparar() -> void:
	if not escena_bala: return
	
	puede_disparar = false
	var bala = escena_bala.instantiate()
	get_tree().current_scene.add_child(bala)
	bala.global_position = global_position
	
	if bala.has_method("configurar"):
		bala.configurar(ultima_direccion)
	
	# CONEXIÓN CLAVE: La bala hereda el daño del jugador y sabe quién es el dueño 
	# para que cuando impacte un enemigo, le sume los puntos y el combo al Player.
	if is_instance_valid(cuerpo_principal):
		if "dano" in bala:
			bala.dano = cuerpo_principal.dano
			
		if "propietario" in bala:
			bala.propietario = cuerpo_principal
		elif "propietario_nodo" in bala:
			bala.propietario_nodo = cuerpo_principal
	
	await get_tree().create_timer(0.2).timeout
	puede_disparar = true
func _procesar_colisiones() -> void:
	for i in range(get_slide_collision_count()):
		var collision = get_slide_collision(i)
		var body = collision.get_collider()
		if body == self: continue

		elif body.is_in_group("enemigos"): recibir_dano(1)
		elif body.is_in_group("pum"):
			recibir_dano(2)
			if body.has_method("recibir_dano"): body.recibir_dano(dano)
# ==========================================
# ENLACE DE DAÑO AL JUGADOR
# ==========================================
func recibir_dano(cantidad: int) -> void:
	# El alma NO sufre el daño. Se lo grita al jugador para que baje su vida/corazones.
	if is_instance_valid(cuerpo_principal) and cuerpo_principal.has_method("recibir_dano"):
		cuerpo_principal.recibir_dano(cantidad)
		
		# Feedback visual en el alma (parpadeo rojo al recibir un golpe)
		var tween = create_tween()
		animated_sprite.modulate = Color(1, 0.2, 0.2)
		tween.tween_property(animated_sprite, "modulate", Color(1, 1, 1), 0.4)

func agregar_puntos(cantidad: int) -> void:
	# La flecha recibe la orden y se la pasa al jugador
	if is_instance_valid(cuerpo_principal) and cuerpo_principal.has_method("agregar_puntos"):
		cuerpo_principal.agregar_puntos(cantidad)
			
func regresar_al_cuerpo() -> void:
	if is_instance_valid(cuerpo_principal):
		if cuerpo_principal.has_method("destransformarse"):
			cuerpo_principal.destransformarse()
func combos():
	if is_instance_valid(cuerpo_principal) and cuerpo_principal.has_method("combos"):
			cuerpo_principal.combos()
