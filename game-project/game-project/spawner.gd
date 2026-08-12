extends Node2D

@export var escena_golem: PackedScene
@export var escena_mago: PackedScene
@export var escena_hormiga: PackedScene
@export var escena_escudo: PackedScene

@onready var timer: Timer = $Timer
@onready var barra_oleada: ProgressBar = $CanvasLayer/BarraOleada
@onready var label_oleada: Label = $CanvasLayer/LabelOleada

var puntos_spawn = []
var oleada_actual: int = 1
var puntos_meta_oleada: int = 100
var puntos_inicio_oleada: int = 0
var jugador: Node2D
var tiempo_base_spawn: float = 0.8

func _ready() -> void:
	randomize()

	puntos_spawn = [
		$Spawn1,
		$Spawn2,
		$Spawn3,
		$Spawn4
	]

	await get_tree().process_frame
	jugador = get_tree().get_first_node_in_group("jugador")
	
	iniciar_oleada()

func iniciar_oleada() -> void:
	if jugador:
		puntos_inicio_oleada = jugador.puntos

	if label_oleada:
		if oleada_actual > 4:
			label_oleada.text = "Oleada: Infinito"
		else:
			label_oleada.text = "Oleada: " + str(oleada_actual)

	match oleada_actual:
		1:
			puntos_meta_oleada = 100
			tiempo_base_spawn = 0.8
		2:
			puntos_meta_oleada = 250
			tiempo_base_spawn = 1.3
		3:
			puntos_meta_oleada = 500
			tiempo_base_spawn = 1.2
		4:
			puntos_meta_oleada = 1000
			tiempo_base_spawn = 1.1
		_:
			puntos_meta_oleada = puntos_inicio_oleada + 250
			tiempo_base_spawn = 1.0

	timer.wait_time = tiempo_base_spawn
	timer.start()


func _process(_delta: float) -> void:
	if not jugador:
		return

	var puntos_en_oleada = jugador.puntos - puntos_inicio_oleada

	if barra_oleada:
		barra_oleada.max_value = puntos_meta_oleada - puntos_inicio_oleada
		barra_oleada.value = puntos_en_oleada

	if jugador.puntos >= puntos_meta_oleada:
		completar_oleada()


func completar_oleada() -> void:
	timer.stop()

	for enemigo in get_tree().get_nodes_in_group("enemigos"):
		enemigo.queue_free()

	get_tree().paused = true
	oleada_actual += 1
	
	if oleada_actual > 5:
		puntos_inicio_oleada = jugador.puntos


func _on_timer_timeout() -> void:
	var punto = puntos_spawn[randi() % puntos_spawn.size()]
	var radio = 500
	var posicion_final = Vector2.ZERO
	var encontrado = false

	for i in range(10):
		var angulo = randf() * TAU
		var distancia = randf() * radio
		var pos = punto.global_position + Vector2.RIGHT.rotated(angulo) * distancia
		var libre = true

		for enemigo in get_tree().get_nodes_in_group("enemigos"):
			if enemigo.global_position.distance_to(pos) < 40:
				libre = false
				break

		if libre:
			posicion_final = pos
			encontrado = true
			break

	if !encontrado:
		return

	var escena: PackedScene = null
	var rnd = randf()

	match oleada_actual:
		1:
			escena = escena_golem
		2:
			escena = escena_golem if rnd < 0.5 else escena_mago
		3:
			if rnd < 0.33:
				escena = escena_golem
			elif rnd < 0.66:
				escena = escena_mago
			else:
				escena = escena_hormiga
		4:
			if rnd < 0.25:
				escena = escena_golem
			elif rnd < 0.50:
				escena = escena_mago
			elif rnd < 0.75:
				escena = escena_hormiga
			else:
				escena = escena_escudo
		_:
			if rnd < 0.10:
				escena = escena_golem
			elif rnd < 0.40:
				escena = escena_mago
			elif rnd < 0.70:
				escena = escena_hormiga
			else:
				escena = escena_escudo

	if escena == null:
		return

	var enemigo = escena.instantiate()
	enemigo.global_position = posicion_final

	get_parent().add_child(enemigo)

	if jugador:
		var puntos_en_oleada = jugador.puntos - puntos_inicio_oleada
		var aceleracion = puntos_en_oleada * 0.0005
		timer.wait_time = max(0.3, tiempo_base_spawn - aceleracion)
