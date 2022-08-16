extends KinematicBody
export var started = false
var nav: Navigation
var player
onready var director: Director = get_node("/root/Director")
var path: PoolVector3Array = []
var path_node = 0
var speed = 5
# Called when the node enters the scene tree for the first time.
func _ready():
	stopCooldown()
	nav = get_parent().get_node("Navigation")
	player = get_parent().get_node("Player")
export var ended = false
func _physics_process(_delta):
	if !started:
		return
	if ended:
		$"jack torrance/AnimationPlayer".play("jackOrc Idle-loop")
		$footsteps.movement = 0
		return;
		
	$footsteps.movement = 1
	if global_transform.origin.distance_to(player.global_transform.origin)<1.5:
		director.levelAnimator.play("FailState")
	$"jack torrance".rotation.y = $looker.rotation.y #lerp($"jack torrance".rotation.y,$looker.rotation.y, delta*3)
	if (path.size()>0):
		if $"jack torrance/AnimationPlayer".current_animation!="jackInjured Run-loop":
			$"jack torrance/AnimationPlayer".play("jackInjured Run-loop")
	if path_node<path.size():
		var direction = path[path_node]-global_transform.origin
		if global_transform.origin.distance_to(player.global_transform.origin)>4 && path.size()<path_node+1:
			$looker.look_at(path[path_node+1], Vector3.UP)
		else:
			$looker.look_at(player.global_transform.origin, Vector3.UP)
		
		if path.size()-path_node>=20 && !enemyCooldown:
			jump()
		#look_at(path[path_node], Vector3.UP)
		if direction.length()<1:
			path_node+=1
		else:
			var move = move_and_slide(direction.normalized()*speed, Vector3.UP)
func stopCooldown():
	yield(get_tree().create_timer(5.0), "timeout")
	enemyCooldown = false

var jumping = false

func jump():
	if jumping:
		return
	jumping = true
	yield(get_tree().create_timer(5.0), "timeout")
	#self.global_transform.origin = path[round(path.size()/2)]
	$"jack torrance/dannyscream".play()
	move_to(player.global_transform.origin)
	
var enemyCooldown = true

func _process(_delta: float) -> void:
	if !started:
		return
	var dist = global_transform.origin.distance_to(player.global_transform.origin)
	if dist<20:
		var perc = dist/20
		director.musicHigh.volume_db = -40 * perc
	else:
		director.musicHigh.volume_db = -40

func move_to(target_pos):

	path = nav.get_simple_path(global_transform.origin, target_pos)

	path_node = 0

func _on_Timer_timeout():
	if !ended:
		move_to(player.global_transform.origin)
	$Timer.start()
