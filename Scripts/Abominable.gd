extends KinematicBody2D

const GRAVITY = 10
const SPEED = 35
const SPEED_ANGRY = 60 
const DAMAGE = 25
const FLOOR = Vector2(0,-1)

var velocity = Vector2()
var knockdir = Vector2(0,0)
var skeleton = preload("res://Personajes/Skeleton.tscn")
var fireDead = preload("res://Efects/fire.tscn")

const TYPE = "ENEMY"
var status = "live"
var modeAttack = false
var wait = false
var hitstun = 0
var direction = 1
var health = 500
var jump = -200
	
func _physics_process(delta):
	if status == "live":
		seek_and_destroy()
		if modeAttack:
			attack()
		else:
			if(wait):
				velocity.x = 0
			else:
				pass
	else:
		velocity.x = 0
	velocity = move_and_slide(velocity,FLOOR)
	damage_loop()
	if is_on_wall():
		turn()

func attack():
	#velocity.x = 0
	$Animation.play("Attack")

func walk():
	velocity.x = SPEED * direction
	if direction == 1:
		$Animation.flip_h = false
	else:
		$Animation.flip_h = true
	$Animation.play("Walk")
	velocity.y += GRAVITY
	
func seek_and_destroy():
	
	if is_on_wall():
		jump(rand_range(1,3))
	else:
		walk()

func jump(power):
	var skel = skeleton.instance()
	skel.position = get_global_position()
	skel.position.x +=50 * - direction
	skel.position.y +=50
	velocity.y = jump * power
	if (rand_range(0,1) < 0.5 ):
		get_parent().add_child(skel)

func evil_movement_loop():
	velocity.x = SPEED_ANGRY * direction
	if direction == 1:
		$Animation.flip_h = false
	else:
		$Animation.flip_h = true
	$Animation.play("Walk_Angry")
	velocity.y += GRAVITY
	








func _on_AttackeZone_body_entered(body):
	if body.get("TYPE") == "PLAYER" and status == "live":
		modeAttack = true
		body.recive_hurt()

func _on_AttackeZone_body_exited(body):
	if body.get("TYPE") == "PLAYER" and status == "live":
		modeAttack = false

func _on_Timer_timeout():
	modeAttack = true

func dead():
	$CollisionShape2D.set_disabled(true) 
	$Animation.play("Dead")
	status = "dead"

func hurt():
	$Animation.play("Hit")
		
func turn():
	direction = direction * -1
	$hitbox.position.x *= -1
	
	
func damage_loop():
	if hitstun > 0:
		hitstun -=1
	else:
		if TYPE == "ENEMY" && health <= 0:
			dead()
	for area in $hitbox.get_overlapping_areas():
		var body = area.get_parent()
		if hitstun == 0 and body.get("DAMAGE") != null and body.get("TYPE") != TYPE:
			health -= body.get("DAMAGE")
			hitstun = 10
			knockdir = transform.origin - body.transform.origin
			emit_signal("health_changed", health)

func _on_Animation_animation_finished():
	if status == "dead":
		queue_free()





func _on_seek_body_entered(body):
	if body.name == "Player":
		evil_movement_loop()
		#attack()
