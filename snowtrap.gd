extends Spatial


# Declare member variables here. Examples:
# var a: int = 2
# var b: String = "text"


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta: float) -> void:
#	pass


func _on_Area_body_entered(body: Node) -> void:
	if body.name=="Player":
		$Tween.interpolate_property($CSGSphere, "translation", Vector3(0,-4, 0), Vector3(0,0,0), 5, Tween.TRANS_QUINT)
		$Tween.start()
		yield(get_tree().create_timer(15.0), "timeout")
		$Tween.interpolate_property($CSGSphere, "translation", Vector3(0,0, 0), Vector3(0,-4,0), 5, Tween.TRANS_QUINT)
