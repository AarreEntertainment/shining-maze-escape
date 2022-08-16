extends TextureProgress


onready var director: Director = get_node("/root/Director")


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta: float) -> void:
#	pass
export var stopped: bool = false

func _on_Timer_timeout() -> void:
	if stopped:
		return
	value-=1
	if value == 0:
		director.levelAnimator.play("WinState")
	$Timer.start()
