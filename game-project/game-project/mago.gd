extends CharacterBody2D

@export var escena_flecha: PackedScene
@export var vida_maxima := 2

var vida := 2
var jugador: Node2D = null
var curandose := false
var ya_se_curo := false
var esta_muerto := false

@onready var timer: Timer = $Timer
@onready var salida: Marker2D = $Marker2D
@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var colision: CollisionShape2D = $CollisionShape2D


func _ready():
	vida = vida_maxima
	timer.timeout.connect(_on_timer_timeout)
	add_to_group("enemigos")
	sprite.play("sleep")


func _physics_process(_delta):
	velocity = Vector2.ZERO
	move_and_slide()


func _on_timer_timeout():
	if jugador == null or escena_flecha == null or esta_muerto:
		return

	var flecha = escena_flecha.instantiate()
	flecha.global_position = salida.global_position
	flecha.direccion = (jugador.global_position - salida.global_position).normalized()
	get_parent().add_child(flecha)


func _on_detector_rango_body_entered(body):
	if esta_muerto:
		return

	if body.is_in_group("jugador"):
		jugador = body
		
		# Transición de dormir a despierto
		sprite.play("despertar")
		await sprite.animation_finished
		
		# Si el jugador sigue en rango después de despertar, entra en estado activo
		if jugador != null and not esta_muerto:
			sprite.play("default")
			timer.start()


func _on_detector_rango_body_exited(body):
	if body == jugador and not esta_muerto:
		jugador = null
		timer.stop()
		
		# Transición de volver a dormir
		sprite.play("volver a dormir")
		await sprite.animation_finished
		
		# Si el jugador no ha vuelto a entrar mientras se dormía, pasa al bucle "sleep"
		if jugador == null and not esta_muerto:
			sprite.play("sleep")


func recibir_dano(dano_recibido):
	if esta_muerto:
		return

	vida -= dano_recibido

	if vida <= 0:
		morir()
		return

	# Animación y feedback visual de daño
	sprite.play("daño")
	sprite.modulate = Color.RED
	await sprite.animation_finished
	sprite.modulate = Color.WHITE

	# Si sigue vivo tras el golpe, vuelve a la animación correspondiente según si ve al jugador
	if not esta_muerto:
		if jugador != null:
			sprite.play("default")
		else:
			sprite.play("sleep")

	# Lógica de curación al quedar a 1 de vida
	if vida == 1 and not ya_se_curo and not curandose:
		curarse()


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
		
	esta_muerto = true
	timer.stop()
	
	if colision:
		colision.set_deferred("disabled", true)

	if jugador != null and jugador.has_method("agregar_puntos"):
		jugador.agregar_puntos(20)

	sprite.play("dead")
	await sprite.animation_finished
	queue_free()
