extends XROrigin3D

var xr_interface: XRInterface

func _ready():
	# Initialize XR
	xr_interface = XRServer.find_interface("OpenXR")
	if xr_interface and xr_interface.is_initialized():
		print("OpenXR initialized successfully")
		
		# Enable VR mode
		get_viewport().use_xr = true
		
		# Get controllers
		var left_controller = $LeftController
		var right_controller = $RightController
		
		if left_controller:
			left_controller.button_pressed.connect(_on_button_pressed.bind("left"))
		if right_controller:
			right_controller.button_pressed.connect(_on_button_pressed.bind("right"))
	else:
		print("OpenXR not initialized, please check your headset connection")

func _on_button_pressed(button_name: String, controller: String):
	print("Button pressed: ", button_name, " on ", controller, " controller")