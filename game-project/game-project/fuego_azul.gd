extends Area2D

@export var velocidad: float = 300.0
@export var dano: int = 1
var direccion: Vector2 = Vector2.ZERO
var ha_chocado: bool = false 

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var colision: CollisionShape2D = $CollisionShape2D

func _ready() -> void:
	# REFUERZO: Conectar la señal por código para asegurar que funciona
	if not sprite.animation_finished.is_connected(_on_animation_finished):
		sprite.animation_finished.connect(_on_animation_finished)
	
	if sprite.sprite_frames.has_animation("default"):
		sprite.play("default")
		
	# Timer de seguridad
	await get_tree().create_timer(5.0).timeout
	if not ha_chocado:
		queue_free()

func _physics_process(delta: float) -> void:
	if ha_chocado:
		return
		
	if direccion != Vector2.ZERO:
		global_position += direccion * velocidad * delta

func configurar_direccion(nueva_dir: Vector2) -> void:
	direccion = nueva_dir.normalized()
	rotation = direccion.angle()

func _on_body_entered(body: Node) -> void:
	if ha_chocado:
		return

	# Si es jugador o pared
	if body.is_in_group("jugador") or body.name == "Jugador" or body.is_in_group("paredes"):
		ha_chocado = true
		
		# Detener el movimiento inmediatamente
		direccion = Vector2.ZERO
		
		if (body.is_in_group("jugador") or body.name == "Jugador") and body.has_method("recibir_dano"):
			body.recibir_dano(dano)
		
		if colision:
			colision.set_deferred("disabled", true)
			
		# REFUERZO: Asegurar que choque no sea loop
		sprite.sprite_frames.set_animation_loop("choque", false)
		sprite.play("choque")

# Esta es la función que debe estar conectada a la señal animation_finished
func _on_animation_finished() -> void:
	if sprite.animation == "choque":
		queue_free()
