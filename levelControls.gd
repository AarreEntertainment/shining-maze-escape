extends Spatial

func exit ():
	get_tree().quit()

func restart():
	get_tree().reload_current_scene()

export var can_restart = false
export var started = false
var exit_timer: float = 2
func _process(delta: float) -> void:
	if (Input.is_action_just_pressed("ui_select") or Input.is_action_just_pressed("ui_accept")) && can_restart:
		restart()
	elif Input.is_joy_button_pressed(0, 0) && !started:
		$CanvasLayer/ColorRect.check_input(false)
	elif (Input.is_key_pressed(KEY_SPACE)) and not started and not $CanvasLayer/ColorRect.input_checked:
		$CanvasLayer/ColorRect.check_input(true)
	elif (Input.is_action_just_pressed("ui_select") or Input.is_action_just_pressed("ui_accept")) and $CanvasLayer/ColorRect.input_checked and not started:
		started = true
		$CanvasLayer/ColorRect.fade_out_help()
		yield(get_tree().create_timer(6), "timeout")
		$Player.movement_locked = false
		$Enemy.started = true
	if Input.is_action_pressed("ui_cancel"):
		if not $CanvasLayer/exit.visible:
			$CanvasLayer/exit.visible = true
		exit_timer -=delta
		$CanvasLayer/exit.value = round(exit_timer/2*100)
		if exit_timer<=0:
			get_tree().quit()
	elif Input.is_action_just_released("ui_cancel"):
		$CanvasLayer/exit.visible = false
		exit_timer = 2.0
