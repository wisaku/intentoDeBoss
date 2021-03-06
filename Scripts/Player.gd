extends "res://Scripts/Entity.gd"

signal health_changed
signal mana_changed

const SPEED = 150
const GRAVITY = 15
const JUMP_POWER = 350
const FLOOR = Vector2(0,-1)
const ACCELERATION = 10
const VELOCITY_CAMERA_H = 2
const FRICTION_IDLE = 8
const FRICTION_DOWN_SLASH = 2
const TYPE = "PLAYER"
var in_attack = false;
var power
var friction = 6
var hurtMode = false
var dead = false
var velocity = Vector2()
var switch_anim = ""
var state = "default"
var sword = preload("res://Items/sword.tscn")
var halo = preload("res://Efects/nebula.tscn")
var fire_power = preload("res://Items/magic.tscn")
var mana = 1000

func _physics_process(delta):
	add_mana()
	if(dead):
		return
	match state:
		"default":
			state_default(delta)
		"swing":
			state_swing(delta)
		"dead":
			game_over()
	damage_loop()

func atack():
	anim_switch("Atack1")

func state_swing(delta):
	animation_loop()

func state_default(delta):
	animation_loop()
	if live == "live":
		movement_loop(delta)
	else:
		dead()
	gravity_loop(delta)
	if hurting:
		set_global_position(global_position + knockdir)
		velocity = move_and_slide(knockdir, FLOOR)
		hurting=false
	else:
		velocity = move_and_slide(velocity, FLOOR)

func anim_switch(newanim):
	switch_anim = newanim


func animation_loop():
	if $Anim.current_animation != switch_anim:
		$Anim.play(switch_anim)


func gravity_loop(delta):
	velocity.y += GRAVITY


func movement_loop(delta):
	var LEFT 	= Input.is_action_pressed("ui_left")
	var RIGHT 	= Input.is_action_pressed("ui_right")
	var UP	 	= Input.is_action_pressed("ui_up")
	var DOWN 	= Input.is_action_pressed("ui_down")
	var PUNCH 	= Input.is_action_pressed("a")
	var MAGIC_PUNCH = Input.is_action_pressed("b")
	MAGIC_PUNCH


	if RIGHT:
		moveRigth()
	elif LEFT:
		moveLeft()
	else:
		#rozamiento
		if velocity.x < 0:
			velocity.x += friction
			velocity.x = min(velocity.x,0)
			anim_switch("Idle_slash")
		elif velocity.x > 0:
			velocity.x -= friction
			velocity.x = max(velocity.x,0)
			anim_switch("Idle_slash")
		else:
			velocity.x = 0
			if is_on_floor():
				anim_switch("Idle")
				$Stand.disabled = false
	#ataque
	if PUNCH and is_on_floor():
		get_tree().get_nodes_in_group("sfx")[0].get_node("attack_player").play()
		use_item(sword)
		anim_switch("Atack1")
	if MAGIC_PUNCH and is_on_floor():
		if mana > 300: 
			$Timer.start()
			anim_switch("Power")
			get_tree().get_nodes_in_group("sfx")[0].get_node("fireball_player").play()
			var newitem = halo.instance()
			add_child(newitem)
			state = "swing"
		else:
			pass
		
	friction = FRICTION_IDLE
	if UP:
		jump()
	if velocity.y > 0:
		fallingDown()
	
	if DOWN && !(RIGHT || LEFT):
		if is_on_floor() && velocity.x != 0:
			friction = FRICTION_DOWN_SLASH
			anim_switch("Slash")
			$Stand.disabled = true
		elif is_on_floor() && velocity.x == 0:
			anim_switch("Idle_down")
		
func moveRigth():
	velocity.x += ACCELERATION
	$Sprite.flip_h = false
	velocity.x = min(velocity.x,SPEED)
	var res = $Camera2D.get_offset().x + VELOCITY_CAMERA_H
	$Camera2D.set_offset(Vector2(min(100,res),$Camera2D.get_offset().y))
	if is_on_floor():
		anim_switch("Run")
		#get_tree().get_nodes_in_group("sfx")[0].get_node("walk_player").play()

func moveLeft():
	velocity.x -= ACCELERATION
	$Sprite.flip_h = true
	velocity.x = max(velocity.x,-SPEED)
	var res = $Camera2D.get_offset().x - VELOCITY_CAMERA_H
	$Camera2D.set_offset(Vector2(max(-100,res),$Camera2D.get_offset().y))
	if is_on_floor():
		anim_switch("Run")
		#get_tree().get_nodes_in_group("sfx")[0].get_node("walk_player").play()

func jump():
	if is_on_floor():
		get_tree().get_nodes_in_group("sfx")[0].get_node("jump_player").play()
		velocity.y = -JUMP_POWER
		anim_switch("Jump")

func fallingDown():
	anim_switch("Down")

func dead():
	anim_switch("Tired")
	game_over()
	
	
		
func _on_Attack_Area_body_entered(body):
	if body.is_in_group("Enemies"):
		body.hurt()
		
func use_magic():
	
	var newitem = fire_power.instance()
	newitem.set_player(self)
	newitem.set_flip($Sprite.flip_h)
	newitem.add_to_group(str(newitem.get_name(),self))
	if($Sprite.flip_h):
		newitem.position = position + Vector2(-10,-40)
	else:
		 newitem.position = position + Vector2(10,-40)
	get_parent().add_child(newitem)
	if get_tree().get_nodes_in_group(str(newitem.get_name(), self)).size() > newitem.maxamount:
		newitem.queue_free()
	mana -= 300
	emit_signal("mana_changed", mana)
	
func use_item(item):
	var newitem = item.instance()
	newitem.add_to_group(str(newitem.get_name(),self))
	if($Sprite.flip_h):
		newitem.position += Vector2(-10,0)
	else:
		newitem.position += Vector2(10,0)
	add_child(newitem)
	if get_tree().get_nodes_in_group(str(newitem.get_name(), self)).size() > newitem.maxamount:
		newitem.queue_free()

func _on_Timer_timeout():
	if state == "dead":
		$Timer.stop()
	else:
		use_magic()
		$Timer.stop()
	
func game_over():
	$Stand.disabled = true
	$Layed.disabled = true
	$Area2D/CollisionShape2D.disabled = true
	$Attack_Area/CollisionShape2D.disabled = true
	$Anim.play("GameOver")
	dead = true
	$Control/PopupDialog.popup_centered()
	
	
	
func add_mana():
	if mana < 1000:
		mana += 0.5
	emit_signal("mana_changed", mana/10)


func add_healt(head):
	get_tree().get_nodes_in_group("sfx")[0].get_node("drink_player").play()
	health += head
	if(health > 100):
		health = 100
	emit_signal("health_changed", health)