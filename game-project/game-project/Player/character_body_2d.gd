extends CharacterBody2D
@export var speed : float = 300.00
@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
func _physics_process(delta: float) -> void:
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
	move_and_slide()
