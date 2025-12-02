extends RigidBody3D

var is_held = false
var holding_controller = null
var muzzle_point: Marker3D
var pickup_area: Area3D

# Shooting settings
var bullet_speed = 50.0
var fire_rate = 0.2
var can_shoot = true
var max_range = 100.0

# Physics settings
var grab_offset = Vector3.ZERO
var last_velocity = Vector3.ZERO
var throw_multiplier = 1.5

func _ready():
	muzzle_point = $MuzzlePoint
	pickup_area = $PickupArea
	
	# Setup physics
	mass = 0.5
	gravity_scale = 1.0
	continuous_cd = true
	contact_monitor = true
	max_contacts_reported = 4
	
	# Make sure collision layers are set
	collision_layer = 1
	collision_mask = 1

func _physics_process(delta):
	if is_held and holding_controller:
		# Store last velocity for throwing
		var new_pos = holding_controller.global_position + holding_controller.global_transform.basis * grab_offset
		last_velocity = (new_pos - global_position) / delta
		
		# Smoothly follow controller
		global_position = new_pos
		global_rotation = holding_controller.global_rotation
		
		# Disable physics while held
		linear_velocity = Vector3.ZERO
		angular_velocity = Vector3.ZERO

func pickup(controller):
	if not is_held:
		print("Picking up gun")
		is_held = true
		holding_controller = controller
		
		# Calculate grab offset
		grab_offset = controller.global_transform.basis.inverse() * (global_position - controller.global_position)
		
		# Disable physics while held
		freeze = true
		linear_velocity = Vector3.ZERO
		angular_velocity = Vector3.ZERO
		
		print("Gun picked up successfully")

func drop():
	if is_held:
		print("Dropping gun")
		is_held = false
		
		# Re-enable physics
		freeze = false
		
		# Apply throw velocity
		linear_velocity = last_velocity * throw_multiplier
		
		holding_controller = null
		last_velocity = Vector3.ZERO
		
		print("Gun dropped successfully")

func shoot():
	if not can_shoot:
		return
		
	can_shoot = false
	print("BANG! Shooting...")
	
	# Get shooting direction
	var from = muzzle_point.global_position
	var direction = -muzzle_point.global_transform.basis.z
	var to = from + direction * max_range
	
	# Perform raycast
	var space_state = get_world_3d().direct_space_state
	var query = PhysicsRayQueryParameters3D.create(from, to)
	query.exclude = [self]
	
	var result = space_state.intersect_ray(query)
	if result:
		print("Hit: ", result.collider.name, " at ", result.position)
		
		# Damage target if it has the method
		if result.collider.has_method("hit"):
			result.collider.hit(result.position)
		
		# Apply physics force to hit objects
		if result.collider is RigidBody3D:
			result.collider.apply_impulse(direction * 5.0, result.position - result.collider.global_position)
		
		# Create visual hit effect
		_create_hit_effect(result.position)
	else:
		print("Miss!")
	
	# Muzzle flash
	_create_muzzle_flash()
	
	# Recoil
	if is_held:
		# Apply small recoil to controller feedback
		pass
	else:
		# Apply physics recoil if dropped
		apply_impulse(direction * -2.0, Vector3.ZERO)
	
	# Fire rate cooldown
	await get_tree().create_timer(fire_rate).timeout
	can_shoot = true

func _create_muzzle_flash():
	var flash = OmniLight3D.new()
	flash.light_energy = 3.0
	flash.light_color = Color(1.0, 0.8, 0.2)
	flash.omni_range = 2.0
	muzzle_point.add_child(flash)
	
	# Fade out
	var tween = create_tween()
	tween.tween_property(flash, "light_energy", 0.0, 0.1)
	await tween.finished
	flash.queue_free()

func _create_hit_effect(position: Vector3):
	# Create hit spark
	var spark = OmniLight3D.new()
	spark.light_energy = 2.0
	spark.light_color = Color.YELLOW
	spark.omni_range = 1.0
	get_parent().add_child(spark)
	spark.global_position = position
	
	await get_tree().create_timer(0.05).timeout
	spark.queue_free()