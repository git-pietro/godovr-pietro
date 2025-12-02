extends XROrigin3D

var xr_interface: XRInterface
var left_controller: XRController3D
var right_controller: XRController3D
var camera: XRCamera3D

# Locomotion settings
var movement_speed = 3.0
var rotation_speed = 90.0  # degrees per second
var smooth_turn_enabled = true
var snap_turn_angle = 45.0

# Teleportation
var teleport_ray_length = 10.0
var is_teleporting = false
var teleport_target = Vector3.ZERO
var teleport_marker: MeshInstance3D

func _ready():
	# Initialize XR
	xr_interface = XRServer.find_interface("OpenXR")
	if xr_interface and xr_interface.is_initialized():
		print("OpenXR initialized successfully")
		
		# Enable VR mode
		get_viewport().use_xr = true
		
		# Get controllers and camera
		left_controller = $LeftController
		right_controller = $RightController
		camera = $XRCamera3D
		
		if left_controller:
			left_controller.button_pressed.connect(_on_button_pressed.bind(left_controller))
			left_controller.button_released.connect(_on_button_released.bind(left_controller))
		if right_controller:
			right_controller.button_pressed.connect(_on_button_pressed.bind(right_controller))
			right_controller.button_released.connect(_on_button_released.bind(right_controller))
		
		# Create teleport marker
		_create_teleport_marker()
	else:
		print("OpenXR not initialized, please check your headset connection")

func _create_teleport_marker():
	teleport_marker = MeshInstance3D.new()
	var cylinder = CylinderMesh.new()
	cylinder.top_radius = 0.3
	cylinder.bottom_radius = 0.3
	cylinder.height = 0.05
	teleport_marker.mesh = cylinder
	
	var material = StandardMaterial3D.new()
	material.albedo_color = Color(0.2, 0.8, 1.0, 0.7)
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	teleport_marker.material_override = material
	
	get_parent().add_child(teleport_marker)
	teleport_marker.visible = false

func _process(delta):
	if not camera:
		return
	
	# Left controller - Movement and Teleportation
	if left_controller:
		# Thumbstick movement
		var left_stick = left_controller.get_vector2("primary")
		if left_stick.length() > 0.2:
			_handle_smooth_movement(left_stick, delta)
		
		# Trigger for teleport aiming
		var trigger_value = left_controller.get_float("trigger")
		if trigger_value > 0.8:
			_show_teleport_ray(left_controller)
		else:
			if teleport_marker:
				teleport_marker.visible = false
	
	# Right controller - Rotation
	if right_controller:
		var right_stick = right_controller.get_vector2("primary")
		if abs(right_stick.x) > 0.2:
			_handle_rotation(right_stick.x, delta)

func _handle_smooth_movement(stick: Vector2, delta: float):
	# Get camera forward direction (ignore Y)
	var cam_forward = -camera.global_transform.basis.z
	cam_forward.y = 0
	cam_forward = cam_forward.normalized()
	
	var cam_right = camera.global_transform.basis.x
	cam_right.y = 0
	cam_right = cam_right.normalized()
	
	# Calculate movement direction
	var movement = (cam_forward * stick.y + cam_right * stick.x) * movement_speed * delta
	
	# Move the XR origin
	global_position += movement
	
	print("Moving: ", movement)

func _handle_rotation(stick_x: float, delta: float):
	if smooth_turn_enabled:
		# Smooth rotation
		rotate_y(deg_to_rad(-stick_x * rotation_speed * delta))
	else:
		# Snap turn (implement if needed)
		pass

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
		
		# Show marker
		if teleport_marker:
			teleport_marker.visible = true
			teleport_marker.global_position = teleport_target + Vector3(0, 0.03, 0)

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
	
	# Teleport on trigger release (left controller only)
	if button == "trigger_click" and controller == left_controller:
		if teleport_target != Vector3.ZERO and teleport_marker and teleport_marker.visible:
			global_position = teleport_target
			teleport_target = Vector3.ZERO
			if teleport_marker:
				teleport_marker.visible = false

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