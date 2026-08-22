extends CharacterBody2D

@export var escena_proyectil: PackedScene # Tu escena de la flama azul
@export var vida_maxima := 3
@export var numero_proyectiles: int = 5   # Hexágono = 6 proyectiles
@export var velocidad_giro: float = 1.0    # Velocidad de giro del patrón

var vida := 3
var jugador: Node2D = null
var esta_muerto := false
var angulo_actual: float = 0.0

@onready var timer: Timer = $Timer
@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var colision: CollisionShape2D = $CollisionShape2D

func _ready():
	vida = vida_maxima
	
	if timer:
		timer.timeout.connect(_on_timer_timeout)
		timer.start()
	
	# Reproduce siempre la única animación disponible
	if sprite:
		sprite.play("default")
	
	add_to_group("enemigos")
	jugador = get_tree().get_first_node_in_group("jugador")

func _physics_process(delta: float):
	if esta_muerto:
		return
		
	# Hace girar el patrón del hexágono constantemente
	angulo_actual += velocidad_giro * delta

	# Movimiento de persecución flotante hacia el jugador
	
# --- DISPARO EN HEXÁGONO GIRATORIO ---

func _on_timer_timeout():
	if jugador == null or escena_proyectil == null or esta_muerto:
		return
		
	var paso_angulo = TAU / numero_proyectiles

	for i in range(numero_proyectiles):
		var proyectil = escena_proyectil.instantiate()
		proyectil.global_position = global_position
		
		# Calcula la dirección de cada rayo del hexágono con la rotación actual
		var angulo_final = angulo_actual + (i * paso_angulo)
		var direccion_proyectil = Vector2(cos(angulo_final), sin(angulo_final))
		
		if proyectil.has_method("configurar_direccion"):
			proyectil.configurar_direccion(direccion_proyectil)
		elif "direccion" in proyectil:
			proyectil.direccion = direccion_proyectil
		
		get_tree().current_scene.add_child(proyectil)

# --- DAÑO Y MUERTE ---

func recibir_dano(dano_recibido):
	if esta_muerto:
		return

	# Efecto visual rojo de daño con Tween
	var tween = create_tween()
	sprite.modulate = Color(1, 0.2, 0.2)
	tween.tween_property(sprite, "modulate", Color.WHITE, 0.3)

	vida -= dano_recibido

	if vida <= 0:
		morir()

func morir():
	if esta_muerto:
		return
		
	esta_muerto = true
	if timer:
		timer.stop()
	
	if colision:
		colision.set_deferred("disabled", true)

	if jugador != null and jugador.has_method("agregar_puntos"):
		jugador.agregar_puntos(50)
		
	queue_free()
