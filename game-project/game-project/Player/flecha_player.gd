extends Area2D

@export var velocidad: float = 900.0
var direccion: Vector2 = Vector2.RIGHT
var dano: float = 1.0 # Valor por defecto que el Alma sobrescribirá a 0.1

func _ready() -> void:
	# Destruir la bala automáticamente después de 3 segundos para que no sature la memoria
	await get_tree().create_timer(3.0).timeout
	queue_free()

func _physics_process(delta: float) -> void:
	# Mover la bala en la dirección asignada
	position += direccion * velocidad * delta

# Función que llaman el jugador o el alma al disparar
func configurar(dir: Vector2) -> void:
	direccion = dir.normalized()
	# Rota el sprite de la bala para que apunte hacia donde se mueve
	rotation = direccion.angle()

var cuerpo_principal: Node2D = null # Referencia al Jugador
func agregar_puntos(cantidad: int) -> void:
	# La flecha recibe la orden y se la pasa al jugador
	if is_instance_valid(cuerpo_principal) and cuerpo_principal.has_method("agregar_puntos"):
		cuerpo_principal.agregar_puntos(cantidad)
	
func _on_body_entered(body):
	if body.is_in_group("enemigos") or body.is_in_group("pum"):
		if body.has_method("recibir_dano"):
			if is_instance_valid(cuerpo_principal) and cuerpo_principal.has_method("combos"):
				cuerpo_principal.combos()
			Sonidos.play("Hit_ene")
			body.recibir_dano(dano)
		
		
		
		queue_free()
