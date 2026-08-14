
extends CharacterBody2D

@export var escena_flecha: PackedScene
@export var vida_maxima := 2

var vida := 2
var jugador: Node2D = null
var curandose := false
var ya_se_curo := false
var esta_muerto := false
var invulnerable := false

@onready var timer: Timer = $Timer
@onready var salida: Marker2D = $Marker2D
@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var colision: CollisionShape2D = $CollisionShape2D


func _ready():
	vida = vida_maxima
	invulnerable = false
	timer.timeout.connect(_on_timer_timeout)
	
	# Conexión de la señal para manejar transiciones y eliminación
	sprite.animation_finished.connect(_on_animation_finished)
	
	add_to_group("enemigos")
	add_to_group("pum")
	sprite.play("sleep")


func _physics_process(_delta):
	velocity = Vector2.ZERO
	move_and_slide()


# --- LÓGICA DE ATAQUE ---

func _on_timer_timeout():
	if jugador == null or escena_flecha == null or esta_muerto:
		return
	Sonidos.play("disparo_mago")
	var flecha = escena_flecha.instantiate()
	flecha.global_position = salida.global_position
	flecha.direccion = (jugador.global_position - salida.global_position).normalized()
	get_parent().add_child(flecha)


func _on_detector_rango_body_entered(body):
	if esta_muerto:
		return

	if body.is_in_group("jugador"):
		jugador = body
		
		if sprite.animation == "sleep" or sprite.animation == "volver a dormir":
			sprite.play("despertar")
		elif sprite.animation == "default":
			if timer.is_stopped():
				timer.start()


func _on_detector_rango_body_exited(body):
	if body == jugador and not esta_muerto:
		jugador = null
		timer.stop()
		sprite.play("volver a dormir")


# --- MANEJO DE ANIMACIONES Y ELIMINACIÓN ---

func _on_animation_finished():
	# Si terminó de reproducir la animación de muerte, borra el nodo
	if sprite.animation == "dead":
		queue_free()
		return

	if esta_muerto:
		return

	match sprite.animation:
		"despertar":
			if jugador != null:
				sprite.play("default")
				if timer.is_stopped():
					timer.start()
			else:
				sprite.play("sleep")
		"volver a dormir":
			if jugador == null:
				sprite.play("sleep")
			else:
				sprite.play("despertar")


# --- SALUD Y DAÑO ---

func recibir_dano(dano_recibido):
	if esta_muerto:
		return

	if invulnerable:
		_efecto_dano_azul()
		return

	var tween = create_tween()
	sprite.modulate = Color(1, 0.2, 0.2)
	tween.tween_property(sprite, "modulate", Color.WHITE, 0.3)

	vida -= dano_recibido

	if vida <= 0:
		morir()
		return

	if jugador != null and timer.is_stopped():
		sprite.play("default")
		timer.start()

	if vida == 1 and not ya_se_curo and not curandose:
		curarse()


func _efecto_dano_azul():
	sprite.modulate = Color(0.3, 0.7, 1.0)
	var tween = create_tween()
	tween.tween_property(sprite, "modulate", Color.WHITE, 0.25)


func curarse():
	curandose = true
	await get_tree().create_timer(5.0).timeout

	if vida == 1 and not esta_muerto:
		vida = 2
		sprite.modulate = Color.GREEN
		await get_tree().create_timer(0.3).timeout
		sprite.modulate = Color.WHITE

	ya_se_curo = true
	curandose = false


func morir():
	if esta_muerto:
		return
	Sonidos.play("explosion")
	esta_muerto = true
	timer.stop()
	
	if colision:
		colision.set_deferred("disabled", true)

	if jugador != null and jugador.has_method("agregar_puntos"):
		jugador.agregar_puntos(20)

	sprite.play("dead")
