extends XROrigin3D

var xr_interface: XRInterface
var left_controller: XRController3D
var right_controller: XRController3D

# Teleportation
var teleport_ray_length = 10.0
var is_teleporting = false
var teleport_target = Vector3.ZERO

func _ready():
	# Initialize XR
	xr_interface = XRServer.find_interface("OpenXR")
	if xr_interface and xr_interface.is_initialized():
		print("OpenXR initialized successfully")
		
		# Enable VR mode
		get_viewport().use_xr = true
		
		# Get controllers
		left_controller = $LeftController
		right_controller = $RightController
		
		if left_controller:
			left_controller.button_pressed.connect(_on_button_pressed.bind(left_controller))
			left_controller.button_released.connect(_on_button_released.bind(left_controller))
		if right_controller:
			right_controller.button_pressed.connect(_on_button_pressed.bind(right_controller))
			right_controller.button_released.connect(_on_button_released.bind(right_controller))
	else:
		print("OpenXR not initialized, please check your headset connection")

func _process(delta):
	# Handle teleportation for left controller
	if left_controller:
		var trigger_value = left_controller.get_float("trigger")
		if trigger_value > 0.5 and not is_teleporting:
			_show_teleport_ray(left_controller)

func _show_teleport_ray(controller: XRController3D):
	var from = controller.global_position
	var direction = -controller.global_transform.basis.z
	
	var space_state = get_world_3d().direct_space_state
	var query = PhysicsRayQueryParameters3D.create(from, from + direction * teleport_ray_length)
	query.exclude = [self]
	
	var result = space_state.intersect_ray(query)
	if result and result.normal.y > 0.7:  # Only teleport to flat surfaces
		teleport_target = result.position
		teleport_target.y = 0  # Keep at ground level

func _on_button_pressed(button: String, controller: XRController3D):
	print("Button pressed: ", button)
	
	# Grip button for grabbing
	if button == "grip_click":
		_try_grab(controller)
	
	# Trigger for shooting (handled by gun)
	if button == "trigger_click":
		if controller.has_meta("holding_object"):
			var held_obj = controller.get_meta("holding_object")
			if held_obj.has_method("shoot"):
				held_obj.shoot()

func _on_button_released(button: String, controller: XRController3D):
	print("Button released: ", button)
	
	# Release grip
	if button == "grip_click":
		_try_release(controller)
	
	# Teleport on trigger release (left controller)
	if button == "trigger_click" and controller == left_controller:
		if teleport_target != Vector3.ZERO:
			global_position = teleport_target
			teleport_target = Vector3.ZERO

func _try_grab(controller: XRController3D):
	# Check for nearby grabbable objects
	var grab_area = controller.get_node_or_null("GrabArea")
	if not grab_area:
		# Create grab area if it doesn't exist
		grab_area = Area3D.new()
		grab_area.name = "GrabArea"
		var collision = CollisionShape3D.new()
		var shape = SphereShape3D.new()
		shape.radius = 0.15
		collision.shape = shape
		grab_area.add_child(collision)
		controller.add_child(grab_area)
	
	var overlapping = grab_area.get_overlapping_bodies()
	for body in overlapping:
		if body.has_method("pickup"):
			body.pickup(controller)
			controller.set_meta("holding_object", body)
			print("Grabbed: ", body.name)
			break

func _try_release(controller: XRController3D):
	if controller.has_meta("holding_object"):
		var held_obj = controller.get_meta("holding_object")
		if held_obj and held_obj.has_method("drop"):
			held_obj.drop()
			controller.remove_meta("holding_object")
			print("Released object")