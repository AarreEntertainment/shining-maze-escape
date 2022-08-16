extends ColorRect

onready var director: Director = get_node("/root/Director")

func _ready() -> void:
	pass
	
func fade_in():
	var tween_temp = Tween.new()
	add_child(tween_temp)
	tween_temp.interpolate_property(self, "modulate", Color(1,1,1,1), Color(1,1,1,0), 2, Tween.TRANS_LINEAR)
	tween_temp.start()
	yield(get_tree().create_timer(4), "timeout")
	tween_temp.queue_free()
	
func fade_out_help():
	var tween_temp = Tween.new()
	add_child(tween_temp)
	tween_temp.interpolate_property($Panel, "modulate", Color(1,1,1,1), Color(1,1,1,0), 2, Tween.TRANS_LINEAR)
	tween_temp.start()
	yield(get_tree().create_timer(4), "timeout")
	tween_temp.queue_free()
	fade_in()

var input_checked = false

func check_input(keyboard: bool):
	input_checked = true
	director.keyboard = keyboard
	$"../TextureRect/Label".text = "This is not how it ends. Press " + director.get_ok() + " to restart."
	var text: String =  "Movement:\n" + director.get_movement() + "\nLook: " + director.get_look() + "\nCrouch: " + director.get_crouch() + "\nAccept: " + director.get_ok() + "\nExit: " + director.get_cancel()
	set_text(text)

func set_text(e: String):
	$Panel/Label.text = e
