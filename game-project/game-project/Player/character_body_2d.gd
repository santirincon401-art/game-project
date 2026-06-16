extends CharacterBody2D

@export var speed : float = 300.0
@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D

var atacando = false

func _physics_process(_delta):

	if Input.is_action_just_pressed("ataque") and !atacando:
		atacando = true
		animated_sprite.play("ataque")
	
	if !atacando:
		var direction : Vector2 = Vector2.ZERO
		direction.x = Input.get_axis("ui_left", "ui_right")
		direction.y = Input.get_axis("ui_up", "ui_down")

		if direction != Vector2.ZERO:
			direction = direction.normalized()
			animated_sprite.play("Walk")

			if direction.x > 0:
				animated_sprite.flip_h = false
			elif direction.x < 0:
				animated_sprite.flip_h = true
		else:
			animated_sprite.play("default")

		velocity = direction * speed
	else:
		velocity = Vector2.ZERO

	move_and_slide()

	


func _on_animated_sprite_2d_animation_finished() -> void:
	print("terminó")
	atacando = false
