extends Node
var keyboard: bool = true
var musicLow: AudioStreamPlayer = null
var musicHigh: AudioStreamPlayer = null
var staminaBar: TextureProgress =  null
var levelAnimator: AnimationPlayer = null
# Declare member variables here. Examples:
# var a: int = 2
# var b: String = "text"
func get_cancel():
	if keyboard:
		return "escape"
	else:
		return "circle"
func get_ok():
	if keyboard: return "left mouse or enter"
	else: return "triangle"
	
func get_crouch():
	if keyboard: return "C"
	else: return "square"

func get_movement():
	if keyboard: return "WASD, sprint with shift, lean with Q and E"
	else: return "left stick, sprint with R2, bumpers for lean"

func get_look():
	if keyboard: return "mouse"
	else: return "right stick"
	

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta: float) -> void:
#	pass
