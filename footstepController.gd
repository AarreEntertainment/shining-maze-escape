extends AudioStreamPlayer3D
export var walkFootStep: AudioStreamSample
export var runFootStep: AudioStreamSample
export var stepInterval: float = 1

var left: bool = true
var movement: int = 0

var intervalcounter

func step():
	if left:
		self.transform.origin = Vector3(0,1,0)
		left = false
	else:
		self.transform.origin = Vector3(0,1,0)
		left = true
	if movement == 2:
		stream = runFootStep
	elif movement == 1:
		stream = walkFootStep
	play()

func _ready() -> void:
	intervalcounter = stepInterval

func _process(delta: float) -> void:
	if intervalcounter>0:
		intervalcounter-=delta*movement
	else:
		step()
		intervalcounter = stepInterval
			
