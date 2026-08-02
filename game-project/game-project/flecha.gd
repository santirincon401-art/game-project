extends Area2D

var direccion: Vector2 = Vector2.ZERO

@export var velocidad := 400.0

func _process(delta):
	position += direccion * velocidad * delta


@export var dano := 1




func _ready():
	body_entered.connect(_on_body_entered)


func _on_body_entered(body):
	if body.is_in_group("jugador"):
		body.recibir_dano(dano)
		queue_free()

	elif body.is_in_group("Pared"):
		queue_free()

func _on_visible_on_screen_enabler_2d_screen_exited() -> void:
	queue_free()
