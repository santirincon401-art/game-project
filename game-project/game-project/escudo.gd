extends CharacterBody2D

@export var vida_maxima := 2

var vida := 2
var esta_muerto := false
var invulnerable := false 

# Lista para llevar el registro de los cuerpos protegidos
var cuerpos_protegidos: Array[Node2D] = []

@onready var colision: CollisionShape2D = $CollisionShape2D
@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D


func _ready():
	vida = vida_maxima
	add_to_group("enemigos")
	add_to_group("pum")
	add_to_group("escudo")

	# Conexión de la señal de animación para transiciones fluidas
	if sprite:
		sprite.animation_finished.connect(_on_animation_finished)
		sprite.play("default")


func _physics_process(_delta):
	velocity = Vector2.ZERO
	move_and_slide()


# --- ÁREA DE PROTECCIÓN (SEÑALES DE AREAPROTECCION) ---

func _on_area_proteccion_body_entered(body: Node2D):
	if body == self or esta_muerto:
		return
	if body.is_in_group("escudo"):
		return
	if body.is_in_group("enemigos") or body.is_in_group("pum") :
		if not cuerpos_protegidos.has(body):
			cuerpos_protegidos.append(body)
			_asignar_invulnerabilidad(body, true)


func _on_area_proteccion_body_exited(body: Node2D):
	if cuerpos_protegidos.has(body):
		cuerpos_protegidos.erase(body)
		_asignar_invulnerabilidad(body, false)


func _asignar_invulnerabilidad(body: Node2D, estado: bool):
	if "invulnerable" in body:
		body.invulnerable = estado
	elif body.has_method("set_invulnerable"):
		body.set_invulnerable(estado)


# --- MANEJO DE ANIMACIONES Y ELIMINACIÓN ---

func _on_animation_finished():
	# Si terminó la animación de muerte, se destruye el nodo
	if sprite.animation == "muerte":
		queue_free()
		return

	if esta_muerto:
		return

	# Al terminar la animación de golpe/ataque ("pegar"), vuelve a su reposo según la vida restante
	if sprite.animation == "pegar":
		if vida == 1:
			sprite.play("default_primer_hit")
		else:
			sprite.play("default")


# --- DAÑO Y PARPADEO ---

func recibir_dano(dano_recibido):
	if esta_muerto:
		return

	if invulnerable:
		_efecto_dano_azul()
		return

	vida -= dano_recibido

	if vida <= 0:
		morir()
		return

	# Muestra reacción visual al golpe
	sprite.play("pegar")
	_efecto_dano_rojo()


func _efecto_dano_rojo():
	sprite.modulate = Color(1.0, 0.3, 0.3)
	var tween = create_tween()
	tween.tween_property(sprite, "modulate", Color.WHITE, 0.2)


func _efecto_dano_azul():
	sprite.modulate = Color(0.3, 0.7, 1.0)
	var tween = create_tween()
	tween.tween_property(sprite, "modulate", Color.WHITE, 0.25)


func morir():
	if esta_muerto:
		return
		
	esta_muerto = true

	# Quita la protección a todos los aliados antes de morir
	for body in cuerpos_protegidos:
		if is_instance_valid(body):
			_asignar_invulnerabilidad(body, false)
	cuerpos_protegidos.clear()

	if colision:
		colision.set_deferred("disabled", true)

	sprite.play("muerte")
