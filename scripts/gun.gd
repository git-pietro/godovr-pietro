extends RigidBody3D

var is_held = false
var holding_controller = null
var muzzle_point: Marker3D

# Shooting settings
var bullet_speed = 50.0
var fire_rate = 0.2  # seconds between shots
var can_shoot = true

func _ready():
	muzzle_point = $MuzzlePoint
	
	# Connect pickup area
	var pickup_area = $PickupArea
	if pickup_area:
		pickup_area.body_entered.connect(_on_pickup_area_entered)

func _process(delta):
	if is_held and holding_controller:
		# Attach gun to controller
		global_transform.origin = holding_controller.global_transform.origin
		global_transform.basis = holding_controller.global_transform.basis
		
		# Check for trigger press
		if Input.is_action_pressed("vr_trigger") and can_shoot:
			shoot()

func _on_pickup_area_entered(body):
	if body.name.contains("Controller"):
		pickup(body)

func pickup(controller):
	if not is_held:
		is_held = true
		holding_controller = controller
		# Disable physics while held
		freeze = true
		print("Gun picked up")

func drop():
	if is_held:
		is_held = false
		holding_controller = null
		# Re-enable physics
		freeze = false
		print("Gun dropped")

func shoot():
	can_shoot = false
	print("BANG! Shooting from position: ", muzzle_point.global_transform.origin)
	
	# Create bullet (simple raycast for now)
	var space_state = get_world_3d().direct_space_state
	var query = PhysicsRayQueryParameters3D.create(
		muzzle_point.global_transform.origin,
		muzzle_point.global_transform.origin + (-muzzle_point.global_transform.basis.z * 100)
	)
	
	var result = space_state.intersect_ray(query)
	if result:
		print("Hit: ", result.collider.name, " at position: ", result.position)
		# Add hit effect here
		if result.collider.has_method("take_damage"):
			result.collider.take_damage()
	else:
		print("Miss!")
	
	# Create visual muzzle flash (simple light)
	var flash = OmniLight3D.new()
	flash.light_energy = 2.0
	flash.light_color = Color.YELLOW
	muzzle_point.add_child(flash)
	await get_tree().create_timer(0.05).timeout
	flash.queue_free()
	
	# Fire rate cooldown
	await get_tree().create_timer(fire_rate).timeout
	can_shoot = true