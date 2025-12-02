extends Node3D

@onready var hand_mesh = $HandMesh
@onready var index_finger = $HandMesh/IndexFinger
@onready var thumb = $HandMesh/Thumb

var controller: XRController3D
var is_gripping = false
var is_triggering = false

func _ready():
	controller = get_parent() as XRController3D
	if controller:
		controller.button_pressed.connect(_on_button_pressed)
		controller.button_released.connect(_on_button_released)

func _process(delta):
	if controller:
		# Animate fingers based on input
		var trigger_value = controller.get_float("trigger")
		var grip_value = controller.get_float("grip")
		
		# Animate index finger (trigger)
		if index_finger:
			index_finger.rotation.x = lerp(0.0, -1.0, trigger_value)
		
		# Animate other fingers (grip)
		if thumb:
			thumb.rotation.z = lerp(0.0, 0.5, grip_value)

func _on_button_pressed(button: String):
	if button == "grip_click":
		is_gripping = true
	elif button == "trigger_click":
		is_triggering = true

func _on_button_released(button: String):
	if button == "grip_click":
		is_gripping = false
	elif button == "trigger_click":
		is_triggering = false