extends CharacterBody2D

@export var escena_flecha: PackedScene
@export var vida_maxima := 2

var vida := 2
var jugador: Node2D = null
var curandose := false
var ya_se_curo := false

@onready var timer: Timer = $Timer
@onready var salida: Marker2D = $Marker2D
@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D


func _ready():
	vida = vida_maxima
	timer.timeout.connect(_on_timer_timeout)
	add_to_group("enemigos")


func _physics_process(_delta):
	velocity = Vector2.ZERO
	move_and_slide()


func _on_timer_timeout():
	if jugador == null:
		return

	if escena_flecha == null:
		return

	var flecha = escena_flecha.instantiate()

	flecha.global_position = salida.global_position
	flecha.direccion = (jugador.global_position - salida.global_position).normalized()

	get_parent().add_child(flecha)


func _on_detector_rango_body_entered(body):
	if body.is_in_group("jugador"):
		jugador = body
		timer.start()


func _on_detector_rango_body_exited(body):
	if body == jugador:
		jugador = null
		timer.stop()


func recibir_dano(dano):
	vida -= dano

	sprite.modulate = Color.RED
	await get_tree().create_timer(0.15).timeout
	sprite.modulate = Color.WHITE

	# Si queda con 1 vida intenta curarse
	if vida == 1 and !ya_se_curo and !curandose:
		curarse()

	if vida <= 0:
		morir()


func curarse():
	curandose = true

	await get_tree().create_timer(5.0).timeout

	# Si sigue vivo y todavía tiene 1 vida
	if vida == 1:
		vida = 2

		sprite.modulate = Color.GREEN
		await get_tree().create_timer(0.3).timeout
		sprite.modulate = Color.WHITE

	ya_se_curo = true
	curandose = false


func morir():
	if jugador != null:
		jugador.agregar_puntos(20)

	queue_free()
