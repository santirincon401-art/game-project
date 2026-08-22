extends Node2D

@export var escena_golem: PackedScene
@export var escena_mago: PackedScene
@export var escena_hormiga: PackedScene
@export var escena_escudo: PackedScene

@export var barra_oleada: ProgressBar
@export var label_oleada: Label
@export var menu_mejoras: Control
@export var btn_puntos: Button
@export var btn_dano: Button
@export var btn_velocidad: Button

@onready var timer: Timer = $Timer

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
	
	if menu_mejoras:
		menu_mejoras.visible = false
	
	# Configurar los pivots de los botones al centro para que el tween de escala o movimiento quede perfecto
	for btn in [btn_puntos, btn_dano, btn_velocidad]:
		if btn:
			btn.pivot_offset = btn.size / 2.0
	
	iniciar_oleada()

func iniciar_oleada() -> void:
	if jugador:
		puntos_inicio_oleada = jugador.puntos

	if label_oleada:
		if oleada_actual > 4:
			label_oleada.text = "Round: 2500"
		else:
			label_oleada.text = "Round: " + str(oleada_actual)

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
		if enemigo is Node2D:
			enemigo.queue_free()

	get_tree().paused = true
	if menu_mejoras:
		menu_mejoras.visible = true
		
		# Animación de entrada god para el menú (Fade in y escalado desde el centro)
		menu_mejoras.modulate.a = 0.0
		menu_mejoras.scale = Vector2(0.8, 0.8)
		var tween_menu = create_tween().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
		tween_menu.parallel().tween_property(menu_mejoras, "modulate:a", 1.0, 0.3)
		tween_menu.parallel().tween_property(menu_mejoras, "scale", Vector2.ONE, 0.3).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


# --- FUNCIONES PRESSED CON TWEEN GOD ---

func _on_btnpuntos_pressed() -> void:
	print("¡Mejora elegida: Puntos!")
	jugador.multipuntos += 0.25
	Sonidos.play("seleccion")
	Sonidos.play("mejora")
	animar_y_finalizar(btn_puntos, func(): 
		finalizar_mejora()
	)


func _on_btndano_pressed() -> void:
	if jugador:
		Sonidos.play("seleccion")
		Sonidos.play("mejora")
		jugador.dano += 1
		print("¡Mejora elegida: Daño aumentado a ", jugador.dano, "!")
	animar_y_finalizar(btn_dano, func(): 
		finalizar_mejora()
	)


func _on_btnvelocidad_pressed() -> void:
	if jugador:
		Sonidos.play("seleccion")
		Sonidos.play("mejora")
		jugador.speed += 100.0
		print("¡Mejora elegida: Velocidad aumentada a ", jugador.speed, "!")
	animar_y_finalizar(btn_velocidad, func(): 
		finalizar_mejora()
	)


# Función para hacer el efecto de que el poder seleccionado se sube y brilla bien pro
func animar_y_finalizar(boton: Button, callback: Callable) -> void:
	# Desactivar los botones para evitar múltiples clics locos
	if btn_puntos: btn_puntos.disabled = true
	if btn_dano: btn_dano.disabled = true
	if btn_velocidad: btn_velocidad.disabled = true

	var tween = create_tween().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	
	# El botón seleccionado se hace más grande y se desplaza hacia arriba con su transición correcta
	var t_scale = tween.parallel().tween_property(boton, "scale", Vector2(1.25, 1.25), 0.25)
	t_scale.set_trans(Tween.TRANS_BACK)
	t_scale.set_ease(Tween.EASE_OUT)
	
	var t_pos = tween.parallel().tween_property(boton, "position:y", boton.position.y - 30, 0.25)
	t_pos.set_trans(Tween.TRANS_QUAD)
	t_pos.set_ease(Tween.EASE_OUT)
	
	# Los otros botones se desvanecen hacia abajo
	for b in [btn_puntos, btn_dano, btn_velocidad]:
		if b and b != boton:
			var tween_otros = create_tween().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
			tween_otros.tween_property(b, "modulate:a", 0.0, 0.2)

	await tween.finished
	callback.call()

func finalizar_mejora() -> void:
	if menu_mejoras:
		menu_mejoras.visible = false
		# Restaurar opacidad y escala del menú y los botones para la próxima vez
		menu_mejoras.modulate.a = 1.0
		menu_mejoras.scale = Vector2.ONE

	for b in [btn_puntos, btn_dano, btn_velocidad]:
		if b:
			b.disabled = false
			b.modulate.a = 1.0
			b.scale = Vector2.ONE
			# Restablecer la posición original si la moviste (puedes ajustar esto según tu diseño de UI)

	get_tree().paused = false
	
	oleada_actual += 1
	if oleada_actual > 5:
		puntos_inicio_oleada = jugador.puntos

	iniciar_oleada()


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
			if enemigo is Node2D and enemigo.global_position.distance_to(pos) < 40:
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
