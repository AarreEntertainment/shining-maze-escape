extends AudioStreamPlayer
onready var director: Director = get_node("/root/Director")
export var highIntensity = false
# Declare member variables here. Examples:
# var a: int = 2
# var b: String = "text"


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	if highIntensity:
		director.musicHigh = self
	else:
		director.musicLow = self


# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta: float) -> void:
#	pass
