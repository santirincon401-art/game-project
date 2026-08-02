extends Node2D

@export var escena_golem: PackedScene
@export var escena_mago: PackedScene
@export var escena_hormiga: PackedScene
@export var tiempo_spawn: float = 1.5
var enemy = 0
@onready var timer: Timer = $Timer

var puntos_spawn = []

func _ready():
	randomize()

	puntos_spawn = [
		$Spawn1,
		$Spawn2,
		$Spawn3,
		$Spawn4
	]

	timer.wait_time = tiempo_spawn
	timer.start()


func _on_timer_timeout():
	var punto = puntos_spawn[randi() % puntos_spawn.size()]

	var radio = 500
	var posicion_final = Vector2.ZERO
	var encontrado = false

	# Buscar una posición libre
	for i in range(10):
		var angulo = randf() * TAU
		var distancia = randf() * radio

		var pos = punto.global_position + Vector2.RIGHT.rotated(angulo) * distancia

		var libre = true

		for enemigo in get_parent().get_node("Enemigos").get_children():
			if enemigo.global_position.distance_to(pos) < 40:
				libre = false
				break

		if libre:
			posicion_final = pos
			encontrado = true
			break

	if !encontrado:
		return

	# Elegir enemigo (50% Golem, 50% Mago)
	var escena: PackedScene
	enemy = randf()
	if enemy < 0.3:
		escena = escena_golem
	elif enemy <0.6:
		escena = escena_hormiga
	else:
		escena = escena_mago

	if escena == null:
		return

	var enemigo = escena.instantiate()
	enemigo.global_position = posicion_final

	get_parent().get_node("Enemigos").add_child(enemigo)
